terraform {
  backend "azurerm" {
    resource_group_name  = "platform-rg-bs"
    storage_account_name = "tfstatebs"
    container_name       = "tfstatebs"
    key                  = "terraforming.tfstate"
  }
}