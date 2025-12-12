# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that builds and deploys the ZavaStorefront .NET application as a container to Azure App Service.

## Prerequisites

- Azure subscription with deployed infrastructure (App Service, Container Registry)
- GitHub repository settings access

## Required GitHub Secrets

### AZURE_CREDENTIALS
Service principal credentials for Azure authentication.

**Create the service principal:**
```bash
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --json-auth
```

**Copy the entire JSON output** and add it as a secret named `AZURE_CREDENTIALS`.

### Additional Role Assignment
The service principal also needs `AcrPush` role on the Container Registry:
```bash
az role assignment create \
  --assignee {service-principal-client-id} \
  --role AcrPush \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

## Required GitHub Variables

### AZURE_CONTAINER_REGISTRY_NAME
The name of your Azure Container Registry (without `.azurecr.io`).

Example: `acregfzcdz6ddveg`

### AZURE_APP_SERVICE_NAME
The name of your Azure App Service.

Example: `app-egfzcdz6ddveg`

## How to Configure

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Under **Secrets** tab:
   - Click **New repository secret**
   - Name: `AZURE_CREDENTIALS`
   - Value: Paste the JSON output from service principal creation
4. Under **Variables** tab:
   - Click **New repository variable**
   - Name: `AZURE_CONTAINER_REGISTRY_NAME`, Value: `{your-acr-name}`
   - Click **New repository variable**
   - Name: `AZURE_APP_SERVICE_NAME`, Value: `{your-app-service-name}`

## Finding Your Resource Names

```bash
# List your resources
az resource list --resource-group {resource-group-name} --output table

# Get ACR name
az acr list --resource-group {resource-group-name} --query "[].name" -o tsv

# Get App Service name
az webapp list --resource-group {resource-group-name} --query "[].name" -o tsv
```

## Workflow Triggers

The workflow runs on:
- Push to `main` branch
- Pull request to `main` branch
- Manual trigger (workflow_dispatch)

## What the Workflow Does

1. Checks out code
2. Logs in to Azure using service principal
3. Builds Docker image using Azure Container Registry (cloud build)
4. Pushes image with commit SHA and `latest` tags
5. Deploys the container to App Service
