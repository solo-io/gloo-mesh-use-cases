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