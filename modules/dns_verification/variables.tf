variable "cloudflare_zonid" {
  type = string
}

variable "record_types" {
  type = list(string)
  default = ["DKIM" ,  "DKIM2" ,  "Domain" ,  "SPF" ,"DMARC"]
}


variable "record_type" {
  type = string
  validation {
    condition     = contains( ["DKIM" ,  "DKIM2" ,  "Domain" ,  "SPF" ,"DMARC"], var.record_type)
    error_message = "Allowed values for input_parameter are \"DKIM\", \"DKIM2\", \"SPF\", or \"Domain\"."
  }
}

variable "name" {
  type = string
}
variable "type" {
  type = string
}
variable "ttl" {
  type = number
  default = 3600
}
variable "value" {
  type = string
}


variable "domain_id" {
   type = string
}

variable "initiate_verification" {
  type = bool
  default = false
}

variable "wait_for_success_verification" {
  type = bool
  default = false
}


variable "az_cli_enabled" {
  type = bool
  default = false
}


variable "dns_verification_fail_silently" {
  type = bool
  default = false
}