---
name: "01 Start Workshop"
description: "Start an Azure Firewall flow-log workshop by validating Azure access, confirming tenant, choosing a workspace path, and locking the read-only guardrails."
argument-hint: "Describe the customer request, Azure tenant if known, whether a workspace is already known, and any known timeframe or VNet focus."
agent: "Discovery"
---
Start the Azure Firewall workshop.

Use the chat input as the customer goal and do all of the following:

1. Restate the goal as a read-only workshop objective.
2. Ask whether the operator completed [prerequisites.md](../../prerequisites.md), including the full `az logout` and re-login reset.
3. Confirm that the active Azure identity is a least-privilege read-only user or managed identity, and stop if that is not true.
4. Ask whether the user is currently signed into Azure and stop for authentication if they are not.
5. Confirm which Azure tenant the analysis should run against. If the user may have access to multiple tenants, require an explicit tenant choice before discovery continues.
6. State that Azure CLI is the required authentication path and that managed identity is preferred when it is available in the customer environment.
7. State that if any non-CLI Azure tooling is used, its tenant and subscription context must be reconciled with Azure CLI before discovery results are trusted.
8. State that no Azure resource changes or firewall deployments are allowed in this workflow.
9. Ask the user to choose one of these two startup paths:
	- provide a specific Log Analytics workspace
	- discover candidate Log Analytics workspaces in the selected tenant
10. If the user wants to provide a workspace, ask for the workspace name or resource ID and continue with workspace validation.
11. If the user wants discovery, explain that subscriptions can be discovered as part of the workflow and that region can be narrowed later if needed.
12. State that discovery will enumerate candidate subscriptions and workspaces inside the selected tenant, identify which workspaces appear to contain relevant VNet flow-log evidence, and ask the customer to choose the workspace to analyze before scope confirmation begins.
13. State that after workspace selection, the workflow will confirm the analysis timeframe, validate freshness, and classify each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` before traffic findings are summarized.
14. State that remediation or enablement CLI commands are optional post-workshop guidance only and are not part of the default read-only flow.