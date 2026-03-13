---
description: "Use when running Azure Firewall traffic discovery workshops, analyzing flow logs in Log Analytics, recommending workspaces by region, or drafting review-only Azure Firewall outputs. Covers managed identity, read-only discovery, Germany and West Europe regional analysis, and confirmation-gated request artifacts."
name: "Azure Firewall Workshop Guardrails"
---

# Azure Firewall Workshop Guardrails

- Treat customer workshop execution as read-only Azure discovery unless the user explicitly asks to create local draft artifacts.
- Use Azure CLI authentication with managed identity in the customer environment. Do not introduce service principals, client secrets, or connection strings.
- If the workflow uses any non-CLI Azure tooling such as extension-backed or MCP-backed queries, first verify that its tenant and subscription context match Azure CLI. Treat any mismatch as a blocking issue until the context is reconciled.
- Start from tenant and region. Discover candidate subscriptions and Log Analytics workspaces first, then recommend which workspace to use based on flow-log evidence, freshness, and coverage.
- Prefer virtual network flow logs over NSG flow logs when both exist.
- When different VNets are backed by different log sources, treat virtual network flow logs as the primary source and NSG flow logs as fallback only for the VNets that lack usable VNet evidence.
- Before traffic analysis begins, propose the candidate VNets observed in the recommended workspace for the requested region, confirm the intended VNet scope, ask for the analysis timeframe, and validate the evidence source for each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`.
- If any confirmed VNet lacks observed usable coverage in the selected workspace, continue only for VNets classified as `VNetFlowLogs` or `NSGFlowLogsFallback` and list `Uncovered` VNets as explicit exclusions and unresolved gaps.
- If the requested production scope includes a hub, transit, shared-services, or otherwise central VNet and that VNet lacks observed coverage, do not generate a full-scope firewall draft unless the customer explicitly narrows the scope or accepts a partial review-only draft.
- If a reusable KQL contract fails because a workspace schema differs from the template, adapt the query with schema-safe expressions such as `column_ifexists(...)`, record that adaptation as an assumption or workflow gap, and avoid presenting the failed template as authoritative.
- Do not deploy Bicep, modify Azure resources, or suggest running deployment commands during the workshop flow.
- Do not generate enablement or remediation commands during the default workshop flow. Only generate review-only CLI remediation guidance if the customer explicitly asks for it after the analysis findings are complete.
- Ask once for confirmation before creating `requests/<datetime>/` and any draft artifacts for that request.
- Keep generated files review-only and approval-pending.
- If a prompt or instruction gap is discovered during workshop execution, document the issue and recommend changes for future runs. Do not self-edit prompts or instructions during the active customer workshop.
- Separate evidence, assumptions, recommendations, and unresolved questions in every summary.
- Align any firewall draft output with [infra/firewall-policy-rules.sample.bicepparam](../../infra/firewall-policy-rules.sample.bicepparam).
- Reuse [firewall-policy-rules.md](../../firewall-policy-rules.md) and [simplified-traffic-flows.md](../../simplified-traffic-flows.md) as the customer-review contract.

## Required Workflow

1. Confirm the customer goal, target tenant, and target region.
2. Discover candidate subscriptions and Log Analytics workspaces for that region.
3. Recommend a primary workspace, record any secondary candidates, and propose the candidate VNets seen in that workspace for the requested region.
4. Confirm the intended VNet scope, capture the analysis timeframe, and validate the evidence source for each confirmed VNet.
5. Validate freshness before analyzing traffic.
6. Analyze internal traffic, egress, and inbound exposure for the covered VNets only, keeping the evidence explicit per covered VNet or equivalent resource scope fragment and preserving whether that evidence came from `VNetFlowLogs` or `NSGFlowLogsFallback`.
7. Ask once for confirmation before creating local request outputs.
8. Write review-only artifacts under `requests/<datetime>/`, and persist the confirmed VNet scope, per-VNet evidence source, covered VNets, uncovered VNets, and material workflow outputs in the request artifacts.

## Output Contract

- `traffic-summary-<region>.md` - must persist the confirmed VNet scope, per-VNet evidence source, covered VNets, and uncovered VNets
- `output-log-<region>.md` - should capture material workflow outputs such as discovery results, classifications, exclusions, and created artifacts without logging the user prompts verbatim
- `validation-questions-<region>.md` - should include follow-up questions for uncovered VNets or coverage gaps
- `firewall-rules-draft-<region>.bicepparam`
- Optional: `remediation-commands-<region>.md`
- Optional: `discovery-summary-<region>.md`

Do not treat generated rule content as approved for deployment.