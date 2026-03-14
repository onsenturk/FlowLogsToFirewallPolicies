# Deployment

## Prerequisites

- Azure subscription access with permission to deploy subscription-scope templates
- permission to deploy resources into the target observability resource group
- permission to create flow logs in the regional `NetworkWatcherRG`
- existing target VNets, subnets, or NICs in a single Azure region
- a globally unique storage account name for the chosen region

## Recommended workflow

1. Copy [infra/main.sample.bicepparam](infra/main.sample.bicepparam) to a region-specific parameter file.
2. Replace placeholder resource IDs with the selected existing VNet, subnet, or NIC resource IDs.
3. Run a subscription-scope `what-if` before any deployment.
4. Deploy the template only after the review output matches expectations.
5. Wait for flow data to accumulate.
6. Run the KQL queries in the `queries/` folder against the new workspace.
7. Review rule recommendations with networking and security stakeholders.
8. Populate [infra/firewall-policy-rules.sample.bicepparam](infra/firewall-policy-rules.sample.bicepparam) or the `firewallPolicyRuleCollectionGroups` parameter only after approval.
9. Run `what-if` again before applying approved rule collections.

## Copilot workshop workflow

Use this workflow when the customer environment already has flow logs and you want read-only analysis plus draft outputs.

### Prerequisites

Complete [prerequisites.md](prerequisites.md) before starting the workshop.

Required setup for the workshop:

- Azure CLI access in the customer environment
- Log Analytics query capability through `az monitor log-analytics query`
- a least-privilege read-only user or managed identity
- read access to the target tenant, its candidate subscriptions, and candidate Log Analytics workspaces
- permission to run Log Analytics queries
- if extension-backed or MCP-backed Azure tooling is used alongside Azure CLI, permission and visibility must exist in the same tenant and subscription context
- a full Azure logout and login reset before the workshop begins

### Recommended workshop sequence

