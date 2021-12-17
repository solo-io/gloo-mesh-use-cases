# Managing Relay Certs with Separate Root of Trust from Management Plane

This example builds on top of the [Gloo Mesh Documentation](https://docs.solo.io/gloo-mesh-enterprise/main/setup/certs/) for generating relay certificates, but does so in a way that the remote clusters can have a separate root of trust from the management plane.

# Create a root cert and tls secret for the management plane

```
.01-create-mgmt-root.sh
```

# Create a root for the remote clusters and secret for relay

```
.02-create-remote-root.sh
```

# Update secrets in the management plane with both roots and restart deployments

```
.03-update-mgmt-root.sh
```