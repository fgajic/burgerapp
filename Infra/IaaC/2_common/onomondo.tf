output "hes_onomondo_vnet_id" {
  description = "Well-known id of vnet with ipsec tunnel to onomondo"
  value       = "/subscriptions/a846a0af-bfc9-44ae-a421-b5ff06d9e7c5/resourceGroups/hes-onomondo-ipsec/providers/Microsoft.Network/virtualNetworks/vnet"
}

output "hes_onomondo_vnet_name" {
  description = "Well-known name of vnet with ipsec tunnel to onomondo"
  value       = "vnet"
}

output "hes_onomondo_ip_prefix" {
  description = "Well-known ip prefix of vnet with ipsec tunnel to onomondo"
  value       = "172.16.0.0/24"
}

variable "is_onomondo_rg" {
  description = "If true, will use well known information for onomondo"
  type        = bool
  default     = false
}

variable "hes_onomondo_resource_group_name" {
  description = "Well-known name of resouce group with ipsec tunnel to onomondo"
  type        = string
  default     = "hes-onomondo-ipsec"
}

output "hes_onomondo_resource_group_name" {
  description = "Well-known name of resouce group with ipsec tunnel to onomondo"
  value       = var.hes_onomondo_resource_group_name
}

output "onomondo_address_range" {
  description = "Well-known address space used for ipsec from onomondo"
  value       = "100.64.0.0/10"
}
