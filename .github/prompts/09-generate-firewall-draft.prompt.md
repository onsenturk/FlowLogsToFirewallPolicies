---
name: "09 Generate Firewall Draft"
description: "Create the review-only Azure Firewall Bicep draft artifact after output creation is confirmed."
argument-hint: "Provide the confirmed request timestamp, region, and approved draft inputs."
agent: "Drafting"
---
Create the Azure Firewall draft artifact in the confirmed request folder.

Requirements:

1. File name: `firewall-rules-draft-<region>.bicepparam`
2. Align structure with [infra/firewall-policy-rules.sample.bicepparam](../../infra/firewall-policy-rules.sample.bicepparam).
3. Keep all content approval-pending.
4. Do not add deployment commands.
5. Prefer service tags, FQDNs, and narrowly scoped rules where possible.
6. Prefer Azure Firewall application rules for outbound HTTP or HTTPS destinations when a defensible FQDN set is known.
7. Prefer network rules only when the dependency is non-HTTP, service-tag-based, internal RFC1918, or explicitly IP-based.
8. Do not place unresolved service names or pseudo-FQDN labels into address fields unless they are valid Azure Firewall constructs.
9. If CIDRs, service tags, or FQDNs are still unresolved, keep explicit placeholders and call them out in comments instead of implying deployment readiness.
10. If any VNet is backed only by `NSGFlowLogsFallback`, carry that lower-confidence evidence status into comments and avoid broad rules derived only from legacy fallback evidence.