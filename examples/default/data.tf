# data "azurerm_subscription" "primary" {
# }

# data "azuread_client_config" "current" {}


data "azapi_resource" "custom_domain" {
  type      = "Microsoft.Communication/emailServices/domains@2023-04-01-preview"
  resource_id = module.azure-communication-smtp.custom_domain_resource_id
#   name      = var.custom_domain
#   parent_id = module.azure-communication-smtp.azurerm_email_communication_service.example.id
  response_export_values = ["*"]
  depends_on = [module.azure-communication-smtp, azapi_resource.sender_usernames ]
}


data "azapi_resource_list" "sender_usernames" {
  type                   = "Microsoft.Communication/emailServices/domains/senderUsernames@2023-04-01-preview"
  parent_id              =    module.azure-communication-smtp.custom_domain_resource_id
  response_export_values = ["*"]
 depends_on = [module.azure-communication-smtp, null_resource.test_curl_azure_api, null_resource.sender_usernames_curl ]
}
