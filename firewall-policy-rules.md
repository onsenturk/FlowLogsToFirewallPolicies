# Firewall policy rule documentation

## Approval-first rule process

This repository is designed so that Azure Firewall Policy rule collections stay empty or sample-only until you approve them.

## Rule sources of truth

Use these sources in order:

1. virtual network flow logs
2. Traffic Analytics recommendations in `NTARuleRecommendation`
3. architecture and platform dependencies that are already known to be required
4. manual validation with application owners

## Recommended rule hierarchy

### 1. Platform dependencies

Create narrowly scoped rules for platform functions that the workloads already require, for example:

- Microsoft Entra ID sign-in endpoints
- Windows or Linux update endpoints
- private DNS or domain-controller dependencies
- time synchronization

Prefer Azure Firewall application rules for FQDN-based egress and network rules only when FQDN rules aren't possible.

### 2. East-west application traffic

Create network rules only for the observed source and destination ranges, protocols, and ports that are required for application communication between trusted segments.

### 3. Private endpoint and PaaS traffic

Document flows that should be converted to private endpoints or service tags instead of broad IP-based allow rules.

### 4. Internet egress

Only allow approved outbound internet traffic. Aggregate destinations by service tag or FQDN where possible.

### 5. Block or advisory findings

Review `RecommendedAction` values of `Block` and `Advisory` from Traffic Analytics before creating any explicit deny rules.

## Rule capture template

| Candidate type | Source scope | Destination scope | Protocol | Port or FQDN | Evidence | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| Platform dependency |  |  |  |  | Query result + owner validation | Pending |
| East-west allow |  |  |  |  | Query result + owner validation | Pending |
| Internet egress allow |  |  |  |  | Query result + owner validation | Pending |
| Block or advisory |  |  |  |  | Query result + risk review | Pending |

## Sanitized evidence guidance

This public repository does not retain live customer evidence snapshots, workspace names, VNet names, subnet names, or measured traffic volumes.

Keep customer-specific findings in private request artifacts or in a private branch, and use this file only as the reusable approval framework.

### How to record customer-specific findings safely

When you build a private review package from Traffic Analytics output, capture the following categories without committing live environment data to the public repository:

- source workspace: store only in private request artifacts
- baseline window and latest refresh window
- covered VNet set and observed VNet subset
- recommendation table status
- high-level platform dependencies
- east-west dependencies that require owner validation
- public inbound exposures that need explicit justification

### Example candidate allow rules for owner validation

| Candidate type | Source scope | Destination scope | Protocol | Port or FQDN | Evidence | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| Platform dependency | `<source-subnet>` | `AzureMonitor` service tag | TCP | `443` | observed outbound dependency in private review output | Pending |
| Platform dependency | `<source-subnet>` | `AzureStorage` service tag | TCP/UDP | `443` | observed outbound dependency in private review output | Pending |
| Platform dependency | `<source-subnet>` | `AzureEventHub` service tag | TCP | `5671` | observed outbound dependency in private review output | Pending |
| Platform dependency | `<source-subnet>` | `AzureCloud` service tag | mixed | platform-specific ports | observed outbound dependency in private review output | Pending |
| East-west allow | `<source-subnet>` | `<destination-subnet>` | UDP/TCP | `53` | DNS dependency validated with workload owners | Pending |
| East-west allow | `<source-subnet>` | `<destination-subnet>` | TCP | `88`, `389`, `445`, `135` | identity and file-service dependency validated with workload owners | Pending |
| East-west allow | `<source-subnet>` | `<destination-subnet>` | TCP | `<validated-rpc-range>` | return-path or RPC dependency validated with workload owners | Pending |

### Example review-only inbound exposures

These remain review items, not auto-approve items.

| Candidate type | Source scope | Destination scope | Protocol | Port or FQDN | Evidence | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| Review public exposure | Internet or Azure public sources | `<destination-subnet>` | TCP | `<exposed-port>` | public inbound traffic observed in private review output | Pending |
| Review public exposure | Azure public sources | `<destination-subnet>` | TCP | `179` | validate against VPN or BGP design before enforcement | Pending |

### Zero-trust interpretation

- Start by allowing platform dependencies with the narrowest construct possible.
- Use Azure Firewall application rules for HTTP or HTTPS destinations when defensible FQDN mapping exists.
- Use Azure Firewall network rules for non-HTTP Azure platform traffic, internal RFC1918 dependencies, or explicitly IP-based traffic.
- Treat broad service buckets such as `AzureCloud` or unmanaged public destinations as review buckets, not direct allow rules.
- Treat public inbound ports as candidate shrink or removal items unless owners confirm a business requirement.

## Translation guidance

### Prefer application rules when

- destination can be expressed as FQDNs
- the traffic is outbound HTTP or HTTPS
- service ownership maps better to names than IP ranges

### Prefer network rules when

- traffic is non-HTTP or non-HTTPS
- destination is internal RFC1918 space
- the dependency is explicitly IP-based

## Bicep handoff

After approval:

1. copy the approved rules into [infra/firewall-policy-rules.sample.bicepparam](infra/firewall-policy-rules.sample.bicepparam) or into the `firewallPolicyRuleCollectionGroups` parameter for the main deployment
2. run `what-if`
3. review the change set
4. deploy only the approved rules
