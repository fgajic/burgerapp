variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "location" {
  description = "The location where the virtual network will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group where the virtual network will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the virtual network"
  type        = map(string)
}

variable "subnets" {
  description = "List of subnets to create in the virtual network"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string))
    service_delegation = optional(object({
      name    = string
      actions = list(string)
    }))
    network_policies_enabled = optional(bool, false)
  }))
  default = {}
}

variable "peerings" {
  description = "Optional list of virtual networks to peer this vnet with"
  type = map(object({
    name                              = string
    id                                = string
    resource_group                    = string
    use_remote_gateways_here_to_there = optional(bool, false)
    use_remote_gateways_there_to_here = optional(bool, false)
  }))
  default = {}
}
