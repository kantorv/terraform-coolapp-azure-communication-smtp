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
  name                = "smtpproj-emailcommunicationservice"
  resource_group_name = azurerm_resource_group.default.name
  data_location       = "United States"
}





resource "azapi_resource" "custom_domain" {

  type      = "Microsoft.Communication/emailServices/domains@2023-04-01-preview"
  name      = var.custom_domain
  location  = "global"
  parent_id = azurerm_email_communication_service.example.id
  #   tags = {
  #     tagName1 = "tagValue1"
  #     tagName2 = "tagValue2"
  #   }
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

  wait_for_success_verification = var.dns_wait_for_success_verification
  az_cli_enabled = var.az_cli_enabled
  dns_verification_fail_silently = var.dns_verification_fail_silently
}


module "dmarc_record" {
  depends_on = [azapi_resource.custom_domain, module.domain_verification]
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
  wait_for_success_verification = var.dns_wait_for_success_verification
  dns_verification_fail_silently = var.dns_verification_fail_silently
  
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
  wait_for_success_verification = var.dns_wait_for_success_verification
  az_cli_enabled = var.az_cli_enabled
  dns_verification_fail_silently = var.dns_verification_fail_silently
}


resource "azurerm_communication_service" "example" {
  name                = "smtpproj-communicationservice"
  resource_group_name = azurerm_resource_group.default.name
  data_location       = "United States"
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

resource "azapi_resource" "sender_usernames" {

  # for_each   =  toset(var.sender_usernames)
  for_each = tomap({
    # for t in var.sender_usernames : "${t.username}" => t
     for t in [] : "${t.username}" => t
  })

  type      = "Microsoft.Communication/emailServices/domains/senderUsernames@2023-04-01-preview"
  name      = each.value.username
  parent_id = azapi_resource.custom_domain.id

  body = jsonencode({
    properties = {
      displayName = "${each.value.display_name}"
      username    = "${each.value.username}"
    }
  })

  response_export_values = ["*"]

  depends_on = [module.entra_app, azapi_update_resource.linked_domain]


}





resource "null_resource" "send_email" {
  count = length(var.smtp_test_email_resipient) > 0 ? 1 : 0


  triggers = {
    always_run = filemd5("${path.module}/scripts/send_email.py")
  }


  provisioner "local-exec" {
    command = <<-EOF
        python3 ${path.module}/scripts/send_email.py \
            -s ${var.smtp_server_host} \
            -f ${local.sender_usernames[0]}  \
            -r ${var.smtp_server_port} \
            -u '${data.azurerm_communication_service.smtp_app.name}|${module.entra_app.client_id}|${module.entra_app.tenant_id}' \
            -p '${module.entra_app.client_secret}' \
            -t ${var.smtp_test_email_resipient}
    EOF
  }

  depends_on = [azapi_resource.sender_usernames, module.spf_dkim_dkim2_verification]
}
