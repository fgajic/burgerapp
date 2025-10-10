
output "read_association" {
  description = "Read association value"
  value       = random_uuid.read_assosiation_uuid.result
}

output "write_association" {
  description = "Write association value"
  value       = random_uuid.write_assosiation_uuid.result
}

output "application_gateway_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway_ip.ip_address
}