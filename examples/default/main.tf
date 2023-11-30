module "azure-communication-smtp" {
  source  = "kantorv/azure-communication-smtp/coolapp"
  version = "0.0.1"
  # insert the 10 required variables here

  azure_subscription_id = var.azure_subscription_id
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_tenant_id       = var.azure_tenant_id
  
  cloudflare_token = var.cloudflare_token
  cloudflare_zonid = var.cloudflare_zonid

  custom_domain = var.custom_domain
  
  smtp_server_host  = var.smtp_server_host
  smtp_server_port = var.smtp_server_port
  smtp_test_email_resipient = var.smtp_test_email_resipient
  sender_usernames = var.sender_usernames
  verification_records_keys = [ "DKIM", "DKIM2", "Domain", "SPF" ]

  dmarc_value = var.dmarc_value
  setup_dmarc_record = true

  az_cli_enabled = true

}