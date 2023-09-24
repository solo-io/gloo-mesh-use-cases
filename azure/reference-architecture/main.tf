data "azurerm_resource_group" "azure-gloo-refarch" {
  name = "azure-gloo-refarch-hub"
}

module "hub" {
  source              = "./layers/layer0"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
}

module "stamp0" {
  source              = "./layers/stamp"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
  hub_vnet_id         = module.hub.hub_vnet_id
  hub_vnet_name       = module.hub.hub_vnet_name
  cardinal            = 0
}

module "stamp1" {
  source              = "./layers/stamp"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
  hub_vnet_id         = module.hub.hub_vnet_id
  hub_vnet_name       = module.hub.hub_vnet_name
  cardinal            = 1
}