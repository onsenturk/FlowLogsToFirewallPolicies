---
name: "03 Confirm Workspace And Scope"
description: "Confirm the chosen Log Analytics workspace, freshness, and region-scoped analysis boundary before traffic analysis begins."
argument-hint: "Provide the recommended workspace, region, proposed VNets, and any preferred timeframe."
agent: "Discovery"
---
Confirm the selected workspace and traffic-analysis scope.

First confirm which of the proposed VNets the customer actually wants in scope and confirm the analysis timeframe.
Then use [queries/verify-vnet-evidence-source.kql](../../queries/verify-vnet-evidence-source.kql) to classify the evidence source for each confirmed VNet.
If the customer provides a custom timeframe, normalize it to a valid KQL duration such as `21d` or `12h` before continuing.
If Azure CLI and any extension-backed or MCP-backed Azure tooling are both in use, explicitly confirm that they are aligned to the same tenant and subscription before trusting the results.
If a confirmed VNet appears to be a hub, transit, or shared-services VNet and is classified as `Uncovered`, treat that as a blocking gap for any full production-scope draft unless the customer narrows the scope or explicitly accepts a partial review-only draft.

Return:

1. The selected workspace.
2. Any secondary workspaces that should remain in reserve.
3. The authentication context validation result.
4. The confirmed analysis timeframe, using a standard choice such as `7d`, `14d`, `30d`, `60d`, `90d`, or a custom KQL duration such as `21d`.
5. The freshness status.
6. The confirmed VNets, subnets, or resources in scope for this region.
7. The evidence source for each confirmed VNet: `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`.
8. The VNets that are covered for analysis.
9. Any VNets excluded from analysis because usable coverage was not found.
10. Any remaining blocking gaps before analysis starts.