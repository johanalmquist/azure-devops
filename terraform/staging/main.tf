#####################################
# SET UP TERRAFORM PROVIDERS TO USE #
#####################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.24.0" # Telling terraform to use the exat version 3.24.0 of AzureRM
    }
    http = {
      source  = "hashicorp/http"
      version = "3.3.0"
    }

  }
  backend "azurerm" {
    resource_group_name  = "ara-terraform"
    storage_account_name = "araterraform"
    container_name       = "services-tfstate"
    key                  = "johan-testing-staging.tfstate"
  }
}
provider "azurerm" {}

data "http" "example" {
  url = "https://checkpoint-api.hashicorp.com/v1/check/terraform"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

output "latest_version" {
  value = jsondecode(data.http.example.response_body)
}

output "respone_coded" {
  value = data.http.example.status_code
}
