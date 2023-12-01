resource "random_string" "random_suffix" {
  length  = 5
  special = false
  upper   = false
}




resource "azurerm_resource_group" "default" {
  name     = "smtpproj-rg-${random_string.random_suffix.result}"
  location = var.location

  tags = {
    #environment = var.environment
  }
}




resource "azurerm_email_communication_service" "example" {
  name                = var.email_communication_service_name
  resource_group_name = azurerm_resource_group.default.name
  data_location       = var.communication_service_data_location
}





resource "azapi_resource" "custom_domain" {

  type      = "Microsoft.Communication/emailServices/domains@2023-04-01-preview"
  name      = var.custom_domain
  location  = "global"
  parent_id = azurerm_email_communication_service.example.id

  body = jsonencode({
    properties = {
      domainManagement       = "CustomerManaged"
      userEngagementTracking = "Enabled"
    }
  })

  response_export_values = ["*"]
  depends_on = [ azurerm_email_communication_service.example ]
}



module "domain_verification" {

  depends_on = [azapi_resource.custom_domain]

  source = "./modules/dns_verification"
  domain_id = azapi_resource.custom_domain.id
  cloudflare_zonid         = var.cloudflare_zonid
  name            = local.verification_records.Domain.name
  value           = local.verification_records.Domain.value
  type            = local.verification_records.Domain.type
  ttl             = 3600
  record_type = "Domain"
  initiate_verification = true
  az_cli_enabled = var.az_cli_enabled

  wait_for_success_verification = var.dns_wait_for_success_verification
  dns_verification_fail_silently = var.dns_verification_fail_silently
  dns_verification_max_retries = var.dns_verification_max_retries
  dns_verification_retry_timeout = var.dns_verification_retry_timeout
}


module "dmarc_record" {
  depends_on = [azapi_resource.custom_domain]
 #   depends_on = [cloudflare_record.verification]
  count = var.setup_dmarc_record?1:0

  source = "./modules/dns_verification"
  domain_id = azapi_resource.custom_domain.id
  cloudflare_zonid         = var.cloudflare_zonid
  name            = "_dmarc.${var.custom_domain}"
  value           = var.dmarc_value
  type            = "TXT"
  ttl             = 3600
  record_type = "DMARC"
  initiate_verification = false
  wait_for_success_verification = false
}


module "spf_dkim_dkim2_verification" {
  depends_on = [module.domain_verification, module.dmarc_record]
 #   depends_on = [cloudflare_record.verification]
  for_each        = { for key in toset([ "DKIM" ,  "DKIM2" ,  "SPF"  ]): key => local.verification_records[key] }

  source = "./modules/dns_verification"
  domain_id = azapi_resource.custom_domain.id
  cloudflare_zonid         = var.cloudflare_zonid
  name            = each.value.name
  value           = each.value.value
  type            = each.value.type
  ttl             = each.value.ttl
  record_type = each.key
  initiate_verification = true
  az_cli_enabled = var.az_cli_enabled

  wait_for_success_verification = var.dns_wait_for_success_verification
  dns_verification_fail_silently = var.dns_verification_fail_silently
  dns_verification_max_retries = var.dns_verification_max_retries
  dns_verification_retry_timeout = var.dns_verification_retry_timeout
}


resource "azurerm_communication_service" "example" {
  name                = var.communication_service_name
  resource_group_name = azurerm_resource_group.default.name
  data_location       = var.communication_service_data_location
  depends_on = [ azapi_resource.custom_domain ]
}



module "entra_app" {
  source = "./modules/entra_app"
  scope = azurerm_communication_service.example.id
  display_name = var.entra_app_display_name
  depends_on = [ azurerm_communication_service.example ]
}






resource "azapi_update_resource" "linked_domain" {
  depends_on = [ module.domain_verification, module.spf_dkim_dkim2_verification ]
  #count = 0  
  type        = "Microsoft.Communication/communicationServices@2023-04-01-preview"
  resource_id = azurerm_communication_service.example.id
  # parent_id = azurerm_resource_group.default.id
  body = jsonencode({
    properties = {
      linkedDomains = [
        "${azapi_resource.custom_domain.id}"
      ]
    }
  })
  response_export_values = ["*"]


  timeouts {
    create = "10m"
    delete = "15m"
    read   = "5m"
  }

}

