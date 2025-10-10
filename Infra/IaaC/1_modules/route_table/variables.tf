variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "location" {
  description = "Location"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "name" {
  description = "Route table name"
  type        = string
}

variable "routes" {
  description = "Routes of the table"
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string, null)
  }))
}

variable "subnet_ids" {
  description = "Subnet ids to associate the routing table with"
  type        = list(string)
}
