resource "random_string" "eventhub_name" {
  length  = 10
  special = false
  numeric = false
}

resource "azurerm_eventhub_namespace" "event_hub_namespace" {
  # Just so it is harder to guess
  name = "${var.name}-${random_string.eventhub_name.id}"

  resource_group_name = var.resource_group_namespace
  location            = var.location
  tags                = var.tags

  auto_inflate_enabled = false
  sku                  = var.sku
  capacity             = var.capacity

  public_network_access_enabled = true
}

resource "azurerm_eventhub_namespace_authorization_rule" "auth_rule" {
  name                = "navi"
  namespace_name      = azurerm_eventhub_namespace.event_hub_namespace.name
  resource_group_name = var.resource_group_namespace

  listen = true
  send   = true
  manage = false
}


//TODO Aleksa move SFTP resources to separate module

resource "random_uuid" "storage_account" {
  keepers = {
    storage_account = var.storage_account_name
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                = "${var.storage_account_name}${substr(replace(random_uuid.storage_account.id, "-", ""), 0, 23 - length(var.storage_account_name))}"
  resource_group_name = var.resource_group_namespace
  location            = var.location
  tags                = var.tags

  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind            = var.storage_account_kind
  is_hns_enabled         = true
  sftp_enabled           = var.enable_sftp
  min_tls_version        = "TLS1_2"
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "${var.name}-storage-container"
  storage_account_id = azurerm_storage_account.storage_account.id
  container_access_type = "private"
}

resource "azurerm_storage_account_local_user" "sftp_user" {
  name                 = var.sftp_user_name
  storage_account_id   = azurerm_storage_account.storage_account.id
  ssh_key_enabled      = false
  ssh_password_enabled = true
  home_directory       = var.sftp_user_home_directory

  permission_scope {
    permissions {
      read   = true
      create = true
      write  = true
    }
    service       = "blob"
    resource_name = azurerm_storage_container.storage_container.name
  }
}

# Additional SFTP-enabled storage account
resource "random_uuid" "sftp_storage_account" {
  count = var.additional_sftp_storage.enabled ? 1 : 0
  keepers = {
    storage_account = var.additional_sftp_storage.name
  }
}

resource "azurerm_storage_account" "sftp_storage_account" {
  count               = var.additional_sftp_storage.enabled ? 1 : 0
  name                = "${var.additional_sftp_storage.name}${substr(replace(random_uuid.sftp_storage_account[0].id, "-", ""), 0, 23 - length(var.additional_sftp_storage.name))}"
  resource_group_name = var.resource_group_namespace
  location            = var.location
  tags                = var.tags

  account_tier             = var.additional_sftp_storage.storage_account_tier
  account_replication_type = var.additional_sftp_storage.storage_account_replication_type
  account_kind            = var.additional_sftp_storage.storage_account_kind
  is_hns_enabled         = true
  sftp_enabled           = true
  min_tls_version        = "TLS1_2"
}

resource "azurerm_storage_container" "sftp_container" {
  count                 = var.additional_sftp_storage.enabled ? 1 : 0
  name                  = var.additional_sftp_storage.container_name
  storage_account_id  = azurerm_storage_account.sftp_storage_account[0].id
  container_access_type = "private"
}

resource "azurerm_storage_account_local_user" "sftp_storage_user" {
  count                = var.additional_sftp_storage.enabled ? 1 : 0
  name                 = var.additional_sftp_storage.sftp_user_name
  storage_account_id   = azurerm_storage_account.sftp_storage_account[0].id
  ssh_key_enabled      = false
  ssh_password_enabled = true
  home_directory       = var.additional_sftp_storage.sftp_user_home_directory

  permission_scope {
    permissions {
      read   = true
      create = true
      write  = true
    }
    service       = "blob"
    resource_name = azurerm_storage_container.sftp_container[0].name
  }
}

resource "azurerm_eventhub" "eventhubs" {
  for_each = var.hubs

  name                = each.key
  namespace_id = azurerm_eventhub_namespace.event_hub_namespace.id
  partition_count     = each.value.partition_count
  message_retention   = each.value.retention_in_days
  status              = each.value.status

  # COMMENTED OUT FOR NOW
  # capture_description {
  #   enabled             = each.value.capture_destination.enabled
  #   encoding            = each.value.capture_destination.encoding
  #   interval_in_seconds = each.value.capture_destination.interval_in_seconds
  #   skip_empty_archives = each.value.capture_destination.skip_empty_archives
  #   destination {
  #     name                = "EventHubArchive.AzureBlockBlob"
  #     archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
  #     blob_container_name = azurerm_storage_container.storage_container.name
  #     storage_account_id  = azurerm_storage_account.storage_account.id
  #   }
  # }
}

resource "azurerm_eventhub_authorization_rule" "write_rules" {
  for_each = var.hubs

  name = "${each.key}-write"
  namespace_name = azurerm_eventhub_namespace.event_hub_namespace.name
  eventhub_name = each.key
  resource_group_name = var.resource_group_namespace
  send = true
  listen = false
  manage = false
  depends_on = [azurerm_eventhub.eventhubs, azurerm_eventhub_namespace.event_hub_namespace]
}

resource "azurerm_eventhub_authorization_rule" "read_rules" {
  for_each = var.hubs

  name = "${each.key}-read"
  namespace_name = azurerm_eventhub_namespace.event_hub_namespace.name
  eventhub_name = each.key
  resource_group_name = var.resource_group_namespace
  send = false
  listen = true
  manage = false

  depends_on = [azurerm_eventhub.eventhubs, azurerm_eventhub_namespace.event_hub_namespace]
}



resource "azurerm_eventhub_consumer_group" "eventhubs_consumer_groups" {
  for_each = var.hubs

  name                = "${each.key}-consumer-group"
  namespace_name      = azurerm_eventhub_namespace.event_hub_namespace.name
  eventhub_name       = each.key
  resource_group_name = var.resource_group_namespace

  depends_on = [azurerm_eventhub.eventhubs, azurerm_eventhub_namespace.event_hub_namespace]
}