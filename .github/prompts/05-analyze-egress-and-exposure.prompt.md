---
name: "05 Analyze Egress And Exposure"
description: "Analyze north-south egress and public inbound exposure for the selected workspace and region."
argument-hint: "Provide the selected workspace, region, scope mode, evidence source by VNet, confirmed covered VNet list, excluded VNets, and analysis timeframe."
agent: "Discovery"
---
Analyze outbound dependencies and public inbound exposure for the approved workspace and region.

Use [queries/region-egress-and-exposure-summary.kql](../../queries/region-egress-and-exposure-summary.kql) as the reusable query pattern and reuse the review categories from [firewall-policy-rules.md](../../firewall-policy-rules.md).
Replace the query template `lookback` value with the selected timeframe before execution.
If multiple covered VNets remain in scope, run the query once per covered VNet or resource scope fragment so the `scopeHint` stays explicit.
Keep the returned findings segmented by that explicit per-VNet or per-scope execution rather than merging them into one blended summary.
If the customer requested an all-covered-VNet traffic diagram, keep that artifact separate from the rule analysis narrative.
If the reusable query fails because a column is absent in the selected workspace schema, rerun with `column_ifexists(...)` and record that the schema-safe variant was required.
Limit the analysis narrative to the confirmed covered VNets only and carry the evidence source for each VNet into the narrative.

Return:

1. Outbound platform dependencies.
2. Public or unmanaged egress to challenge.
3. Public inbound exposures to review.
4. Candidate Azure Firewall design implications.
5. Any exclusions caused by missing VNet flow-log coverage.