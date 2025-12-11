targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, test, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Unique identifier for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

@description('The container image name')
param containerImageName string = 'zavastore:latest'

// Tags to apply to all resources
var tags = {
  'azd-env-name': environmentName
  'project': 'ZavaStorefront'
}

// Resource names
var resourceGroupName = 'rg-${environmentName}-${location}'
var logAnalyticsName = 'log-${resourceToken}'
var appInsightsName = 'appi-${resourceToken}'
var acrName = 'acr${replace(resourceToken, '-', '')}'
var appServicePlanName = 'plan-${resourceToken}'
var appServiceName = 'app-${resourceToken}'
var aiServicesName = 'ai-${resourceToken}'

// Create resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy Log Analytics Workspace
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  scope: resourceGroup
  params: {
    workspaceName: logAnalyticsName
    location: location
    retentionInDays: 30
    tags: tags
  }
}

// Deploy Application Insights
module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Deploy Azure Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr'
  scope: resourceGroup
  params: {
    registryName: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// Deploy App Service Plan
module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  scope: resourceGroup
  params: {
    planName: appServicePlanName
    location: location
    sku: 'B1'
    tags: tags
  }
}

// Deploy App Service
module appService './modules/appService.bicep' = {
  name: 'appService'
  scope: resourceGroup
  params: {
    appName: appServiceName
    location: location
    appServicePlanId: appServicePlan.outputs.planId
    acrLoginServer: acr.outputs.loginServer
    containerImageName: containerImageName
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    tags: tags
  }
}

// Assign AcrPull role to App Service managed identity
module acrPullRoleAssignment './modules/roleAssignment.bicep' = {
  name: 'acrPullRoleAssignment'
  scope: resourceGroup
  params: {
    principalId: appService.outputs.appServicePrincipalId
    resourceId: acr.outputs.registryId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
  }
}

// Deploy AI Services (Microsoft Foundry) in westus3
module aiServices './modules/aiServices.bicep' = {
  name: 'aiServices'
  scope: resourceGroup
  params: {
    aiServicesName: aiServicesName
    location: location
    sku: 'S0'
    tags: tags
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.registryName
output AZURE_APP_SERVICE_NAME string = appService.outputs.appServiceName
output AZURE_APP_SERVICE_URL string = appService.outputs.appServiceUrl
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AI_SERVICES_ENDPOINT string = aiServices.outputs.aiServicesEndpoint
output AI_SERVICES_NAME string = aiServices.outputs.aiServicesName
