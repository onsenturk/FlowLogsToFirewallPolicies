# Copilot workshop prompt library

Use these prompts in order for customer workshops that analyze existing Azure flow logs and generate review-only Azure Firewall infrastructure-as-code drafts.

## Quick Start

- Start the workflow with natural language such as `start` or `start the Azure Firewall workshop`, or use `/00-choose-flow` to explicitly select between providing a known workspace or running dynamic discovery.
- The startup flow first checks Azure sign-in state, confirms the tenant, and asks whether the customer wants to provide a specific Log Analytics workspace (predefined flow) or discover candidate workspaces dynamically.
- Workspace discovery then identifies which candidate workspaces appear to contain relevant VNet flow-log evidence and asks the customer to choose one before scope confirmation begins.

## Execution order

1. `/00-choose-flow` — choose predefined (workspace already known) or dynamic discovery
2. `/01-start-workshop` — validate Azure access, confirm tenant, lock read-only guardrails
3. `/02-discover-workspaces` — only if dynamic discovery was chosen in step 1
4. `/03-confirm-workspace-and-scope`
5. `/04-analyze-internal-traffic`
6. `/05-analyze-egress-and-exposure`
7. `/05a-create-traffic-diagram` — optional Mermaid traffic flow diagram
8. `/05b-summarize-rules` — summarize candidate rules before generating the draft
9. `/06-generate-customer-questions`
10. `/07-confirm-output-creation`
11. `/08-create-traffic-summary`
12. `/08a-create-output-log` when the user wants a review-only record of material workflow outputs inside the request folder
13. `/09-generate-firewall-draft`
14. `/10-close-workshop`

Optional post-workshop step:

15. `/11-generate-remediation-commands` only when the customer explicitly asks for review-only CLI commands to enable VNet flow logs to a chosen workspace

## Predefined vs dynamic discovery

**Predefined flow** (`/00-choose-flow` → Path A):
- Use when the Log Analytics workspace, tenant, and subscription are already known.
- The customer provides workspace name or resource ID, tenant ID, subscription ID, and preferred analysis timeframe.
- Skips `/02-discover-workspaces` and goes directly to `/03-confirm-workspace-and-scope`.

**Dynamic discovery** (`/00-choose-flow` → Path B):
- Use when the workspace is not yet known or when reviewing all candidate workspaces is preferred.
- The customer provides only tenant ID and optional region or subscription hints.
- Runs the full discovery flow through `/02-discover-workspaces` before scope confirmation.

## Large environment guidance

All KQL analysis and rule-recommendation queries in this repository default to a `7d` lookback window. On large tenants a shorter initial window keeps query execution time manageable while still capturing recent flows. If results are sparse for a given VNet, re-run that query with `14d` then `30d` until the evidence is sufficient. The workflow uses this progressive time-window approach instead of hard row limits, so no flows between VNets are arbitrarily dropped.

If a query still returns few or no results after extending to `30d`, the affected VNet is recorded as having insufficient evidence and noted as an unresolved gap in the traffic summary and output log.

## Guardrails

- Discovery is read-only and tenant-scoped by default.
- Use managed identity with Azure CLI in customer environments.
- If Azure CLI and any extension-backed or MCP-backed Azure tooling are both used, validate that they point to the same tenant and subscription before trusting discovery or query results.
- Startup should check Azure sign-in state first, confirm the tenant next, and treat region as a later detail unless it is needed to disambiguate candidate workspaces or downstream analysis.
- Prefer virtual network flow logs over NSG flow logs when both are present.
- If different VNets are backed by different log sources, classify each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` and preserve that classification through the workflow.
- Discovery must identify which candidate workspaces appear to contain the relevant VNet flow-log evidence, ask the customer to choose the workspace to analyze, then propose the candidate VNets, confirm the intended VNet scope, and capture the analysis timeframe before traffic analysis starts.
- If any confirmed VNet lacks observed usable coverage in the selected workspace, continue only for covered VNets and list the uncovered VNets as explicit exclusions.
- If an uncovered VNet is a hub, transit, or shared-services VNet in the requested production scope, treat that as a blocking gap for a full-scope draft unless the customer narrows scope or accepts a partial review-only output.
- If a reusable query fails due to workspace schema drift, rerun it with schema-safe expressions and record the adaptation in the summary.
- Remediation or enablement commands are outside the default workshop flow and may be generated only as an explicit post-workshop, review-only artifact.
- If a prompt or instruction gap is found during execution, report recommendation-only workflow improvements and do not self-edit the repo during the active workshop.
- Ask once before creating local request artifacts.
- Keep all outputs under `requests/<datetime>/`.
- Treat every output as review-only until explicitly approved.
- Treat firewall draft outputs as local IaC artifacts only. They must not create, modify, or deploy live Azure Firewall rules automatically.

## Discovery handoff

- `/02-discover-workspaces` should end by asking the exact follow-up question that makes the customer choose the workspace for the rest of the analysis.
- `/03-confirm-workspace-and-scope` is the hard handoff gate after workspace selection and should return the confirmed timeframe, evidence source by VNet, covered VNets, excluded VNets, and any remaining gaps before prompts 04 and 05 are used.
- `/04-analyze-internal-traffic` and `/05-analyze-egress-and-exposure` should keep `scopeHint` explicit by running once per covered VNet or equivalent resource scope fragment when more than one covered VNet remains, and the returned analysis should stay segmented by that explicit scope.
- `/05b-summarize-rules` runs after analysis is complete and before output creation is confirmed. It produces the candidate rule set that feeds `/09-generate-firewall-draft`.
- Request artifacts should persist the confirmed VNet scope, evidence source by VNet, covered VNets, and uncovered VNets rather than relying on chat context only.
- If output capture is requested, the drafting flow should also create `output-log-<region>.md` with substantive workflow outputs only, not the raw user prompts.

## Output contract

- `traffic-summary-<region>.md`
- `output-log-<region>.md` when output capture is requested
- `validation-questions-<region>.md`
- `firewall-rules-draft-<region>.bicepparam` — review-only IaC draft only
- Optional: `traffic-diagram-<region>.md` when the customer requests a visual traffic summary
- Optional: `remediation-commands-<region>.md`
- Optional: `discovery-summary-<region>.md`