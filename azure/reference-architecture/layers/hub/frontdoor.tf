data "azurerm_dns_zone" "dnszone" {
  name                = var.dns_zone
  resource_group_name = var.dns_resource_group_name
}

resource "azurerm_cdn_frontdoor_profile" "hub" {
  name                = "hubfd"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
}