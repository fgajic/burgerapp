locals {
  resource_group_name     = "filip-bourgerapp"
  location                = "uksouth"
  app_gateway_name        = "filip-app-gateway"
}



resource "random_uuid" "read_assosiation_uuid" {
}
resource "random_uuid" "write_assosiation_uuid" {
}

module "common" {
  source             = "../../../2_common"
  resouce_group_name = local.resource_group_name
}

locals {
  address_space  = module.common.network_specification.address_space
  address_prefix = module.common.network_specification.address_prefix
}

resource "azurerm_public_ip" "app_gateway_ip" {
  name                = "${local.app_gateway_name}-public-ip"
  location            = local.location
  resource_group_name = local.resource_group_name

  # This should be adapted once we transition to
  # using domain names
  allocation_method = "Static"
  tags              = var.common_tags
}

module "vnet" {
  source              = "../../../1_modules/network"
  vnet_name           = "VirtualNetwork"
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = [local.address_space]
  tags                = var.common_tags
  subnets = {
    "default" = {
      address_prefixes = ["${local.address_prefix}.0.0/24"]
    }
    "app-gateway" = {
      address_prefixes         = ["${local.address_prefix}.1.0/24"]
      network_policies_enabled = false
    }
    "db-subnet" = {
      address_prefixes = ["${local.address_prefix}.2.0/24"]
      service_endpoints = [
        "Microsoft.Storage"
      ]
      service_delegation = {
        name = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action"
        ]
      }
    }
    "container-apps" = {
      address_prefixes = ["${local.address_prefix}.6.0/24"]
      service_delegation = {
        name = "Microsoft.App/environments"
        actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

module "analytics" {
  source              = "../../../1_modules/analytics"
  location            = local.location
  resource_group_name = local.resource_group_name
  tags                = var.common_tags
}

module "container-apps" {
  source = "../../../1_modules/container_apps"

  acr_password                   = var.ACR_PASSWORD
  acr_username                   = "filipbourgerappacr"
  location                       = local.location
  resource_group_name            = local.resource_group_name
  subnet_id                      = [for subnet in module.vnet.subnets : subnet.id if subnet.name == "container-apps"][0]
  vnet_id                        = module.vnet.vnet_id
  log_analytics_workspace_id     = module.analytics.workspace_id
  internal_load_balancer_enabled = true

  tags = var.common_tags

  containers = [
    {
      name                     = "backend"
      image_repository         = "burgerbuilder-backend"
      registry                 = "filipbourgerappacr.azurecr.io"
      image_tag                = "v1.0.0"
      cpu                      = 1
      port                     = 8080
      session_affinity_enabled = true

      liveness_path           = "/actuator/health"
      enable_session_affinity = true
      environment_variables = {
        "SPRING_PROFILES_ACTIVE" : "docker"
        "DB_HOST" : module.app-db.server_fqdn
        "DB_PORT" : 5432
        "DB_NAME" : "burgerbuilder"
        "DB_USERNAME" : "postgres"
        "DB_PASSWORD" : var.PG_PASSWORD
        "DB_DRIVER" : "org.postgresql.Driver"
      }
    },
    {
      name                    = "frontend"
      image_repository        = "burgerbuilder-frontend"
      registry                = "filipbourgerappacr.azurecr.io"
      image_tag               = "v1.0.0"
      cpu                     = 0.25
      port                    = 80
      enable_session_affinity = false
      environment_variables = {
        "VITE_API_BASE_URL" : "http://51.140.70.53"
      }
    }
  ]
}

module "app-db" {
  source = "../../../1_modules/flexible_postgresql"

  name                = "burger-db"
  admin_username      = "postgres"
  admin_password      = var.PG_PASSWORD
  location            = local.location
  resource_group_name = local.resource_group_name
  has_replica         = false
  vnet-id             = module.vnet.vnet_id
  subnet_id           = [for subnet in module.vnet.subnets : subnet.id if subnet.name == "db-subnet"][0]
  tags                = var.common_tags
  dns_prefix          = "staging"

  storage      = 131072
  sku          = "GP_Standard_D2s_v3"
  storage_tier = "P30"

  high_availability_enabled = false

  databases = ["burgerbuilder"]
}


module "bourgerapp-app-gateway" {
  source = "../../../1_modules/application_gateway_v2"
  name   = local.app_gateway_name

  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = [for subnet in module.vnet.subnets : subnet.id if subnet.name == "app-gateway"][0]
  tags                = var.common_tags
  ip_id               = azurerm_public_ip.app_gateway_ip.id

  sku          = "Standard_v2"
  sku_capacity = 1
  zones        = null

  pools = {
    "frontend" : "frontend.${module.container-apps.domain_name}"
    "backend" : "backend.${module.container-apps.domain_name}"
  }
  backend_settings = {
    "frontend" : { port = 80, protocol = "Http" }
    "backend" : { port = 80, protocol = "Http" }
  }

  listeners = {
    "frontend" : { port = 80, protocol = "Http" }
  }

  rules = {
    "frontend" : { priority = 1 }
  }
  redirect_rules = {}
  probes = {
    "frontend" : { port = 80, protocol = "Http", path = "/" }
    "backend" : { port = 80, protocol = "Http", path = "/actuator/health" }
  }

  # Path based: default -> frontend, /api/* -> backend
  path_rules = {
    "frontend" = {
      listener        = "frontend"
      priority        = 2
      default_backend = "frontend"
      paths = [
        { path = "/api/*", backend = "backend" }
      ]
    }
  }
}
