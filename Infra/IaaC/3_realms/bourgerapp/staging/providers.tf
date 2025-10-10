terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.14.0, <= 4.38.1"
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
  backend "azurerm" {
    resource_group_name  = "env-staging"
    storage_account_name = "burgerapp"
    container_name       = "tfstate-staging"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
