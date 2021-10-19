# Multi-root certs with VirtualMesh using Vault

*Disclaimer: This set of instructions is a work in progress.*

This example assumes that you are running Vault as an external server. To follow along with a dev instance of Vault, use the following command:

```
vault server -dev -dev-listen-address=0.0.0.0:8200
```

For the rest of the commands, make sure you have the VAULT_SERVER env variable set to your host ip (e.g. "http://<host-ip>:8200").
Grab the VAULT_TOKEN from the Vault server output.  

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

## Install root A into Vault

```
./scripts/04-install-roota.sh
```

## Create secrets and Virtual Mesh

```
./scripts/05-create-virtual-mesh.sh
```