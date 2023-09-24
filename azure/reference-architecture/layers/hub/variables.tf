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