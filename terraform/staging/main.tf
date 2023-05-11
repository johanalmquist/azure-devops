#####################################
# SET UP TERRAFORM PROVIDERS TO USE #
#####################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.24.0" # Telling terraform to use the exat version 3.24.0 of AzureRM
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.17.1"
    }
  }
  backend "azurerm" {
    resource_group_name  = "ara-terraform"
    storage_account_name = "araterraform"
    container_name       = "services-tfstate"
    key                  = "${SERVICE_NAME}-${ENVIRONMENT}.tfstate"
  }
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

#####################
# COMMON AZURE DATA ##
#####################

data "azurerm_client_config" "current" {}


data "azurerm_resource_group" "ara-managed-services" {
  name = "ara-managed-services-${var.ENVIRONMENT}"
}

data "azurerm_key_vault" "aranya-kv" {
  name                = "aranya-ms-kv-01-${var.ENVIRONMENT}"
  resource_group_name = data.azurerm_resource_group.ara-managed-services.name
}

###############################
# POSTGRESQL FLEXIBLE SERVERS #
###############################

# Get root password to postgresql server
data "azurerm_key_vault_secret" "postgresql_password" {
  name         = "psql-flex-staging-aranya-password"
  key_vault_id = data.azurerm_key_vault.aranya-kv.id
}

data "azurerm_postgresql_flexible_server" "postgresql" {
  name                = "ara-managed-services-psql-${var.ENVIRONMENT}"
  resource_group_name = data.azurerm_resource_group.ara-managed-services.name
}

#Setup postgresql provider
provider "postgresql" {
  host            = data.azurerm_postgresql_flexible_server.postgresql.fqdn
  port            = 5432
  database        = "postgres" # system databse
  username        = data.azurerm_postgresql_flexible_server.postgresql.administrator_login
  password        = data.azurerm_key_vault_secret.postgresql_password.value
  sslmode         = "require"
  superuser       = false # set to false then this user it not a superuser
  connect_timeout = 60
}

# Create database user for this service
resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "postgresql_role" "database_user" {
  name     = var.SERVICE_NAME
  login    = true
  password = random_password.database_password.result
}

resource "postgresql_database" "service_database" {
  name  = "${var.SERVICE_NAME}-new"
  owner = postgresql_role.database_user.name
  depends_on = [
    postgresql_role.database_user
  ]
}
