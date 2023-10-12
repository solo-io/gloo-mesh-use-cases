output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "gloo_mgmnt_ip" {
  value = data.kubernetes_service.gloo-mesh.status.0.load_balancer.0.ingress.0.ip
}

output "gloo_mgmnt_telemetry_ip" {
  value = data.kubernetes_service.gloo-mesh-telemetry.status.0.load_balancer.0.ingress.0.ip
}

output "hub_kubeconfig_host" {
  value = azurerm_kubernetes_cluster.hub.kube_config.0.host
}
output "hub_kubeconfig_client_certificate" {
  value = azurerm_kubernetes_cluster.hub.kube_config.0.client_certificate
}
output "hub_kubeconfig_client_key" {
  value = azurerm_kubernetes_cluster.hub.kube_config.0.client_key
}
output "hub_kubeconfig_cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.hub.kube_config.0.cluster_ca_certificate
}