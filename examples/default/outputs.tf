
output "smtp_server_host" {
  value =  module.azure-communication-smtp.smtp_server_host
}

output "smtp_server_port" {
  value =  module.azure-communication-smtp.smtp_server_port
}



output "smtp_username" {
  value = module.azure-communication-smtp.smtp_username
}


output "smtp_password" {
  description = "Run for view: echo  $(terraform output -raw smtp_password)"
  value = module.azure-communication-smtp.smtp_password
  sensitive = true
}

# https://en.wikipedia.org/wiki/Email_address#Syntax
output "sender_usernames" {
   value = [for s in jsondecode(data.azapi_resource_list.sender_usernames.output).value: format("%s@%s",s.properties.username,var.custom_domain) ]
}

output "verification_states" {
   value = jsondecode(data.azapi_resource.custom_domain.output).properties.verificationStates 
}



# output "custom_domain_id" {
#  value = module.azure-communication-smtp.custom_domain_resource_id
# }


# output "custom_domain_data" {
#   value = jsondecode(data.azapi_resource.custom_domain.output).properties
# }