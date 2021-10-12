#! /bin/bash

MGMT=mgmt
CLUSTER1=cluster1
CLUSTER2=cluster2

kubectl --context ${MGMT} create ns gloo-mesh
kubectl --context ${CLUSTER1} create ns gloo-mesh
kubectl --context ${CLUSTER2} create ns gloo-mesh

# Create TLS secrets for root CA for cert-manager
kubectl --context ${MGMT} create secret tls ca-key-pair -n gloo-mesh \
  --cert=./relay-root-cert.pem --key=./relay-root-key.pem
kubectl --context ${CLUSTER1} create secret tls ca-key-pair -n gloo-mesh \
  --cert=./relay-root-cert.pem --key=./relay-root-key.pem
kubectl --context ${CLUSTER2} create secret tls ca-key-pair -n gloo-mesh \
  --cert=./relay-root-cert.pem --key=./relay-root-key.pem

# Create relay tokens (tokens used for AuthN)
kubectl --context ${MGMT} apply -f relay-identity-token-secret.yaml
kubectl --context ${CLUSTER1} apply -f relay-identity-token-secret.yaml
kubectl --context ${CLUSTER2} apply -f relay-identity-token-secret.yaml

kubectl --context ${MGMT} apply -f relay-fwd-identity-token-secret.yaml
kubectl --context ${CLUSTER1} apply -f relay-fwd-identity-token-secret.yaml
kubectl --context ${CLUSTER2} apply -f relay-fwd-identity-token-secret.yaml

# Create Issuer for all clusters
for CONTEXT in ${MGMT} ${CLUSTER1} ${CLUSTER2}; do
echo "creating cert-manager Issuer for cluster ${CONTEXT}"
kubectl apply --context ${CONTEXT} -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ca-issuer
  namespace: gloo-mesh
spec:
  ca:
    secretName: ca-key-pair
EOF
done

# Create server Certificate
kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: relay-server-tls
  namespace: gloo-mesh
spec:
  commonName: "enterprise-networking-ca"
  dnsNames:
    - "enterprise-networking-ca"
    - "enterprise-networking-ca.gloo-mesh"
    - "enterprise-networking-ca.gloo-mesh.svc"
    - "*.gloo-mesh"
  secretName: relay-server-tls-secret
  duration: 24h
  renewBefore: 30m
  privateKey:
    rotationPolicy: Always
    algorithm: RSA
    size: 2048
  usages:
    - digital signature
    - key encipherment
    - server auth
    - client auth
  issuerRef:
    name: ca-issuer
    kind: Issuer
    group: cert-manager.io
EOF

# create client certificates for each leaf cluster
kubectl apply --context ${CLUSTER1} -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: relay-client-tls
  namespace: gloo-mesh
spec:
  commonName: "enterprise-networking-ca"
  dnsNames:
    - "cluster1"
  secretName: relay-client-tls-secret
  duration: 24h
  renewBefore: 30m
  privateKey:
    rotationPolicy: Always
    algorithm: RSA
    size: 2048
  issuerRef:
    name: ca-issuer
    kind: Issuer
    group: cert-manager.io
EOF

kubectl apply --context ${CLUSTER2} -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: relay-client-tls
  namespace: gloo-mesh
spec:
  commonName: "enterprise-networking-ca"
  dnsNames:
    - "cluster2"
  secretName: relay-client-tls-secret
  duration: 24h
  renewBefore: 30m
  privateKey:
    rotationPolicy: Always
    algorithm: RSA
    size: 2048
  issuerRef:
    name: ca-issuer
    kind: Issuer
    group: cert-manager.io
EOF

