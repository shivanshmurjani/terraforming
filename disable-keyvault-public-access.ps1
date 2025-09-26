# disable-keyvault-public-access.ps1
# Run this script after Terraform deployment to fully secure Key Vault

# Get the Key Vault name from Terraform output
$kvName = terraform output -raw key_vault_name
$rgName = terraform output -raw resource_group_name

Write-Host "Securing Key Vault: $kvName" -ForegroundColor Yellow

# First set network ACLs to deny all, then disable public access
az keyvault network-rule add --name $kvName --resource-group $rgName --subnet "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rgName/providers/Microsoft.Network/virtualNetworks/vnet-myapp-dev/subnets/subnet-pe-myapp-dev"

az keyvault update --name $kvName --resource-group $rgName --default-action Deny

# Finally disable public network access completely
az keyvault update --name $kvName --resource-group $rgName --public-network-access Disabled

Write-Host "Key Vault fully secured!" -ForegroundColor Green
Write-Host "Key Vault is now accessible only via private endpoint" -ForegroundColor Green