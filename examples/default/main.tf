module "azure-communication-smtp" {
  source  = "kantorv/azure-communication-smtp/coolapp"
  version = "0.0.6"
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

  depends_on = [module.azure-communication-smtp]
}
