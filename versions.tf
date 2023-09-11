terraform {
  required_version = ">= 1.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.30.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.40.0"
    }
  }
}