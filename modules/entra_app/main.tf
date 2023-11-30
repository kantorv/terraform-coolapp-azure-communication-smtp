

resource "azurerm_role_definition" "smtp_server_role" {
  name        = "ACS Email Write"
  scope       = var.scope
  description = "This is a custom role created via Terraform"

  permissions {
    actions = [
      "Microsoft.Communication/EmailServices/write",
      "Microsoft.Communication/CommunicationServices/Read",
    ]

    not_actions      = []
    data_actions     = []
    not_data_actions = []
  }

  assignable_scopes = [
    var.scope, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]


  #depends_on = [ azapi_resource.sender_usernames, azapi_update_resource.linked_domain ]
}
resource "azuread_application" "stmp_app" {
  display_name = var.display_name
  owners       = [data.azuread_client_config.current.object_id]
  #depends_on = [ azapi_resource.sender_usernames, azapi_update_resource.linked_domain ]
}

resource "azuread_service_principal" "stmp_app" {
  client_id                    = azuread_application.stmp_app.client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]

  #depends_on = [ azuread_application.stmp_app ]
}

resource "azuread_application_password" "stmp_app" {
  application_id = azuread_application.stmp_app.id
}


resource "azurerm_role_assignment" "stmp_app" {
  scope              = var.scope
  role_definition_id = azurerm_role_definition.smtp_server_role.role_definition_resource_id
  principal_id       = azuread_service_principal.stmp_app.object_id



}

