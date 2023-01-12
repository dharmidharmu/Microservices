@description('Tag Value for Managed By')
param tag_managedBy string = 'l.bischard@gov.je'

@description('Tag Value for Department')
param tag_department string = 'coo\\mad'

@description('Tag Value for Service')
param tag_service string = 'online'

@description('Tag Value for Environment')
param tag_environment string = 'dev'

param AppService_name string = 'dev-euw-dharmi-logicapp-appservice'
param ASP_sku_tier string = 'WorkflowStandard'
param ASP_sku_name string = 'WS1'

@description('Name of the Storage Account(logicApp)')
param storageAccount_name string = 'devdharmieuwlogicappsa'

@description('Storage Account Sku')
param sku_storageAccount string = 'Standard_ZRS'

@description('Name of the Log Analytics WorkSpace(Application Insights)')
param logAnalyticsWorkspace_name string = 'dev-euw-dharmi-law'

@description('Name of the Application Insights(Function App)')
param applicationInsights_name string = 'dev-euw-dharmi-ai'

@description('Name of the Logic App')
param logicApp_name string = 'dev-dharmi-euw-logicapp'


@description('Name of the Keyvault')
param keyVault_name string = 'dev-euw-dharmi-backend-kv'

resource AppService_name_resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: AppService_name
  location: resourceGroup().location
  tags: {
    environment: tag_environment
    service: tag_service
    department: tag_department
    managedBy: tag_managedBy
  }
  sku: {
    name: ASP_sku_name
    tier: ASP_sku_tier
  }
  kind: 'elastic'
  properties: {
    reserved: false
  }
}

resource storageAccount_name_resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccount_name
  location: resourceGroup().location
  tags: {
    environment: tag_environment
    service: tag_service
    department: tag_department
    managedBy: tag_managedBy
  }
  sku: {
    name: sku_storageAccount
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource logAnalyticsWorkspace_name_resource 'microsoft.operationalinsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspace_name
  location: resourceGroup().location
  tags: {
    environment: tag_environment
    service: tag_service
    department: tag_department
    managedBy: tag_managedBy
  }
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource applicationInsights_name_resource 'microsoft.insights/components@2020-02-02' = {
  name: applicationInsights_name
  location: resourceGroup().location
  dependsOn: [
    logAnalyticsWorkspace_name_resource
  ]
  tags: {
    environment: tag_environment
    service: tag_service
    department: tag_department
    managedBy: tag_managedBy
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspace_name_resource.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource logicApp_name_resource 'Microsoft.Web/sites@2022-03-01' = {
  name: logicApp_name
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    environment: tag_environment
    service: tag_service
    department: tag_department
    managedBy: tag_managedBy
  }
  kind: 'functionapp,workflowapp'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${logicApp_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${logicApp_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: AppService_name_resource.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights_name_resource.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount_name};AccountKey=${listKeys(storageAccount_name_resource.id, '2017-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount_name};AccountKey=${listKeys(storageAccount_name_resource.id, '2017-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(logicApp_name)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_TIME_ZONE'
          value: 'UTC'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
      ]
    }
  }
  dependsOn: [

    logAnalyticsWorkspace_name_resource, storageAccount_name_resource, AppService_name_resource, applicationInsights_name_resource

  ]
}
resource keyVault_name_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVault_name}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(logicApp_name_resource.id, '2019-08-01', 'full').identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
            'list'
          ]
          certificates: []
        }
      }
    ]
  }
}