1. Complete the logout and re-login reset from [prerequisites.md](prerequisites.md) and verify the intended read-only Azure identity.
2. Start with the prompts in [.github/prompts](.github/prompts).
3. Use tenant and region as the initial scope.
4. Reconcile Azure CLI context with any extension-backed or MCP-backed Azure tooling before trusting discovery or query results.
5. Let the discovery flow enumerate candidate subscriptions and recommend the best workspace based on coverage and freshness.
6. Run the lightweight discovery and coverage pass with a default `7d` lookback unless the customer explicitly overrides it.
7. Choose either `dynamic discovery` or `predefined VNet scope`.
8. Confirm the intended VNet scope and detailed analysis timeframe.
9. Validate the evidence source for each confirmed VNet, classifying it as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`, then narrow the analysis scope to the covered VNets if any are missing.
10. If a requested hub, transit, or shared-services VNet is uncovered, stop the full production-scope draft unless the customer narrows scope or explicitly accepts a partial review-only output.
11. Keep Azure activity read-only during discovery.
12. Ask once before creating local request artifacts.
13. Write review-only outputs under `requests/<datetime>/`.
14. If the customer asks to capture substantive workflow results in the request folder, create `output-log-<region>.md` alongside the other approved artifacts.
15. If the customer asks for an optional all-covered-VNet diagram, create `traffic-flow-diagram-<region>.md` as a separate review-only artifact.
16. Export the authoritative analyzed subnet CIDR manifest from Azure resource inventory into `requests/<datetime>/query-results/subnet-cidrs.json` before finalizing the firewall draft, and use that saved file for subnet placeholder replacement.

The workshop supports standard timeframe choices such as `7d`, `14d`, `30d`, `60d`, and `90d`, plus custom KQL-compatible duration values when needed.

If some confirmed VNets do not show usable observed coverage in the selected workspace, the workflow should continue only for the covered VNets and record the uncovered VNets as exclusions that still need customer follow-up.

If some covered VNets are backed only by NSG flow logs, the workflow should preserve that lower-confidence fallback status explicitly in the outputs instead of blending it with VNet-backed evidence.

If the customer wants a traffic-flow diagram, the diagram may summarize all confirmed covered VNets, but the downstream rule evidence and exclusions must remain explicit per VNet.

If the selected workspace schema differs from the reusable KQL templates, adapt the queries with schema-safe expressions such as `column_ifexists(...)` and record that adaptation in the review output.

### Query selection guidance

Use the queries by category so large workspaces stay on the per-VNet path once coverage is confirmed.

Discovery and coverage:

- [queries/workspace-flow-log-coverage.kql](queries/workspace-flow-log-coverage.kql)
- [queries/workspace-flow-log-freshness.kql](queries/workspace-flow-log-freshness.kql)
- [queries/workspace-vnet-flow-log-targets.kql](queries/workspace-vnet-flow-log-targets.kql)
- [queries/verify-vnet-flow-log-coverage.kql](queries/verify-vnet-flow-log-coverage.kql)
- [queries/verify-vnet-evidence-source.kql](queries/verify-vnet-evidence-source.kql)

To avoid pushing large inline KQL strings through the terminal, run the query files through [scripts/Run-LogAnalyticsQuery.ps1](scripts/Run-LogAnalyticsQuery.ps1). It writes the rendered query and the JSON result to local files so the workshop output remains reproducible and easier to review.

Once the analyzed subnet set is known from the per-VNet outputs, export the CIDR manifest from Azure resource inventory with [scripts/Export-AnalyzedSubnetCidrs.ps1](scripts/Export-AnalyzedSubnetCidrs.ps1) so the run persists `query-results/subnet-cidrs.json` inside the same request folder. Use [scripts/Update-FirewallDraftFromSubnetCidrs.ps1](scripts/Update-FirewallDraftFromSubnetCidrs.ps1) to consume that saved manifest when replacing draft subnet placeholders.

Per-VNet internal, egress, exposure, and rule analysis:

- [queries/region-internal-traffic-summary.kql](queries/region-internal-traffic-summary.kql) run once per covered VNet or scope fragment
- [queries/region-egress-and-exposure-summary.kql](queries/region-egress-and-exposure-summary.kql) run once per covered VNet or scope fragment
- [queries/recommended-rules-by-vnet.kql](queries/recommended-rules-by-vnet.kql)
- [queries/rule-candidates-summary.kql](queries/rule-candidates-summary.kql) only after the scope is narrowed

Optional diagram or high-level reviewer summaries:

- [queries/region-internal-traffic-summary.kql](queries/region-internal-traffic-summary.kql) when intentionally aggregated for a traffic-flow diagram
- [queries/region-egress-and-exposure-summary.kql](queries/region-egress-and-exposure-summary.kql) when intentionally aggregated for a traffic-flow diagram

### Expected local outputs

- `traffic-summary-<region>.md`
- `output-log-<region>.md` when output capture is requested
- `traffic-flow-diagram-<region>.md` when a diagram is requested
- `validation-questions-<region>.md`
- `firewall-rules-draft-<region>.bicepparam`
- `query-results/subnet-cidrs.json`
- optional `remediation-commands-<region>.md`

These artifacts are draft-only and must still go through the documented approval process before any Bicep deployment.

Before trusting any agent-generated draft as a production review artifact, run the checks in [production-dry-run-checklist.md](production-dry-run-checklist.md).

If the customer explicitly asks for remediation guidance after the workshop, use [.github/prompts/11-generate-remediation-commands.prompt.md](.github/prompts/11-generate-remediation-commands.prompt.md) to generate review-only CLI commands. Do not execute them as part of the workshop.

## Validation checklist

- Log Analytics workspace exists
- storage account exists in the same region as the target resources
- flow log resources exist in `NetworkWatcherRG`
- Traffic Analytics is enabled for every flow log
- `NTARuleRecommendation` data appears in Log Analytics after traffic has been processed
- Azure Firewall Policy exists with empty or approved-only rule collections

## Rollback guidance

- disable or remove the flow log resources if data collection is no longer required
- keep the storage account until retention requirements are satisfied
- do not delete approved firewall rule history without change-management review
