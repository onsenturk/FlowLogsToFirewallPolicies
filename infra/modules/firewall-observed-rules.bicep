// Deploys Azure Firewall Policy rule collection groups from a JSON rules file.
// The JSON is produced by scripts/New-FirewallRulesFromTraffic.ps1.
// Do NOT deploy without reviewing the JSON first.

targetScope = 'resourceGroup'

@description('Name of an EXISTING Azure Firewall Policy to add rules to.')
param firewallPolicyName string

@description('Firewall rules from New-FirewallRulesFromTraffic.ps1. Load with: loadJsonContent(\'path/to/firewall-rules.json\')')
param rules array

var egressRules  = filter(rules, r => r.category == 'Egress')
var ingressRules = filter(rules, r => r.category == 'Ingress')
var interVNetRules = filter(rules, r => r.category == 'InterVNet')

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' existing = {
  name: firewallPolicyName
}

resource rcgEgress 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = if (!empty(egressRules)) {
  parent: firewallPolicy
  name: 'rcg-observed-egress'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'network-allow-egress'
        priority: 200
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: { type: 'Allow' }
        rules: [for (r, i) in egressRules: {
          name: 'egress-${toLower(r.protocol)}-${r.port}-${padLeft(string(i), 4, '0')}'
          ruleType: 'NetworkRule'
          ipProtocols: [toUpper(r.protocol)]
          sourceAddresses: [r.srcIp]
          destinationAddresses: [r.destIp]
          destinationPorts: [string(r.port)]
        }]
      }
    ]
  }
}

resource rcgIngress 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = if (!empty(ingressRules)) {
  parent: firewallPolicy
  name: 'rcg-observed-ingress'
  dependsOn: [rcgEgress]
  properties: {
    priority: 300
    ruleCollections: [
      {
        name: 'network-allow-ingress'
        priority: 300
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: { type: 'Allow' }
        rules: [for (r, i) in ingressRules: {
          name: 'ingress-${toLower(r.protocol)}-${r.port}-${padLeft(string(i), 4, '0')}'
          ruleType: 'NetworkRule'
          ipProtocols: [toUpper(r.protocol)]
          sourceAddresses: [r.srcIp]
          destinationAddresses: [r.destIp]
          destinationPorts: [string(r.port)]
        }]
      }
    ]
  }
}

resource rcgInterVNet 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = if (!empty(interVNetRules)) {
  parent: firewallPolicy
  name: 'rcg-observed-intervnet'
  dependsOn: [rcgIngress]
  properties: {
    priority: 400
    ruleCollections: [
      {
        name: 'network-allow-intervnet'
        priority: 400
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: { type: 'Allow' }
        rules: [for (r, i) in interVNetRules: {
          name: 'ivnet-${toLower(r.protocol)}-${r.port}-${padLeft(string(i), 4, '0')}'
          ruleType: 'NetworkRule'
          ipProtocols: [toUpper(r.protocol)]
          sourceAddresses: [r.srcIp]
          destinationAddresses: [r.destIp]
          destinationPorts: [string(r.port)]
        }]
      }
    ]
  }
}
