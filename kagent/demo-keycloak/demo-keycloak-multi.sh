#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Base URL for realm data files in GitHub
GITHUB_RAW_BASE="https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/kagent/demo-keycloak/realm-data"

# Create directories for SSL and realm data
mkdir -p "${SCRIPT_DIR}/ssl"
mkdir -p "${SCRIPT_DIR}/realm-data"

# Download realm data files from GitHub
echo "Downloading Keycloak realm data..."
curl -sSL "${GITHUB_RAW_BASE}/kagent-dev-realm.json" -o "${SCRIPT_DIR}/realm-data/kagent-dev-realm.json"
curl -sSL "${GITHUB_RAW_BASE}/kagent-dev-users-0.json" -o "${SCRIPT_DIR}/realm-data/kagent-dev-users-0.json"
echo "Realm data downloaded successfully."

# Generate SSL certificates
openssl req -nodes -new -x509 -subj "/C=US/ST=/L=/O=solo.io/OU=/CN=keycloak.default" -addext "subjectAltName = DNS:keycloak.default,DNS:host.docker.internal" -keyout "${SCRIPT_DIR}/ssl/server.key" -out "${SCRIPT_DIR}/ssl/server.cert"

# Start Keycloak container
docker run -d --name keycloak -p 8088:8080 -p 8443:8443 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KEYCLOAK_ADMIN_EMAIL=admin@example.com \
  -v "${SCRIPT_DIR}/ssl":/opt/keycloak/ssl:ro \
  -v "${SCRIPT_DIR}/realm-data":/opt/keycloak/data/import:ro \
  quay.io/keycloak/keycloak:21.1.1 start-dev --hostname keycloak.default --import-realm --https-certificate-file=/opt/keycloak/ssl/server.cert --https-certificate-key-file=/opt/keycloak/ssl/server.key


for context in ${MGMT_CONTEXT} ${REMOTE_CONTEXT}; do
kubectl apply -f --context ${context} - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: default
spec:
  type: ExternalName
  externalName: host.docker.internal
  ports:
  - protocol: TCP
    port: 8443
EOF

kubectl create namespace kagent --context ${context}

kubectl apply -f --context ${context} - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: kagent-backend-secret
  namespace: kagent
type: Opaque
stringData:
  clientSecret: hiIXdxOG5epokX92Es36RPEWuq4lORnw
EOF
done

export BACKEND_CLIENT_ID="kagent-backend"
export BACKEND_CLIENT_SECRET_REF="kagent-backend-secret"
export BACKEND_CLIENT_SECRET="hiIXdxOG5epokX92Es36RPEWuq4lORnw"
export BACKEND_ISSUER="https://keycloak.default:8443/realms/kagent-dev"
export FRONTEND_AUTH_ENDPOINT="https://keycloak.default:8443/realms/kagent-dev/protocol/openid-connect/auth"
export FRONTEND_LOGOUT_ENDPOINT="https://keycloak.default:8443/realms/kagent-dev/protocol/openid-connect/logout"
export FRONTEND_TOKEN_ENDPOINT="https://keycloak.default:8443/realms/kagent-dev/protocol/openid-connect/token"