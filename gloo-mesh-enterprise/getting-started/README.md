# Gloo Mesh Enterprise quickstart resources

These directories contain files to help you quick start Gloo Mesh Enterprise. For instructions on how to use these files, see [Getting started](https://docs.solo.io/gloo-mesh-enterprise/main/getting_started/).

- The demo Istio operator files provide quick-start install profiles for Istio. These profiles are provided for their simplicity. For example, you install the `istio-ingressgateway` for ingress (north-south) traffic and `istio-eastwestgateway` for cross-cluster (east-west) traffic in the same namespace as the Istio control plane.
- The `in-mesh` and `not-in-mesh` files provide deployments for two `httpbin` demo apps that you can use to test service isolation across your Gloo Mesh workspaces.