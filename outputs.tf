output "domain" {
  value = var.custom_domain
}

output "smtp_server_host" {
  value = var.smtp_server_host
}

output "smtp_server_port" {
  value = var.smtp_server_port
}



output "smtp_username" {
  value = "${data.azurerm_communication_service.smtp_app.name}|${module.entra_app.client_id}|${ module.entra_app.tenant_id}"
}


output "smtp_password" {
  description = "Run for view: echo  $(terraform output -raw smtp_password)"
  value = module.entra_app.client_secret
  sensitive = true
}

# https://en.wikipedia.org/wiki/Email_address#Syntax
output "sender_usernames" {
   value = [for s in jsondecode(data.azapi_resource_list.sender_usernames.output).value: format("%s<%s@%s>",s.properties.displayName, s.properties.username,"${var.custom_domain}") ]
}

output "verification_records" {
  value = jsondecode(data.azapi_resource.custom_domain.output).properties.verificationRecords
}

output "custom_domain_id" {
  value = azapi_resource.custom_domain.id
}