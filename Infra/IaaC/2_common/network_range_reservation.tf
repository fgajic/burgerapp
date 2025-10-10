# This file lays out networking for our environments
#
# To be able to support network peering we have to
# have environemnts who's base vnet's don't overlap

# Azure allows the following network ranges
# 1. "10.0.0.0/8" <- this will be used by our main applications
# 2. "172.16.0.0/12" <- this will be used by integration stacks, such as ipsec tunnel
# 3. "192.168.0.0/16" <- ATM not allocated

variable "resouce_group_name" {
  description = "Based on the resource group name we determine the prefix"
  type        = string
  default     = ""
}

locals {
  namespace_to_ranges = {
    # 10.0 ranges
    "filip-bourgerapp" : {
      address_space  = "10.4.0.0/16"
      address_prefix = "10.4"
    }
  }
}

output "network_specification" {
  description = "Network specification for the resource group"
  value       = local.namespace_to_ranges[var.resouce_group_name]
}
