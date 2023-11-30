
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
   value = module.azure-communication-smtp.sender_usernames
}




output "custom_domain_id" {
 value = module.azure-communication-smtp.custom_domain_resource_id
}
