output "datachain_compute_azure_subscription_id" {
  value = basename(data.azurerm_subscription.current.id)
}

output "datachain_compute_azure_tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
}

output "datachain_compute_azure_client_id" {
  value = azuread_application.datachain_oidc_compute.client_id
}

output "datachain_storage_azure_subscription_id" {
  value = basename(data.azurerm_subscription.current.id)
}

output "datachain_storage_azure_tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
}

output "datachain_storage_azure_client_id" {
  value = azuread_application.datachain_oidc_storage.client_id
}


output "datachain_compute_resource_group" {
  value = azurerm_resource_group.datachain.name
}
