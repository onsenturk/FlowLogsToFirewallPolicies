---
name: "08b Create Traffic Diagram"
description: "Create the optional review-only traffic-flow diagram artifact after discovery is complete and output creation has been confirmed."
argument-hint: "Provide the confirmed request timestamp, region, covered VNets, key internal and egress relationships, and any evidence caveats."
agent: "Drafting"
---
Create the optional traffic-flow diagram artifact in the confirmed request folder.

Requirements:

1. File name: `traffic-flow-diagram-<region>.md`
2. Include a short `Run Metadata` section with the chosen scope mode, the discovery and coverage timeframe, the detailed analysis timeframe, and the covered or excluded VNets used for the diagram.
3. Render the diagram as Mermaid inside the markdown file.
4. Keep the diagram limited to the confirmed covered VNets and any high-confidence external dependencies worth showing.
5. Do not treat the diagram as the primary evidence source for firewall-rule generation.
6. Include a short caveat section that points readers back to `traffic-summary-<region>.md` for per-VNet evidence, exclusions, and lower-confidence findings.
7. Keep the artifact review-only and approval-pending.