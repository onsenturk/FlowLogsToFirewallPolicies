---
name: "03 Confirm Workspace And Scope"
description: "Confirm the chosen Log Analytics workspace, freshness, and region-scoped analysis boundary before traffic analysis begins."
argument-hint: "Provide the selected workspace, any known region, the proposed VNets, and any preferred timeframe."
agent: "Discovery"
---
Confirm the selected workspace and traffic-analysis scope.

First confirm the selected workspace. If region is still ambiguous or still needed for downstream analysis and artifact naming, confirm or infer it at this stage.

Then run a lightweight discovery and coverage pass with a default timeframe of `7d` unless the customer explicitly wants a different initial lookback for scope confirmation.

After that, ask the customer to choose one of these scope modes:

- `dynamic discovery` - propose the candidate VNets observed in the selected workspace and let the customer confirm the final VNet scope
- `predefined VNet scope` - let the customer provide the VNet list up front and validate only that scope

Then confirm the analysis timeframe for the detailed traffic analysis. The detailed analysis timeframe may stay at `7d` or use a different customer-approved lookback.

Query `NTANetAnalytics` to classify the evidence source for each confirmed VNet.
If the customer provides a custom timeframe, normalize it to a valid KQL duration such as `21d` or `12h` before continuing.
If Azure CLI and any extension-backed or MCP-backed Azure tooling are both in use, explicitly confirm that they are aligned to the same tenant and subscription before trusting the results.
If a confirmed VNet appears to be a hub, transit, or shared-services VNet and is classified as `Uncovered`, treat that as a blocking gap for any full production-scope draft unless the customer narrows the scope or explicitly accepts a partial review-only draft.

Return:

1. The selected workspace.
2. Any secondary workspaces that should remain in reserve.
3. The authentication context validation result.
4. The chosen scope mode: `dynamic discovery` or `predefined VNet scope`.
5. The confirmed discovery and coverage timeframe, defaulting to `7d` unless the customer explicitly overrides it.
6. The confirmed detailed analysis timeframe, using a standard choice such as `7d`, `14d`, `30d`, `60d`, `90d`, or a custom KQL duration such as `21d`.
7. The freshness status.
8. The confirmed VNets, subnets, or resources in scope for this region.
9. The evidence source for each confirmed VNet: `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`.
10. The VNets that are covered for analysis.
11. Any VNets excluded from analysis because usable coverage was not found.
12. Whether an all-covered-VNet traffic diagram was requested.
13. Any remaining blocking gaps before analysis starts.