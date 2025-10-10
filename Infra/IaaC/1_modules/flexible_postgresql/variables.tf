variable "name" {
  description = "Name for the instance, will be used for dns"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "dns_prefix" {
  description = "Prefix for the dns"
  type        = string
}

variable "vnet-id" {
  description = "Id for the virtual network"
  type        = string
}

variable "location" {
  description = "Location for the server, best if it could be same as resource group"
  type        = string
}

variable "pg_version" {
  description = "Postgres version to use, defaults to 16"
  type        = string
  default     = "16"
}

variable "subnet_id" {
  description = "Subnet id with delegation for postgresql"
  type        = string
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
}

variable "storage" {
  description = "Storage in MB, must be one of the following: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server#storage_mb"
  type        = number
  default     = 32768
}

variable "storage_tier" {
  description = "Storage tier"
  type        = string
  default     = "P10"
}


variable "sku" {
  description = "SKU for the instance"
  type        = string
  default     = "B_Standard_B1ms"
}


variable "server_config" {
  description = "Server configuration block. Key's need to be valid values from: https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIER"
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "Databases to add in the server"
  type        = list(string)
  default     = []
}

variable "has_replica" {
  description = "Specifies whether this server should have a replica"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Retention policy that specifies how long the backup should be stored"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "availability_zone" {
  description = "Main availability zone"
  type = string
  default = null
}

variable "standby_availability_zone" {
  description = "Standby zone for high availability, defaults to null"
  type = string
  default = null
}

variable "high_availability_enabled" {
  description = "Enable high availability for the PostgreSQL Flexible Server"
  type        = bool
  default     = false
}
