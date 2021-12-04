# Gloo Mesh Enterprise production Istio resources

These directories contain example resource files for installing Istio in your workload clusters for production-level setups. Be sure to select the directory for the version of Istio that you want to install.

Note that several resources include a `revision` label that matches the Istio version of the resource to facilitate [canary-based upgrades](https://istio.io/latest/blog/2017/0.1-canary/). This revision label helps you upgrade the version of the Istio control plane more easily, as documented in the [Istio upgrade guide]({{% versioned_link_path fromRoot="/setup/istio/upgrade/" %}}).

For more information about the content of the provided `IstioOperator` examples, check these resources:
* [Istio default profiles](https://github.com/istio/istio/tree/master/manifests/profiles)
* [Istio Operator Spec](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/)
* [Istio MeshConfig Spec](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)

## Contents

These resources are configured with production-level settings; however, depending on your environment, you might need to edit settings to achieve specific Istio functionality. For instructions on how to install Istio for use with Gloo Mesh Enterprise, see [Install Istio](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/istio/).

- The `istiod-kubernetes.yaml` and `istiod-openshift.yaml` files provide example production-level settings for the `IstioOperator` resource to install the istiod control plane in a cluster. Choose the resource for your cluster's container orchestration platform.
- The `ingress-gateway.yaml` file provides the following resources for the Istio ingress gateway. Note that these gateway resources are deployed to the `istio-gateways` namespace. If you use individual namespaces for each gateway, be sure to specify `istio-ingress` for the resource namespaces instead.
  - A service account for the ingress gateway deployment to use
  - An `IstioOperator` resource for the ingress gateway deployment
  - A separate load balancer service to expose the ingress gateway
- The `eastwest-gateway.yaml` file provides the following resources for the Istio east-west gateway. Note that these gateway resources are deployed to the `istio-gateways` namespace. If you use individual namespaces for each gateway, be sure to specify `istio-eastwest` for the resource namespaces instead.
  - A service account for the east-west gateway deployment to use
  - An `IstioOperator` resource for the east-west gateway deployment
  - A separate load balancer service to expose the east-west gateway