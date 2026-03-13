using './main.bicep'

param deploymentPrefix = 'akzazfwweu'
param location = 'westeurope'
param monitoringResourceGroupName = 'rg-akz-network-observability-weu'
param networkWatcherResourceGroupName = 'NetworkWatcherRG'
param networkWatcherName = 'NetworkWatcher_westeurope'
param logAnalyticsWorkspaceName = 'law-akz-network-observability-weu'
param storageAccountName = 'stakzflowlogweu001'
param firewallPolicyName = 'fp-akz-zero-trust-weu'
param firewallPolicyTier = 'Premium'
param retentionInDays = 30
param trafficAnalyticsInterval = 60
param tags = {
  Environment: 'Prod'
  Owner: 'NetworkSecurity'
  Workload: 'AzureFirewallObservability'
}

param flowLogTargets = [
  {
    flowLogName: 'vnet-spoke01-weu-flowlog'
    targetResourceId: '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name>'
  }
]

// Keep the rule collection groups empty until rule changes are reviewed and approved.
param firewallPolicyRuleCollectionGroups = []
