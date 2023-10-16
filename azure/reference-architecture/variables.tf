variable "client_secret" {
}

variable "resource_group_name" {
  description = "value of the license key"
  default     = "azure-gloo-refarch-hub"
}

variable "gloo_mesh_license_key" {
  description = "value of the license key"
}

variable "aks_version" {
  description = "The Kubernetes version"
  default     = "1.28.0"
}

variable "dns_resource_group_name" {
  description = "value of the dns resource group name"
}

variable "dns_zone" {
  description = "value of the dns zone"
}