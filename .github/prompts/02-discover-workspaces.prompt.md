---
name: "02 Discover Workspaces"
description: "Discover candidate Log Analytics workspaces for a tenant and region, then recommend which workspace to use for Azure Firewall flow-log analysis."
argument-hint: "Provide the tenant and target region, plus any known VNet scope hints."
agent: "Discovery"
---
Discover candidate Log Analytics workspaces for the provided tenant and region.

Use these rules:

1. Prefer virtual network flow logs over NSG flow logs.
2. If Azure CLI and any extension-backed or MCP-backed Azure tooling are both used, reconcile their tenant and subscription context before evaluating results.
3. Enumerate candidate subscriptions in scope before evaluating workspaces.
4. Evaluate freshness and coverage before recommending a workspace.
5. If evidence is split, recommend a primary workspace and list secondary candidates.
6. For the recommended workspace, propose the candidate VNets or resource scopes observed for the requested region.
7. Note whether each proposed VNet appears to have VNet flow-log evidence, NSG-only evidence, mixed evidence, or no evidence yet.
8. Keep the result concise and evidence-based.
9. End with the exact follow-up question needed to confirm the intended VNet scope and analysis timeframe.

Use [queries/workspace-flow-log-coverage.kql](../../queries/workspace-flow-log-coverage.kql) and [queries/workspace-flow-log-freshness.kql](../../queries/workspace-flow-log-freshness.kql) as the reusable query contracts.
If a query fails because a workspace schema differs from the template, rerun it with schema-safe equivalents and record that adaptation.