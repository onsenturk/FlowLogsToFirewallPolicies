---
name: "09a Generate NSG Draft"
description: "Create the review-only NSG Bicep draft artifact for intra-subnet and inter-subnet traffic after the firewall draft step."
argument-hint: "Provide the confirmed request timestamp, region, and approved draft inputs."
agent: "Drafting"
---
Create the review-only NSG infrastructure-as-code draft artifact in the confirmed request folder.

Synthesize the draft from the per-VNet internal traffic analysis. Group rules by destination subnet, separating intra-subnet and inter-subnet flows.

Requirements:

1. File name: `nsg-rules-draft-<region>.bicepparam`
2. Align structure with [infra/modules/nsg-observed-rules.bicep](../../infra/modules/nsg-observed-rules.bicep) input expectations.
3. Keep all content approval-pending.
4. Do not create, modify, deploy, or imply live NSG changes.
5. Do not add deployment commands.
6. Group rules by VNet and subnet to produce one NSG definition per observed subnet.
7. Use narrowly scoped source and destination addresses from observed traffic.
8. Prefer the saved `requests/<datetime>/query-results/subnet-cidrs.json` manifest for subnet CIDR resolution instead of issuing fresh Azure lookups while drafting.
9. If a subnet CIDR cannot be resolved from the saved manifest, leave the placeholder intact and call the gap out in the review text or output log.
10. If CIDRs are still unresolved, keep explicit placeholders and call them out in comments instead of implying deployment readiness.
11. If any VNet is backed only by `NSGFlowLogsFallback`, carry that lower-confidence evidence status into comments and avoid broad rules derived only from legacy fallback evidence.
12. Preserve per-VNet evidence attribution so reviewers can trace which VNet and subnet contributed each rule candidate.
13. Assign priorities starting at 110, incrementing by 10, to leave room for manual adjustments.
14. Set direction to `Inbound` for inter-subnet and intra-subnet allow rules that match the observed east-west patterns.
