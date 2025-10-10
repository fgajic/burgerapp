locals {
  workload_profile_name = var.workload_profile.workload_profile_type == "Consumption" ? "Consumption" : "${var.workload_profile.workload_profile_type}-workload-profile"
}

resource "random_string" "container_app_env_name" {
  length  = 10
  special = false
  numeric = false
  upper   = false
}

resource "azurerm_container_app_environment" "container_app_env" {
  name                               = "container-app-env-${random_string.container_app_env_name.id}"
  location                           = var.location
  resource_group_name                = var.resource_group_name
  log_analytics_workspace_id         = var.log_analytics_workspace_id
  infrastructure_subnet_id           = var.subnet_id
  infrastructure_resource_group_name = "${var.resource_group_name}-container-app-env"

  # Do we need to change workload profile for prod?
  workload_profile {
    name                  = local.workload_profile_name
    maximum_count         = var.workload_profile.workload_profile_type == "Consumption" ? null : var.workload_profile.maximum_containers_count
    minimum_count         = var.workload_profile.workload_profile_type == "Consumption" ? null : var.workload_profile.minimum_containers_count
    workload_profile_type = var.workload_profile.workload_profile_type
  }
  tags = var.tags

  zone_redundancy_enabled        = var.zone_redundancy_enabled
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
}

resource "azurerm_private_dns_zone" "aca_dns_zone" {
  name                = azurerm_container_app_environment.container_app_env.default_domain
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aca_vnet_link" {
  name                  = "aca-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aca_dns_zone.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "aca_wildcard_a_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.aca_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_container_app_environment.container_app_env.static_ip_address]
}


resource "azurerm_container_app" "container_apps" {
  for_each = { for idx, container in var.containers : container.name => container }

  name                         = each.value.name
  container_app_environment_id = azurerm_container_app_environment.container_app_env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  tags                  = var.tags
  workload_profile_name = local.workload_profile_name
  template {
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas
    container {
      name   = each.value.name
      image  = "${each.value.registry}/${each.value.image_repository}:${each.value.image_tag}"
      cpu    = each.value.cpu
      memory = "${each.value.cpu * 2}Gi"

      dynamic "env" {
        for_each = each.value.environment_variables

        content {
          name  = env.key
          value = env.value
        }
      }

      liveness_probe {
        initial_delay    = each.value.liveness_initial_delay
        interval_seconds = each.value.liveness_interval_seconds
        path             = each.value.liveness_path
        port             = each.value.port
        transport        = upper(each.value.transport)
      }
    }
  }
  secret {
    name  = "terraform-pass"
    value = var.acr_password
  }
  ingress {
    allow_insecure_connections = true
    transport                  = lower(each.value.transport)
    target_port                = each.value.port
    external_enabled           = true

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
  registry {
    server               = each.value.registry
    username             = var.acr_username
    password_secret_name = "terraform-pass"
  }

}


resource "azapi_update_resource" "container_app_api" {
  for_each = {
    for container in var.containers : container.name => container
    if length(try(container.additional_port_mappings, [])) > 0 || try(container.session_affinity_enabled, false)
  }
  type        = "Microsoft.App/containerApps@2024-10-02-preview"
  resource_id = azurerm_container_app.container_apps[each.key].id

  body = {
    properties = {
      configuration = {
        ingress = {
          additionalPortMappings = each.value.additional_port_mappings
          stickySessions = {
            affinity = each.value.enable_session_affinity ? "sticky" : "none"
          }
        }
        secrets = [
          {
            name  = "terraform-pass"
            value = var.acr_password
          }
        ]
      }
    }
  }

  depends_on = [
    azurerm_container_app.container_apps,
  ]
  lifecycle {
    replace_triggered_by = [azurerm_container_app.container_apps]
  }
}