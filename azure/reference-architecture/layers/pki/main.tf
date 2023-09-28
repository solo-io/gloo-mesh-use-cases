data "azurerm_client_config" "current" {}

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