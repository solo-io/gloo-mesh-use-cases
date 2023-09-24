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
