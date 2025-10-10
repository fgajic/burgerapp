variable "common_tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default = {
    environment = "production"
    owner       = "hes-team"
    project     = "hes"
  }
}

variable "ACR_PASSWORD" {
  description = "Common password for azure container registry. Should be set via environment variable"
  type        = string
}

variable "PG_PASSWORD" {
  description = "Common password for postgresql instances. Should be set via environment variable and should be secure"
  type        = string
}

variable "sftp_user_name" {
  description = "Name for the SFTP user"
  type        = string
}