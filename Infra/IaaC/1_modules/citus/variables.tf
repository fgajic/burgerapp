variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "name" {
  description = "Name of the instance"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name to use"
  type        = string
}

variable "location" {
  description = "Location to use to provision citus"
  type        = string
}

variable "worker_node_count" {
  description = "Number of worker nodes to deploy, can't be 1"
  type        = number
  default     = 0
}

variable "password" {
  description = "Password for the database"
  type        = string
}

variable "username" {
  description = "Username for the role created for the server"
  type        = string
  default     = "anothercitus"
}

variable "citus_version" {
  description = "Version of citus to use"
  type        = string
  default     = "12.1"
}

variable "coordinator_storage" {
  description = "Storage to use for coordinator"
  type        = number
  default     = 131072
}

variable "node_storage" {
  description = "Storage to use for worker nodes"
  type        = number
  default     = 32768
}

variable "pg_version" {
  description = "Version of postgresql to use"
  type        = string
  default     = "16"
}

variable "node_config" {
  description = "Worker node configuration block. Key's need to be valid values from: https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIER"
  type        = map(string)
  default     = {}
}

variable "coordinator_config" {
  description = "Coordinator configuration block. Key's need to be valid values from: https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIER"
  type        = map(string)
  default     = {}
}

variable "has_replica" {
  description = "Specify if this server has a replica"
  type        = bool
  default     = false
}

variable "node_vcores" {
  description = "Number of cores for each worker node"
  type        = number
  default     = 2
}

variable "coordinator_vcores" {
  description = "Number of cores for each coordinator"
  type        = number
  default     = 2
}

variable "subnet_id" {
  description = "Subnet id for the server"
  type        = string
}

variable "vnet_id" {
  description = "Virtual network id"
  type        = string
}

variable "node_server_edition" {
  description = "The edition of the coordinator server"
  type        = string
  default     = "MemoryOptimized"
}

variable "coordinator_server_edition" {
  description = "The edition of the coordinator server"
  type        = string
  default     = "BurstableGeneralPurpose"
}

variable "ha_enabled" {
  description = "Enable or disable high availability for the Citus cluster"
  type        = bool
  default     = false
}
