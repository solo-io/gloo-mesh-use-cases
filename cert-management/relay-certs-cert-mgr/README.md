Using Cert Manager to Establish Relay Certs for Gloo Mesh
---------------------------------------------------------

**Disclaimer**: *This is strictly an example for how to create relay certs that your remote clusters can use.  These scripts are not to be considered production ready.*

In this example, we will use [cert-manager](https://cert-manager.io) to create relay certs from a root that is generated via openssl.

This example assumes the typical three-cluster setup as seen in the [Gloo Mesh Workshops](https://workshops.solo.io/gloo-workshops/gloo-mesh#gloo-mesh-workshop).  It also assumes that you have not yet installed Gloo Mesh.

You will need to ensure that your kubectl context is using `mgmt`, `cluster1` and `cluster2` for the management and remote clusters.

## Pre-requisites
- cert-manager installed on all clusters - https://cert-manager.io/docs/installation/helm/.
- GLOO_MESH_LICENSE_KEY environment variable set to a valid license.

## Steps
Once the above pre-requisites are met, follow these simple steps to create the relay certs for the remote clusters and install Gloo Mesh.

1. Create the root cert/key pair which will be used by each cert-manager instance
```
./gen-relay-root-ca.sh
```
2. Create the tokens necessary for relay communication and create the certificates for the mgmt server and each leaf cluster via cert-manager custom resources
```
./bootstrap-relay-secrets.sh
```
3. Install Gloo Mesh management plane on mgmt cluster and Gloo Mesh agents on leaf clusters. Set the correct values to use relay certs we've already created.

If not using OpenShift, 
```
./install-gloo-mesh.sh
```

If using OpenShift,
```
./install-gloo-mesh-ocp.sh
```