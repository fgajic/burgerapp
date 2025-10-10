resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                       = "log-analytics"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  retention_in_days          = var.retention_in_days
  tags                       = var.tags
  internet_ingestion_enabled = true
}

resource "azurerm_application_insights" "application_insights" {
  name                       = "application-insights"
  location                   = var.location
  retention_in_days          = var.retention_in_days
  workspace_id               = azurerm_log_analytics_workspace.log_analytics.id
  application_type           = "web"
  resource_group_name        = var.resource_group_name
  tags                       = var.tags
  internet_ingestion_enabled = true
}
