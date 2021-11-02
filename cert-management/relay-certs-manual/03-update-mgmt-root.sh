#!/bin/sh

RELAY_ROOT_CERT_NAME=relay-root
RELAY_SERVER_CERT_NAME=relay-server-tls
RELAY_SIGNING_CERT_NAME=relay-tls-signing 
CONCATENATED_ROOT_CERT_NAME=combined-root
MGMT=mgmt
CLUSTER1=cluster1 
CLUSTER2=cluster2 

echo "Updating clusters with multiple roots"

kubectl create secret generic ${RELAY_SERVER_CERT_NAME}-secret \
  --from-file=tls.key=${RELAY_SERVER_CERT_NAME}.key \
  --from-file=tls.crt=${RELAY_SERVER_CERT_NAME}.crt \
  --from-file=ca.crt=${CONCATENATED_ROOT_CERT_NAME}.crt \
  --dry-run=client -oyaml | kubectl apply -f- \
  --context ${MGMT} \
  --namespace gloo-mesh

# Note: ${RELAY_ROOT_CERT_NAME}-tls-secret must match the agent Helm value `relay.rootTlsSecret.Name`
for context in ${MGMT} ${CLUSTER1} ${CLUSTER2}; do
    echo "creating matching root cert for agent in cluster context ${context}..."
    kubectl create secret generic ${RELAY_ROOT_CERT_NAME}-tls-secret \
        --from-file=ca.crt=${CONCATENATED_ROOT_CERT_NAME}.crt \
        --dry-run=client -oyaml | kubectl apply -f- \
        --context ${context} \
        --namespace gloo-mesh
done

# Restart the remote agents and the mgmt cluster 
for context in ${MGMT} ${CLUSTER1} ${CLUSTER2}; do
  kubectl --context ${context} rollout restart deploy -n gloo-mesh
done

echo "Done."