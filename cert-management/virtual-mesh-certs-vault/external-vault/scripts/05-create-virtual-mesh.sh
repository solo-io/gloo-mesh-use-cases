#!/bin/bash

if [[ "${PWD}" == *scripts ]]; then
  cd ..
fi

kubectl create secret generic vault-token --context ${MGMT} -n gloo-mesh --from-literal=token=${VAULT_TOKEN}
kubectl create secret generic vault-token --context ${CLUSTER1} -n gloo-mesh --from-literal=token=${VAULT_TOKEN}
kubectl create secret generic vault-token --context ${CLUSTER2} -n gloo-mesh --from-literal=token=${VAULT_TOKEN}

kubectl apply -f virtual-mesh.yaml --context ${MGMT}