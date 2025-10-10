locals {
  frontend_ip_config_name = "${var.name}-frontend-ip-config"
}

# Data source to fetch the certificate from the key vault (optional)
data "azurerm_key_vault_certificate" "cert" {
  count        = var.key_vault_id != null && var.certificate_name != null ? 1 : 0
  name         = var.certificate_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway_identity.id]
  }


  gateway_ip_configuration {
    name      = "${var.name}-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = var.ip_id
  }

  dynamic "ssl_certificate" {
    for_each = var.key_vault_id != null && var.certificate_name != null ? [1] : []
    content {
      name                = var.certificate_name
      key_vault_secret_id = data.azurerm_key_vault_certificate.cert[0].versionless_secret_id
    }
  }

  sku {
    name     = var.sku
    tier     = var.sku
    capacity = var.sku_capacity
  }

  dynamic "frontend_port" {
    for_each = var.listeners

    content {
      name = "${frontend_port.key}-listener-port"
      port = frontend_port.value.port
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.pools

    content {
      name = "${backend_address_pool.key}-pool"
      fqdns = [
        backend_address_pool.value
      ]
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_settings

    content {
      name                                = "${backend_http_settings.key}-settings"
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      probe_name                          = "${backend_http_settings.key}-probe"
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = "${probe.key}-probe"
      interval                                  = probe.value.interval
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      timeout                                   = probe.value.timeout
      port = probe.value.port

      match {
        status_code = [
          "200-399"
        ]
      }
    }
  }

  dynamic "http_listener" {
    for_each = var.listeners

    content {
      name                           = "${http_listener.key}-listener"
      frontend_ip_configuration_name = local.frontend_ip_config_name
      frontend_port_name             = "${http_listener.key}-listener-port"
      protocol                       = http_listener.value.protocol
      ssl_certificate_name           = http_listener.value.protocol == "Https" && var.certificate_name != null && var.key_vault_id != null ? var.certificate_name : null
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.redirect_rules
    content {
      name = "${redirect_configuration.key}-redirect"
      redirect_type = redirect_configuration.value.redirect_type
      target_listener_name = "${redirect_configuration.value.target}-listener"
      include_path = true
      include_query_string = true
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.redirect_rules

    content {
      name = "${request_routing_rule.key}-redirect-rule"
      priority = request_routing_rule.value.priority
      rule_type = "Basic"
      http_listener_name = "${request_routing_rule.key}-listener"
      redirect_configuration_name = "${request_routing_rule.key}-redirect"
    }
  }

  # Only create basic rules when there are no path-based rules for the same listener
  dynamic "request_routing_rule" {
    for_each = length(var.path_rules) == 0 ? var.rules : {}

    content {
      name                       = "${request_routing_rule.key}-routing-rule"
      priority                   = request_routing_rule.value.priority
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.key}-listener"
      backend_address_pool_name  = "${request_routing_rule.key}-pool"
      backend_http_settings_name = "${request_routing_rule.key}-settings"
    }
  }

  # Path-based routing support
  dynamic "url_path_map" {
    for_each = var.path_rules
    content {
      name = "${url_path_map.key}-url-path-map"
      default_backend_http_settings_name = "${url_path_map.value.default_backend}-settings"
      default_backend_address_pool_name  = "${url_path_map.value.default_backend}-pool"

      dynamic "path_rule" {
        for_each = { for pr in url_path_map.value.paths : pr.path => pr }
        content {
          # Azure name requirements: start/end with word char or '_', allow '.', '-', '_'
          name                       = trim(replace(replace(path_rule.key, "/", "-"), "*", "star"), "-")
          paths                      = [path_rule.key]
          backend_address_pool_name  = "${path_rule.value.backend}-pool"
          backend_http_settings_name = "${path_rule.value.backend}-settings"
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.path_rules
    content {
      name                  = "${request_routing_rule.key}-path-rule"
      priority              = request_routing_rule.value.priority
      rule_type             = "PathBasedRouting"
      http_listener_name    = "${request_routing_rule.value.listener}-listener"
      url_path_map_name     = "${request_routing_rule.key}-url-path-map"
    }
  }
}

# 

resource "azurerm_user_assigned_identity" "app_gateway_identity" {
  name                = "${var.name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "gateway_keyvault_access" {
  count               = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_gateway_identity.principal_id
}

resource "azurerm_key_vault_access_policy" "gateway_keyvault_policy" {
  count        = var.key_vault_id != null ? 1 : 0
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_user_assigned_identity.app_gateway_identity.tenant_id
  object_id    = azurerm_user_assigned_identity.app_gateway_identity.principal_id

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
}