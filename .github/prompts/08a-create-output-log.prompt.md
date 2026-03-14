---
name: "08a Create Output Log"
description: "Create the review-only output log artifact after discovery is complete and output creation has been confirmed."
argument-hint: "Provide the confirmed request timestamp, region, and the material workflow outputs to capture."
agent: "Drafting"
---
Create the output log artifact in the confirmed request folder.

Requirements:

1. File name: `output-log-<region>.md`
2. Capture material workflow outputs only, not the user prompts or a full transcript.
3. Include sections for `Run Metadata`, `Discovery Outputs`, `Scope And Timeframe`, `Evidence Classification`, `Key Findings`, `Exclusions And Gaps`, `Generated Artifacts`, and `Outstanding Approvals`.
4. Record discovered subscriptions, workspaces used or considered, the chosen scope mode, the discovery and coverage timeframe, the detailed analysis timeframe, confirmed VNet scope, enabled versus not-enabled flow-log status when that output was produced, evidence-source classification, whether a traffic-flow diagram was requested, and any blocking gaps that affect interpretation.
5. Keep the file concise, factual, review-only, and approval-pending.
6. Do not repeat detailed traffic analysis that already belongs in `traffic-summary-<region>.md`; summarize only the outputs that matter for traceability.