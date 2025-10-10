output "server_id" {
  description = "Id of the created flexible server"
  value       = azurerm_cosmosdb_postgresql_cluster.server.id
}

output "connection_string" {
  description = "Connection strings for the databases"
  value       = "User ID=citus;Password=${var.password};Server=${azurerm_cosmosdb_postgresql_cluster.server.servers[0].fqdn};Port=5432;Database=citus;Ssl Mode=Require;"
}

output "replica_fqdn" {
  description = "If set, this will contain the FQDN for the replica"
  value       = length(azurerm_cosmosdb_postgresql_cluster.server_replica) > 0 ? azurerm_cosmosdb_postgresql_cluster.server_replica[0].servers[0].fqdn : ""
}
