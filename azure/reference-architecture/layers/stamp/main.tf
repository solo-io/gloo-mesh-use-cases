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