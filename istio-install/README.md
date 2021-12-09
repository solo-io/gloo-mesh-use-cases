# Gloo Mesh Enterprise production Istio resources

These directories contain example resource files for installing Istio in your workload clusters for production-level setups. Be sure to select the directory for the version of Istio that you want to install.

Note that several resources include a `revision` label that matches the Istio version of the resource to facilitate [canary-based upgrades](https://istio.io/latest/blog/2017/0.1-canary/). This revision label helps you upgrade the version of the Istio control plane more easily, as documented in the [Istio upgrade guide](https://docs.solo.io/gloo-mesh-enterprise/main/setup/istio/upgrade/).

For more information about the content of the provided `IstioOperator` examples, check these resources:
* [Istio default profiles](https://github.com/istio/istio/tree/master/manifests/profiles)
* [Istio Operator Spec](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/)
* [Istio MeshConfig Spec](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)

## Contents

These resources are configured with production-level settings; however, depending on your environment, you might need to edit settings to achieve specific Istio functionality. For instructions on how to install Istio for use with Gloo Mesh Enterprise, see [Install Istio](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/istio/).

- The `istiod-kubernetes.yaml` and `istiod-openshift.yaml` files provide example production-level settings for the `IstioOperator` resource to install the istiod control plane in a cluster. Choose the resource for your cluster's container orchestration platform.
- The `ingress-gateway.yaml` file provides an `IstioOperator` resource for the ingress gateway deployment and a service account for the ingress gateway deployment to use. Note that these gateway resources are deployed to the `istio-ingress` namespace. If use only [one namespaces](https://docs.solo.io/gloo-mesh-enterprise/main/setup/istio/namespaces/) for all gateways, be sure to specify `istio-gateways` for the resource namespaces instead.
- The `ingress-gateway-lb.yaml` file provisions a separate load balancer service to expose the ingress gateway.
- The `eastwest-gateway.yaml` file provides an `IstioOperator` resource for the east-west gateway deployment and a service account for the east-west gateway deployment to use. Note that these gateway resources are deployed to the `istio-eastwest` namespace.  If use only [one namespaces](https://docs.solo.io/gloo-mesh-enterprise/main/setup/istio/namespaces/) for all gateways, be sure to specify `istio-gateways` for the resource namespaces instead.
- The `eastwest-gateway-lb.yaml` file provisions a separate load balancer service to expose the east-west gateway.
