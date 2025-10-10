output "static_ip_address" {
  description = "Static ip address of the container apps environment"
  value       = azurerm_container_app_environment.container_app_env.static_ip_address
}

output "domain_name" {
  description = "Domain of the container app environment"
  value       = azurerm_container_app_environment.container_app_env.default_domain
}

output "containers" {
  description = "FQDNs of all containers deployed"
  value       = azurerm_container_app.container_apps
}
