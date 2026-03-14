# Azure Firewall zero-trust traffic discovery

This repository provisions the observability resources needed to discover Azure traffic patterns before enforcing Azure Firewall rules.

Any firewall-rule output from the workshop remains a local, review-only infrastructure-as-code draft. The workflow does not create, populate, or deploy live Azure Firewall rule collections automatically.

Before using the Copilot workshop flow, complete the operator setup in [prerequisites.md](prerequisites.md). That guide covers Azure CLI installation, Log Analytics query capability, recommended VS Code extensions, the required full Azure logout and login reset, and the recommendation to use a least-privilege read-only identity.

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
- [queries/existing-flow-logs-discovery.kql](queries/existing-flow-logs-discovery.kql) - discovery query for the current tenant setup
- [queries/existing-recommended-rules.kql](queries/existing-recommended-rules.kql) - rule recommendations for the currently covered VNets
- [queries/existing-east-west-candidates.kql](queries/existing-east-west-candidates.kql) - east-west candidate flow analysis for the current VNets
- [queries/existing-internet-egress-candidates.kql](queries/existing-internet-egress-candidates.kql) - internet egress candidate analysis for the current VNets
- [queries/existing-inbound-exposure-candidates.kql](queries/existing-inbound-exposure-candidates.kql) - public inbound exposure review for the current VNets
- [prerequisites.md](prerequisites.md) - required operator setup for read-only workshop execution
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

1. complete [prerequisites.md](prerequisites.md), including a full `az logout`, a fresh login to the intended tenant, and confirmation that the active Azure identity is read-only
2. start with natural language such as `start` or with `/01-start-workshop`
3. confirm Azure sign-in state and tenant before discovery begins
4. choose whether to provide a specific Log Analytics workspace or let the workflow discover candidate workspaces in the selected tenant
5. verify that Azure CLI and any extension-backed or MCP-backed Azure tooling are aligned to the same tenant and subscription before trusting discovery results
6. let the discovery flow enumerate candidate subscriptions, identify which candidate workspaces appear to contain relevant VNet flow-log evidence, and ask the customer to choose the workspace to analyze
7. run a lightweight discovery and coverage pass with a default `7d` lookback unless the customer explicitly overrides it
8. choose either `dynamic discovery` or `predefined VNet scope`
9. confirm region only if it is still needed, then confirm the intended VNet scope and detailed analysis timeframe, and validate the evidence source for each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`
10. if an uncovered VNet is a hub, transit, or shared-services VNet in the requested production scope, stop the full-scope draft unless the customer narrows scope or explicitly accepts a partial review-only output
11. validate freshness and analyze only the covered VNets, while carrying uncovered VNets forward as explicit exclusions
12. keep internal, egress, and exposure findings explicit per covered VNet or equivalent scope fragment rather than blending them into a single undifferentiated summary
13. optionally create a traffic-flow diagram that covers all confirmed covered VNets without replacing the per-VNet evidence contract for rules
14. if a reusable KQL query fails because of schema drift in the selected workspace, rerun it with schema-safe expressions and record that adaptation in the output
15. ask once before creating any local draft artifacts
16. write review-only outputs under `requests/<datetime>/`, persisting the confirmed VNet scope, covered VNets, uncovered VNets, and any requested material output log in the request artifacts

Optional post-workshop step:

11. if the customer explicitly asks for remediation guidance, generate a review-only `remediation-commands-<region>.md` artifact with Azure CLI commands to enable VNet flow logs to the chosen workspace

Supported analysis timeframes are the standard workshop choices `7d`, `14d`, `30d`, `60d`, and `90d`, plus custom KQL-compatible duration values such as `21d` when the customer requests a different lookback window.

The discovery flow now treats VNet flow-log coverage as a pre-analysis scope check. If a confirmed VNet is not observed in the selected workspace for the chosen window, the workflow does not claim full regional coverage. It continues only for the covered VNets and lists uncovered VNets as exclusions that still need customer follow-up.

If the workflow encounters a prompt or instruction gap during a workshop run, it should surface recommendation-only improvements for future runs instead of editing the repo during customer execution.

Expected workshop outputs:

- `traffic-summary-<region>.md`
- `output-log-<region>.md` when the customer wants a concise record of material workflow outputs
- `validation-questions-<region>.md`
- `firewall-rules-draft-<region>.bicepparam` - review-only IaC draft only, not a deployed ruleset
- optional `remediation-commands-<region>.md`

The workflow uses Azure CLI in customer environments and recommends a least-privilege read-only user or managed identity. Start each workshop with the logout and re-login sequence documented in [prerequisites.md](prerequisites.md), and do not deploy or modify Azure resources during discovery.

## Query roles

Use the KQL files by role so large workspaces do not fall back to one broad blended analysis run.

### Discovery and coverage queries

Use these first to identify candidate workspaces, validate freshness, and confirm covered versus uncovered VNets.

- [queries/workspace-flow-log-coverage.kql](queries/workspace-flow-log-coverage.kql)
- [queries/workspace-flow-log-freshness.kql](queries/workspace-flow-log-freshness.kql)
- [queries/verify-vnet-flow-log-coverage.kql](queries/verify-vnet-flow-log-coverage.kql)
- [queries/verify-vnet-evidence-source.kql](queries/verify-vnet-evidence-source.kql)
- [queries/existing-flow-logs-discovery.kql](queries/existing-flow-logs-discovery.kql)

### Per-VNet analysis queries

Use these for the detailed internal, egress, exposure, and rule analysis once the covered VNet set is confirmed.

- [queries/recommended-rules-by-vnet.kql](queries/recommended-rules-by-vnet.kql)
- [queries/region-internal-traffic-summary.kql](queries/region-internal-traffic-summary.kql) when run once per covered VNet or scope fragment
- [queries/region-egress-and-exposure-summary.kql](queries/region-egress-and-exposure-summary.kql) when run once per covered VNet or scope fragment
- [queries/rule-candidates-summary.kql](queries/rule-candidates-summary.kql) after the VNet scope is narrowed
- [queries/existing-east-west-candidates.kql](queries/existing-east-west-candidates.kql)
- [queries/existing-internet-egress-candidates.kql](queries/existing-internet-egress-candidates.kql)
- [queries/existing-inbound-exposure-candidates.kql](queries/existing-inbound-exposure-candidates.kql)
- [queries/existing-recommended-rules.kql](queries/existing-recommended-rules.kql)

### Optional all-VNet diagram or summary inputs

Use these only when the customer wants a traffic-flow diagram or a high-level cross-VNet view. Do not use them as the primary evidence source for final firewall-rule generation.

- [queries/region-internal-traffic-summary.kql](queries/region-internal-traffic-summary.kql) when intentionally summarized across all covered VNets for a diagram or reviewer visualization
- [queries/region-egress-and-exposure-summary.kql](queries/region-egress-and-exposure-summary.kql) when intentionally summarized across all covered VNets for a diagram or reviewer visualization

## Cost note

The incremental monthly cost is primarily usage-driven:

- Log Analytics ingestion for Traffic Analytics
- Traffic Analytics processing charges
- Azure Storage capacity and transactions for flow log blobs
- Azure Firewall Policy control plane resource (minimal compared to an Azure Firewall instance)

A practical estimate should be calculated with your expected monthly flow-log volume and the Azure pricing calculator before deployment. This repository does not provision an Azure Firewall instance, so Azure Firewall runtime charges are out of scope.
