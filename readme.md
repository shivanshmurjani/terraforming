# GitHub Actions Secrets for Terraform on Azure

This project uses **Terraform** with **GitHub Actions** to deploy resources into Azure.  
Authentication is handled using an **Azure Service Principal (SP)**, with credentials stored as GitHub Secrets.

---

## Required Secretss

Add the following secrets in your repository:

| Secret Name          | Description |
|-----------------------|-------------|
| `ARM_CLIENT_ID`       | The Application (client) ID of the Service Principal. |
| `ARM_CLIENT_SECRET`   | The password/secret value of the Service Principal. |
| `ARM_SUBSCRIPTION_ID` | The Azure Subscription ID where resources will be deployed. |
| `ARM_TENANT_ID`       | The Azure Tenant (directory) ID of your organization. |

---

## How to Generate These Secrets

1. Login to Azure CLI:

   ```powershell
   az login
   ```

2. Create a Service Principal with **Contributor** access to your subscription:

   ```powershell
   az ad sp create-for-rbac `
     --name "github-actions-terraform" `
     --role Contributor `
     --scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
   ```

3. The command outputs JSON similar to:

   ```json
   {
     "appId": "xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "displayName": "github-actions-terraform",
     "password": "xxxxxxxxxxxxxxxxxxxx",
     "tenant": "xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   }
   ```

4. Map the values:
   - `ARM_CLIENT_ID` → `appId`
   - `ARM_CLIENT_SECRET` → `password`
   - `ARM_TENANT_ID` → `tenant`
   - `ARM_SUBSCRIPTION_ID` → your subscription ID (get with `az account show --query id -o tsv`)

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

⚠️ **Security Note:**  
Never commit these credentials into source control. Always store them as GitHub Secrets.
