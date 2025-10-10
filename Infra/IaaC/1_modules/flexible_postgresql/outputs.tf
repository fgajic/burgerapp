output "server_id" {
  description = "Id of the created flexible server"
  value       = azurerm_postgresql_flexible_server.server.id
}

output "connection_strings" {
  description = "Connection strings for the databases"
  value       = [for database in concat(var.databases, ["postgres"]) : "User ID=${var.admin_username};Password=${var.admin_password};Host=${azurerm_postgresql_flexible_server.server.fqdn};Port=5432;Database=${database};Pooling=true;"]
}

output "replica_fqdn" {
  description = "If set, this will contain the FQDN for the replica"
  value       = length(azurerm_postgresql_flexible_server.server_replica) > 0 ? azurerm_postgresql_flexible_server.server_replica[0].fqdn : ""
}

output "server_fqdn" {
  description = "FQDN for the primary flexible server"
  value       = azurerm_postgresql_flexible_server.server.fqdn
}