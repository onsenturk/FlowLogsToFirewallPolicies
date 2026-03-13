# Copilot workshop prompt library

Use these prompts in order for customer workshops that analyze existing Azure flow logs and generate review-only Azure Firewall drafts.

## Execution order

1. `/01-start-workshop`
2. `/02-discover-workspaces`
3. `/03-confirm-workspace-and-scope`
4. `/04-analyze-internal-traffic`
5. `/05-analyze-egress-and-exposure`
6. `/06-generate-customer-questions`
7. `/07-confirm-output-creation`
8. `/08-create-traffic-summary`
9. `/08a-create-output-log` when the user wants a review-only record of material workflow outputs inside the request folder
10. `/09-generate-firewall-draft`
11. `/10-close-workshop`

Optional post-workshop step:

12. `/11-generate-remediation-commands` only when the customer explicitly asks for review-only CLI commands to enable VNet flow logs to a chosen workspace

## Guardrails

- Discovery is read-only and tenant-scoped by default.
- Use managed identity with Azure CLI in customer environments.
- If Azure CLI and any extension-backed or MCP-backed Azure tooling are both used, validate that they point to the same tenant and subscription before trusting discovery or query results.
- Prefer virtual network flow logs over NSG flow logs when both are present.
- If different VNets are backed by different log sources, classify each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` and preserve that classification through the workflow.
- Discovery must propose the candidate VNets, confirm the intended VNet scope, and capture the analysis timeframe before traffic analysis starts.
- If any confirmed VNet lacks observed usable coverage in the selected workspace, continue only for covered VNets and list the uncovered VNets as explicit exclusions.
- If an uncovered VNet is a hub, transit, or shared-services VNet in the requested production scope, treat that as a blocking gap for a full-scope draft unless the customer narrows scope or accepts a partial review-only output.
- If a reusable query fails due to workspace schema drift, rerun it with schema-safe expressions and record the adaptation in the summary.
- Remediation or enablement commands are outside the default workshop flow and may be generated only as an explicit post-workshop, review-only artifact.
- If a prompt or instruction gap is found during execution, report recommendation-only workflow improvements and do not self-edit the repo during the active workshop.
- Ask once before creating local request artifacts.
- Keep all outputs under `requests/<datetime>/`.
- Treat every output as review-only until explicitly approved.

## Discovery handoff

- `/02-discover-workspaces` should end by asking the exact follow-up question needed to confirm the VNet scope and timeframe.
- `/03-confirm-workspace-and-scope` is the hard handoff gate and should return the confirmed timeframe, evidence source by VNet, covered VNets, excluded VNets, and any remaining gaps before prompts 04 and 05 are used.
- `/04-analyze-internal-traffic` and `/05-analyze-egress-and-exposure` should keep `scopeHint` explicit by running once per covered VNet or equivalent resource scope fragment when more than one covered VNet remains, and the returned analysis should stay segmented by that explicit scope.
- Request artifacts should persist the confirmed VNet scope, evidence source by VNet, covered VNets, and uncovered VNets rather than relying on chat context only.
- If output capture is requested, the drafting flow should also create `output-log-<region>.md` with substantive workflow outputs only, not the raw user prompts.

## Output contract

- `traffic-summary-<region>.md`
- `output-log-<region>.md` when output capture is requested
- `validation-questions-<region>.md`
- `firewall-rules-draft-<region>.bicepparam`
- Optional: `remediation-commands-<region>.md`
- Optional: `discovery-summary-<region>.md`