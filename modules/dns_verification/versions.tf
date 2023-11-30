terraform {
  required_version = "~>1.3"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.80"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~>1.10"
    }


    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>4.19"
    }


    azuread = {
      source = "hashicorp/azuread"
      version = "~>2.46"
    }

  }


  # backend "azurerm" {

  # }
}

