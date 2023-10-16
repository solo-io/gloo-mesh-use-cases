variable "client_secret" {
}

variable "location" {
  description = "location of the resource group"
}
variable "resource_group_name" {
  description = "resource group name"
}

variable "gloo_mesh_license_key" {
  description = "Gloo Mesh Enterprise License Key"
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