# Copilot workshop prompt library

Use these prompts in order for customer workshops that analyze existing Azure flow logs and generate review-only Azure Firewall infrastructure-as-code drafts.

## Quick Start

- Complete [prerequisites.md](../../prerequisites.md) before running the prompt flow.
- Start the workflow with natural language such as `start` or `start the Azure Firewall workshop`, or use `/01-start-workshop` when you want the explicit prompt entry point.
- The startup flow first checks Azure sign-in state, confirms the tenant, and asks whether the customer wants to provide a specific Log Analytics workspace or discover candidate workspaces.
- Workspace discovery then identifies which candidate workspaces appear to contain relevant VNet flow-log evidence and asks the customer to choose one before scope confirmation begins.
- After workspace selection, the workflow runs a lightweight 7-day discovery and coverage pass, then branches into either `dynamic discovery` or `predefined VNet scope` before detailed traffic analysis begins.

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
- Startup should check Azure sign-in state first, confirm the tenant next, and treat region as a later detail unless it is needed to disambiguate candidate workspaces or downstream analysis.
- Prefer virtual network flow logs over NSG flow logs when both are present.
- If different VNets are backed by different log sources, classify each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` and preserve that classification through the workflow.
- Discovery must identify which candidate workspaces appear to contain the relevant VNet flow-log evidence, ask the customer to choose the workspace to analyze, then run a lightweight 7-day coverage pass and ask the customer to choose either `dynamic discovery` or `predefined VNet scope` before the final VNet scope is confirmed.
- If any confirmed VNet lacks observed usable coverage in the selected workspace, continue only for covered VNets and list the uncovered VNets as explicit exclusions.
- If an uncovered VNet is a hub, transit, or shared-services VNet in the requested production scope, treat that as a blocking gap for a full-scope draft unless the customer narrows scope or accepts a partial review-only output.
- If a reusable query fails due to workspace schema drift, rerun it with schema-safe expressions and record the adaptation in the summary.
- Detailed internal, egress, exposure, and rule analysis should run once per covered VNet or equivalent scope fragment, not as one blended workspace-wide run.
- A traffic-flow diagram may cover all confirmed covered VNets, but rule evidence and exclusions must remain explicit per VNet.
- Remediation or enablement commands are outside the default workshop flow and may be generated only as an explicit post-workshop, review-only artifact.
- If a prompt or instruction gap is found during execution, report recommendation-only workflow improvements and do not self-edit the repo during the active workshop.
- Ask once before creating local request artifacts.
- Keep all outputs under `requests/<datetime>/`.
- Treat every output as review-only until explicitly approved.
- Treat firewall draft outputs as local IaC artifacts only. They must not create, modify, or deploy live Azure Firewall rules automatically.

## Discovery handoff

- `/02-discover-workspaces` should end by asking the exact follow-up question that makes the customer choose the workspace for the rest of the analysis.
- `/03-confirm-workspace-and-scope` is the hard handoff gate after workspace selection and should return the chosen scope mode, the confirmed timeframe, evidence source by VNet, covered VNets, excluded VNets, and any remaining gaps before prompts 04 and 05 are used.
- `/04-analyze-internal-traffic` and `/05-analyze-egress-and-exposure` should keep `scopeHint` explicit by running once per covered VNet or equivalent resource scope fragment when more than one covered VNet remains, and the returned analysis should stay segmented by that explicit scope.
- `/09-generate-firewall-draft` should synthesize one aggregated review-only draft from the per-VNet analysis outputs and carry forward any lower-confidence or unresolved items explicitly.
- Request artifacts should persist the confirmed VNet scope, evidence source by VNet, covered VNets, and uncovered VNets rather than relying on chat context only.
- If output capture is requested, the drafting flow should also create `output-log-<region>.md` with substantive workflow outputs only, not the raw user prompts.

## Query roles

Use the KQL files by role so large workspaces stay on the per-VNet path after coverage is confirmed.

### Discovery and coverage

- [queries/workspace-flow-log-coverage.kql](../../queries/workspace-flow-log-coverage.kql)
- [queries/workspace-flow-log-freshness.kql](../../queries/workspace-flow-log-freshness.kql)
- [queries/verify-vnet-flow-log-coverage.kql](../../queries/verify-vnet-flow-log-coverage.kql)
- [queries/verify-vnet-evidence-source.kql](../../queries/verify-vnet-evidence-source.kql)
- [queries/existing-flow-logs-discovery.kql](../../queries/existing-flow-logs-discovery.kql)

### Per-VNet analysis

- [queries/region-internal-traffic-summary.kql](../../queries/region-internal-traffic-summary.kql) when run once per covered VNet or scope fragment
- [queries/region-egress-and-exposure-summary.kql](../../queries/region-egress-and-exposure-summary.kql) when run once per covered VNet or scope fragment
- [queries/recommended-rules-by-vnet.kql](../../queries/recommended-rules-by-vnet.kql)
- [queries/rule-candidates-summary.kql](../../queries/rule-candidates-summary.kql) after the scope is narrowed
- [queries/existing-east-west-candidates.kql](../../queries/existing-east-west-candidates.kql)
- [queries/existing-internet-egress-candidates.kql](../../queries/existing-internet-egress-candidates.kql)
- [queries/existing-inbound-exposure-candidates.kql](../../queries/existing-inbound-exposure-candidates.kql)
- [queries/existing-recommended-rules.kql](../../queries/existing-recommended-rules.kql)

### Optional all-VNet diagram or reviewer summary inputs

- [queries/region-internal-traffic-summary.kql](../../queries/region-internal-traffic-summary.kql) when intentionally summarized across all covered VNets for a traffic-flow diagram
- [queries/region-egress-and-exposure-summary.kql](../../queries/region-egress-and-exposure-summary.kql) when intentionally summarized across all covered VNets for a traffic-flow diagram

## Output contract

- `traffic-summary-<region>.md`
- `output-log-<region>.md` when output capture is requested
- `validation-questions-<region>.md`
- `firewall-rules-draft-<region>.bicepparam`
- `firewall-rules-draft-<region>.bicepparam` - review-only IaC draft only
- Optional: `remediation-commands-<region>.md`
- Optional: `discovery-summary-<region>.md`