# Multi-root certs with VirtualMesh using Vault

*Disclaimer: This set of instructions is a work in progress.*

This example assumes that you are running Vault as an external server. To follow along with a dev instance of Vault, use the following command:

```
vault server -dev -dev-listen-address=0.0.0.0:8200
```

For the rest of the commands, make sure you have the VAULT_ADDR env variable set to your host ip (e.g. "http://host-ip:8200").
Grab the VAULT_TOKEN from the Vault server output and set that as an environment variable named VAULT_TOKEN.

## Pre-requisites

- openssl
- vault
- jq

To check your system, run 

```
./scripts/01-check-prereqs.sh
```

## Establishing initial root (rootA)
Create the first root cert.

```
./scripts/02-create-root-a.sh
```

## Initialize Vault with the pki and pki_int mounts

```
./scripts/03-init-vault.sh
```

If you check the terminal window where you started the dev server, you should see the following output.

```
2021-10-29T15:41:16.380Z [INFO]  core: successful mount: namespace="" path=pki/ type=pki
2021-10-29T15:41:16.526Z [INFO]  core: successful mount: namespace="" path=pki_int/ type=pki
```

## Install root A into Vault

```
./scripts/04-install-roota.sh
```

## Create secrets and Virtual Mesh

Edit virtual-mesh.yaml and replace `"http://<vault-server-address>:8200"` with your vault server address.

```
./scripts/05-create-virtual-mesh.sh
```

## Update Istio deployments in remote clusters

This will patch the enteprise-agent deployment with a role binding for the istio sidecar and inject a vault agent container into istiod to enable certificate retrieval and rotation.  

Copy `rb-values.yaml` to `cluster1-values.yaml` and `cluster2-values.yaml` and modify your relay address with the value from ENDPOINT_GLOO_MESH.

```
./scripts/06-update-rbac.sh
```

Now, test access to Bookinfo on cluster1.  You should see an error in the browser complaining about the certificates.  To fix that, we need to restart the pods in istio-system and the workloads.

## Restart workloads

```
./scripts/07-restart-workloads.sh
```

## Test the application

Refresh the browser to make sure you can still access bookinfo.  You can also check the workload certs.

```
kubectl --context ${CLUSTER1} exec -t deploy/reviews-v1 -c istio-proxy \
-- openssl s_client -showcerts -connect ratings:9080
```

You should now see the `issuer=CN = Istio` along with `CN = gloo-mesh-roota` in the resulting output.