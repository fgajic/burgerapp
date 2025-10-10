terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.3"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.1.0"
    }
  }
  required_version = ">= 1.9"
}