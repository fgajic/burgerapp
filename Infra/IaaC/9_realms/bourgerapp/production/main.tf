locals {
  resource_group_name     = "hes-production"
  location                = "uksouth"
  app_gateway_name        = "hes-prod-gateway"
  heswebapp_listener_port = 8443
  hes_dlms_listener_port  = 8444
  hes_image_tag           = "db8e12972e8b3ec3537cb27df87a69de7cf4e633"
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
  domain_name_label = "bps-hes"
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
      address_prefixes = ["${local.address_prefix}.1.0/24"]
    }
    "dlms-db-subnet" = {
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
    "hes-db-subnet" = {
      address_prefixes = ["${local.address_prefix}.3.0/24"]
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

module "dlms-db" {
  source = "../../../1_modules/flexible_postgresql"

  name                = "dlms-db"
  admin_username      = "postgres"
  admin_password      = var.PG_PASSWORD
  location            = local.location
  resource_group_name = local.resource_group_name
  has_replica         = false
  vnet-id             = module.vnet.vnet_id
  subnet_id           = [for subnet in module.vnet.subnets : subnet.id if subnet.name == "dlms-db-subnet"][0]
  tags                = var.common_tags

  storage      = 131072
  sku          = "GP_Standard_D2s_v3"
  storage_tier = "P30"

  high_availability_enabled = true
  availability_zone        = "1"
  standby_availability_zone = "1"
}

module "container-apps" {
  source = "../../../1_modules/container_apps"

  acr_password               = var.ACR_PASSWORD
  acr_username               = module.common.acr_username
  location                   = local.location
  resource_group_name        = local.resource_group_name
  subnet_id                  = [for subnet in module.vnet.subnets : subnet.id if subnet.name == "container-apps"][0]
  log_analytics_workspace_id = module.analytics.workspace_id
  tags                       = var.common_tags

  internal_load_balancer_enabled = true

  containers = [
    {
      name             = "heswebapp"
      image_repository = module.common.heswebapp_image_name
      image_tag        = local.hes_image_tag
      cpu              = 0.5
      port             = 8080

      liveness_path = "/api/hello"

      min_replicas = 2
      max_replicas = 4

      environment_variables = {
        "ConnectionStrings__HeadEndDb" : module.hes-api-db.connection_string
        "ConnectionStrings__HeadEndLocationDb" : module.hes-api-db.connection_string
        "ConnectionStrings__HeadEndUserSettingsDb" : module.hes-api-db.connection_string
        "ASPNETCORE_ENVIRONMENT" : "Production"
        "Logging__LogLevel__Microsoft.AspNetCore" : "Trace"
        "Logging__LogLevel__Default" : "Trace"
        "CommandKafkaPublisher__BootstrapServers" : module.event-hub.bootstrap_server
        "CommandKafkaPublisher__SecurityProtocol" : "SaslSsl"
        "CommandKafkaPublisher__ConnectionString" : "<placeholder>"
        "CommandKafkaPublisher__EventTopic" : "hes-command"
        "CommandKafkaPublisher__SocketTimeoutMs" : 60000
        "CommandKafkaPublisher__Group" : "hes-command-consumer-group"
        "CommandKafkaPublisher__SessionTimeoutMs" : 30000
        "CommandKafkaPublisher__BrokerVersionFallback" : "1.0.0"
        "CommandKafkaPublisher__Debug" : "security,broker,protocol"
        "CommandKafkaPublisher__SaslUsername" : "$ConnectionString"
        "CommandResponseKafkaConsumer__BootstrapServers" : module.event-hub.bootstrap_server
        "CommandResponseKafkaConsumer__SecurityProtocol" : "SaslSsl"
        "CommandResponseKafkaConsumer__ConnectionString" : "<placeholder>"
        "CommandResponseKafkaConsumer__EventTopic" : "hes-command-response"
        "CommandResponseKafkaConsumer__SocketTimeoutMs" : 60000
        "CommandResponseKafkaConsumer__SessionTimeoutMs" : 30000
        "CommandResponseKafkaConsumer__BrokerVersionFallback" : "1.0.0"
        "CommandResponseKafkaConsumer__Debug" : "security,broker,protocol"
        "CommandResponseKafkaConsumer__SaslUsername" : "$ConnectionString"
        "CommandResponseKafkaConsumer__Group" : "hes-command-response-consumer-group"
        "EventKafkaConsumer__BootstrapServers" : module.event-hub.bootstrap_server
        "EventKafkaConsumer__SecurityProtocol" : "SaslSsl"
        "EventKafkaConsumer__ConnectionString" : "<placeholder>"
        "EventKafkaConsumer__EventTopic" : "hes-event"
        "EventKafkaConsumer__SocketTimeoutMs" : 60000
        "EventKafkaConsumer__SessionTimeoutMs" : 30000
        "EventKafkaConsumer__BrokerVersionFallback" : "1.0.0"
        "EventKafkaConsumer__Debug" : "security,broker,protocol"
        "EventKafkaConsumer__SaslUsername" : "$ConnectionString"
        "EventKafkaConsumer__Group" : "hes-event-consumer-group"
        "ApiKeys__WriteAssociation" : random_uuid.write_assosiation_uuid.result
        "ApiKeys__ReadAssociation" : random_uuid.read_assosiation_uuid.result
        "Orleans__DashboardPort" : 4057
        "Orleans__DashboardUsername" : "admin"
        "Orleans__DashboardPassword" : "Admin!!123"
        "Orleans__OrleansDbCluster" : module.dlms-db.connection_strings[0]
        "Orleans__OrleansDbGrain" : module.dlms-db.connection_strings[0]
        "Orleans__OrleansDbReminder" : module.dlms-db.connection_strings[0]
        "ApplicationInsights__ConnectionString" : module.analytics.insights_connection_string
        "ApplicationInsights__LogLevel" : "Warning"
        "Sftp__SftpPort" : module.event-hub.sftp_storage_credentials[0].port
        "Sftp__SftpHost" : module.event-hub.sftp_storage_credentials[0].host
        "Sftp__SftpUser" : module.event-hub.sftp_storage_credentials[0].username
        "Sftp__SftpPassword" : module.event-hub.sftp_storage_credentials[0].password
        "AllowedHosts" : "*"
        "EmailConfiguration__Username" : "apikey"
        "EmailConfiguration__ApiKey" : "<placeholder>"
        "EmailConfiguration__From" : "noreply@bpsafrica.com"
        "EmailConfiguration__Host" : "smtp.sendgrid.net"
        "EmailConfiguration__Port" : 587
        "Identity__ClientId" : "c09df06a-afdc-4618-9930-36cfa18b2370"
        "Identity__ClientSecret" : "249977e6-cc35-4137-9053-bd65a1c459bf"
        "Identity__RedirectLoginUrl" : "https://adora.hes.bpsafrica.com/process-login"
        "Identity__UiUrl" : "https://adora.hes.bpsafrica.com"
        "Identity__useOpenIdDict" : "true"
        "Identity__identityUrl" : "https://bps-identity-staging.azurewebsites.net"
        "Identity__appDisplayName" : "HeadEndStaging"
        "Identity__ConnectionString" : "<placeholder>"
        "Identity__ApiKey" : "249977e6-cc35-4137-9053-bd65a1c459bf"
        "Identity__queueName" : "identity-api-requests-staging"
        "Identity__BaseUrl" : "https://adora.hes.bpsafrica.com:${local.heswebapp_listener_port}"
        "GITHUB_SHA" : local.hes_image_tag
      }

      additional_port_mappings = [{
        external    = true
        targetPort  = 4057
        exposedPort = 4057
        }, {
        external    = false
        targetPort  = 11111
        exposedPort = 11111
        }, {
        external    = false
        targetPort  = 30000
        exposedPort = 30000
      }]
    },
    {
      name             = "hes-frontend"
      image_repository = module.common.hes_fe_image_name
      image_tag        = local.hes_image_tag
      cpu              = 0.25
      port             = 8080

      min_replicas = 2
      max_replicas = 4

      environment_variables = {
        "API_URL" : "https://${azurerm_public_ip.app_gateway_ip.ip_address}:${local.heswebapp_listener_port}"
        "USEOPENIDDICT" : "true"
        "GITHUB_SHA" : local.hes_image_tag
      }
    },
    {
      name             = "hes-dlms"
      image_repository = module.common.hes_dlms_image_name
      image_tag        = local.hes_image_tag
      cpu              = 1
      port             = 8080

      liveness_path = "/api/hello"

      min_replicas = 2
      max_replicas = 4

      environment_variables = {
        "ConnectionStrings__HeadEndDlmsDb" : module.dlms-db.connection_strings[0]
        "ASPNETCORE_ENVIRONMENT" : "Production"
        "Logging__LogLevel__Microsoft.AspNetCore" : "Trace"
        "Logging__LogLevel__Default" : "Trace"
        "CommandKafkaConsumer__BootstrapServers" : module.event-hub.bootstrap_server
        "CommandKafkaConsumer__ConnectionString" : "<placeholder>"
        "CommandKafkaConsumer__EventTopic" : "hes-command"
        "CommandKafkaConsumer__Group" : "hes-command-consumer-group"
        "CommandKafkaConsumer__SecurityProtocol" : "SaslSsl"
        "CommandKafkaConsumer__SocketTimeoutMs" : 60000
        "CommandKafkaConsumer__SessionTimeoutMs" : 30000
        "CommandKafkaConsumer__BrokerVersionFallback" : "1.0.0"
        "CommandKafkaConsumer__Debug" : "security,broker,protocol"
        "CommandKafkaConsumer__SaslUsername" : "$ConnectionString"
        "CommandResponseKafkaPublisher__BootstrapServers" : module.event-hub.bootstrap_server
        "CommandResponseKafkaPublisher__ConnectionString" : "<placeholder>"
        "CommandResponseKafkaPublisher__EventTopic" : "hes-command-response"
        "CommandResponseKafkaPublisher__SecurityProtocol" : "SaslSsl"
        "CommandResponseKafkaPublisher__SocketTimeoutMs" : 60000
        "CommandResponseKafkaPublisher__SessionTimeoutMs" : 30000
        "CommandResponseKafkaPublisher__Group" : "hes-command-response-consumer-group"
        "CommandResponseKafkaPublisher__BrokerVersionFallback" : "1.0.0"
        "CommandResponseKafkaPublisher__Debug" : "security,broker,protocol"
        "CommandResponseKafkaPublisher__SaslUsername" : "$ConnectionString"
        "EventKafkaPublisher__BootstrapServers" : module.event-hub.bootstrap_server
        "EventKafkaPublisher__ConnectionString" : "<placeholder>"
        "EventKafkaPublisher__EventTopic" : "hes-event"
        "EventKafkaPublisher__Group" : "hes-event-consumer-group"
        "EventKafkaPublisher__SecurityProtocol" : "SaslSsl"
        "EventKafkaPublisher__SocketTimeoutMs" : 60000
        "EventKafkaPublisher__SessionTimeoutMs" : 30000
        "EventKafkaPublisher__BrokerVersionFallback" : "1.0.0"
        "EventKafkaPublisher__Debug" : "security,broker,protocol"
        "EventKafkaPublisher__SaslUsername" : "$ConnectionString"
        "ApiKeys__WriteAssociation" : random_uuid.write_assosiation_uuid.result
        "ApiKeys__ReadAssociation" : random_uuid.read_assosiation_uuid.result
        "Orleans__DashboardPort" : 4058
        "Orleans__DashboardUsername" : "admin"
        "Orleans__DashboardPassword" : "Admin!!123"
        "Orleans__OrleansDbCluster" : module.dlms-db.connection_strings[0]
        "Orleans__OrleansDbGrain" : module.dlms-db.connection_strings[0]
        "Orleans__OrleansDbReminder" : module.dlms-db.connection_strings[0]
        "ApplicationInsights__ConnectionString" : module.analytics.insights_connection_string
        "ApplicationInsights__LogLevel" : "Warning"
        "MeterEventServerOptions__IP" : "0.0.0.0"
        "MeterEventServerOptions_Port" : 4060
        "MeterEventServerOptions_bufferSize" : 264
        "AllowedHosts" : "*"
        "ExternalServices__HesWebApp" : "https://adora.hes.bpsafrica.com:${local.heswebapp_listener_port}"
        "GITHUB_SHA" : local.hes_image_tag
        "GsmProviderApiKeys__Onomondo": "<placeholder>"
      }

      additional_port_mappings = [{
        external    = true
        targetPort  = 4058
        exposedPort = 4058
        }, {
        external    = false
        targetPort  = 11112
        exposedPort = 11112
        }, {
        external    = false
        targetPort  = 30001
        exposedPort = 30001
      }, {
        external    = true
        targetPort  = 4060
        exposedPort = 4060
      }]
    }
  ]
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "bps_certificates" {
  name                = "bps-certificates-kv"
  resource_group_name = "hes-acr"
}

# Update the app gateway configuration to use HTTPS
module "hes-app-gateway" {
  source = "../../../1_modules/application_gateway"
  name   = local.app_gateway_name

  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id          = [for subnet in module.vnet.subnets : subnet.id if subnet.name == "app-gateway"][0]
  tags               = var.common_tags
  ip_id              = azurerm_public_ip.app_gateway_ip.id

  # Add Key Vault configuration
  key_vault_id       = data.azurerm_key_vault.bps_certificates.id
  certificate_name   = "adora-hes-bpsafrica-com"
  tenant_id          = data.azurerm_client_config.current.tenant_id
  subscription_id    = data.azurerm_client_config.current.subscription_id

  links = {
    "heswebapp" : {
      listener_port : local.heswebapp_listener_port
      priority : 2
      probe_path : "/api/hello"
      url : "heswebapp.${module.container-apps.domain_name}"
    }
    "hes-frontend" : {
      listener_port : 443
      priority : 1
      url : "hes-frontend.${module.container-apps.domain_name}"
    }
    "hes-dlms" : {
      listener_port : local.hes_dlms_listener_port
      priority : 3
      probe_path : "/api/hello"
      url : "hes-dlms.${module.container-apps.domain_name}"
    }
  }
  environment = "production"
}
