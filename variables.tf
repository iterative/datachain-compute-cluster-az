variable "az_subscription_id" {
  default = "00000000-0000-0000-0000-000000000000"
}

variable "az_location" {
  default = "East US"
}

variable "oidc_provider" {
  default = "studio.datachain.ai/api"
}

variable "oidc_condition_compute" {
  default = "credentials:example-team/datachain-compute"
}

variable "oidc_condition_storage" {
  default = "credentials:example-team/datachain-storage"
}

variable "storage_buckets" {
  default = {
    "example-resource-group" = "examplestorageaccount"
  }
}
