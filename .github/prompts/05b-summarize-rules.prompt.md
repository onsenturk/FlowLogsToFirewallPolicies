---
name: "05b Summarize Rules"
description: "Summarize the candidate firewall rules derived from internal traffic, egress, and exposure analysis before the firewall draft is generated."
argument-hint: "Provide the confirmed workspace, covered VNet list, evidence source by VNet, internal findings, egress findings, and exposure findings."
agent: "Discovery"
---
Produce a rule candidate summary from the workshop findings before the firewall draft is generated.

Use [queries/existing-recommended-rules.kql](../../queries/existing-recommended-rules.kql) as the reusable query pattern against the confirmed workspace.
Replace the `CoveredVnets` placeholder with the confirmed covered VNet resource IDs before execution.
Run the query once per covered VNet rather than across all VNets at once, so that one busy VNet does not obscure recommendations for others.
Start with the default `7d` lookback. If the result set is sparse for a given VNet, re-run that VNet's query with `14d` then `30d` until the evidence is sufficient.
If the query still returns few or no results after extending to `30d`, record that VNet as having insufficient evidence and note it as an unresolved gap.

Return a structured summary grouped as:

1. **Network rules — east-west (RFC1918 to RFC1918)**
   - Source subnet or CIDR, destination subnet or CIDR, protocol, destination port range, VNet evidence source.

2. **Network rules — private endpoints and platform-internal**
   - Source, destination, protocol, destination port range, evidence source.

3. **Application rules — outbound FQDN or service tag**
   - Source, FQDN or service tag, destination port (443 or custom), evidence source.
   - Prefer application rules for HTTP/HTTPS destinations where a defensible FQDN set is known.

4. **Inbound exposure review items**
   - Exposed subnet, port, protocol, source class (PublicInbound or OtherInbound), evidence source.
   - These are review items, not allow recommendations.

5. **Unresolved or placeholder entries**
   - Any rules that still have unknown CIDRs, FQDNs, or service names that need customer clarification.

6. **Exclusions and gaps**
   - Any covered VNet where evidence was insufficient even after extending to `30d`.
   - Any uncovered VNets that could not contribute rule candidates.

Rules backed only by `NSGFlowLogsFallback` evidence must be labelled as lower-confidence candidates and should not be treated as primary evidence.

This summary is the input to `/09-generate-firewall-draft`. It is not itself a deployable rule set.
