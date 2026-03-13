using 'br/public:avm/res/network/firewall-policy:0.3.4'

// This parameter file is intentionally separate from the deployment entry point.
// Populate it only after reviewing Traffic Analytics findings and getting approval.
param name = 'replace-with-approved-firewall-policy-name'
param location = 'westeurope'
param tier = 'Premium'
param threatIntelMode = 'Deny'
param snat = {
  autoLearnPrivateRanges: 'Enabled'
}
param ruleCollectionGroups = [
  // Example allow rule collection group for approved east-west traffic.
  {
    name: 'rcg-approved-network-allow'
    priority: 200
    ruleCollections: [
      {
        name: 'network-allow-approved'
        priority: 200
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'example-app-to-api-443'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '10.10.0.0/24'
            ]
            destinationAddresses: [
              '10.20.0.0/24'
            ]
            destinationPorts: [
              '443'
            ]
          }
        ]
      }
    ]
  }
  // Example application rule collection group for approved internet egress.
  {
    name: 'rcg-approved-application-egress'
    priority: 300
    ruleCollections: [
      {
        name: 'app-allow-approved'
        priority: 300
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'example-os-updates'
            ruleType: 'ApplicationRule'
            sourceAddresses: [
              '10.30.0.0/24'
            ]
            targetFqdns: [
              'login.microsoftonline.com'
              'sls.update.microsoft.com'
            ]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
          }
        ]
      }
    ]
  }
]
