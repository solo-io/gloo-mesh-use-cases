provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.workload.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.workload.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.workload.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.workload.kube_config.0.cluster_ca_certificate)
}

# provider "kubernetes" {
#   alias                  = "hub"
#   host                   = var.hub_kubeconfig_host
#   client_certificate     = base64decode(var.hub_kubeconfig_client_certificate)
#   client_key             = base64decode(var.hub_kubeconfig_client_key)
#   cluster_ca_certificate = base64decode(var.hub_kubeconfig_cluster_ca_certificate)
# }

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.workload.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.workload.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.workload.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.workload.kube_config.0.cluster_ca_certificate)
  }
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}

}

provider "azurerm" {

  alias = "networksp"

  client_id       = "13831d95-09e9-44aa-aee8-f8e41bb12530"
  client_secret   = var.client_secret
  tenant_id       = "5e7d8166-7876-4755-a1a4-b476d4a344f6"
  subscription_id = "b90e29d2-2678-4c54-a939-8ddfe80153d6"

  features {}

}