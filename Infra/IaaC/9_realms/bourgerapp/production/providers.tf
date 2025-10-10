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
  backend "azurerm" {
    resource_group_name  = "hes-tfstate"
    storage_account_name = "hestfstateacc"
    container_name       = "tf-state-hes-production"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
