targetScope = 'resourceGroup'

@description('Azure region for the monitoring resources.')
param location string

@description('Name of the Log Analytics workspace that receives Traffic Analytics data.')
param logAnalyticsWorkspaceName string

@description('Name of the storage account that stores virtual network flow logs. Must be globally unique and lower-case.')
param storageAccountName string

@description('Name of the Azure Firewall policy to create.')
param firewallPolicyName string

@description('Azure Firewall policy tier.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param firewallPolicyTier string = 'Premium'

@description('Retention period for Log Analytics data and Firewall Policy insights.')
@minValue(30)
@maxValue(365)
param retentionInDays int = 30

@description('Initial Firewall Policy rule collection groups. Keep this empty until rule changes are approved.')
param firewallPolicyRuleCollectionGroups array = []

@description('Resource tags applied to all monitoring resources.')
param tags object = {}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  name: 'logAnalyticsWorkspace'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    dataRetention: retentionInDays
    features: {
      disableLocalAuth: true
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    enableTelemetry: false
    tags: union(tags, {
      Role: 'TrafficAnalytics'
    })
  }
}

module flowLogStorage 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'flowLogStorage'
  params: {
    name: storageAccountName
    location: location
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Enabled'
    requireInfrastructureEncryption: true
    supportsHttpsTrafficOnly: true
    enableTelemetry: false
    tags: union(tags, {
      Role: 'FlowLogsStorage'
    })
  }
}

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.4' = {
  name: 'azureFirewallPolicy'
  params: {
    name: firewallPolicyName
    location: location
    tier: firewallPolicyTier
    insightsIsEnabled: true
    defaultWorkspaceResourceId: logAnalytics.outputs.resourceId
    retentionDays: retentionInDays
    ruleCollectionGroups: firewallPolicyRuleCollectionGroups
    snat: {
      autoLearnPrivateRanges: 'Enabled'
    }
    threatIntelMode: 'Deny'
    enableTelemetry: false
    tags: union(tags, {
      ApprovalRequired: 'true'
      Role: 'AzureFirewallPolicy'
    })
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output logAnalyticsWorkspaceResourceId string = logAnalytics.outputs.resourceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.name
output flowLogStorageAccountResourceId string = flowLogStorage.outputs.resourceId
output flowLogStorageAccountName string = flowLogStorage.outputs.name
output firewallPolicyResourceId string = firewallPolicy.outputs.resourceId
output firewallPolicyName string = firewallPolicy.outputs.name
