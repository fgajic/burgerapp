output "acr_username" {
  description = "Common username for acr"
  value       = "terraform"
}

output "acr_resource_group_name" {
  description = "Common acr resource group name"
  value       = "hes-acr"
}

output "acr_name" {
  description = "Common name for acr"
  value       = "hesbps.azurecr.io"
}

output "heswebapp_image_name" {
  description = "Name for hes web app docker image repository"
  value       = "heswebapp"
}

output "hes_dlms_image_name" {
  description = "Name for hes dlms app docker image repository"
  value       = "hes-dlms"
}

output "hes_auditlog_image_name" {
  description = "Name for hes auditlog app docker image repository"
  value       = "hes-auditlog"
}

output "hes_fe_image_name" {
  description = "Name for the hes frontend docker image repository"
  value       = "hes-frontend"
}
