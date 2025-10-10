variable "common_tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default = {
    environment = "staging"
    owner       = "filip"
    project     = "burgerapp"
  }
}

variable "IMAGE_TAG" {
  description = "Value of the image tag to be used in the container registry"
  type        = string
}


variable "PG_PASSWORD" {
  description = "Password for flexible_postgresql"
  type        = string
}

variable "ACR_PASSWORD" {
  description = "Password for ACR (registry token/password)"
  type        = string
  sensitive   = true
}