variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "name" {
  description = "Name of the application gateway instance"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the application gateway"
  type        = string
}

variable "location" {
  description = "Location for the application gateway to be deployed in"
  type        = string
}

variable "subnet_id" {
  description = "Subnet id for the application gateway to use"
  type        = string
}

variable "sku" {
  description = "The SKU of the Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "sku_capacity" {
  description = "The capacity of the Application Gateway"
  type        = number
  default     = 2
}

variable "pools" {
  description = "Map of Backend pools for application gateway where the key is the name of the listener and the value the ip address/fqdn (ex. webapp -> webapp.dns.record )"
  type = map(string)
}

variable "backend_settings" {
  type = map(object({
    port = number
    protocol = string
    cookie_based_affinity = optional(string,"Disabled")
    request_timeout = optional(number,20)
    pick_host_name_from_backend_address = optional(bool,true)
  }))
}

variable "listeners" {
  description = "Map of listeners"
  type = map(object({
    port = number
    protocol = string
  }))
}

variable "rules" {
  type = map(object({
    priority = number
  }))
}

variable "path_rules" {
  description = "Path-based routing rules"
  type = map(object({
    listener = string
    priority = number
    default_backend = string
    paths = list(object({
      path = string
      backend = string
    }))
  }))
  default = {}
}

variable "redirect_rules" {
  description = "Redirect rules"
  type = map(object({
    redirect_type = optional(string,"Permanent")
    target = string
    priority = number
  }))
}

variable "probes" {
  type = map(object({
    port = number
    protocol = string
    path = string
    interval = optional(number,30)
    timeout = optional(number,10)
    unhealthy_threshold = optional(number,5)
    pick_host_name_from_backend_http_settings = optional(bool,true)
  }))
}

variable "ip_id" {
  description = "Id of public ip resource that should be tied to gateway"
  type        = string
}

variable "zones" {
  description = "Availability zones for the Application Gateway (omit for non-zonal)"
  type        = list(string)
  default     = null
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store certificates"
  type        = string
  default     = null
}

variable "certificate_name" {
  description = "Name of an existing certificate in the key vault. If provided, will use this instead of creating a new certificate."
  type        = string
  default     = null
}
