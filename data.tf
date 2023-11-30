data "azurerm_communication_service" "smtp_app" {
  name                = azurerm_communication_service.example.name
  resource_group_name = azurerm_resource_group.default.name
  depends_on = [ azurerm_communication_service.example ]
}



data "azapi_resource" "custom_domain" {
  type      = "Microsoft.Communication/emailServices/domains@2023-04-01-preview"
  name      = var.custom_domain
  parent_id = azurerm_email_communication_service.example.id
  response_export_values = ["properties.verificationRecords"]
depends_on = [ azurerm_email_communication_service.example, azapi_resource.custom_domain ]
}


# data "local_file" "verification_status" {
#     filename = "${path.module}/dns_verification_status.json"
#   depends_on = [null_resource.dns_verification_status]
# }


# data "external" "azurerm_communication_service_info" {
#   program = ["echo", "${azurerm_email_communication_service.example.id}"]  # Replace with a script or command to get the needed information
#   depends_on = [ azurerm_communication_service.example ]
# }

# data "azurerm_subscription" "primary" {
# }

# data "azuread_client_config" "current" {}


# data "azurerm_role_definition" "smtp_server_role" {
#   role_definition_id = azurerm_role_definition.smtp_server_role.role_definition_id
#   scope              = azurerm_role_definition.smtp_server_role.scope # /subscriptions/00000000-0000-0000-0000-000000000000
# }


# data "azapi_resource" "sender_usernames" {
#   name = "info"
#   parent_id =  azapi_resource.custom_domain.id
#   type      =  "Microsoft.Communication/emailServices/domains/senderUsernames@2023-04-01-preview"

#   response_export_values = ["*"]
#   depends_on = [ azapi_resource.sender_usernames ]

# }



data "azapi_resource_list" "sender_usernames" {
  type                   = "Microsoft.Communication/emailServices/domains/senderUsernames@2023-04-01-preview"
  parent_id              =   azapi_resource.custom_domain.id
  response_export_values = ["*"]
  depends_on = [ azapi_resource.sender_usernames ]
}


# data "external" "send_email" {
#   program = ["python3", "scripts/send_email2.py","-h"]
#   depends_on = [ azuread_application_password.stmp_app, azapi_resource.sender_usernames, azapi_resource_action.initiate_verification ]
# }