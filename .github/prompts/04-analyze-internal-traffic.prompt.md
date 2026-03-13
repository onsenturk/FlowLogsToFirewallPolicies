---
name: "04 Analyze Internal Traffic"
description: "Analyze east-west and internal Azure traffic for the chosen region and workspace to support Azure Firewall zero-trust planning."
argument-hint: "Provide the selected workspace, region, evidence source by VNet, confirmed covered VNet list, excluded VNets, and analysis timeframe."
agent: "Discovery"
---
Analyze the internal Azure traffic for the approved workspace and region.

Use [queries/region-internal-traffic-summary.kql](../../queries/region-internal-traffic-summary.kql) as the reusable query pattern and reuse the evidence language from [simplified-traffic-flows.md](../../simplified-traffic-flows.md).
Replace the query template `lookback` value with the selected timeframe before execution.
If multiple covered VNets remain in scope, run the query once per covered VNet or resource scope fragment so the `scopeHint` stays explicit.
Keep the returned findings segmented by that explicit per-VNet or per-scope execution rather than merging them into one blended summary.
Limit the analysis narrative to the confirmed covered VNets only and carry the evidence source for each VNet into the narrative.

Return:

1. East-west traffic summary.
2. Platform dependencies that look internal or private.
3. Flows that still need customer validation.
4. Candidate Azure Firewall rule implications.
5. Any exclusions caused by missing VNet flow-log coverage.