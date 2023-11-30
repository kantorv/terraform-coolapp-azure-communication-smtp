locals {
  verification_records = jsondecode(data.azapi_resource.custom_domain.output).properties.verificationRecords 
  sender_usernames = [for s in jsondecode(data.azapi_resource_list.sender_usernames.output).value: format("%s@%s",s.properties.username,"${var.custom_domain}") ]
}
