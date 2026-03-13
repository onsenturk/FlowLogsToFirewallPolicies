---
name: "01 Start Workshop"
description: "Start an Azure Firewall flow-log workshop by locking customer intent, tenant, region, and read-only guardrails."
argument-hint: "Describe the customer request, Azure tenant, target region, and any known timeframe or VNet focus."
agent: "Discovery"
---
Start the Azure Firewall workshop.

Use the chat input as the customer goal and do all of the following:

1. Restate the goal as a read-only workshop objective.
2. Confirm the Azure tenant and target region.
3. State that Azure CLI with managed identity is the expected authentication model.
4. State that if any non-CLI Azure tooling is used, its tenant and subscription context must be reconciled with Azure CLI before discovery results are trusted.
5. State that no Azure resource changes or firewall deployments are allowed in this workflow.
6. State that discovery will enumerate candidate subscriptions and workspaces inside the tenant before analysis.
7. State that discovery will propose candidate VNets, ask for the analysis timeframe, and classify each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` before traffic findings are summarized.
8. State that remediation or enablement CLI commands are optional post-workshop guidance only and are not part of the default read-only flow.