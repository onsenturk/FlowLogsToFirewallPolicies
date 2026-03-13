# Requirements

## Goal

Use Azure network telemetry to identify the least-privilege Azure Firewall rules required for a zero-trust rollout.

## Platform constraint

The original intent was to use NSG flow logs. That conflicts with the current Azure platform state because new NSG flow logs can't be created after June 30, 2025. The compliant alternative is to use virtual network flow logs.

## In scope

- provision a new Log Analytics workspace by using Bicep
- provision regional storage for virtual network flow logs by using Bicep
- enable virtual network flow logs on selected existing VNets, subnets, or NICs by using Bicep
- enable Traffic Analytics for those flow logs
- provision an Azure Firewall Policy resource by using Bicep
- document an approval-first process for turning Traffic Analytics findings into Firewall Policy rules
- provide KQL queries that surface rule recommendations from Traffic Analytics
- provide a paginated KQL query variant for large environments where the default queries exceed workspace query limits
- provide a GitHub Copilot-first workshop workflow that offers two startup paths:
  - **predefined flow**: the customer provides the Log Analytics workspace name or resource ID, tenant ID, subscription ID, and analysis timeframe directly and skips workspace discovery
  - **dynamic discovery**: the customer provides only a tenant ID and optional hints; the workflow enumerates candidate subscriptions and workspaces and asks the customer to choose the workspace before scope confirmation begins
- require that both paths validate Azure sign-in state, confirm the tenant, and reconcile authentication context before discovery results are trusted
- allow the workflow to export VNet flow logs from the selected Log Analytics workspace using KQL before rule candidates are summarized
- include an explicit rule-candidate summary step before the firewall draft is generated, grouping candidates by rule type (network east-west, network platform-internal, application FQDN/service-tag, inbound review items, and unresolved placeholders)
- include an optional step to produce a Mermaid traffic flow diagram from the discovered flows for human review
- classify each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` when mixed evidence sources exist
- treat VNet flow logs as the primary evidence source and NSG flow logs as fallback only for VNets without usable VNet evidence
- treat missing coverage on requested hub, transit, or shared-services VNets as a blocking gap for any full production-scope firewall draft unless the customer explicitly narrows scope or accepts a partial review-only output
- keep multi-VNet analysis explicit per covered VNet or equivalent scope fragment rather than blending findings across covered VNets
- keep reusable KQL contracts schema-safe across tenant variations where practical
- use a progressive time-window approach in all KQL queries: default to `7d` lookback, re-run per VNet with `14d` then `30d` if results are sparse, so that no flows between VNets are arbitrarily dropped by a hard row limit
- allow an optional post-workshop remediation artifact that contains review-only CLI commands to enable VNet flow logs to a chosen workspace when the customer explicitly asks
- keep any generated firewall-rule artifact limited to review-only infrastructure-as-code output and never apply or populate live Azure Firewall rules automatically during the workshop

## Out of scope

- creating a new Azure Firewall instance
- attaching the Firewall Policy to an existing Azure Firewall instance
- applying approved rule collections to production without review
- changing any existing firewall rules directly in the tenant
- deploying across multiple Azure regions in one run
- hosting the workflow as a managed service in the first release
- automatic Azure changes during customer workshops
- automatic execution of remediation or enablement commands during customer workshops

## Approval boundary

The repository can create the Azure Firewall Policy resource, but the rule collections must remain empty or sample-only until explicit approval is given.

Any workshop-generated firewall-rule output must remain a local infrastructure-as-code draft only. It is not a live rule change and must not be applied automatically.

## Simplicity decision

The solution is intentionally single-region per deployment. This keeps the storage account compliant with the virtual network flow log regional requirement and avoids hidden cross-region behavior.

The first workshop release is intentionally Copilot-native and repo-driven. It uses workspace instructions, custom agents, prompt files, and reusable KQL assets instead of introducing a hosted runtime.

The workshop flow allows partial analysis when some confirmed VNets lack observed flow-log coverage in the selected workspace. In that case, the analysis must stay limited to the covered VNets and must list uncovered VNets as exclusions instead of implying complete regional evidence.

## Estimated cost impact

Expected recurring cost drivers:

- Log Analytics ingestion volume
- Traffic Analytics processed volume
- storage account retention volume and transactions

Expected one-time control-plane impact:

- negligible for the resource group and policy metadata

Use the Azure pricing calculator with expected monthly log volume before deployment.
