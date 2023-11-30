module "azure-communication-smtp" {
  source  = "kantorv/azure-communication-smtp/coolapp"
  version = "0.0.5"
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
        "username" : "info",
        "display_name": "Office Team"
    },
    {
        "username" : "llama",
        "display_name": "Email Bot"
    },
    {
        "username" : "d",
        "display_name": "DMARC REPORTS"
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




}


resource "azapi_resource" "sender_usernames" {
  for_each = tomap({
     # for t in var.sender_usernames : "${t.username}" => t
     for t in  [
        {
            "username" : "gpt",
            "display_name": "Email Bot"
        },
        {
            "username" : "sales",
            "display_name": "Sales Team"
        },
        # {
        #     "username" : "support",
        #     "display_name": "Support Team"
        # },
        # {
        #     "username" : "it",
        #     "display_name": "IT Support Team"
        # },
        # {
        #     "username" : "hr",
        #     "display_name": "HR Team"
        # }
    ]  : "${t.username}" => t
  })

  type      = "Microsoft.Communication/emailServices/domains/senderUsernames@2023-04-01-preview"
  name      = each.value.username
  parent_id = module.azure-communication-smtp.custom_domain_id

  body = jsonencode({
    properties = {
      displayName = "${each.value.display_name}"
      username    = "${each.value.username}"
    }
  })

  response_export_values = ["*"]

  depends_on = [module.azure-communication-smtp]


}



resource "null_resource" "send_email" {
  count = length(var.smtp_test_email_resipient) > 0 ? 1 : 0



  provisioner "local-exec" {
    command = <<-EOF
        python3 ${path.module}/scripts/send_email.py \
            -s ${module.azure-communication-smtp.smtp_server_host} \
            -f ${module.azure-communication-smtp.sender_usernames[0]}  \
            -r ${module.azure-communication-smtp.smtp_server_port} \
            -u ${module.azure-communication-smtp.smtp_username} \
            -p ${module.azure-communication-smtp.smtp_password}' \
            -t ${var.smtp_test_email_resipient}
    EOF
  }

  depends_on = [module.azure-communication-smtp]
}
