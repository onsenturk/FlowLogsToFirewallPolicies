targetScope = 'subscription'

@description('Configuration for a target resource that will have virtual network flow logs enabled.')
type FlowLogTarget = {
  @description('Resource ID of the target virtual network, subnet, or network interface.')
  targetResourceId: string
  @description('Name of the flow log resource.')
  flowLogName: string
  @description('Optional filtering criteria for flow logging.')
  enabledFilteringCriteria: string?
}

@description('Deployment prefix used in resource names.')
@minLength(3)
@maxLength(20)
param deploymentPrefix string

@description('Azure region for this deployment. Deploy once per region because the flow log storage account must match the region of the target resources.')
param location string

@description('Resource group that will contain the Log Analytics workspace, storage account, and Azure Firewall policy.')
param monitoringResourceGroupName string = '${deploymentPrefix}-network-observability-rg'

@description('Existing resource group that contains the regional Network Watcher resource.')
param networkWatcherResourceGroupName string = 'NetworkWatcherRG'

@description('Existing Network Watcher resource name for the region.')
param networkWatcherName string = 'NetworkWatcher_${location}'

@description('Name of the Log Analytics workspace to create.')
param logAnalyticsWorkspaceName string = '${deploymentPrefix}-law'

@description('Globally unique lower-case storage account name for flow log storage.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Name of the Azure Firewall policy to create. This template creates the policy only; it does not attach the policy to an Azure Firewall instance.')
param firewallPolicyName string = '${deploymentPrefix}-azfw-policy'

@description('Azure Firewall policy tier.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param firewallPolicyTier string = 'Premium'

@description('Retention period for flow logs, Log Analytics, and Firewall Policy insights.')
@minValue(30)
@maxValue(365)
param retentionInDays int = 30

@description('Traffic Analytics processing interval in minutes.')
@allowed([
  10
  60
])
param trafficAnalyticsInterval int = 60

@description('Target resources for virtual network flow logging. All targets must be in the same region as the deployment.')
param flowLogTargets FlowLogTarget[]

@description('Initial Firewall Policy rule collection groups. Leave this empty until rule changes are approved.')
param firewallPolicyRuleCollectionGroups array = []

@description('Tags applied to all resources created by this deployment.')
param tags object = {}

resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: monitoringResourceGroupName
  location: location
  tags: tags
}

module monitoringStack './modules/monitoring-stack.bicep' = {
  name: 'monitoringStack'
  scope: monitoringResourceGroup
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    storageAccountName: storageAccountName
    firewallPolicyName: firewallPolicyName
    firewallPolicyTier: firewallPolicyTier
    retentionInDays: retentionInDays
    firewallPolicyRuleCollectionGroups: firewallPolicyRuleCollectionGroups
    tags: tags
  }
}

module flowLogDeployments './modules/flow-log.bicep' = [for target in flowLogTargets: {
  name: 'flowLog-${uniqueString(target.targetResourceId)}'
  scope: resourceGroup(subscription().subscriptionId, networkWatcherResourceGroupName)
  params: {
    location: location
    networkWatcherName: networkWatcherName
    flowLogName: target.flowLogName
    targetResourceId: target.targetResourceId
    storageId: monitoringStack.outputs.flowLogStorageAccountResourceId
    retentionInDays: retentionInDays
    enableTrafficAnalytics: true
    workspaceId: monitoringStack.outputs.logAnalyticsWorkspaceId
    workspaceRegion: location
    workspaceResourceId: monitoringStack.outputs.logAnalyticsWorkspaceResourceId
    trafficAnalyticsInterval: trafficAnalyticsInterval
    enabledFilteringCriteria: target.?enabledFilteringCriteria ?? ''
    tags: union(tags, {
      TargetResource: last(split(target.targetResourceId, '/'))
    })
  }
}]

output monitoringResourceGroupName string = monitoringResourceGroup.name
output logAnalyticsWorkspaceName string = monitoringStack.outputs.logAnalyticsWorkspaceName
output logAnalyticsWorkspaceResourceId string = monitoringStack.outputs.logAnalyticsWorkspaceResourceId
output flowLogStorageAccountName string = monitoringStack.outputs.flowLogStorageAccountName
output flowLogStorageAccountResourceId string = monitoringStack.outputs.flowLogStorageAccountResourceId
output firewallPolicyName string = monitoringStack.outputs.firewallPolicyName
output firewallPolicyResourceId string = monitoringStack.outputs.firewallPolicyResourceId
output flowLogResourceIds array = [for (target, i) in flowLogTargets: flowLogDeployments[i].outputs.resourceId]
