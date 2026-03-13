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

- Azure CLI access in the customer environment
- managed identity available for `az login --identity`
- read access to the target tenant, its candidate subscriptions, and candidate Log Analytics workspaces
- permission to run Log Analytics queries
- if extension-backed or MCP-backed Azure tooling is used alongside Azure CLI, permission and visibility must exist in the same tenant and subscription context

### Recommended workshop sequence

1. Start with the prompts in [.github/prompts](.github/prompts).
2. Use tenant and region as the initial scope.
3. Reconcile Azure CLI context with any extension-backed or MCP-backed Azure tooling before trusting discovery or query results.
4. Let the discovery flow enumerate candidate subscriptions, recommend the best workspace based on coverage and freshness, and propose the candidate VNets observed for that region.
5. Confirm the intended VNet scope and analysis timeframe.
6. Validate the evidence source for each confirmed VNet, classifying it as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`, then narrow the analysis scope to the covered VNets if any are missing.
7. If a requested hub, transit, or shared-services VNet is uncovered, stop the full production-scope draft unless the customer narrows scope or explicitly accepts a partial review-only output.
8. Keep Azure activity read-only during discovery.
9. Ask once before creating local request artifacts.
10. Write review-only outputs under `requests/<datetime>/`.
11. If the customer asks to capture substantive workflow results in the request folder, create `output-log-<region>.md` alongside the other approved artifacts.

The workshop supports standard timeframe choices such as `7d`, `14d`, `30d`, `60d`, and `90d`, plus custom KQL-compatible duration values when needed.

If some confirmed VNets do not show usable observed coverage in the selected workspace, the workflow should continue only for the covered VNets and record the uncovered VNets as exclusions that still need customer follow-up.

If some covered VNets are backed only by NSG flow logs, the workflow should preserve that lower-confidence fallback status explicitly in the outputs instead of blending it with VNet-backed evidence.

If the selected workspace schema differs from the reusable KQL templates, adapt the queries with schema-safe expressions such as `column_ifexists(...)` and record that adaptation in the review output.

### Expected local outputs

- `traffic-summary-<region>.md`
- `output-log-<region>.md` when output capture is requested
- `validation-questions-<region>.md`
- `firewall-rules-draft-<region>.bicepparam`
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
