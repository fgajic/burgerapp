locals {
  frontend_ip_config_name = "${var.name}-frontend-ip-config"
}

# Data source to fetch the certificate from the key vault
data "azurerm_key_vault_certificate" "cert" {
  name         = var.certificate_name
  key_vault_id = var.key_vault_id
}

resource "time_sleep" "wait_for_role_propagation" {
  depends_on = [azurerm_role_assignment.gateway_keyvault_access]
  create_duration = "30s"
}

resource "azurerm_application_gateway" "app_gateway" {
  depends_on = [time_sleep.wait_for_role_propagation]
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  zones = ["1", "2", "3"]

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

  ssl_certificate {
    name                = var.certificate_name
    key_vault_secret_id = data.azurerm_key_vault_certificate.cert.versionless_secret_id
  }

  sku {
    name     = var.sku
    tier     = var.sku
    capacity = var.sku_capacity
  }

  dynamic "frontend_port" {
    for_each = var.links

    content {
      name = "${frontend_port.key}-listener-port"
      port = frontend_port.value.listener_port
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.links

    content {
      name = "${backend_address_pool.key}-backend-pool"
      fqdns = [
        backend_address_pool.value.url
      ]
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.links

    content {
      name                                = "${backend_http_settings.key}-settings"
      cookie_based_affinity               = "Disabled"
      # this port is the target port on the container that is exposed, when this isnt set on the container its set to 443 by default
      port                                = backend_http_settings.value.backend_port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      pick_host_name_from_backend_address = true
      probe_name                          = "${backend_http_settings.key}-probe"
    }
  }

  dynamic "http_listener" {
    for_each = var.links

    content {
      name                           = "${http_listener.key}-config"
      frontend_ip_configuration_name = local.frontend_ip_config_name
      frontend_port_name             = "${http_listener.key}-listener-port"
      protocol                       = http_listener.value.protocol
      ssl_certificate_name           = http_listener.value.protocol == "Https" ? var.certificate_name : null
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.links

    content {
      name                       = "${request_routing_rule.key}-routing-rule"
      priority                   = request_routing_rule.value.priority
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.key}-config"
      backend_address_pool_name  = "${request_routing_rule.key}-backend-pool"
      backend_http_settings_name = "${request_routing_rule.key}-settings"
    }
  }

  dynamic "probe" {
    for_each = var.links

    content {
      name                                      = "${probe.key}-probe"
      interval                                  = probe.value.probe_interval
      protocol                                  = probe.value.protocol
      path                                      = probe.value.probe_path
      unhealthy_threshold                       = 5
      pick_host_name_from_backend_http_settings = true
      timeout                                   = 10
      port = probe.value.probe_port

      match {
        status_code = [
          "200-399"
        ]
      }
    }
  }
}

resource "azurerm_user_assigned_identity" "app_gateway_identity" {
  name                = "${var.name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "gateway_keyvault_access" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_gateway_identity.principal_id
}

resource "azurerm_key_vault_access_policy" "gateway_keyvault_policy" {
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