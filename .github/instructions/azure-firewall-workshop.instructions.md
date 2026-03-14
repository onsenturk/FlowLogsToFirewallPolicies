---
description: "Use when running Azure Firewall traffic discovery workshops, analyzing flow logs in Log Analytics, recommending workspaces by region, or drafting review-only Azure Firewall outputs. Covers managed identity, read-only discovery, Germany and West Europe regional analysis, and confirmation-gated request artifacts."
name: "Azure Firewall Workshop Guardrails"
---

# Azure Firewall Workshop Guardrails

- Treat customer workshop execution as read-only Azure discovery unless the user explicitly asks to create local draft artifacts.
- Use Azure CLI authentication with managed identity in the customer environment. Do not introduce service principals, client secrets, or connection strings.
- If the workflow uses any non-CLI Azure tooling such as extension-backed or MCP-backed queries, first verify that its tenant and subscription context match Azure CLI. Treat any mismatch as a blocking issue until the context is reconciled.
- Start from Azure sign-in state and tenant. Discover candidate subscriptions and Log Analytics workspaces first, then recommend which workspace to use based on flow-log evidence, freshness, and coverage. Confirm region later only when it is needed to disambiguate workspaces, interpret evidence, or name artifacts.
- Prefer virtual network flow logs over NSG flow logs when both exist.
- When different VNets are backed by different log sources, treat virtual network flow logs as the primary source and NSG flow logs as fallback only for the VNets that lack usable VNet evidence.
- Before traffic analysis begins, identify which candidate workspaces appear to contain the relevant VNet flow-log evidence, have the customer choose the workspace to analyze, run a lightweight discovery and coverage pass with a default `7d` lookback unless the customer explicitly overrides it, ask the customer to choose either `dynamic discovery` or `predefined VNet scope`, confirm the intended VNet scope, ask for the detailed analysis timeframe, and validate the evidence source for each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`.
- If any confirmed VNet lacks observed usable coverage in the selected workspace, continue only for VNets classified as `VNetFlowLogs` or `NSGFlowLogsFallback` and list `Uncovered` VNets as explicit exclusions and unresolved gaps.
- If the requested production scope includes a hub, transit, shared-services, or otherwise central VNet and that VNet lacks observed coverage, do not generate a full-scope firewall draft unless the customer explicitly narrows the scope or accepts a partial review-only draft.
- If a reusable KQL contract fails because a workspace schema differs from the template, adapt the query with schema-safe expressions such as `column_ifexists(...)`, record that adaptation as an assumption or workflow gap, and avoid presenting the failed template as authoritative.
- Do not deploy Bicep, modify Azure resources, or suggest running deployment commands during the workshop flow.
- Do not create or modify live Azure Firewall rule collections during the workshop flow. Firewall outputs must remain review-only infrastructure-as-code drafts until explicitly approved and deployed outside the workshop.
- Do not generate enablement or remediation commands during the default workshop flow. Only generate review-only CLI remediation guidance if the customer explicitly asks for it after the analysis findings are complete.
- Ask once for confirmation before creating `requests/<datetime>/` and any draft artifacts for that request.
- Keep generated files review-only and approval-pending.
- If a prompt or instruction gap is discovered during workshop execution, document the issue and recommend changes for future runs. Do not self-edit prompts or instructions during the active customer workshop.
- Separate evidence, assumptions, recommendations, and unresolved questions in every summary.
- Align any firewall draft output with [infra/firewall-policy-rules.sample.bicepparam](../../infra/firewall-policy-rules.sample.bicepparam).
- Reuse [firewall-policy-rules.md](../../firewall-policy-rules.md) and [simplified-traffic-flows.md](../../simplified-traffic-flows.md) as the customer-review contract.

## Required Workflow

1. Confirm the customer goal, Azure sign-in state, and target tenant.
2. Determine whether the customer wants to provide a specific Log Analytics workspace or discover candidate workspaces.
3. Discover candidate subscriptions and Log Analytics workspaces for the selected tenant when discovery is needed.
4. Recommend a primary workspace, record any secondary candidates, identify which workspaces appear to contain relevant VNet flow-log evidence, and have the customer choose the workspace to analyze.
5. Confirm region only if it is still needed, run the lightweight discovery and coverage pass, confirm the chosen scope mode, then confirm the intended VNet scope, capture the analysis timeframe, and validate the evidence source for each confirmed VNet.
6. Validate freshness before analyzing traffic.
7. Analyze internal traffic, egress, and inbound exposure for the covered VNets only, keeping the evidence explicit per covered VNet or equivalent resource scope fragment and preserving whether that evidence came from `VNetFlowLogs` or `NSGFlowLogsFallback`.
8. Treat any all-covered-VNet traffic diagram as a separate optional artifact and do not let it replace the per-VNet evidence contract for rules.
9. Ask once for confirmation before creating local request outputs.
10. Write review-only artifacts under `requests/<datetime>/`, persist the confirmed VNet scope, per-VNet evidence source, covered VNets, uncovered VNets, and material workflow outputs in the request artifacts, and keep the analyzed subnet CIDR manifest in the same request folder.

## Output Contract

- `traffic-summary-<region>.md` - must persist the confirmed VNet scope, per-VNet evidence source, covered VNets, and uncovered VNets
- `output-log-<region>.md` - should capture material workflow outputs such as discovery results, classifications, exclusions, and created artifacts without logging the user prompts verbatim
- `traffic-flow-diagram-<region>.md` - optional review-only diagram artifact that may summarize all confirmed covered VNets without replacing the per-VNet evidence contract
- `validation-questions-<region>.md` - should include follow-up questions for uncovered VNets or coverage gaps
- `firewall-rules-draft-<region>.bicepparam` - review-only infrastructure-as-code draft, never a live rule change
- `query-results/subnet-cidrs.json` - read-only subnet CIDR manifest exported from Azure resource inventory for the analyzed subnets
- Optional: `remediation-commands-<region>.md`
- Optional: `discovery-summary-<region>.md`

Do not treat generated rule content as approved for deployment.