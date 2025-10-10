output "app_gateway_id" {
  description = "Application gateway id"
  value       = azurerm_application_gateway.app_gateway.id
}

output "links" {
  description = "Links that were input"
  value       = var.links
}
