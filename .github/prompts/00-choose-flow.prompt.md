---
name: "00 Choose Flow"
description: "Let the user choose between providing a known Log Analytics workspace, tenant, and subscription directly (predefined flow) or letting the agent discover candidate workspaces dynamically."
argument-hint: "Optionally describe the customer environment — include any known workspace name, tenant ID, or subscription ID."
agent: "Discovery"
---
Welcome to the Azure Firewall flow-log workshop.

Before discovery begins, confirm which startup path the customer wants to use:

**Path A — Predefined flow (I already know my workspace)**

Use this path when the workspace, tenant, and subscription are already known.

Ask the customer to provide all of the following:

1. Azure tenant ID or display name.
2. Azure subscription ID or name where the Log Analytics workspace lives.
3. Log Analytics workspace name or full resource ID.
4. Preferred analysis timeframe (`7d`, `14d`, `30d`, `60d`, `90d`, or a custom KQL duration such as `21d`).

Once those inputs are confirmed, skip workspace discovery and proceed directly to `/03-confirm-workspace-and-scope` to validate freshness, classify VNet evidence sources, and confirm scope before traffic analysis starts.

**Path B — Dynamic discovery (let the agent find candidate workspaces)**

Use this path when the workspace is not yet known or when the customer wants to review all candidate workspaces across the tenant before choosing one.

Ask the customer to provide:

1. Azure tenant ID or display name.
2. Any known subscription hints (optional).
3. Any known VNet or region hints (optional).

Once those inputs are confirmed, proceed to `/02-discover-workspaces` to enumerate candidate subscriptions, identify workspaces that appear to contain VNet flow-log evidence, and ask the customer to choose the workspace before scope confirmation begins.

---

Rules that apply to both paths:

- State that Azure CLI with managed identity is the expected authentication model.
- If any non-CLI Azure tooling is also in use, its tenant and subscription context must be reconciled with Azure CLI before discovery results are trusted.
- State that no Azure resource changes or firewall deployments happen in this workflow.
- Confirm Azure sign-in state before continuing. Stop for authentication if the customer is not yet signed in.
- All outputs remain review-only until explicitly approved.
