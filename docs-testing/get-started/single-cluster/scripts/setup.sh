#!/bin/bash

if [[ -z "$SOLO_LICENSE_KEY" ]]; then
  echo "Error: SOLO_LICENSE_KEY environment variable is not set."
  exit 1
fi

if [[ -z "$GLOO_OPERATOR_VERSION" ]]; then
  echo "Error: GLOO_OPERATOR_VERSION environment variable is not set."
  exit 1
fi

if [[ -z "$ISTIO_VERSION" ]]; then
  echo "Error: ISTIO_VERSION environment variable is not set."
  exit 1
fi

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

helm install gloo-operator oci://us-docker.pkg.dev/solo-public/gloo-operator-helm/gloo-operator \
--version ${GLOO_OPERATOR_VERSION} \
-n gloo-mesh \
--create-namespace \
--set manager.env.SOLO_ISTIO_LICENSE_KEY=${SOLO_LICENSE_KEY}

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gloo-operator -n gloo-mesh --timeout=180s

echo "Gloo Mesh Operator installed successfully."

kubectl apply -n gloo-mesh -f -<<EOF
apiVersion: operator.gloo.solo.io/v1
kind: ServiceMeshController
metadata:
  name: managed-istio
  labels:
    app.kubernetes.io/name: managed-istio
spec:
  dataplaneMode: Ambient
  installNamespace: istio-system
  version: ${ISTIO_VERSION}
EOF

sleep 20

kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s

echo "Istio installed successfully."

## Deploy a sample application
kubectl create ns bookinfo
kubectl label ns bookinfo istio.io/dataplane-mode=ambient

# deploy bookinfo application components for all versions
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml -l 'app'
# deploy an updated product page with extra container utilities such as 'curl' and 'netcat'
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/productpage-with-curl.yaml
# deploy all bookinfo service accounts
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml -l 'account'

sleep 10
kubectl wait --for=condition=ready pod -l app=productpage -n bookinfo --timeout=180s

echo "Bookinfo application deployed successfully."

