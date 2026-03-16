// Deploys NSGs for intra-subnet and inter-subnet traffic from a JSON rules file.
// The JSON is produced by scripts/New-FirewallRulesFromTraffic.ps1.
// Do NOT deploy without reviewing the JSON first.

targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('NSG subnet groups from New-FirewallRulesFromTraffic.ps1. Load with: loadJsonContent(\'path/to/nsg-rules.json\').subnets')
param subnets array

resource nsgs 'Microsoft.Network/networkSecurityGroups@2024-05-01' = [for (s, si) in subnets: {
  name: toLower('nsg-${s.vnet}-${s.subnet}-observed')
  location: location
  properties: {
    securityRules: [for (r, ri) in s.rules: {
      name: 'allow-${toLower(r.category)}-${toLower(r.protocol)}-${r.port}-${padLeft(string(ri), 4, '0')}'
      properties: {
        priority: 110 + ri * 10
        direction: 'Inbound'
        access: 'Allow'
        protocol: r.protocol == 'TCP' || r.protocol == 'UDP' ? r.protocol : '*'
        sourceAddressPrefix: r.srcIp
        sourcePortRange: '*'
        destinationAddressPrefix: r.destIp
        destinationPortRange: string(r.port)
      }
    }]
  }
}]
