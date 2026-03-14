---
name: "07 Confirm Output Creation"
description: "Ask once for confirmation before creating the local request folder and review-only workshop artifacts."
argument-hint: "Provide the region and the artifacts you want to create."
agent: "agent"
---
Ask for one-time confirmation before creating local request artifacts.

The confirmation must include:

1. The request folder pattern: `requests/<datetime>/`
2. The chosen scope mode and the timeframes that will be carried into the request artifacts, including the discovery and coverage timeframe and the detailed analysis timeframe when they differ
3. The confirmed VNet scope that will be carried into the request artifacts, including evidence source by VNet, covered VNets, and uncovered VNets when known
4. The specific files that will be created, including `output-log-<region>.md` when output capture is requested and `traffic-flow-diagram-<region>.md` when a diagram was requested
4. A reminder that all outputs are review-only and not approved for deployment
5. A reminder that any uncovered hub, transit, or shared-services VNet means the output is partial unless the customer narrowed scope explicitly

Do not create files in this step.