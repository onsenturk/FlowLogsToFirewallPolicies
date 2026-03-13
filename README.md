# Azure Firewall zero-trust traffic discovery

This repository provisions the observability resources needed to discover Azure traffic patterns before enforcing Azure Firewall rules.

Any firewall-rule output from the workshop remains a local, review-only infrastructure-as-code draft. The workflow does not create, populate, or deploy live Azure Firewall rule collections automatically.

## Why this repository uses virtual network flow logs

New NSG flow logs can no longer be created after June 30, 2025. Because of that Azure platform constraint, this repository uses virtual network flow logs instead of NSG flow logs for new deployments. The design still supports the original objective:

- create a new Log Analytics workspace
- enable flow logging on selected existing network resources
- analyze the observed traffic with Traffic Analytics
- prepare Azure Firewall policy rules in Bicep
- keep Firewall Policy rule changes out of production until explicit approval

## What this deployment creates

- one resource group for observability resources
- one Log Analytics workspace for Traffic Analytics
- one regional storage account for flow log blobs
- one Azure Firewall Policy with no approved rule collections by default
- one or more virtual network flow logs targeting existing VNets, subnets, or NICs in the same region

## Files

- [infra/main.bicep](infra/main.bicep) - subscription-scope deployment entry point
- [infra/main.sample.bicepparam](infra/main.sample.bicepparam) - sample parameter file
- [infra/modules/monitoring-stack.bicep](infra/modules/monitoring-stack.bicep) - shared monitoring resources
- [infra/modules/flow-log.bicep](infra/modules/flow-log.bicep) - regional virtual network flow log deployment
- [infra/firewall-policy-rules.sample.bicepparam](infra/firewall-policy-rules.sample.bicepparam) - approved-rule template only, used as the shape for review-only IaC drafts
- [queries/recommended-rules-by-vnet.kql](queries/recommended-rules-by-vnet.kql) - Traffic Analytics recommendation query
- [queries/rule-candidates-summary.kql](queries/rule-candidates-summary.kql) - summarized rule candidate query
- [queries/rule-summary-paginated.kql](queries/rule-summary-paginated.kql) - per-VNet rule summary query with progressive time windows; run once per covered VNet, start with `7d`, extend to `14d` then `30d` if results are sparse
- [queries/existing-flow-logs-discovery.kql](queries/existing-flow-logs-discovery.kql) - discovery query for the current tenant setup
- [queries/existing-recommended-rules.kql](queries/existing-recommended-rules.kql) - rule recommendations for the currently covered VNets
- [queries/existing-east-west-candidates.kql](queries/existing-east-west-candidates.kql) - east-west candidate flow analysis for the current VNets
- [queries/existing-internet-egress-candidates.kql](queries/existing-internet-egress-candidates.kql) - internet egress candidate analysis for the current VNets
- [queries/existing-inbound-exposure-candidates.kql](queries/existing-inbound-exposure-candidates.kql) - public inbound exposure review for the current VNets
- [.github/prompts/README.md](.github/prompts/README.md) - active GitHub Copilot prompt library for customer workshops
- [firewall-policy-rules.md](firewall-policy-rules.md) - approval workflow and rule documentation guidance
- [simplified-traffic-flows.md](simplified-traffic-flows.md) - simplified human review checklist for observed traffic flows
- [production-dry-run-checklist.md](production-dry-run-checklist.md) - operator checklist for validating a production workshop run before trusting an agent-generated firewall draft

## Current operating mode

The repository can still provision new observability resources, but the current tenant already has usable virtual network flow logs.

For the current analysis phase, use the documented existing environment in [azure.md](azure.md) and the `queries/existing-*.kql` files instead of creating duplicate flow logs.

Any customer-specific evidence and candidate rule sets should be kept in private request artifacts or private working branches. The public repository keeps only sanitized guidance and reusable query patterns.

When customer environments contain mixed evidence sources, this workflow treats VNet flow logs as the primary source and NSG flow logs as fallback only for VNets that lack usable VNet evidence. The workflow keeps that evidence source explicit per VNet instead of blending it into one regional summary.

## Copilot workshop workflow

This repository now includes a GitHub Copilot-first customer workshop workflow.

- repo-wide engineering governance remains in [.github/copilot-instructions.md](.github/copilot-instructions.md)
- Azure Firewall workshop guardrails live in [.github/instructions/azure-firewall-workshop.instructions.md](.github/instructions/azure-firewall-workshop.instructions.md)
- the specialized agents are [.github/agents/discovery.agent.md](.github/agents/discovery.agent.md) and [.github/agents/drafting.agent.md](.github/agents/drafting.agent.md)
- the active prompt entry points are in [.github/prompts](.github/prompts)

