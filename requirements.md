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
- document a prerequisite guide for the read-only workshop flow, including Azure CLI setup, Log Analytics query capability, recommended operator extensions, a full Azure logout and login reset, and least-privilege read-only identity guidance
- document an approval-first process for turning Traffic Analytics findings into Firewall Policy rules
- provide KQL queries that surface rule recommendations from Traffic Analytics
- provide a GitHub Copilot-first workshop workflow that starts by validating Azure sign-in state and tenant, lets the customer provide a specific Log Analytics workspace or discover candidate subscriptions and workspaces across the tenant, identifies which workspaces appear to contain relevant VNet flow-log evidence, asks the customer to choose the workspace to analyze, then proposes candidate VNets, captures the analysis timeframe, validates observed VNet flow-log coverage for the confirmed scope, and creates review-only request artifacts after confirmation
- support two post-workspace scope modes for the workshop: `dynamic discovery` and `predefined VNet scope`
- run a lightweight discovery and coverage pass with a default `7d` lookback before detailed traffic analysis begins
- require authentication-context reconciliation when Azure CLI and any extension-backed or MCP-backed Azure tooling are both used during workshop discovery
- recommend a least-privilege read-only Azure identity and require a full Azure logout and login reset before workshop discovery starts
- classify each confirmed VNet as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered` when mixed evidence sources exist
- treat VNet flow logs as the primary evidence source and NSG flow logs as fallback only for VNets without usable VNet evidence
- treat missing coverage on requested hub, transit, or shared-services VNets as a blocking gap for any full production-scope firewall draft unless the customer explicitly narrows scope or accepts a partial review-only output
- keep multi-VNet analysis explicit per covered VNet or equivalent scope fragment rather than blending findings across covered VNets
- allow an optional all-covered-VNet traffic diagram while keeping rule evidence explicit per VNet
- keep reusable KQL contracts schema-safe across tenant variations where practical
- allow an optional post-workshop remediation artifact that contains review-only CLI commands to enable VNet flow logs to a chosen workspace when the customer explicitly asks
- keep any generated firewall-rule artifact limited to review-only infrastructure-as-code output and never apply or populate live Azure Firewall rules automatically during the workshop
- keep any generated NSG-rule artifact limited to review-only infrastructure-as-code output and never apply or modify live NSGs automatically during the workshop
- generate both Azure Firewall and NSG infrastructure-as-code drafts at the end of the analysis so that intra-subnet and inter-subnet rules are captured alongside egress, ingress, and inter-VNet rules

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
