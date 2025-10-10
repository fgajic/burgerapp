variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "location" {
  description = "Location of the resource"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name to tie to deployment"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log analytics workspace id used for observability"
  type        = string
}

variable "workload_profile" {
  description = "Workload profile to use for container apps"
  type = object({
    workload_profile_type    = string
    maximum_containers_count = number
    minimum_containers_count = number
  })

  default = {
    workload_profile_type    = "Consumption"
    maximum_containers_count = 0
    minimum_containers_count = 0
  }
}

variable "subnet_id" {
  description = "Subnet id used for container app environment"
  type        = string
}

variable "vnet_id" {
  description = "Virtual network id"
  type = string
}

variable "acr_password" {
  description = "The password for Azure Container Registry"
  type        = string
  sensitive   = true
}

variable "acr_username" {
  description = "The username for Azure Container Registry"
  type        = string
}

variable "zone_redundancy_enabled" {
  description = "Zone redundancy enabled on Container Apps Environment"
  type = bool
  default = false
}

variable "internal_load_balancer_enabled" {
  description = "Internal load-balancer enabled on Container Apps Environment"
  type = bool
  default = false
}

variable "containers" {
  description = "Definition of containers to deploy"
  type = list(object({
    name         = string
    min_replicas = optional(number, 1)
    max_replicas = optional(number, 2)

    image_repository = string
    image_tag        = string
    registry         = optional(string, "hesbps.azurecr.io")

    cpu = number

    environment_variables = optional(map(string), {})

    liveness_initial_delay    = optional(number, 10)
    liveness_interval_seconds = optional(number, 5)
    liveness_path             = optional(string, "/")

    port      = number
    transport = optional(string, "http")
    additional_port_mappings = optional(list(object({
      exposedPort = number
      external    = bool
      targetPort  = number
    })), [])
    enable_session_affinity = bool
  }))
  default = []
}
