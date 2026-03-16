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
4. Operators run `scripts/New-FirewallRulesFromTraffic.ps1` to query NTANetAnalytics, classify traffic, and generate review-only JSON rule files.
5. Approved findings are converted into Azure Firewall Policy rule collection groups via the static Bicep templates.
6. Rule collection groups are deployed only after business and security approval.

## Workshop orchestration flow

1. The user starts the workshop with natural language such as `start` or with the explicit `/01-start-workshop` prompt.
2. The discovery agent checks Azure sign-in state, confirms the tenant, and asks whether the user wants to provide a specific Log Analytics workspace or discover candidate workspaces in the selected tenant.
3. The discovery agent validates that Azure CLI and any extension-backed or MCP-backed Azure context are aligned before relying on discovery or query results.
4. When discovery is needed, the discovery agent identifies candidate subscriptions and Log Analytics workspaces, highlights which workspaces appear to contain relevant VNet flow-log evidence, and asks the customer to choose the workspace to use.
5. After workspace selection, the discovery agent confirms region only if it is still needed, runs a lightweight discovery and coverage pass with a default `7d` lookback unless the customer explicitly overrides it, then asks the customer to choose either `dynamic discovery` or `predefined VNet scope`.
6. In `dynamic discovery`, the discovery flow proposes the candidate VNets observed for the selected workspace. In `predefined VNet scope`, the customer supplies the VNet list up front and the workflow validates only that scope.
7. The user confirms the intended VNet scope and the workflow captures the detailed analysis timeframe.
8. The discovery flow classifies each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` and carries uncovered VNets forward as explicit exclusions.
9. If a requested hub, transit, or shared-services VNet is `Uncovered`, the workflow treats that as a blocking gap for a full production-scope draft unless the user narrows scope or explicitly accepts a partial review-only output.
10. The discovery flow analyzes internal traffic, north-south egress, and public inbound exposure for the covered VNets only, keeping the findings explicit per covered VNet or equivalent scope fragment and preserving the evidence source by VNet.
11. An optional traffic-flow diagram may summarize all confirmed covered VNets, but it does not replace the per-VNet evidence contract for firewall-rule generation.
12. Copilot asks once for confirmation before creating any local request artifacts.
13. The drafting agent writes review-only outputs under `requests/<datetime>/`.
14. Generated firewall rule content remains a local infrastructure-as-code draft, stays approval-pending, and is synthesized from the per-VNet evidence rather than a single blended workspace-wide summary.
15. If the customer explicitly asks for remediation guidance after the workshop, the workflow may generate a separate review-only artifact with CLI commands to enable VNet flow logs to the chosen workspace.

## Security model

- storage account blocks anonymous blob access
- storage account firewall defaults to deny and allows trusted Azure services
- storage requires HTTPS and infrastructure encryption
- Log Analytics workspace disables local auth
- Firewall Policy is created with `threatIntelMode` set to `Deny`
- no secrets are stored in the repository

## Regional constraint

Virtual network flow log storage must be in the same region as the logged resources. For that reason, run one deployment per Azure region.
