output "public_urls" {
  description = "Public URLs for the services"
  value       = [for name, link in module.hes-app-gateway.links : "${name} - ${lower(link.protocol)}://${azurerm_public_ip.app_gateway_ip.ip_address}:${link.listener_port}"]
}

output "read_association" {
  description = "Read association value"
  value       = random_uuid.read_assosiation_uuid.result
}

output "write_association" {
  description = "Write association value"
  value       = random_uuid.write_assosiation_uuid.result
}

output "sftp_password" {
  description = "Generated password for the SFTP user"
  value       = module.event-hub.sftp_user_password
  sensitive   = true
}

output "sftp_storage_credentials" {
  description = "SFTP credentials for the additional storage account"
  value       = module.event-hub.sftp_storage_credentials
  sensitive   = true
}