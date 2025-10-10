data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = var.sku_name

  enabled_for_disk_encryption = true
  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.purge_protection_enabled

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

# Assign Key Vault Administrator role to the current service principal
resource "azurerm_role_assignment" "key_vault_admin" {
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign Key Vault Certificates Officer role to the current service principal
resource "azurerm_role_assignment" "key_vault_cert_officer" {
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

output "id" {
  value = azurerm_key_vault.vault.id
}

output "uri" {
  value = azurerm_key_vault.vault.vault_uri
} 