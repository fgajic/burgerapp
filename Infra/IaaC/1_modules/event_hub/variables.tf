variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "name" {
  description = "Name of the event hub namespace"
  type        = string
}

variable "location" {
  description = "Location where to deploy the event hub namespace"
  type        = string
}

variable "resource_group_namespace" {
  description = "Resource group namespace where to deploy event hub"
  type        = string
}

variable "sku" {
  description = "SKU tier to use for event hub namespace"
  type        = string
  default     = "Standard"
}

variable "capacity" {
  description = "Capacity for the namespace"
  type        = number
  default     = 2
}

variable "hubs" {
  description = "Hubs to deploy to the event hub namespace"
  type = map(object({
    partition_count   = optional(number, 1)
    retention_in_days = optional(number, 7)
    status            = optional(string, "Active")

    capture_destination = optional(object({
      enabled             = optional(bool, true)
      encoding            = optional(string, "Avro")
      interval_in_seconds = optional(number, 600)
      skip_empty_archives = optional(bool, true)
      }), {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 600
      skip_empty_archives = true
    })
  }))
}

variable "storage_account_kind" {
  description = "Kind of storage account. Must be StorageV2 for SFTP support"
  type        = string
  default     = "StorageV2"
}

variable "storage_account_tier" {
  description = "Account tier to use for the blob storage. Must be Standard for SFTP support"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "storage_account_name" {
  description = "Storage account name to use"
  type        = string
  default     = "hubstorageacc"
}

variable "sftp_user_name" {
  description = "Name for the SFTP user"
  type        = string
}

variable "sftp_user_home_directory" {
  description = "Home directory for the SFTP user"
  type        = string
}

variable "enable_sftp" {
  description = "Whether to enable SFTP on the main storage account"
  type        = bool
  default     = true
}

variable "additional_sftp_storage" {
  description = "Configuration for additional SFTP storage account"
  type = object({
    enabled = bool
    name = string
    storage_account_tier = string
    storage_account_replication_type = string
    storage_account_kind = string
    container_name = string
    sftp_user_name = string
    sftp_user_home_directory = string
  })
  default = {
    enabled = false
    name = ""
    storage_account_tier = "Standard"
    storage_account_replication_type = "LRS"
    storage_account_kind = "StorageV2"
    container_name = ""
    sftp_user_name = ""
    sftp_user_home_directory = ""
  }
}