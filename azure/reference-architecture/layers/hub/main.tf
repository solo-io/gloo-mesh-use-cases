data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "hub" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "hub"
  address_space       = ["172.255.0.0/16"] #Since cardinal can be 0..254, we set this to 255
}

resource "azurerm_subnet" "hub" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  name                 = "hub"
  address_prefixes     = ["172.255.1.0/24"]
}
resource "random_integer" "vault" {
  min = 1
  max = 256
}

resource "azurerm_key_vault" "hub" {
  name                     = "hub-${random_integer.vault.result}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku_name                 = "standard"
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
}

resource "azurerm_kubernetes_cluster" "hub" {
  name                = "hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "hub"
  kubernetes_version  = var.aks_version

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_B4ms"
    vnet_subnet_id = azurerm_subnet.hub.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"

  }
  tags = {
    Role = "Hub"
  }
}

resource "azurerm_role_assignment" "aksnetwork" {
  provider             = azurerm.networksp
  scope                = azurerm_virtual_network.hub.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.hub.identity[0].principal_id
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
  name = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = true
  }
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

resource "helm_release" "gloo-mesh" {

  depends_on = [helm_release.gloo-crds, azurerm_role_assignment.aksnetwork]

  name = "gloo-platform"

  repository = "https://storage.googleapis.com/gloo-platform/helm-charts"
  chart      = "gloo-platform"
  namespace  = "gloo-mesh"
  wait       = false

  values = [
    <<EOT
licensing:
  glooMeshLicenseKey: ${var.gloo_mesh_license_key}
common:
  cluster: mgmt-cluster
glooMgmtServer:
  enabled: true
  serviceOverrides:
    metadata:
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-internal: "true"
glooUi:
  enabled: true
  auth:
    enabled: false
  serviceType: LoadBalancer
prometheus:
  enabled: true
redis:
  deployment:
    enabled: true
telemetryGateway:
  enabled: true
EOT
  ]

}