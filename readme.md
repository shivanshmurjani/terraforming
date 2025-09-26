This repository demonstrates how to deploy secure Azure infrastructure using Terraform, with automated provisioning via GitHub Actions.

---

## Project Structure

```
|   .gitignore
|   backend.tf
|   disable-keyvault-public-access.ps1
|   main.tf
|   quick-security-test.ps1
|   readme.md
|
+---.github
|   \---workflows
|           deploy.yml
|           destroy.yml
|
\---modules
    +---app-service
    |       main.tf
    |       outputs.tf
    |       variables.tf
    |
    +---keyvault
    |       main.tf
    |       outputs.tf
    |       variables.tf
    |
    +---networking
    |       main.tf
    |       outputs.tf
    |       variables.tf
    |
    +---resource-group
    |       main.tf
    |       outputs.tf
    |       variables.tf
    |
    \---storage
            main.tf
            outputs.tf
            variables.tf
```

---

## Initial Backend Setup

Terraform requires a backend to store state. Follow these steps:

### 1. Generate Random Names (Optional)

```powershell
# Generate a random 6-character suffix
$rand = -join ((97..122) | Get-Random -Count 3 | ForEach-Object {[char]$_})

# Define names using the random suffix
$rgName        = "platform-rg-$rand"
$storageName   = "tfstate$rand"
$containerName = "tfstate$rand"

Write-Host "Resource Group: $rgName"
Write-Host "Storage Account: $storageName"
Write-Host "Blob Container: $containerName"
```

### 2. Create Resource Group

```powershell
az group create --name $rgName --location centralindia
```

### 3. Create Storage Account

```powershell
az storage account create `
  --name $storageName `
  --resource-group $rgName `
  --location centralindia `
  --sku Standard_LRS `
  --kind StorageV2 `
  --enable-hierarchical-namespace false
```

### 4. Create Blob Container

```powershell
az storage container create `
  --name $containerName `
  --account-name $storageName
```

### 5. Update `backend.tf`

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "$rgName"
    storage_account_name = "$storageName"
    container_name       = "$containerName"
    key                  = "azure-iac-terraform.tfstate"
  }
}
```

> Tip: Use environment variables or GitHub Actions secrets to make backend dynamic in CI/CD pipelines.

---

## Deploying Infrastructure Locally

1. Initialize Terraform:

```bash
terraform init
```

2. Validate configuration:

```bash
terraform validate
```

3. Plan changes:

```bash
terraform plan
```

4. Apply infrastructure:

```bash
terraform apply -auto-approve
```

5. Check outputs:

```bash
terraform output
```

---

## Required Secrets for GITHUB ACTIONS

Add the following secrets in your repository:

| Secret Name          | Description |
|-----------------------|-------------|
| `ARM_CLIENT_ID`       | The Application (client) ID of the Service Principal. |
| `ARM_CLIENT_SECRET`   | The password/secret value of the Service Principal. |
| `ARM_SUBSCRIPTION_ID` | The Azure Subscription ID where resources will be deployed. |
| `ARM_TENANT_ID`       | The Azure Tenant (directory) ID of your organization. |
| `AZURE_CREDENTIALS`   | Entire json
---

## How to Generate These Secrets

1. Login to Azure CLI:

   ```powershell
   az login
   ```

2. Create a Service Principal with **Contributor** access:

   ```powershell
   az ad sp create-for-rbac --name "github-actions-terraform" --role Contributor --scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
   ```

3. Take the output JSON and create the `AZURE_CREDENTIALS` JSON in this format:

   ```json
   {
     "clientId": "<appId from SP>",
     "clientSecret": "<password from SP>",
     "tenantId": "<tenant from SP>",
     "subscriptionId": "<your Azure subscription ID>"
   }
   ```

4. Map the values:
   - `ARM_CLIENT_ID` → `appId`
   - `ARM_CLIENT_SECRET` → `password`
   - `ARM_TENANT_ID` → `tenant`
   - `ARM_SUBSCRIPTION_ID` → your subscription ID (get with `az account show --query id -o tsv`)
   - `AZURE_CREDENTIALS` → `Go to 3`

---

## Adding Secrets in GitHub

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**.  
2. Click **New repository secret**.  
3. Add each secret with the names listed above.  

---

## Usage in GitHub Actions

In the workflow (`deploy.yml`), the secrets are consumed like this:

```yaml
- name: Azure Login
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.ARM_CLIENT_ID }}
    tenant-id: ${{ secrets.ARM_TENANT_ID }}
    subscription-id: ${{ secrets.ARM_SUBSCRIPTION_ID }}
    client-secret: ${{ secrets.ARM_CLIENT_SECRET }}
```

---

## Setting up secrets

```
# Get Key Vault name
$kvName = terraform output -raw key_vault_name

# Add database connection string
az keyvault secret set --vault-name $kvName --name "db-connection-string" --value "Server=myserver;Database=prod;User Id=myuser;Password=mypass;"

# Add API keys
az keyvault secret set --vault-name $kvName --name "api-key" --value "your-secret-api-key-here"

# Add storage connection string
az keyvault secret set --vault-name $kvName --name "storage-connection" --value "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=mykey"

# Add other secrets
az keyvault secret set --vault-name $kvName --name "jwt-secret" --value "your-jwt-signing-secret"



#Disable public access after:
# Run the security hardening script
.\disable-keyvault-public-access.ps1
# Now Key Vault is only accessible from private network

```

---

---

## Deploying application

```
# Get the web app name from Terraform output
$webAppName = terraform output -raw web_app_url | Select-String -Pattern "https://(.+?).azurewebsites.net" | ForEach-Object { $_.Matches[0].Groups[1].Value }

# Get the resource group name from Terraform output
$rgName = terraform output -raw resource_group_name

# Verify values
$webAppName
$rgName

# Switch to the directory with the app and run this cmd to deploy the app
az webapp up --name $webAppName --resource-group $rgName

```

---

## Expected Output after deployment:
```
key_vault_name = "kv-my-app-dev-sx7m"
resource_group_name = "rg-my-app-dev"
storage_account_name = "stmyappdevbm9"
web_app_url = "https://app-my-app-dev-rhvw5a.azurewebsites.net"

The names would be randomized.
```