Use the workflow like this:

1. start with `/00-choose-flow` to select between predefined flow (workspace already known) and dynamic discovery; alternatively use natural language such as `start` or `/01-start-workshop`
2. **predefined flow** — provide the Log Analytics workspace name or resource ID, tenant ID, subscription ID, and preferred analysis timeframe, then skip to workspace validation
3. **dynamic discovery** — provide only the tenant ID and optional hints; let the workflow enumerate candidate subscriptions and workspaces
4. confirm Azure sign-in state and tenant before discovery begins
5. verify that Azure CLI and any extension-backed or MCP-backed Azure tooling are aligned to the same tenant and subscription before trusting discovery results
6. let the discovery flow enumerate candidate subscriptions, identify which candidate workspaces appear to contain relevant VNet flow-log evidence, and ask the customer to choose the workspace to analyze
7. confirm region only if it is still needed, then confirm the intended VNet scope and analysis timeframe, and validate the evidence source for each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`
8. if an uncovered VNet is a hub, transit, or shared-services VNet in the requested production scope, stop the full-scope draft unless the customer narrows scope or explicitly accepts a partial review-only output
9. validate freshness and analyze only the covered VNets, while carrying uncovered VNets forward as explicit exclusions
10. keep internal, egress, and exposure findings explicit per covered VNet or equivalent scope fragment rather than blending them into a single undifferentiated summary
11. optionally use `/05a-create-traffic-diagram` to produce a Mermaid traffic flow diagram from the discovered flows
12. use `/05b-summarize-rules` to produce a structured rule candidate summary before generating the firewall draft; this step runs once per covered VNet with a progressive time window (start at `7d`, extend to `14d` then `30d` if results are sparse)
13. if a reusable KQL query fails because of schema drift in the selected workspace, rerun it with schema-safe expressions and record that adaptation in the output
14. ask once before creating any local draft artifacts
15. write review-only outputs under `requests/<datetime>/`, persisting the confirmed VNet scope, covered VNets, uncovered VNets, and any requested material output log in the request artifacts

Optional post-workshop step:

16. if the customer explicitly asks for remediation guidance, generate a review-only `remediation-commands-<region>.md` artifact with Azure CLI commands to enable VNet flow logs to the chosen workspace

Supported analysis timeframes are the standard workshop choices `7d`, `14d`, `30d`, `60d`, and `90d`, plus custom KQL-compatible duration values such as `21d` when the customer requests a different lookback window.

The discovery flow now treats VNet flow-log coverage as a pre-analysis scope check. If a confirmed VNet is not observed in the selected workspace for the chosen window, the workflow does not claim full regional coverage. It continues only for the covered VNets and lists uncovered VNets as exclusions that still need customer follow-up.

If the workflow encounters a prompt or instruction gap during a workshop run, it should surface recommendation-only improvements for future runs instead of editing the repo during customer execution.

### Large environment guidance

All KQL analysis and rule-recommendation queries in this repository default to a `7d` lookback window. On large tenants, a shorter initial window keeps query execution time manageable while still capturing recent flows. If results are sparse for a given VNet, re-run that query with `14d` then `30d` until the evidence is sufficient. The workflow uses this progressive time-window approach instead of hard row limits, so no flows between VNets are arbitrarily dropped.

Queries are also run once per covered VNet (using the `scopeHint` variable or by setting a single VNet in `CoveredVnets`) rather than across all VNets in a single query, so that one busy VNet does not obscure findings for other VNets.

If a query still returns few or no results after extending to `30d`, the affected VNet is recorded as having insufficient evidence and noted as an unresolved gap in the traffic summary and output log.

Expected workshop outputs:

- `traffic-summary-<region>.md`
- `output-log-<region>.md` when the customer wants a concise record of material workflow outputs
- `validation-questions-<region>.md`
- `firewall-rules-draft-<region>.bicepparam` - review-only IaC draft only, not a deployed ruleset
- optional `traffic-diagram-<region>.md` when the customer requests a visual summary
- optional `remediation-commands-<region>.md`

The workflow uses managed identity with Azure CLI in customer environments and does not deploy or modify Azure resources during discovery.

## Cost note

The incremental monthly cost is primarily usage-driven:

- Log Analytics ingestion for Traffic Analytics
- Traffic Analytics processing charges
- Azure Storage capacity and transactions for flow log blobs
- Azure Firewall Policy control plane resource (minimal compared to an Azure Firewall instance)

A practical estimate should be calculated with your expected monthly flow-log volume and the Azure pricing calculator before deployment. This repository does not provision an Azure Firewall instance, so Azure Firewall runtime charges are out of scope.
