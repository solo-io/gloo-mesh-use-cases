#!/usr/bin/env bash
SCRIPT_DIR=$(dirname "$0")

## Preflight Checks
if [[ -z "$ISTIO_VERSION" ]]; then
  echo "ISTIO_VERSION environment variable is not set. Please set it to the desired Istio version."
  exit 1
fi

if [[ -z "$REPO_KEY" ]]; then
  echo "REPO_KEY environment variable is not set. Please set it to your repository key."
  exit 1
fi

if [[ -z "$CLUSTER1" ]]; then
  echo "CLUSTER1 environment variable is not set. Please set it to the target cluster name."
  exit 1
fi

if [[ -z "$CLUSTER2" ]]; then
  echo "CLUSTER2 environment variable is not set. Please set it to the target cluster name."
  exit 1
fi

if [[ -z "$GLOO_OPERATOR_VERSION" ]]; then
  echo "GLOO_OPERATOR_VERSION environment variable is not set. Please set it to the desired Gloo Operator version."
  exit 1
fi

if [[ -z "$GLOO_MESH_LICENSE_KEY" ]]; then
  echo "GLOO_MESH_LICENSE_KEY environment variable is not set. Please set it to your Gloo Mesh license key."
  exit 1
fi

ISTIO_IMAGE=${ISTIO_VERSION}-solo

OS_RAW=${OS:-$(uname -s)}
OS_NORMALIZED=$(echo "$OS_RAW" | tr '[:upper:]' '[:lower:]')
case "$OS_NORMALIZED" in
  linux*) OS="linux" ;;
  darwin*) OS="osx" ;;
  *) echo "Error: unsupported OS '$OS_RAW'. Expected Linux or macOS." && exit 1 ;;
esac
ARCH=$(uname -m | sed -E 's/aarch/arm/; s/x86_64/amd64/; s/armv71/armv7/')
echo "Detected OS: $OS, ARCH: $ARCH"

mkdir -p ~/.istioctl/bin
DOWNLOAD_URL="https://storage.googleapis.com/istio-binaries-$REPO_KEY/$ISTIO_IMAGE/istioctl-$ISTIO_IMAGE-$OS-$ARCH.tar.gz"
if ! curl -fIsL "$DOWNLOAD_URL" >/dev/null 2>&1; then
  echo "Error: download URL not accessible: $DOWNLOAD_URL"
  exit 1
fi
curl -sSL "$DOWNLOAD_URL" | tar xzf - -C ~/.istioctl/bin
chmod +x ~/.istioctl/bin/istioctl
ISTIOCTL=~/.istioctl/bin/istioctl

$ISTIOCTL version --remote=false

# Create a shared root of trust for the clusters
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
cd istio-${ISTIO_VERSION}
mkdir -p certs
pushd certs
make -f ../tools/certs/Makefile.selfsigned.mk root-ca

for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    make -f ../tools/certs/Makefile.selfsigned.mk ${CLUSTER}-cacerts
    kubectl --context=${CLUSTER} create ns istio-system || true
    kubectl --context=${CLUSTER} create secret generic cacerts -n istio-system \
        --from-file=${CLUSTER}/ca-cert.pem \
        --from-file=${CLUSTER}/ca-key.pem \
        --from-file=${CLUSTER}/root-cert.pem \
        --from-file=${CLUSTER}/cert-chain.pem
done

for cluster in ${CLUSTER1} ${CLUSTER2}; do
    kubectl --context ${cluster} apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
done

# Deploy Ambient
for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    helm install gloo-operator oci://us-docker.pkg.dev/solo-public/gloo-operator-helm/gloo-operator \
        --version ${GLOO_OPERATOR_VERSION} \
        -n gloo-mesh \
        --create-namespace \
        --kube-context="${CLUSTER}" \
        --set manager.env.SOLO_ISTIO_LICENSE_KEY=${GLOO_MESH_LICENSE_KEY} 
done

for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    kubectl --context="${CLUSTER}" wait --for=condition=available --timeout=5m deployment/gloo-operator -n gloo-mesh
done

for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    kubectl --context="${CLUSTER}" apply -n gloo-mesh -f - <<EOF
apiVersion: operator.gloo.solo.io/v1
kind: ServiceMeshController
metadata:
  name: managed-istio
  labels:
    app.kubernetes.io/name: managed-istio
spec:
  cluster: ${CLUSTER}
  network: ${CLUSTER}
  dataplaneMode: Ambient
  installNamespace: istio-system
  version: ${ISTIO_VERSION}
EOF
done

sleep 40

# Link clusters
for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    kubectl create namespace istio-eastwest --context ${CLUSTER} 
    $ISTIOCTL multicluster expose --namespace istio-eastwest --context ${CLUSTER}
done

sleep 10

$ISTIOCTL multicluster link --namespace istio-eastwest --contexts=${CLUSTER1},${CLUSTER2}

for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    kubectl --context="${CLUSTER}" get gateways -n istio-eastwest
done

# Deploy bookinfo
for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    kubectl --context="${CLUSTER}" create ns bookinfo
    kubectl --context="${CLUSTER}" label namespace bookinfo istio.io/dataplane-mode=ambient
    kubectl --context="${CLUSTER}" -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'app'
    kubectl --context="${CLUSTER}" -n bookinfo apply -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/productpage-with-curl.yaml
    kubectl --context="${CLUSTER}" -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'account'
    kubectl --context="${CLUSTER}" -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo-versions.yaml
done

sleep 30

for CLUSTER in ${CLUSTER1} ${CLUSTER2}; do
    kubectl --context="${CLUSTER}" label service productpage -n bookinfo solo.io/service-scope=global
    kubectl --context="${CLUSTER}" annotate service productpage -n bookinfo networking.istio.io/traffic-distribution=Any
done

# Use the ratings app to send a request to the productpage.bookinfo.mesh.internal hostname.
kubectl -n bookinfo --context $CLUSTER1 debug -i pods/$(kubectl get pod -l app=ratings \
--context $CLUSTER1 -A -o jsonpath='{.items[0].metadata.name}') \
--image=curlimages/curl -- curl -vik http://productpage.bookinfo.mesh.internal:9080/productpage