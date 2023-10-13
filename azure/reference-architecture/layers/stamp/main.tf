data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "stamp" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "stamp-${var.cardinal}"
  address_space       = ["172.${var.cardinal}.0.0/16"]
}

resource "azurerm_subnet" "stamp" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.stamp.name
  name                 = "stamp-${var.cardinal}"
  address_prefixes     = ["172.${var.cardinal}.1.0/24"]
}

resource "azurerm_virtual_network_peering" "stamp-to-hub" {
  name                      = "stamp-${var.cardinal}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.stamp.name
  remote_virtual_network_id = var.hub_vnet_id
}

resource "azurerm_virtual_network_peering" "hub-to-stamp" {
  name                      = "hub-to-stamp-${var.cardinal}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.stamp.id
}

resource "azurerm_kubernetes_cluster" "workload" {
  name                = "workload-${var.cardinal}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "workload-${var.cardinal}"
  kubernetes_version  = var.aks_version

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_B4ms"
    vnet_subnet_id = azurerm_subnet.stamp.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"

  }
  tags = {
    Role = "Workload"
  }
}

resource "azurerm_role_assignment" "aksnetwork" {
  provider             = azurerm.networksp
  scope                = azurerm_virtual_network.stamp.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.workload.identity[0].principal_id
}

resource "kubernetes_namespace" "gloo-mesh" {
  metadata {
    name = "gloo-mesh"
  }
}

resource "helm_release" "gloo-crds" {
  name = "gloo-crds"

  repository = "https://storage.googleapis.com/gloo-platform/helm-charts"
  chart      = "gloo-platform-crds"
  namespace  = "gloo-mesh"

}
resource "kubernetes_manifest" "workspace_gloo_mesh_mgmt_cluster" {

  provider = kubernetes.hub

  manifest = {
    "apiVersion" = "admin.gloo.solo.io/v2"
    "kind"       = "Workspace"
    "metadata" = {
      "name"      = "hub"
      "namespace" = "gloo-mesh"
    }
    "spec" = {
      "workloadClusters" = [
        {
          "name" = "*"
          "namespaces" = [
            {
              "name" = "*"
            },
          ]
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "workspacesettings_gloo_mesh_config_mgmt_cluster" {

  provider = kubernetes.hub
  manifest = {
    "apiVersion" = "admin.gloo.solo.io/v2"
    "kind"       = "WorkspaceSettings"
    "metadata" = {
      "name"      = "hub"
      "namespace" = "gloo-mesh-config"
    }
    "spec" = {
      "options" = {
        "eastWestGateways" = [
          {
            "selector" = {
              "labels" = {
                "istio" = "eastwestgateway"
              }
            }
          },
        ]
        "federation" = {
          "enabled" = false
          "serviceSelector" = [
            {},
          ]
        }
        "serviceIsolation" = {
          "enabled" = false
        }
      }
    }
  }
}

resource "kubernetes_manifest" "kubernetescluster_gloo_mesh___remote_cluster_" {

  provider = kubernetes.hub
  manifest = {
    "apiVersion" = "admin.gloo.solo.io/v2"
    "kind"       = "KubernetesCluster"
    "metadata" = {
      "labels" = {
        "env" = "prod"
      }
      "name"      = "workload-${var.cardinal}"
      "namespace" = "gloo-mesh"
    }
    "spec" = {
      "clusterDomain" = "cluster.local"
    }
  }
}

resource "helm_release" "gloo-mesh" {

  depends_on = [helm_release.gloo-crds, azurerm_role_assignment.aksnetwork]

  name = "gloo-platform"

  repository = "https://storage.googleapis.com/gloo-platform/helm-charts"
  chart      = "gloo-platform"
  namespace  = "gloo-mesh"
  wait       = false

  values = [
    <<EOT
common:
  cluster: mgmt-cluster
glooAgent:
  relayServerAddress: ${var.gloo_mngmt_ip}:9900
telemetryCollector:
  config:
    exporters:
      otlp:
        endpoint: ${var.gloo_mngmt_telemetry_ip}:4317
glooAgent:
  enabled: true
telemetryCollector:
  enabled: true
EOT
  ]

}