# resource "azapi_resource" "sender_usernames" {

#   # for_each   =  toset(var.sender_usernames)
#   for_each = tomap({
#     # for t in var.sender_usernames : "${t.username}" => t
#      for t in [] : "${t.username}" => t
#   })

#   type      = "Microsoft.Communication/emailServices/domains/senderUsernames@2023-04-01-preview"
#   name      = each.value.username
#   parent_id = azapi_resource.custom_domain.id

#   body = jsonencode({
#     properties = {
#       displayName = "${each.value.display_name}"
#       username    = "${each.value.username}"
#     }
#   })

#   response_export_values = ["*"]

#   depends_on = [module.entra_app, azapi_update_resource.linked_domain]


# }







resource "null_resource" "sender_usernames" {
  depends_on = [module.entra_app, azapi_update_resource.linked_domain]


  # Use the local-exec provisioner to run an inline Bash script
  provisioner "local-exec" {

    command = <<-EOF
      #!/bin/bash
      azure_subscription_id="${var.azure_subscription_id}"
      azure_tenant_id="${var.azure_tenant_id}"
      azure_client_id="${var.azure_client_id}"
      azure_client_secret="${var.azure_client_secret}"
      custom_domain_resource_id="${ azapi_resource.custom_domain.id}"


      access_token_resp=$(
          curl -s  -X POST \
              -d "grant_type=client_credentials\
                  &client_id=$azure_client_id\
                  &client_secret=$azure_client_secret\
                  &resource=https%3A%2F%2Fmanagement.azure.com%2F" \
              https://login.microsoftonline.com/$azure_tenant_id/oauth2/token
      ) 

      access_token=$(echo $access_token_resp | jq -r ".access_token")

      sender_usernames_endpoint="https://management.azure.com$custom_domain_resource_id/senderUsernames"
      api_version="2023-03-31"


      users_to_create='${var.sender_usernames}'



      for i in $(echo $users_to_create  | jq -r '.[] | @base64');
      do
          var=$(echo $i | base64 --decode)
          username=$(echo $var | jq -r '.username')
          displayName=$(echo $var | jq -r '.displayName')
          #echo "Creating: $displayName<$username@example.org>"

          url="$sender_usernames_endpoint/$username?api-version=$api_version"
          api_resp=$(
              curl -s -X PUT \
              -H "Authorization: Bearer $access_token" \
              -H "Content-Type:application/json" \
              -d "{\"properties\":{\"username\": \"$username\",\"displayName\": \"$displayName\"}}" \
              $url
          )
          # exit_code=$?
          # echo $username
          # echo $api_resp
          # echo $exit_code
          # echo 
          
      done


      url="$sender_usernames_endpoint?api-version=$api_version"

      get_users_api_resp=$(
          curl -s -v -X GET \
          -H "Authorization: Bearer $access_token" \
          -H "Content-Type:application/json"  \
          $url
      )



      existing_users=$( echo $get_users_api_resp | jq '[.value[].properties]' ) 
      #echo $existing_users  
      just_added=$(
          echo $existing_users  | jq |   \
          jq --argjson new_users "$users_to_create"  '{"created":[$new_users[].username],"received": . }' | \
          jq   '[.created as $users_list | .received[] | select( .username as $username | $users_list | index($username))]'
      )

      # echo $users_to_create   |   jq -c '.[]' 
      # echo "*****************"
      # echo $just_added   |   jq -c '.[]' 


      to_be_created_count=$(echo $users_to_create | jq -c '.[]' | wc -l)
      found_count=$(echo $just_added  |   jq -c '.[]' | wc -l)

      # echo "FOUND COUNT: $found_count"
      # echo "USERS TO BE CREATED COUNT: $to_be_created_count"


      if [ "$found_count" -eq "$to_be_created_count" ]; then
          echo "All users created" 
          exit 0 
      fi

      echo "Some users not created" 
      exit 1
    EOF
  }
}




