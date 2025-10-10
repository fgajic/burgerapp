variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "location" {
  description = "Location for the workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name to attach to"
  type        = string
}

variable "retention_in_days" {
  description = "Retention in days for the workspace"
  type        = number
  default     = 30
}
