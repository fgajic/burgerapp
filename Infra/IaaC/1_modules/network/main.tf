resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  tags                = var.tags
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = try(each.value.service_endpoints, [])
  private_link_service_network_policies_enabled = each.value.network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.service_delegation != null ? [1] : []

    content {
      name = "delegation"

      service_delegation {
        name    = each.value.service_delegation.name
        actions = each.value.service_delegation.actions
      }
    }
  }
}

resource "azurerm_virtual_network_peering" "peering-here-to-there" {
  for_each = var.peerings

  name                                   = "from-${var.resource_group_name}-to-${each.value.resource_group}"
  virtual_network_name                   = azurerm_virtual_network.vnet.name
  remote_virtual_network_id              = each.value.id
  resource_group_name                    = var.resource_group_name
  allow_virtual_network_access           = true
  peer_complete_virtual_networks_enabled = true
  allow_forwarded_traffic                = true
  use_remote_gateways                    = each.value.use_remote_gateways_here_to_there
  allow_gateway_transit                  = true
}

resource "azurerm_virtual_network_peering" "peering-there-to-here" {
  for_each = var.peerings

  name                                   = "from-${each.value.resource_group}-to-${var.resource_group_name}"
  virtual_network_name                   = each.value.name
  remote_virtual_network_id              = azurerm_virtual_network.vnet.id
  resource_group_name                    = each.value.resource_group
  allow_virtual_network_access           = true
  peer_complete_virtual_networks_enabled = true
  allow_forwarded_traffic                = true
  allow_gateway_transit                  = true
  use_remote_gateways                    = each.value.use_remote_gateways_there_to_here
}
