---
name: "02 Discover Workspaces"
description: "Discover candidate Log Analytics workspaces for a tenant, identify which appear to contain VNet flow-log evidence, and ask the customer to choose a workspace for Azure Firewall flow-log analysis."
argument-hint: "Provide the tenant, any known workspace or subscription hints, and any known VNet scope hints."
agent: "Discovery"
---
Discover candidate Log Analytics workspaces for the provided tenant.

Use these rules:

1. Prefer virtual network flow logs over NSG flow logs.
2. If Azure CLI and any extension-backed or MCP-backed Azure tooling are both used, reconcile their tenant and subscription context before evaluating results.
3. Enumerate candidate subscriptions in scope before evaluating workspaces.
4. Group candidate workspaces in whatever way best helps the customer choose, such as by subscription or region, but do not require region as an input if it is not yet known.
5. Evaluate freshness and coverage before recommending a workspace.
6. If evidence is split, recommend a primary workspace and list secondary candidates.
7. Explicitly identify which candidate workspaces appear to contain VNet flow-log evidence, which appear to have only NSG-based fallback evidence, and which do not yet show usable evidence.
8. For the recommended workspace, propose the candidate VNets or resource scopes observed for the relevant evidence set.
9. Keep the result concise and evidence-based.
10. End with the exact customer question that asks the user to choose which candidate workspace should be used for the rest of the analysis.

Use [queries/workspace-flow-log-coverage.kql](../../queries/workspace-flow-log-coverage.kql) and [queries/workspace-flow-log-freshness.kql](../../queries/workspace-flow-log-freshness.kql) as the reusable query contracts.
If a query fails because a workspace schema differs from the template, rerun it with schema-safe equivalents and record that adaptation.