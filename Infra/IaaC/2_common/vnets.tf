# This is used to extract vnet ids from terraform directly
variable "vnets" {
  description = "List of vnet name resource group objects to use to get their coresponding ids"
  type = list(object({
    name = string
    resource_group_name = string
  }))
  default = []
}

data "azurerm_virtual_network" "selected_vnets" {
  # Create a unique key combining name and resource group
  for_each = { for vnet in var.vnets : "${vnet.name}-${vnet.resource_group_name}" => vnet }
  name = each.value.name
  resource_group_name = each.value.resource_group_name
}

output "vnet_ids" {
  description = "List of objects with name, resource group name, and id of all selected vnets"
  value = {
    for key, v in data.azurerm_virtual_network.selected_vnets : key => {
      id = v.id
    }
  }
}




