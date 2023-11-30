module "azure-communication-smtp" {
  source  = "kantorv/azure-communication-smtp/coolapp"
  version = "0.0.3"
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
  smtp_test_email_resipient = var.smtp_test_email_resipient
  sender_usernames = ["info","support","hr","llama"]
  verification_records_keys = [ "DKIM", "DKIM2", "Domain", "SPF" ]

  dmarc_value = var.dmarc_value
  setup_dmarc_record = false

  az_cli_enabled = true

  entra_app_display_name = "smtp-app-dev"
  dns_wait_for_success_verification = false
  dns_verification_fail_silently = true


}