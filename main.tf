terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.28.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.3.0"
    }
  }

  required_version = ">= 1.11.0"
}

provider "azuread" {}

provider "azurerm" {
  subscription_id = var.az_subscription_id
  features {}
}

data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azurerm_storage_account" "datachain_oidc_storage" {
  for_each = var.storage_buckets

  resource_group_name = each.key
  name                = each.value
}

resource "azurerm_resource_group" "datachain" {
  name     = "datachain"
  location = var.az_location
}

# resource "azuread_application" "datachain_oidc_compute" {
#   display_name = "datachain-oidc-compute"
#
#   api {
#     requested_access_token_version = 2
#   }
# }

# resource "azuread_application" "datachain_oidc_storage" {
#   display_name = "datachain-oidc-storage"
#
#   api {
#     requested_access_token_version = 2
#   }
# }

resource "azuread_service_principal" "datachain_oidc_compute" {
  client_id = azuread_application.datachain_oidc_compute.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "datachain_oidc_storage" {
  client_id = azuread_application.datachain_oidc_storage.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_federated_identity_credential" "datachain_oidc_compute" {
  application_id = azuread_application.datachain_oidc_compute.id
  display_name   = azuread_application.datachain_oidc_compute.display_name
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://${var.oidc_provider}"
  subject        = var.oidc_condition_compute
}

resource "azuread_application_federated_identity_credential" "datachain_oidc_storage" {
  application_id = azuread_application.datachain_oidc_storage.id
  display_name   = azuread_application.datachain_oidc_storage.display_name
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://${var.oidc_provider}"
  subject        = var.oidc_condition_compute
}

resource "azurerm_role_definition" "datachain_oidc_compute" {
    name  = azuread_application.datachain_oidc_compute.display_name
    scope = azurerm_resource_group.datachain.id

    permissions {
        actions = [
            "Microsoft.ContainerService/managedClusters/*",
            "Microsoft.Network/virtualNetworks/read",
            "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
            "Microsoft.ManagedIdentity/userAssignedIdentities/read",
        ]
    }
}

resource "azurerm_role_definition" "datachain_oidc_storage" {
  name  = azuread_application.datachain_oidc_storage.display_name
  scope = data.azurerm_subscription.current.id

    permissions {
        actions = [
            "Microsoft.Storage/storageAccounts/read",
            "Microsoft.Storage/storageAccounts/write",
            "Microsoft.Storage/storageAccounts/delete",
            "Microsoft.Storage/storageAccounts/listKeys/action",
            "Microsoft.Storage/storageAccounts/blobServices/containers/read",
            "Microsoft.Storage/storageAccounts/blobServices/containers/write",
            "Microsoft.Storage/storageAccounts/blobServices/containers/delete",
        ]
        not_actions = []
    }

  assignable_scopes = [
    for storage_account in data.azurerm_storage_account.datachain_oidc_storage :
    storage_account.id
  ]
}

resource "azurerm_role_assignment" "datachain_oidc_compute" {
  name               = azurerm_role_definition.datachain_oidc_compute.role_definition_id
  scope              = azurerm_resource_group.datachain.id
  role_definition_id = azurerm_role_definition.datachain_oidc_compute.role_definition_resource_id
  principal_id       = azuread_service_principal.datachain_oidc_compute.object_id
}

resource "azurerm_role_assignment" "oidc_storage_assignments" {
  for_each = { 
    for storage_account in data.azurerm_storage_account.datachain_oidc_storage :
    storage_account.name => storage_account.id
  }

  scope              = each.value
  role_definition_id = azurerm_role_definition.datachain_oidc_storage.role_definition_resource_id
  principal_id       = azuread_service_principal.datachain_oidc_storage.object_id
}
