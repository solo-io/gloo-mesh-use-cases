# Gloo Platform reference architecture in Azure


## Pre-requisites

- A resource group named `azure-gloo-refarch-hub` for the hub resources

```bash
az group create -n azure-gloo-refarch-hub -l eastus
```

- A valid license key for Gloo Mesh Enterprise, in a file called `license.auto.tfvars` in the root of this repo

```bash
gloo_mesh_license_key = "license-key-here"
```

## Deploy

```bash
terraform init
terraform apply
```

## Notes

- All clusters have overlapping PodCIDRs, as= 

## Cleanup

```bash
terraform destroy
```

## References

- [Setup Multicluster Gloo Mesh](https://docs.solo.io/gloo-mesh-enterprise/latest/getting_started/multi/gs_multi/)