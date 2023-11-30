resource "cloudflare_record" "default" {
  provider = cloudflare
  #for_each        = local.verification_records
  allow_overwrite = true
  zone_id         = var.cloudflare_zonid
  name            = var.name
  value           = var.value
  type            = var.type
  ttl             = var.ttl
  proxied         = false
  comment         = "terraform automation"
}



resource "azapi_resource_action" "initiate_verification" {
  count = var.initiate_verification?1:0

  type                   = "Microsoft.Communication/emailServices/domains@2023-04-01-preview"
  resource_id            = var.domain_id
  action                 = "initiateVerification"
  response_export_values = ["*"]

  body = jsonencode({
    verificationType = var.record_type
  })


  depends_on = [cloudflare_record.default]

}



resource "null_resource" "dns_verification_status" {
  # count = var.wait_for_success_verification?1:0
  # Define any dependencies or triggers that determine when this resource should run
  depends_on = [azapi_resource_action.initiate_verification]

  # Use the local-exec provisioner to run an inline Bash script
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash

      if [ "${var.wait_for_success_verification?1:0}" -eq 0 ]; then
          echo "${var.record_type} Verification skipped!"
          exit 0 
      fi

      if [ "${var.az_cli_enabled?1:0}" -eq 0 ]; then
          echo "${var.record_type} az cli disabled!" 
          exit 0 
      fi

  
      max_retries=20
      retry_interval=30

      # Implement a for loop to wait for the API to become available
      i=0
      while [ $i -lt $max_retries ]; do
        response=$(
                az resource show --ids ${var.domain_id} \
                    --query "properties.verificationStates.{${var.record_type} : ${var.record_type}} | length(values(@) | [?status != 'Verified'])"
        )
        if [ "$response" -eq 0 ]; then
            echo "${var.record_type} Verification finished!"
            exit 0 
        fi
 

        # If the API is not accessible, wait for a few seconds before retrying
        echo "Verification in progress [${var.record_type}]. Retrying in $retry_interval seconds (attempt $((i+1))/$max_retries)."
        sleep $retry_interval

        # Increment the loop counter
        i=$((i+1))
      done

      # If the loop completes without success, exit with an error
      echo "Timeout reached. Unable to check verification status."
      exit ${var.dns_verification_fail_silently?0:1}
    EOF
  }
}

