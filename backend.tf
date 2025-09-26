terraform {
  backend "azurerm" {
    resource_group_name  = "platform-rg-tcj"
    storage_account_name = "tfstatetcj"
    container_name       = "tfstatetcj"
    key                  = "terraforming.tfstate"
  }
}