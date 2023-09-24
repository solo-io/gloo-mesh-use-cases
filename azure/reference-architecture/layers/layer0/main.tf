data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "hub" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "hub"
  address_space       = ["172.0.0.1/16"]
}

resource "azurerm_subnet" "hub" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  name                 = "hub"
  address_prefixes     = ["172.0.0.1/24"]
}

resource "azurerm_key_vault" "hub" {
  name                     = "hub"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku_name                 = "standard"
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
} 