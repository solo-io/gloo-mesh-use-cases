data "azurerm_resource_group" "azure-gloo-refarch" {
  name = "azure-gloo-refarch-hub"
}

module "pki" {
  source              = "./layers/pki"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
}

module "hub" {
  source                = "./layers/hub"
  location              = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name   = data.azurerm_resource_group.azure-gloo-refarch.name
  gloo_mesh_license_key = var.gloo_mesh_license_key
  aks_version           = var.aks_version
  client_secret         = var.client_secret

  dns_zone                = var.dns_zone
  dns_resource_group_name = var.dns_resource_group_name
}

module "stamp0" {
  source              = "./layers/stamp"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
  hub_vnet_id         = module.hub.hub_vnet_id
  hub_vnet_name       = module.hub.hub_vnet_name
  aks_version         = var.aks_version
  cardinal            = 0
  client_secret       = var.client_secret

  gloo_mngmt_ip           = module.hub.gloo_mgmnt_ip
  gloo_mngmt_telemetry_ip = module.hub.gloo_mgmnt_telemetry_ip

  hub_kubeconfig_host                   = module.hub.hub_kubeconfig_host
  hub_kubeconfig_client_certificate     = module.hub.hub_kubeconfig_client_certificate
  hub_kubeconfig_client_key             = module.hub.hub_kubeconfig_client_key
  hub_kubeconfig_cluster_ca_certificate = module.hub.hub_kubeconfig_cluster_ca_certificate

}

module "stamp1" {
  source              = "./layers/stamp"
  location            = data.azurerm_resource_group.azure-gloo-refarch.location
  resource_group_name = data.azurerm_resource_group.azure-gloo-refarch.name
  hub_vnet_id         = module.hub.hub_vnet_id
  hub_vnet_name       = module.hub.hub_vnet_name
  aks_version         = var.aks_version
  cardinal            = 1
  client_secret       = var.client_secret

  gloo_mngmt_ip                         = module.hub.gloo_mgmnt_ip
  gloo_mngmt_telemetry_ip               = module.hub.gloo_mgmnt_telemetry_ip
  hub_kubeconfig_host                   = module.hub.hub_kubeconfig_host
  hub_kubeconfig_client_certificate     = module.hub.hub_kubeconfig_client_certificate
  hub_kubeconfig_client_key             = module.hub.hub_kubeconfig_client_key
  hub_kubeconfig_cluster_ca_certificate = module.hub.hub_kubeconfig_cluster_ca_certificate

}