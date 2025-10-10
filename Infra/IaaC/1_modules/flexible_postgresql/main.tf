resource "azurerm_private_dns_zone" "dns" {
  count = var.has_replica ? 2 : 1

  name                = "${var.dns_prefix}-${var.name}${count.index == 1 ? "-replica" : ""}.flexible-server.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  count = var.has_replica ? 2 : 1

  name                  = "${var.dns_prefix}-${var.name}${count.index == 1 ? "Replica" : ""}VnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.dns[count.index].name
  virtual_network_id    = var.vnet-id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

resource "azurerm_postgresql_flexible_server" "server" {
  name                = "${var.name}-${random_string.eventhub_name.id}"
  private_dns_zone_id = azurerm_private_dns_zone.dns[0].id
  create_mode         = "Default"

  resource_group_name           = var.resource_group_name
  tags                          = var.tags
  location                      = var.location
  version                       = var.pg_version
  delegated_subnet_id           = var.subnet_id
  public_network_access_enabled = false
  administrator_login           = var.admin_username
  administrator_password        = var.admin_password

  # Set zone only when HA is enabled; otherwise leave unset to avoid conflicts
  zone = var.high_availability_enabled ? var.availability_zone : null

  storage_mb   = var.storage
  storage_tier = var.storage_tier
  sku_name     = var.sku
  depends_on   = [var.subnet_id]

  lifecycle {
    ignore_changes = [
      zone,
      administrator_password
    ]
  }

  backup_retention_days = var.backup_retention_days

  dynamic "high_availability" {
    for_each = var.high_availability_enabled ? [1] : []
    content {
      mode                      = "SameZone"
      standby_availability_zone = var.availability_zone
    }
  }
}

resource "azurerm_postgresql_flexible_server" "server_replica" {
  count = (var.has_replica ? 1 : 0)

  name                          = "${var.name}-replica"
  resource_group_name           = var.resource_group_name
  tags                          = var.tags
  location                      = var.location
  version                       = var.pg_version
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.dns[1].id
  public_network_access_enabled = false
  administrator_login           = var.admin_username
  administrator_password        = var.admin_password
  zone                          = "1"

  storage_mb   = var.storage
  storage_tier = var.storage_tier
  create_mode  = "Replica"
  sku_name     = var.sku
  depends_on   = [var.subnet_id]

  source_server_id = azurerm_postgresql_flexible_server.server.id
}

resource "azurerm_postgresql_flexible_server_configuration" "configuration" {
  for_each = var.server_config

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.server.id
  value     = each.value
}

resource "azurerm_postgresql_flexible_server_configuration" "configuration_replica" {
  for_each = (var.has_replica ? var.server_config : {})

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.server.id
  value     = each.value
}

resource "azurerm_postgresql_flexible_server_database" "database" {
  count = length(var.databases)

  name      = var.databases[count.index]
  server_id = azurerm_postgresql_flexible_server.server.id
}

resource "azurerm_postgresql_flexible_server_database" "database_replica" {
  count = var.has_replica ? length(var.databases) : 0

  name      = var.databases[count.index]
  server_id = azurerm_postgresql_flexible_server.server_replica[0].id
}

