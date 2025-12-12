```markdown
# Deployment quickstart — Build & deploy container to Azure App Service

This repository includes a minimal deployment guide (deploy.md) and a GitHub Actions workflow (.github/workflows/deploy.yml) that builds the .NET app into a Docker image, pushes it to an Azure Container Registry (ACR), and configures your Azure Web App (App Service) to use that image.

Note: The workflow assumes you already have:
- An Azure App Service configured for containers (the "web app" resource).
- An Azure Container Registry (ACR) where the image will be pushed.
- A service principal with appropriate permissions to push to ACR and update the Web App.

Required GitHub Secrets
- AZURE_CREDENTIALS — JSON string for an Azure service principal (sdk-auth JSON) OR set these secrets separately: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID.
- RESOURCE_GROUP — Azure resource group that contains the Web App.
- WEBAPP_NAME — Name of the Azure Web App to update.
- ACR_NAME — Short ACR name (used by `az acr login`, e.g. myregistry).
- ACR_LOGIN_SERVER — ACR login server (e.g. myregistry.azurecr.io).

Where to find files
- Deployment instructions: deploy.md (root of the repo)
- GitHub Actions workflow: .github/workflows/deploy.yml

How the workflow works (brief)
1. Checkout code.
2. Set IMAGE_TAG from the commit SHA.
3. Login to Azure using the provided credentials.
4. az acr login to the ACR.
5. docker build and docker push the image to ACR.
6. Use `az webapp config container set` to point the Web App at the new image.

If your infra uses a different flow (for example, you're not using ACR, or your App Service pulls an image from Docker Hub), adjust the workflow and deploy.md accordingly.
```
