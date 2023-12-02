module "azure-communication-smtp" {
  source  = "kantorv/azure-communication-smtp/coolapp"
  version = "0.0.64"
  # insert the 10 required variables here

  azure_subscription_id = var.azure_subscription_id
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_tenant_id       = var.azure_tenant_id

  # cloudflare settings
  custom_domain = var.custom_domain
  cloudflare_token = var.cloudflare_token
  cloudflare_zonid = var.cloudflare_zonid

  smtp_server_host = "smtp.azurecomm.net"
  smtp_server_port = 587
  sender_usernames =  [
    {
        "username" : "team",
        "displayName": "Office Team"
    },
    {
        "username" : "gpt",
        "displayName": "Email Bot"
    },
    {
        "username" : "nnd",
        "displayName": "DMARC REPORTS"
    },
    {
        "username" : "ddg",
        "displayName": "g REPORTS"
    },    {
        "username" : "bbp",
        "displayName": "p REPORTS"
    }

  ]
  verification_records_keys = [ "DKIM", "DKIM2", "Domain", "SPF" ]

  dmarc_value = var.dmarc_value
  setup_dmarc_record = true

  az_cli_enabled = true

  entra_app_display_name = "smtp_app"
  dns_wait_for_success_verification = true
  dns_verification_fail_silently = false
  dns_verification_max_retries = 10
  dns_verification_retry_timeout = 60

  communication_service_name = "smtpproj-communication-service"
  email_communication_service_name = "smtpproj-email-communication-service"
  communication_service_data_location = "United States"


}


# resource "azapi_resource" "sender_usernames" {

#   # for_each   =  toset(var.sender_usernames)
#   # for_each = tomap({
#   #   # for t in var.sender_usernames : "${t.username}" => t
#   #    for t in [
#   #     {
#   #         "username" : "info",
#   #         "display_name": "Office Team"
#   #     },
#   #     {
#   #         "username" : "llama",
#   #         "display_name": "Email Bot"
#   #     },
#   #     {
#   #         "username" : "d",
#   #         "display_name": "DMARC REPORTS"
#   #     }

#   #   ] : "${t.username}" => t
#   # })
#   count = 0
#   type      = "Microsoft.Communication/emailServices/domains/senderUsernames@2023-04-01-preview"
#   name      = "user${count.index}"
#   parent_id = module.azure-communication-smtp.custom_domain_resource_id

#   body = jsonencode({
#     properties = {
#       displayName = "Test User${count.index}"
#       username    = "user${count.index}"
#     }
#   })

#   response_export_values = ["*"]

#   depends_on = [module.azure-communication-smtp]


# }








# resource "null_resource" "test_curl_azure_api" {
#   # count = var.wait_for_success_verification?1:0
#   # Define any dependencies or triggers that determine when this resource should run
#   count = 0
#   depends_on = [module.azure-communication-smtp]

#   triggers = {
#     always_run = timestamp()
#   }

#   # Use the local-exec provisioner to run an inline Bash script
#   provisioner "local-exec" {



#     command = <<-EOF
#       #!/bin/bash
#       resp=$(
#         curl -X POST -d 'grant_type=client_credentials&client_id=${var.azure_client_id}&client_secret=${var.azure_client_secret}&resource=https%3A%2F%2Fmanagement.azure.com%2F' https://login.microsoftonline.com/${var.azure_tenant_id}/oauth2/token
#       ) 

#       access_token=$(echo $resp | jq -r ".access_token")

#       username=""
#       sleep 2

#       query=$(
#         curl -X PUT -H "Authorization: Bearer $access_token" -H "Content-Type:application/json" -d '{"properties":{"username": "hello${count.index}","displayName": "Hello${count.index} Alerts"}}' 'https://management.azure.com${module.azure-communication-smtp.custom_domain_resource_id}/senderUsernames/hello${count.index}?api-version=2023-03-31'
#       )

#       sleep 2

#       check=$(
#         curl -X GET -H "Authorization: Bearer $access_token" -H "Content-Type:application/json"  'https://management.azure.com${module.azure-communication-smtp.custom_domain_resource_id}/senderUsernames/hello${count.index}?api-version=2023-03-31'
#       )
#       echo  "----------------${count.index}------------------" >> hello.txt
#       echo $query >> hello.txt
#       echo $check >> hello.txt


#       max_retries=10
#       retry_interval=30


#       exit 0
#     EOF
#   }
# }




resource "null_resource" "sender_usernames_curl" {
  # count = var.wait_for_success_verification?1:0
  # Define any dependencies or triggers that determine when this resource should run
  #count = 0
  depends_on = [module.azure-communication-smtp]

  triggers = {
    always_run = timestamp()
  }

  # Use the local-exec provisioner to run an inline Bash script
  provisioner "local-exec" {

    command = <<-EOF
      #!/bin/bash
      azure_subscription_id="${var.azure_subscription_id}"
      azure_tenant_id="${var.azure_tenant_id}"
      azure_client_id="${var.azure_client_id}"
      azure_client_secret="${var.azure_client_secret}"
      custom_domain_resource_id="${module.azure-communication-smtp.custom_domain_resource_id}"
      #users_to_create='${jsonencode(var.users_to_create)}'
      users_to_create='${var.users_to_create}'

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





      for i in $(echo $users_to_create  | jq -r '.[] | @base64');
      do
          var=$(echo $i | base64 --decode)
          username=$(echo $var | jq -r '.username')
          displayName=$(echo $var | jq -r '.displayName')
          echo "Creating: $displayName<$username@example.org>"


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



      to_be_created_count=$(echo $users_to_create | jq -c '.[]' | wc -l)
      found_count=$(echo $just_added  |   jq -c '.[]' | wc -l)

      if [ "$found_count" -eq "$to_be_created_count" ]; then
          echo "All users created" 
          exit 0 
      fi

      echo "Some users not created" 
      exit 1
    EOF
  }
}





resource "null_resource" "send_email" {
  count = length(var.smtp_test_email_resipient) > 0 ? 1 : 0
  provisioner "local-exec" {
    command = <<-EOF
        python3 ${path.module}/scripts/send_email.py \
            -s "${module.azure-communication-smtp.smtp_server_host}" \
            -r ${module.azure-communication-smtp.smtp_server_port} \
            -u "${module.azure-communication-smtp.smtp_username}" \
            -p "${module.azure-communication-smtp.smtp_password}" \
            -f "donotreply@${var.custom_domain}"  \
            -t "${var.smtp_test_email_resipient}"
    EOF
  }

  depends_on = [null_resource.sender_usernames_curl]
}


