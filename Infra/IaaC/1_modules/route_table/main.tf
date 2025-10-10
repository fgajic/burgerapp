resource "azurerm_route_table" "route_table" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = var.routes

    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "example" {
  count = length(var.subnet_ids)

  subnet_id      = var.subnet_ids[count.index]
  route_table_id = azurerm_route_table.route_table.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name      = "AllowAllOutbound"
    priority  = 340
    direction = "Outbound"
    access    = "Allow"

    source_port_range          = "*"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name      = "AllowAllInbound"
    priority  = 330
    direction = "Inbound"
    access    = "Allow"

    source_port_range          = "*"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg-assignation" {
  count = length(var.subnet_ids)

  subnet_id                 = var.subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.nsg.id
}
