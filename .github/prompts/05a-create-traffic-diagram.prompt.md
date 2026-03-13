---
name: "05a Create Traffic Diagram"
description: "Optionally generate a Mermaid traffic flow diagram summarizing the internal, egress, and inbound flows discovered for the covered VNets."
argument-hint: "Provide the confirmed covered VNet list, evidence source by VNet, internal flows, egress dependencies, and inbound exposures."
agent: "Drafting"
---
Generate an optional Mermaid traffic flow diagram from the workshop findings.

Only run this step if the customer wants a visual summary. Ask first if this step has not been explicitly requested.

Requirements:

1. Use Mermaid `flowchart LR` or `flowchart TD` syntax.
2. Represent each covered VNet or subnet as a distinct node.
3. Show internal (east-west) flows as arrows between VNet or subnet nodes.
4. Show outbound platform dependencies (AzureMonitor, AzureStorage, AzureCloud, and similar service tags) as arrows to labelled external nodes.
5. Show public inbound exposures as arrows from an `Internet` node to the destination subnet.
6. Label each arrow with the protocol and port range where known.
7. Annotate nodes that are backed only by `NSGFlowLogsFallback` evidence with a comment or label so reviewers know the data source is legacy fallback.
8. Omit uncovered VNets from the diagram body but note them in a comment block below the diagram.
9. Keep the diagram readable. If the covered scope is large, split into one diagram per covered VNet rather than creating a single unreadable diagram.
10. Embed the diagram in the `traffic-summary-<region>.md` artifact if it already exists, or save it as a standalone `traffic-diagram-<region>.md` in the confirmed request folder.

The diagram is for human review only. It is not an approved firewall rule set.
