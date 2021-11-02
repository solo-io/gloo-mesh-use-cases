#!/bin/sh

RELAY_ROOT_CERT_NAME=relay-root
RELAY_SERVER_CERT_NAME=relay-server-tls
RELAY_SIGNING_CERT_NAME=relay-tls-signing 
MGMT=mgmt
CLUSTER1=cluster1 
CLUSTER2=cluster2 

echo "creating root cert ..."
openssl req -new -newkey rsa:4096 -x509 -sha256 \
    -days 3650 -nodes -out ${RELAY_ROOT_CERT_NAME}.crt -keyout ${RELAY_ROOT_CERT_NAME}.key \
    -subj "/CN=enterprise-networking-mgmt-ca" \
    -addext "extendedKeyUsage = clientAuth, serverAuth"

echo "creating grpc server tls cert ..."
cat > "${RELAY_SERVER_CERT_NAME}.conf" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
DNS = *.gloo-mesh
EOF

# Generate private key
openssl genrsa -out "${RELAY_SERVER_CERT_NAME}.key" 2048
# Generate CSR
openssl req -new -key "${RELAY_SERVER_CERT_NAME}.key" -out ${RELAY_SERVER_CERT_NAME}.csr -subj "/CN=enterprise-networking-mgmt-ca" -config "${RELAY_SERVER_CERT_NAME}.conf"

# Sign certificate with root
openssl x509 -req \
    -days 3650 \
    -CA ${RELAY_ROOT_CERT_NAME}.crt -CAkey ${RELAY_ROOT_CERT_NAME}.key \
    -set_serial 0 \
    -in ${RELAY_SERVER_CERT_NAME}.csr -out ${RELAY_SERVER_CERT_NAME}.crt \
    -extensions v3_req -extfile "${RELAY_SERVER_CERT_NAME}.conf"

# create secrets from certs
# Note: ${RELAY_SERVER_CERT_NAME}-secret must match the server Helm value `relayTlsSecret.Name`
kubectl create secret generic ${RELAY_SERVER_CERT_NAME}-secret \
  --from-file=tls.key=${RELAY_SERVER_CERT_NAME}.key \
  --from-file=tls.crt=${RELAY_SERVER_CERT_NAME}.crt \
  --from-file=ca.crt=${RELAY_ROOT_CERT_NAME}.crt \
  --dry-run=client -oyaml | kubectl apply -f- \
  --context ${MGMT} \
  --namespace gloo-mesh

kubectl create secret generic ${RELAY_SIGNING_CERT_NAME}-secret \
  --from-file=tls.key=${RELAY_SERVER_CERT_NAME}.key \
  --from-file=tls.crt=${RELAY_SERVER_CERT_NAME}.crt \
  --from-file=ca.crt=${RELAY_ROOT_CERT_NAME}.crt \
  --dry-run=client -oyaml | kubectl apply -f- \
  --context ${MGMT} \
  --namespace gloo-mesh
  
# Note: ${RELAY_ROOT_CERT_NAME}-tls-secret must match the agent Helm value `relay.rootTlsSecret.Name`
for context in ${MGMT} ${CLUSTER1} ${CLUSTER2}; do
echo "creating matching root cert for agent in cluster context ${context}..."
  kubectl create secret generic ${RELAY_ROOT_CERT_NAME}-tls-secret \
  --from-file=ca.crt=${RELAY_ROOT_CERT_NAME}.crt \
  --dry-run=client -oyaml | kubectl apply -f- \
  --context ${context} \
  --namespace gloo-mesh
done

echo "Done."