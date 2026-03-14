---
name: "09 Generate Firewall Draft"
description: "Create the review-only Azure Firewall Bicep draft artifact after output creation is confirmed."
argument-hint: "Provide the confirmed request timestamp, region, and approved draft inputs."
agent: "Drafting"
---
Create the review-only Azure Firewall infrastructure-as-code draft artifact in the confirmed request folder.

Synthesize the draft from the per-VNet internal, egress, and exposure summaries. Deduplicate shared dependencies only after preserving the per-VNet evidence and exclusion record.

Requirements:

1. File name: `firewall-rules-draft-<region>.bicepparam`
2. Align structure with [infra/firewall-policy-rules.sample.bicepparam](../../infra/firewall-policy-rules.sample.bicepparam).
3. Keep all content approval-pending.
4. Do not create, modify, deploy, or imply live Azure Firewall rule changes.
5. Do not add deployment commands.
6. Prefer service tags, FQDNs, and narrowly scoped rules where possible.
7. Prefer Azure Firewall application rules for outbound HTTP or HTTPS destinations when a defensible FQDN set is known.
8. Prefer network rules only when the dependency is non-HTTP, service-tag-based, internal RFC1918, or explicitly IP-based.
9. Do not place unresolved service names or pseudo-FQDN labels into address fields unless they are valid Azure Firewall constructs.
10. If CIDRs, service tags, or FQDNs are still unresolved, keep explicit placeholders and call them out in comments instead of implying deployment readiness.
11. If any VNet is backed only by `NSGFlowLogsFallback`, carry that lower-confidence evidence status into comments and avoid broad rules derived only from legacy fallback evidence.
12. If a shared dependency is aggregated across multiple VNets, preserve enough context in comments or nearby review text so reviewers can still trace which VNets contributed that rule candidate.