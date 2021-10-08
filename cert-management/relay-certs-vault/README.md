# Managing Relay Certificates with Hashicorp Vault

## Pre-requisites
* Two Kubernetes clusters
* kubectl installled
* helm installed

## Installing Vault
For this demonstration, we will install Vault server on the management cluster in dev mode.  We will use Helm to perform the installation.

First, fetch the helm chart for Vault.

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
kubectl create ns vault
```

### OpenShift Installation
Skip this section if not using OpenShift.

Install Vault

```
helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --set "global.openshift=true" \
  --set "server.dev.enabled=true" \
  --set "injector.image.repository=docker.io/hashicorp/vault-k8s" \
  --set "injector.agentImage.repository=docker.io/hashicorp/vault" \
  --set "server.image.repository=docker.io/hashicorp/vault"
```

### Install Vault
Skip this section if using OpenShift

```
helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --set "server.dev.enabled=true"
```

### Verify installation
Check the pods in the vault namespace.

```
> kubectl get pods -n vault
NAME                                    READY   STATUS  RESTARTS    AGE
vault-0                                 1/1     Running 0           15s
vault-agent-injector-69556c7d9d-7jhxq   1/1     Running 0           20s
```

## Configure Kubernetes authentication

Follow these steps to enable Kubernetes authn in Vault.

Exec into the `vault-0` pod.
```
kubectl exec -it vault-0 -n vault -- /bin/sh
/ #
```

Find the issuer for your Kubernetes cluster.  This can be found in one of two ways.

First, try querying the default service account.

```
kubectl proxy &
curl --silent http://127.0.0.1:8001/api/v1/namespaces/default/serviceaccounts/default/token \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{"apiVersion": "authentication.k8s.io/v1", "kind": "TokenRequest"}' \
  | jq -r '.status.token' \
  | cut -d . -f2 \
  | base64 -D
```

If that return an empty string, then the information you need will be in a configuration file.

```
kubectl proxy &
curl --silent http://127.0.0.1:8001/.well-known/openid-configuration | jq -r .issuer
```

In most cluster you will either see `https://kubernetes.default.svc.cluster.local` or `https://kubernetes.default.svc` but it could be different based on your cloud provider.

Enable the Kubernetes authentication method making sure to set the issuer field appropriately.

```
vault auth enable kubernetes
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  issuer="https://kubernetes.default.svc"
```

Exit the pod.

```
exit
```

## Connecting to Vault from a remote cluster
If you are attempting to connect to Vault from a remote cluster here are a couple of helpful tips.

### Getting the Vault Token
In order to login to Vault for administration, you will need the Vault Token.  Check the `vault-0` pod in the cluster hosting Vault and grab the token from the logs.

Log snippet below:
```
You may need to set the following environment variable:

    $ export VAULT_ADDR='http://0.0.0.0:8200'

The unseal key and root token are displayed below in case you want to
seal/unseal the Vault or re-authenticate.

Unseal Key: CefHBwrMlAZGDOKtkVOSyUGvRNDS3c1vTeJNxX/58V8=
Root Token: root
```

Exposing that token in the environment variable VAULT_TOKEN will allow you to do `vault login root` without needing to specify the token.

You should also set VAULT_ADDR to the external address for your Vault server.

### Dealing with Self-Signed Certs
If you created a secure route with a self-signed cert in front of Vault, then you will need to provide the certificate to the vault client for verification.

You can grab the certifcate using openssl.

```
openssl s_client -connect ${VAULT_HOST}:${VAULT_PORT} -showcerts
```

Get the first certificate from "-----BEGIN CERTIFICATE-----" to "-----END CERTIFICATE-----" and save the contents to a file.  Then, set the environment variable VAULT_CACERT to point to that file.
