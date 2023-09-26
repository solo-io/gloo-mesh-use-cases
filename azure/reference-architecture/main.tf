data "azurerm_resource_group" "azure-gloo-refarch" {
  name = "azure-gloo-refarch-hub"
}

module "hub" {
  source                = "./layers/hub"
  location              = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name   = data.azurerm_resource_group.azure-gloo-refarch.name
  gloo_mesh_license_key = var.gloo_mesh_license_key
  aks_version           = var.aks_version
  client_secret         = var.client_secret
}

module "stamp0" {
  source              = "./layers/stamp"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
  hub_vnet_id         = module.hub.hub_vnet_id
  hub_vnet_name       = module.hub.hub_vnet_name
  aks_version         = var.aks_version
  cardinal            = 0
}

module "stamp1" {
  source              = "./layers/stamp"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
  hub_vnet_id         = module.hub.hub_vnet_id
  hub_vnet_name       = module.hub.hub_vnet_name
  aks_version         = var.aks_version

  cardinal = 1
}