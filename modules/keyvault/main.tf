# File: modules/keyvault/main.tf
data "azurerm_client_config" "current" {}

# Get current public IP for Terraform access
data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.project_name}-${var.environment}-${random_string.kv_suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  
  # Enable public access temporarily for Terraform operations
  public_network_access_enabled = true
  
  # Allow access from current IP for Terraform
  network_acls {
    default_action = "Allow"  # Temporarily allow all for deployment
    bypass         = "AzureServices"
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Sample secret (can be created after Key Vault is accessible)
resource "azurerm_key_vault_secret" "app_secret" {
  name         = "app-connection-string"
  value        = "Server=private;Database=myapp;Integrated Security=true;"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id

  private_service_connection {
    name                           = "psc-kv-${var.project_name}-${var.environment}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Private DNS zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-kv-${var.project_name}-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}