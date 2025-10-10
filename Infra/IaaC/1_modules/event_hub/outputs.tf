output "namespace_id" {
  description = "Id of the event hub namespace"
  value       = azurerm_eventhub_namespace.event_hub_namespace.id
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_eventhub_namespace_authorization_rule.auth_rule.primary_connection_string
}

output "secondary_connection_string" {
  description = "Secondary connection string"
  value       = azurerm_eventhub_namespace_authorization_rule.auth_rule.secondary_connection_string
}

output "event_hub_ids" {
  description = "Ids of created event hubs"
  value       = [for event_hub in azurerm_eventhub.eventhubs : event_hub.id]
}

output "bootstrap_server" {
  description = "Bootstrap server used for servicebus"
  value       = "${azurerm_eventhub_namespace.event_hub_namespace.name}.servicebus.windows.net:9093"
}

output "sftp_user_password" {
  description = "The generated password for the SFTP user"
  value       = azurerm_storage_account_local_user.sftp_user.password
  sensitive   = true
}

output "sftp_storage_credentials" {
  description = "SFTP credentials for the additional storage account"
  value = var.additional_sftp_storage.enabled ? [{
    host     = azurerm_storage_account.sftp_storage_account[0].primary_blob_host
    port     = 22
    # the expected format of this is <STORAGE-ACCOUNT>.<CONTAINER>.<USER> refer to docs https://learn.microsoft.com/en-us/azure/storage/blobs/secure-file-transfer-protocol-support#home-directory
    username = "${azurerm_storage_account.sftp_storage_account[0].name}.${azurerm_storage_container.sftp_container[0].name}.${azurerm_storage_account_local_user.sftp_storage_user[0].name}"
    password = azurerm_storage_account_local_user.sftp_storage_user[0].password
  }] : []
  sensitive = true
}

output "eventhub_read_connection_strings" {
  description = "Connection strings for the Read policies"
  value = {
    for k, v in azurerm_eventhub_authorization_rule.read_rules :
    k => v.primary_connection_string
  }
  sensitive = true 
}

output "eventhub_write_connection_strings" {
  description = "Connection strings for the Write policies"
  value = {
    for k, v in azurerm_eventhub_authorization_rule.write_rules :
    k => v.primary_connection_string
  }
  sensitive = true
}