resource "azuread_application" "datachain_oidc_compute" {
  display_name = "datachain-oidc-compute"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application" "datachain_oidc_storage" {
  display_name = "datachain-oidc-storage"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "datachain_oidc_compute" {
  application_id = azuread_application.datachain_oidc_compute.id
}

resource "azuread_application_password" "datachain_oidc_storage" {
  application_id = azuread_application.datachain_oidc_storage.id
}