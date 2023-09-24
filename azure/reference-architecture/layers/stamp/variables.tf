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