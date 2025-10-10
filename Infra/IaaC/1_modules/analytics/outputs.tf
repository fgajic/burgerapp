output "workspace_id" {
  description = "Log analytics workspace id"
  value       = azurerm_log_analytics_workspace.log_analytics.id
}

output "insights_connection_string" {
  description = "Insights connection string"
  value       = azurerm_application_insights.application_insights.connection_string
}

output "insights_id" {
  description = "Application insights id"
  value       = azurerm_application_insights.application_insights.id
}
