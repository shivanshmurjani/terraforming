# File: modules/storage/main.tf
resource "azurerm_storage_account" "main" {
  name                     = "st${var.project_name}${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "random_string" "storage_suffix" {
  length  = 3
  special = false
  upper   = false
}

# Private endpoint for storage account
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id

  private_service_connection {
    name                           = "psc-storage-${var.project_name}-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Private DNS zone for storage
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "link-storage-${var.project_name}-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# DNS A record for private endpoint
resource "azurerm_private_dns_a_record" "storage" {
  name                = azurerm_storage_account.main.name
  zone_name           = azurerm_private_dns_zone.storage.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}