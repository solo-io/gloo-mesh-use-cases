#!/bin/sh

RELAY_ROOT_CERT_NAME=relay-root
REMOTE_CLUSTER_ROOT_NAME=remote-cluster-root
RELAY_SERVER_CERT_NAME=relay-server-tls
RELAY_SIGNING_CERT_NAME=relay-tls-signing 
CONCATENATED_ROOT_CERT_NAME=combined-root
MGMT=mgmt
CLUSTER1=cluster1 
CLUSTER2=cluster2 
RELAY_CLIENT_CERT_NAME=relay-client-tls

echo "creating root cert for remote clusters"
openssl req -new -newkey rsa:4096 -x509 -sha256 \
    -days 3650 -nodes -out ${REMOTE_CLUSTER_ROOT_NAME}.crt -keyout ${REMOTE_CLUSTER_ROOT_NAME}.key \
    -subj "/CN=enterprise-networking-remote-ca" \
    -addext "extendedKeyUsage = clientAuth, serverAuth"

# Concatenate the REMOTE_CLUSTER_ROOT_NAME cert and the RELAY_ROOT_CERT_NAME cert
cat ${REMOTE_CLUSTER_ROOT_NAME}.crt ${RELAY_ROOT_CERT_NAME}.crt > ${CONCATENATED_ROOT_CERT_NAME}.crt

for cluster in ${MGMT} ${CLUSTER1} ${CLUSTER2}; do
    echo "Creating relay client-certs for cluster ${cluster}..."
    # The value here is the most important, the management plane uses the SAN to figure out the identity
    # so replace the cluster names here if different from the context names.
    echo "[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
DNS = ${cluster}" > "${RELAY_CLIENT_CERT_NAME}.conf"

    # Generate private key
    openssl genrsa -out "${RELAY_CLIENT_CERT_NAME}.key" 2048

    # Generate CSR
    openssl req -new -key "${RELAY_CLIENT_CERT_NAME}.key" -out ${RELAY_CLIENT_CERT_NAME}.csr -subj "/CN=enterprise-networking-remote-ca" -config "${RELAY_CLIENT_CERT_NAME}.conf"

    # Sign certificate with remote cluster root
    openssl x509 -req \
        -days 3650 \
        -CA ${RELAY_ROOT_CERT_NAME}.crt -CAkey ${RELAY_ROOT_CERT_NAME}.key \
        -set_serial 0 \
        -in ${RELAY_CLIENT_CERT_NAME}.csr -out ${RELAY_CLIENT_CERT_NAME}.crt \
        -extensions v3_req -extfile "${RELAY_CLIENT_CERT_NAME}.conf"

    # create relay secret
    kubectl create secret generic ${RELAY_CLIENT_CERT_NAME}-secret \
        --from-file=tls.key=${RELAY_CLIENT_CERT_NAME}.key \
        --from-file=tls.crt=${RELAY_CLIENT_CERT_NAME}.crt \
        --from-file=ca.crt=${CONCATENATED_ROOT_CERT_NAME}.crt \
        --dry-run=client -oyaml | kubectl apply -f- \
        --context ${cluster} \
        --namespace gloo-mesh
done

echo "Done."