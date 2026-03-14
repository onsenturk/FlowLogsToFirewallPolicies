---
name: "08 Create Traffic Summary"
description: "Create the review-only traffic summary artifact after discovery is complete and output creation has been confirmed."
argument-hint: "Provide the confirmed request timestamp, region, and analysis findings."
agent: "Drafting"
---
Create the traffic summary artifact in the confirmed request folder.

Requirements:

1. File name: `traffic-summary-<region>.md`
2. Include a `Run Metadata` section that persists the chosen scope mode, the discovery and coverage timeframe, the detailed analysis timeframe, and whether an all-covered-VNet traffic diagram was requested.
3. Include a `Scope` section that persists the confirmed VNet scope, evidence source by VNet, covered VNets, and uncovered VNets or exclusions.
3. Separate evidence, assumptions, recommendations, and unresolved questions.
4. Cover internal traffic, egress, and inbound exposure.
5. Keep the document customer-readable.
6. If workflow gaps were discovered during the run, add them under unresolved questions as recommendation-only process improvements.
7. If any VNet is backed only by `NSGFlowLogsFallback`, state that explicitly as lower-confidence legacy evidence.