
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id

}


provider "cloudflare" {
  # Comment out key & email if using token
    #email = var.cloudflare_email
    #api_key = var.cloudflare_api_key
    api_token = var.cloudflare_token
}


