---
name: "11 Generate Remediation Commands"
description: "Generate review-only Azure CLI commands to enable VNet flow logs to a chosen Log Analytics workspace after the customer explicitly asks for remediation guidance."
argument-hint: "Provide the target region, chosen workspace, target VNet resources, and confirmation that the customer explicitly requested remediation commands."
agent: "Drafting"
---
Generate a review-only remediation artifact with Azure CLI commands to enable VNet flow logs to a chosen Log Analytics workspace.

Use this prompt only after the default read-only workshop flow is complete and only when the customer explicitly asks for remediation guidance.

Requirements:

1. File name: `remediation-commands-<region>.md`
2. Keep the commands review-only and not executed.
3. State that customer testing, approval, and change-management review are required before execution.
4. Generate commands only for enabling VNet flow logs and related workspace wiring. Do not generate deployment commands for firewall rules.
5. If the customer environment still relies on NSG-only evidence, prefer remediation commands that move the environment toward VNet flow logs rather than creating new NSG flow logs.
6. Include assumptions, required placeholders, and any permissions the operator needs.