resource "random_string" "citus_name" {
  length  = 10
  special = false
  numeric = false
  upper   = false
}

resource "azurerm_cosmosdb_postgresql_cluster" "server" {
  name = "${var.name}-${random_string.citus_name.id}"
  tags = var.tags

  administrator_login_password         = var.password
  citus_version                        = var.citus_version
  sql_version                          = var.pg_version
  coordinator_public_ip_access_enabled = false
  node_public_ip_access_enabled        = false
  coordinator_storage_quota_in_mb      = var.coordinator_storage
  node_storage_quota_in_mb             = var.node_storage
  location                             = var.location
  resource_group_name                  = var.resource_group_name
  node_count                           = var.worker_node_count
  coordinator_vcore_count              = var.coordinator_vcores
  node_vcores                          = var.node_vcores
  coordinator_server_edition           = var.coordinator_server_edition
  node_server_edition                  = var.node_server_edition
  ha_enabled                           = var.ha_enabled

  lifecycle {
    ignore_changes = [
      administrator_login_password
    ]
  }

}

// Sleep is needed because there is some time needed to
// allow replication on a fresh created server. The value
// is chosen by guessing because there is no better way
// to ensure readiness ATM
resource "time_sleep" "wait_citus_to_be_ready" {
  count = var.has_replica ? 1 : 0

  depends_on      = [azurerm_cosmosdb_postgresql_cluster.server]
  create_duration = "600s"
}

resource "azurerm_cosmosdb_postgresql_cluster" "server_replica" {
  count = var.has_replica ? 1 : 0

  name = "${var.name}-replica"
  tags = var.tags

  administrator_login_password         = var.password
  citus_version                        = var.citus_version
  sql_version                          = var.pg_version
  coordinator_public_ip_access_enabled = false
  node_public_ip_access_enabled        = false
  coordinator_storage_quota_in_mb      = var.coordinator_storage
  node_storage_quota_in_mb             = var.node_storage
  location                             = var.location
  resource_group_name                  = var.resource_group_name
  node_count                           = var.worker_node_count
  source_resource_id                   = azurerm_cosmosdb_postgresql_cluster.server.id
  source_location                      = azurerm_cosmosdb_postgresql_cluster.server.location
  coordinator_vcore_count              = var.coordinator_vcores
  node_vcores                          = var.node_vcores

  coordinator_server_edition = var.coordinator_server_edition
  node_server_edition        = var.node_server_edition

  depends_on = [time_sleep.wait_citus_to_be_ready]
}

resource "azurerm_cosmosdb_postgresql_coordinator_configuration" "coordinator_configuration" {
  for_each = var.coordinator_config

  name       = each.key
  cluster_id = azurerm_cosmosdb_postgresql_cluster.server.id
  value      = each.value
}

resource "azurerm_cosmosdb_postgresql_coordinator_configuration" "coordinator_configuration_replica" {
  for_each = var.has_replica ? var.coordinator_config : {}

  name       = each.key
  cluster_id = azurerm_cosmosdb_postgresql_cluster.server_replica[0].id
  value      = each.value
}

resource "azurerm_cosmosdb_postgresql_node_configuration" "node_configuration" {
  for_each = var.node_config

  name       = each.key
  cluster_id = azurerm_cosmosdb_postgresql_cluster.server.id
  value      = each.value
}

resource "azurerm_cosmosdb_postgresql_node_configuration" "node_configuration_replica" {
  for_each = var.has_replica ? var.node_config : {}

  name       = each.key
  cluster_id = azurerm_cosmosdb_postgresql_cluster.server_replica[0].id
  value      = each.value
}

resource "azurerm_private_dns_zone" "dns" {
  name                = "privatelink.postgres.cosmos.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  tags                  = var.tags
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                = "${var.name}-private-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-private-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cosmosdb_postgresql_cluster.server.id
    subresource_names = [
      "coordinator"
    ]
  }

  private_dns_zone_group {
    name                 = "citus"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns.id]
  }
}

resource "azurerm_private_endpoint" "private_endpoint_replica" {
  count = var.has_replica ? 1 : 0

  name                = "${var.name}-replica-private-endpoint"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-replica-private-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cosmosdb_postgresql_cluster.server_replica[0].id
    subresource_names = [
      "coordinator"
    ]
  }

  private_dns_zone_group {
    name                 = "hes-citus"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns.id]
  }
}
