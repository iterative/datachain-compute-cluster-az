# Supporting infrastructure for DataChain Compute Clusters on Azure

This repository contains the supporting infrastructure (OIDC, roles, resource group, etc.) needed to grant DataChain Studio enough permissions to manage compute clusters on Azure, and for those clusters to access the designated storage accounts.

## Setup

1. Update `variables.tf` with values specific to your deployment.
1. [Install Terraform](https://developer.hashicorp.com/terraform/install)
1. Run `terraform init`
1. Run `terraform apply`
1. Run `terraform output` and copy the output values

## Overview

### 1. **Resource Group**
- **`azurerm_resource_group.datachain`**: Central resource group to organize and manage all related compute and storage resources for the DataChain Compute Clusters.

### 2. **Identity and Access Management (IAM)**
- **Azure AD Applications**:
  - `datachain_oidc_compute`: Represents the identity used by DataChain Studio to provision and manage compute resources.
  - `datachain_oidc_storage`: Represents the identity used by DataChain Studio to access storage resources.
- **Service Principals**:
  - Created for both OIDC applications above, allowing authentication and role assignment.
- **Federated Identity Credentials**:
  - Define OIDC-based trust between DataChain Studio and Azure AD applications, using a specific issuer and subject claim.

### 3. **Role Definitions and Assignments**
- **Custom Role: Compute (`azurerm_role_definition.datachain_oidc_compute`)**:
  - Grants permissions to manage AKS clusters and assign managed identities within the resource group.
  - Assigned to the `datachain_oidc_compute` service principal on the resource group scope.
- **Custom Role: Storage (`azurerm_role_definition.datachain_oidc_storage`)**:
  - Grants permissions to read/write/delete storage accounts and containers.
  - Assigned to the `datachain_oidc_storage` service principal on each authorized storage account.

### 4. **Storage Accounts**
- **`azurerm_storage_account.datachain_oidc_storage`**:
  - Retrieves information from the storage accounts that DataChain jobs should have access to.

## Security Considerations

1. **Least Privilege Access**: Custom role definitions limit actions to only those required for compute and storage operations.

2. **OIDC-based Federation**: Federated identity credentials eliminate the need for long-lived secrets, enabling secure and auditable access from DataChain Studio.

3. **Scoped Role Assignments**: Storage permissions are granted only to explicitly defined accounts. Compute permissions are limited to a single resource group.

4. **AKS Resource Group Boundaries**: Permissions for the compute role are restricted to a single Resource Group, under which the AKS Compute clusters are created. AKS will automatically create additional resource groups prefixed with `MC_` to host internal infrastructure like virtual networks and managed node pools.

## Variables

| Name                     | Description                                          | Example                                                    |
|--------------------------|------------------------------------------------------|------------------------------------------------------------|
| `az_subscription_id`     | Azure subscription ID                                | `"00000000-0000-0000-0000-000000000000"`                   |
| `az_location`            | Azure region where resources will be deployed        | `"East US"`                                                |
| `oidc_provider`          | OIDC issuer URL (used in federated identity)         | `"studio.datachain.ai/api"`                                |
| `oidc_condition_compute` | OIDC subject string for compute role                 | `"credentials:example-team/datachain-compute"`             |
| `oidc_condition_storage` | OIDC subject string for storage role                 | `"credentials:example-team/datachain-storage"`             |
| `storage_buckets`        | Map of resource group names to storage account names | `{ "example-resource-group" = "examplestorageaccount" }`   |
| `secret_stores`          | Map of resource group names to Key Vault names       | `{ "example-resource-group" = "example-key-vault" }`       |

## Outputs

| Name                                      | Description                                                    |
|-------------------------------------------|----------------------------------------------------------------|
| `datachain_compute_azure_subscription_id` | Subscription ID used for compute                               |
| `datachain_compute_azure_tenant_id`       | Azure tenant ID for compute resources                          |
| `datachain_compute_azure_client_id`       | Client ID of the compute Azure AD application                  |
| `datachain_storage_azure_subscription_id` | Subscription ID used for storage                               |
| `datachain_storage_azure_tenant_id`       | Azure tenant ID for storage resources                          |
| `datachain_storage_azure_client_id`       | Client ID of the storage Azure AD application                  |
| `datachain_compute_resource_group`        | Name of the resource group used for AKS and compute            |

## Architecture

![architecture](diagram.jpg)

DataChain Studio is split into 2 main components:

- Control Plane — typically hosted by us as a fully managed service
- Compute & Data Plane — typically hosted on your cloud accounts

Compute resources will be provisioned through managed Kubernetes clusters we automatically deploy on your account, using the permissions described in this repository.

## Guidance

### Granting Access to Azure Storage Accounts in DataChain Studio Jobs

Update the `storage_buckets` map in `variables.tf` with the resource groups and storage account names DataChain Studio Jobs should have access to, and run `terraform apply`.

### Granting Access to Azure Key Vault Secrets in DataChain Studio Jobs

You can securely inject sensitive configuration (such as tokens, passwords, or private URLs) into your compute jobs by referencing Azure Key Vault secrets through environment variables. This avoids hardcoding credentials and allows fine-grained secret management.

1. **Create a Secret in Azure Key Vault**

   Store your secret value under a named key in an existing Key Vault.

2. **Grant Access to the Key Vault through Terraform**

   Update the `secret_stores` map in `variables.tf` with the resource group and name of the Key Vault, and run `terraform apply`. This grants the storage service principal the `Key Vault Secrets User` role on the vault.

3. **Set an Environment Variable in the Studio Job Settings**

   In DataChain Studio, configure your job with an environment variable that references the secret using the `azsecret://` syntax:

   ```
   EXAMPLE_SECRET=azsecret://example-key-vault.vault.azure.net/secrets/example-secret#EXAMPLE_SECRET
   ```

   - Replace `example-key-vault.vault.azure.net` with the hostname of your Key Vault.
   - Replace `example-secret` with the name of the secret inside the vault.
   - The part after the `#` (e.g., `#EXAMPLE_SECRET`) refers to the key in your JSON secret payload (omit it if the secret is a plain string).
