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

variable "links" {
  description = "Map of backend services configurations"
  type = map(object({
    listener_port   = number
    priority       = number
    url            = string
    probe_path     = optional(string, "/")
    probe_interval = optional(number, 30)
    probe_port = optional(number, null)
    backend_port   = optional(number, 443)
    protocol       = optional(string, "Https")
    request_timeout = optional(number, 20)
  }))
}

variable "ip_id" {
  description = "Id of public ip resource that should be tied to gateway"
  type        = string
}

variable "certificate_path" {
  description = "Path to the SSL certificate file (PFX format)"
  type        = string
  default     = ""
}

variable "generate_self_signed" {
  description = "Whether to generate a self-signed certificate if no certificate is provided"
  type        = bool
  default     = true
}

variable "ssl_certificate_base64" {
  description = "Base64 encoded PFX certificate for SSL/TLS termination"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssl_certificate_password" {
  description = "Password for the PFX certificate"
  type        = string
  sensitive   = true
  default     = null
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store certificates"
  type        = string
}

variable "rule_type" {
  description = "The rule type for request routing rules"
  type        = string
  default     = "Basic"
}

variable "probe_protocol" {
  description = "The protocol used for health probes"
  type        = string
  default     = "Https"
}

variable "certificate_name" {
  description = "Name of an existing certificate in the key vault. If provided, will use this instead of creating a new certificate."
  type        = string
  default     = null
}

variable "enable_cors" {
  description = "Enable CORS for the application gateway"
  type        = bool
  default     = false
}

variable "cors_allow_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = []
}
