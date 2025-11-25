#!/bin/bash

set -e

# Check if required environment variables are defined
required_vars=("CLUSTER_NAME" "ISTIO_IMAGE" "ECS_DOMAIN" "AWS_ACCOUNT" "GLOO_MESH_LICENSE_KEY")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not defined."
    exit 1
  fi
done

# Auto-detect and set REPO and HELM_REPO based on Istio version if not already set
if [ -z "$HELM_REPO" ] || [ -z "$REPO" ]; then
  # Extract Istio version number (e.g., "1.28.1" from "1.28.1-solo")
  ISTIO_VERSION_NUM=$(echo $ISTIO_IMAGE | sed 's/-solo//')
  ISTIO_MAJOR_MINOR=$(echo $ISTIO_VERSION_NUM | cut -d. -f1,2)
  
  # Determine repo location based on Istio version
  # Istio 1.29+ uses the new repository location
  if [ "$(printf '%s\n' "1.29" "$ISTIO_MAJOR_MINOR" | sort -V | head -n1)" = "1.29" ]; then
    # Istio 1.29 and later - use new repo locations
    export REPO=${REPO:-us-docker.pkg.dev/soloio-img/istio}
    export HELM_REPO=${HELM_REPO:-us-docker.pkg.dev/soloio-img/istio-helm}
    echo "Detected Istio 1.29 or later, using updated repository locations."
  else
    # Istio 1.28 and earlier - require REPO_KEY
    if [ -z "$REPO_KEY" ]; then
      echo "Error: For Istio 1.28 and earlier, REPO_KEY must be set."
      echo "Set REPO_KEY to the 12-character hash from the repo URL."
      exit 1
    fi
    export REPO=${REPO:-us-docker.pkg.dev/gloo-mesh/istio-${REPO_KEY}}
    export HELM_REPO=${HELM_REPO:-us-docker.pkg.dev/gloo-mesh/istio-helm-${REPO_KEY}}
    echo "Detected Istio 1.28 or earlier, using 1.28 repository locations."
  fi
fi

echo "========================================="
echo "Installing Istio ambient mesh components"
echo "========================================="
echo ""
echo "Cluster: $CLUSTER_NAME"
echo "Istio Version: $ISTIO_IMAGE"
echo "Helm Repository: $HELM_REPO"
echo ""

# Step 1: Install istio-base
echo "Step 1/4: Installing istio-base chart..."
helm upgrade --install istio-base oci://${HELM_REPO}/base \
  --namespace istio-system \
  --create-namespace \
  --version ${ISTIO_IMAGE} \
  -f <(eval "echo \"$(cat manifests/istio-base-values.yaml)\"")

if [ $? -eq 0 ]; then
  echo "✓ istio-base installed successfully"
else
  echo "✗ Failed to install istio-base"
  exit 1
fi
echo ""

# Step 2: Install istiod
echo "Step 2/4: Installing istiod control plane..."
helm upgrade --install istiod oci://${HELM_REPO}/istiod \
  --namespace istio-system \
  --version ${ISTIO_IMAGE} \
  -f <(eval "echo \"$(cat manifests/istiod-values.yaml)\"")

if [ $? -eq 0 ]; then
  echo "✓ istiod installed successfully"
  echo "Waiting for istiod to be ready..."
  kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system
  echo "✓ istiod is ready"
else
  echo "✗ Failed to install istiod"
  exit 1
fi
echo ""

# Step 3: Install istio-cni
echo "Step 3/4: Installing Istio CNI node agent daemonset..."
helm upgrade --install istio-cni oci://${HELM_REPO}/cni \
  --namespace istio-system \
  --version ${ISTIO_IMAGE} \
  -f <(eval "echo \"$(cat manifests/istio-cni-values.yaml)\"")

if [ $? -eq 0 ]; then
  echo "✓ istio-cni installed successfully"
  echo "Waiting for CNI daemonset to be ready..."
  kubectl rollout status daemonset/istio-cni-node -n istio-system --timeout=300s
  echo "✓ istio-cni is ready"
else
  echo "✗ Failed to install istio-cni"
  exit 1
fi
echo ""

# Step 4: Install ztunnel
echo "Step 4/4: Installing ztunnel daemonset..."
helm upgrade --install ztunnel oci://${HELM_REPO}/ztunnel \
  --namespace istio-system \
  --version ${ISTIO_IMAGE} \
  -f <(eval "echo \"$(cat manifests/ztunnel-values.yaml)\"")

if [ $? -eq 0 ]; then
  echo "✓ ztunnel installed successfully"
  echo "Waiting for ztunnel daemonset to be ready..."
  kubectl rollout status daemonset/ztunnel -n istio-system --timeout=300s
  echo "✓ ztunnel is ready"
else
  echo "✗ Failed to install ztunnel"
  exit 1
fi
echo ""

# Verify all components
echo "========================================="
echo "Verifying ambient mesh components"
echo "========================================="
echo ""
kubectl get pods -n istio-system
echo ""

# Label istio-system namespace
echo "========================================="
echo "Labeling istio-system namespace"
echo "========================================="
echo ""
echo "Labeling istio-system namespace with network: ${CLUSTER_NAME}..."
kubectl label namespace istio-system topology.istio.io/network=${CLUSTER_NAME} --overwrite
echo "✓ Namespace labeled successfully"
echo ""

echo "========================================="
echo "Installation complete!"
echo "========================================="
echo ""
echo "Istio ambient mesh has been successfully installed and configured."
echo "Next steps: Create an east-west gateway to facilitate traffic between ECS and EKS."

