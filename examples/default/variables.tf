## service principal
variable "azure_client_id" {}
variable "azure_client_secret" {
  sensitive = true
}
variable "azure_subscription_id" {}
variable "azure_tenant_id" {}

variable "location" {
  default = "eastus2"
}

## cloudflare
variable "cloudflare_token" {

}

variable "cloudflare_zonid" {

}



variable "custom_domain" {
  type = string
}


variable "verification_records_keys" {
  type    = set(string)
  default = ["DKIM", "DKIM2", "Domain", "SPF"]
}


variable "sender_usernames" {
  description = "sender_usernames"
  type = list(object({
    username     = string
    displayName = string
  }))
  default = []
  #   validation {
  #     condition     = can(regex("^(Standard_DS3_v2|Standard_DS1_v2)$", var.virtual_machines[0].size))
  #     error_message = "Invalid input, options: \"Standard_DS3_v2\",\"Standard_DS1_v2\"."
  #   }
}


variable "users_to_create" {
  description = "users_to_create"
  type = list(object({
    username    = string
    displayName = string
  }))
  default = [
  
  ]
  #   validation {
  #     condition     = can(regex("^(Standard_DS3_v2|Standard_DS1_v2)$", var.virtual_machines[0].size))
  #     error_message = "Invalid input, options: \"Standard_DS3_v2\",\"Standard_DS1_v2\"."
  #   }
}


variable "smtp_test_email_resipient" {
  type    = string
  default = ""
}



variable "setup_dmarc_record" {
  type    = bool
  default = false
}

variable "dmarc_value" {
  type = string
}


variable "az_cli_enabled" {
  type    = bool
  default = false
}
