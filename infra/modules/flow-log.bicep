targetScope = 'resourceGroup'

@description('Azure region of the target resource and storage account.')
param location string

@description('Existing Network Watcher name for the region.')
param networkWatcherName string

@description('Name of the flow log resource to create under the regional Network Watcher.')
param flowLogName string

@description('Resource ID of the target virtual network, subnet, or network interface.')
param targetResourceId string

@description('Resource ID of the storage account used to store the flow logs.')
param storageId string

@description('Retention period for stored flow logs in days. Use 0 to keep logs indefinitely.')
@minValue(0)
@maxValue(365)
param retentionInDays int = 30

@description('Enable Traffic Analytics for the flow log.')
param enableTrafficAnalytics bool = true

@description('Log Analytics workspace GUID used by Traffic Analytics.')
param workspaceId string = ''

@description('Azure region of the Log Analytics workspace used by Traffic Analytics.')
param workspaceRegion string = ''

@description('Resource ID of the Log Analytics workspace used by Traffic Analytics.')
param workspaceResourceId string = ''

@description('Traffic Analytics processing interval in minutes.')
@allowed([
  10
  60
])
param trafficAnalyticsInterval int = 60

@description('Optional filtering criteria for flow logging. Leave empty to capture all supported traffic.')
param enabledFilteringCriteria string = ''

@description('Resource tags applied to the flow log resource.')
param tags object = {}

resource networkWatcher 'Microsoft.Network/networkWatchers@2024-05-01' existing = {
  name: networkWatcherName
}

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2024-05-01' = {
  name: flowLogName
  parent: networkWatcher
  location: location
  tags: tags
  properties: {
    targetResourceId: targetResourceId
    storageId: storageId
    enabled: true
    enabledFilteringCriteria: enabledFilteringCriteria
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: retentionInDays
      enabled: retentionInDays > 0
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: enableTrafficAnalytics
        trafficAnalyticsInterval: trafficAnalyticsInterval
        workspaceId: workspaceId
        workspaceRegion: workspaceRegion
        workspaceResourceId: workspaceResourceId
      }
    }
  }
}

output name string = flowLog.name
output resourceId string = flowLog.id
