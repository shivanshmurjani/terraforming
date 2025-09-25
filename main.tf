# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "location" {
  description = "Azure region"
  type        = string
  default     = "central india"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "myapp"
}

# Resource Group Module
module "resource_group" {
  source       = "./modules/resource-group"
  project_name = var.project_name
  environment  = var.environment
  location     = var.location
}

# Networking Module
module "networking" {
  source              = "./modules/networking"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
}

# Storage Module
module "storage" {
  source              = "./modules/storage"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
}

# App Service Module
module "app_service" {
  source              = "./modules/app-service"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.networking.subnet_id
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "web_app_url" {
  description = "URL of the web application"
  value       = module.app_service.web_app_url
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}