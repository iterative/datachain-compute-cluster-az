output "static_credential_compute_azure_subscription_id" {
  value = basename(data.azurerm_subscription.current.id)
}

output "static_credential_compute_azure_tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
}

output "static_credential_compute_azure_client_id" {
  value = azuread_application.datachain_oidc_compute.client_id
}

output "static_credential_compute_azure_client_secret" {
  value     = azuread_application_password.datachain_oidc_compute.value
  sensitive = true
}