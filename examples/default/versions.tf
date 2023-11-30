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


    random = {
      source  = "hashicorp/random"
      version = "~>3.5"
    }

    time = {
      source  = "hashicorp/time"
      version = "~>0.9"
    }

    null = {
      source  = "hashicorp/null"
      version = "~>3.2"
    }

    local = {
      source  = "hashicorp/local"
      version = "~>2.4"
    }

    azuread = {
      source = "hashicorp/azuread"
      version = "~>2.46"
    }

   external = {
      source = "hashicorp/external"
      version = "~>2.3"
    }
  }


  # backend "azurerm" {

  # }
}

