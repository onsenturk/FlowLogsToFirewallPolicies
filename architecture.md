# Architecture

## Deployment model

This repository uses a subscription-scope Bicep entry point that orchestrates two resource-group scopes:

1. an observability resource group for shared monitoring resources
2. the regional `NetworkWatcherRG` resource group for flow log resources

## Copilot workflow layer

The repository now also contains a GitHub Copilot-first workflow layer for customer workshops.

- repo-wide engineering rules are defined in [.github/copilot-instructions.md](.github/copilot-instructions.md)
- Azure Firewall workshop behavior is defined in [.github/instructions/azure-firewall-workshop.instructions.md](.github/instructions/azure-firewall-workshop.instructions.md)
- specialized execution roles are defined in [.github/agents/discovery.agent.md](.github/agents/discovery.agent.md) and [.github/agents/drafting.agent.md](.github/agents/drafting.agent.md)
- user-invocable workflow steps are defined in [.github/prompts](.github/prompts)

## Resources

### Observability resource group

- Log Analytics workspace for Traffic Analytics
- regional storage account for virtual network flow log blobs
- Azure Firewall Policy with approval-gated rule collection groups

### Existing Azure resources updated when deployed

- selected existing virtual networks, subnets, or network interfaces receive virtual network flow logs through the regional Network Watcher

## Data flow

1. Azure Network Watcher captures traffic metadata for the selected target resources.
2. Flow logs are written to the regional storage account.
3. Traffic Analytics enriches the flow data and sends recommendations into Log Analytics.
4. Operators run the KQL queries in [queries/recommended-rules-by-vnet.kql](queries/recommended-rules-by-vnet.kql) and [queries/rule-candidates-summary.kql](queries/rule-candidates-summary.kql).
5. Approved findings are converted into Azure Firewall Policy rule collection groups.
6. Rule collection groups are deployed only after business and security approval.

## Workshop orchestration flow

1. The user starts the workshop with `/00-choose-flow`, natural language such as `start`, or the explicit `/01-start-workshop` prompt.
2. The discovery agent checks Azure sign-in state and confirms the tenant.
3. The user chooses one of two startup paths:
   - **Predefined flow**: the user provides the Log Analytics workspace name or resource ID, tenant ID, subscription ID, and preferred analysis timeframe. The workflow skips workspace discovery and proceeds directly to scope validation.
   - **Dynamic discovery**: the user provides only the tenant ID and optional hints. The discovery agent enumerates candidate subscriptions and Log Analytics workspaces, highlights which workspaces appear to contain relevant VNet flow-log evidence, and asks the customer to choose the workspace to use.
4. The discovery agent validates that Azure CLI and any extension-backed or MCP-backed Azure context are aligned before relying on discovery or query results.
5. After workspace selection, the discovery agent confirms region only if it is still needed, then proposes the candidate VNets observed for the selected workspace, the user confirms the intended VNet scope, and the workflow captures the analysis timeframe.
6. The discovery flow classifies each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` and carries uncovered VNets forward as explicit exclusions.
7. If a requested hub, transit, or shared-services VNet is `Uncovered`, the workflow treats that as a blocking gap for a full production-scope draft unless the user narrows scope or explicitly accepts a partial review-only output.
8. The discovery flow exports VNet flow logs from the selected Log Analytics workspace using KQL and analyzes internal traffic, north-south egress, and public inbound exposure for the covered VNets only. Queries run once per covered VNet and start with a `7d` lookback window; if results are sparse for a given VNet the query is re-run with `14d` then `30d` so that no flows are arbitrarily dropped.
9. Optionally, the workflow produces a Mermaid traffic flow diagram from the discovered flows for human review.
10. The workflow produces an explicit rule-candidate summary grouped by rule type (network east-west, network platform-internal, application FQDN/service-tag, inbound review items, and unresolved placeholders) before the firewall draft is generated.
11. Copilot asks once for confirmation before creating any local request artifacts.
12. The drafting agent writes review-only outputs under `requests/<datetime>/`.
13. Generated firewall rule content remains a local infrastructure-as-code draft, stays approval-pending, and is not deployed or applied automatically.
14. If the customer explicitly asks for remediation guidance after the workshop, the workflow may generate a separate review-only artifact with CLI commands to enable VNet flow logs to the chosen workspace.

## Security model

- storage account blocks anonymous blob access
- storage account firewall defaults to deny and allows trusted Azure services
- storage requires HTTPS and infrastructure encryption
- Log Analytics workspace disables local auth
- Firewall Policy is created with `threatIntelMode` set to `Deny`
- no secrets are stored in the repository

## Regional constraint

Virtual network flow log storage must be in the same region as the logged resources. For that reason, run one deployment per Azure region.
