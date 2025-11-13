#!/usr/bin/env bash

if [[ -z "$GLOO_MESH_VERSION" ]]; then
  echo "GLOO_MESH_VERSION is not set. Please set it to the desired Gloo Mesh version."
  exit 1
fi

if [[ -z "$GLOO_MESH_LICENSE_KEY" ]]; then
  echo "GLOO_MESH_LICENSE_KEY is not set. Please set it to your Gloo Mesh license key."
  exit 1
fi

if [[ -z "$MGMT" ]]; then
  echo "MGMT is not set. Please set it to the name of the management cluster."
  exit 1
fi

if [[ -z "$CLUSTER1" ]]; then
  echo "CLUSTER1 is not set. Please set it to the name of the first data plane cluster."
  exit 1
fi

if [[ -z "$CLUSTER2" ]]; then
  echo "CLUSTER2 is not set. Please set it to the name of the second data plane cluster."
  exit 1
fi

if [[ -z "$GLOO_OPERATOR_VERSION" ]]; then
  echo "GLOO_OPERATOR_VERSION is not set. Please set it to the desired Gloo Operator version."
  exit 1
fi

if [[ -z "$ISTIO_VERSION" ]]; then
  echo "ISTIO_VERSION is not set. Please set it to the desired Istio version."
  exit 1
fi

# Assume management cluster context is current
kubectl config use-context "$MGMT"

curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION="$GLOO_MESH_VERSION" sh -
export PATH="$PATH:$HOME/.gloo-mesh/bin"

MESHCTL=$HOME/.gloo-mesh/bin/meshctl

$MESHCTL version

$MESHCTL install --profiles mgmt-server \
  --set common.cluster=${MGMT} \
  --set licensing.glooMeshLicenseKey="${GLOO_MESH_LICENSE_KEY}"

export TELEMETRY_GATEWAY_IP=$(kubectl get svc -n gloo-mesh gloo-telemetry-gateway -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
export TELEMETRY_GATEWAY_PORT=$(kubectl get svc -n gloo-mesh gloo-telemetry-gateway -o jsonpath='{.spec.ports[?(@.name=="otlp")].port}')
export TELEMETRY_GATEWAY_ADDRESS=${TELEMETRY_GATEWAY_IP}:${TELEMETRY_GATEWAY_PORT}

# Create a global workspace
kubectl apply -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: $MGMT
  namespace: gloo-mesh
spec:
  workloadClusters:
    - name: '*'
      namespaces:
        - name: '*'
---
apiVersion: v1
kind: Namespace
metadata:
  name: gloo-mesh-config
---
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: $MGMT
  namespace: gloo-mesh-config
spec:
  options:
    serviceIsolation:
      enabled: false
    federation:
      enabled: false
      serviceSelector:
      - {}
    eastWestGateways:
    - selector:
        labels:
          istio: eastwestgateway
EOF

sleep 20

# Install the Gloo Data plane
$MESHCTL cluster register $CLUSTER1 \
--remote-context $CLUSTER1 \
--profiles agent,ratelimit,extauth \
--telemetry-server-address $TELEMETRY_GATEWAY_ADDRESS

$MESHCTL cluster register $CLUSTER2 \
--remote-context $CLUSTER2 \
--profiles agent,ratelimit,extauth \
--telemetry-server-address $TELEMETRY_GATEWAY_ADDRESS

sleep 20

$MESHCTL check

for CLUSTER in $CLUSTER1 $CLUSTER2; do
  helm install gloo-operator oci://us-docker.pkg.dev/solo-public/gloo-operator-helm/gloo-operator \
  --version "$GLOO_OPERATOR_VERSION" \
  --kube-context $CLUSTER \
  -n gloo-mesh \
  --create-namespace \
  --set manager.env.SOLO_ISTIO_LICENSE_KEY=${GLOO_MESH_LICENSE_KEY}

  sleep 20

  kubectl apply -n gloo-mesh --context $CLUSTER -f - <<EOF
  apiVersion: operator.gloo.solo.io/v1
  kind: ServiceMeshController
  metadata:
    name: managed-istio
    labels:
      app.kubernetes.io/name: managed-istio
  spec:
    cluster: ${CLUSTER}
    dataplaneMode: Sidecar
    installNamespace: istio-system
    version: $ISTIO_VERSION
EOF
done

