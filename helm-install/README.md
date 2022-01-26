# Gloo Mesh Enterprise production installation resources

These directories contain example Helm values files to customize the Gloo Mesh Enterprise Helm charts for production setups. Be sure to select the directory for the version of Gloo Mesh Enterprise that you want to install.

- The `values-mgmt-plane.yaml` values file provides example production-level settings for the `gloo-mesh-enterprise` Helm chart, which you can use to install Gloo Mesh Enterprise. You can edit this file to provide your own details for settings that are recommended for a production installation of Gloo Mesh, including custom certificates, OIDC authorization for the Gloo Mesh dashboard, and RBAC enablement.
  - For instructions on how to install Gloo Mesh Enterprise with Helm, see [Install Gloo Mesh Enterprise](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/installation/enterprise_installation/).
  - For more information about the settings in this values file, see [Best practices for production](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/installation/recommended_setup/) and the [Helm values documentation](https://docs.solo.io/gloo-mesh-enterprise/main/reference/helm/gloo_mesh_enterprise/latest/) for each component.

- The `values-data-plane.yaml` values file provides example production-level settings for the `enterprise-agent` Helm chart, which you can use to register workload clusters with Gloo Mesh. You can edit this file to provide your own details for settings that are recommended for production setups. For example, if you provided your own certificates during Gloo Mesh installation, you can use these certificates during cluster registration too.
  - For instructions on how to register workload clusters with Gloo Mesh by using Helm, see [Registering clusters with Gloo Mesh](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/enterprise_cluster_registration/).
  - For more information about the settings in this values file, see [Best practices for production](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/installation/recommended_setup/#data-plane-settings) and the [Helm values documentation](https://docs.solo.io/gloo-mesh-enterprise/main/reference/helm/gloo_mesh_enterprise/latest/enterprise_agent/).

## Last Mile Helm Chart Customization

Sub-charts of the `gloo-mesh-addons` within the `enterprise-agent` chart allow for a few customizations.  However, if you need to modify the deployment template then the following strategy will work.

### Create a Patch for the Deployment

Available deployments in `gloo-mesh-addons` are `redis`, `ext-auth-service`, and `rate-limiter`.  The following example adds a `nodeSelector` to the `redis` deployment.

The following yaml is also found in [redis-patch.yaml](./1.2/enterprise-agent-addons/redis/redis-patch.yaml).

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  template:
    spec:
      nodeSelector:
        node_type: infra
```

Create a shell script to execute kustomize from Helm.  The following can be found in [kustomize.sh](./1.2/enterprise-agent-addons/redis/kustomize.sh).

```
#!/bin/sh
cat > base.yaml
# you can also use "kustomize build ." if you have it installed.
exec kubectl kustomize
```

Finally, create a [kustomization.yaml](./1.2/enterprise-agent-addons/redis/kustomization.yaml).

```
resources:
- base.yaml
patchesStrategicMerge:
- redis-patch.yaml
```

### Test the Patch

Use `helm template` to test your patch. For example, from the 1.2/enterprise-agent-addons/redis/ directory, type the following

```
helm template enterprise-agent-addons enterprise-agent/enterprise-agent --set rate-limiter.enabled=true --set enterpriseAgent.enabled=false --post-renderer ./kustomize.sh
```

### Installing the Patch

Install either using `helm upgrade --install` or `helm install` as you would normally, but including the `--post-renderer` flag.

### Modifying Multiple Services

To modify more than a single deployment see the [kustomization.yaml](./1.2/enterprise-agent-addons/multiple/kustomization.yaml) in the `multiple` directory.