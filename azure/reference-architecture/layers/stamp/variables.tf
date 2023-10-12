variable "client_secret" {
}

variable "location" {
}
variable "resource_group_name" {

}

variable "hub_vnet_id" {
}

variable "hub_vnet_name" {
}

variable "cardinal" {
  default = 0
  validation {
    condition = (
      var.cardinal <= 254
    )
    error_message = "Must be between 0 and 253, inclusive."
  }
}

variable "aks_version" {
  description = "The Kubernetes version"
  default     = "1.28.0"
}

variable "gloo_mngmt_ip" {
  description = "The IP address of the Gloo Mesh management plane"
}

variable "hub_kubeconfig_host" {
  description = "The kubeconfig for the hub cluster"
}

variable "hub_kubeconfig_client_certificate" {
  description = "The kubeconfig for the hub cluster"
}

variable "hub_kubeconfig_client_key" {
  description = "The kubeconfig for the hub cluster"
}

variable "hub_kubeconfig_cluster_ca_certificate" {
  description = "The kubeconfig for the hub cluster"
}