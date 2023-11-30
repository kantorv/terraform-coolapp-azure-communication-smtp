output "client_secret" {
  value = azuread_application_password.stmp_app.value
  sensitive = true
}

output "tenant_id" {
  value = azuread_service_principal.stmp_app.application_tenant_id
}

output "client_id" {
  value = azuread_service_principal.stmp_app.client_id
}