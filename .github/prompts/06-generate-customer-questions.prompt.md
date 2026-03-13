---
name: "06 Generate Customer Questions"
description: "Generate decision-oriented customer validation questions from the discovered internal traffic, egress, and exposure findings."
argument-hint: "Provide the current workshop findings and target region."
agent: "Discovery"
---
Generate the exact questions to ask the customer before drafting Azure Firewall rules.

If any confirmed VNets were uncovered or excluded because observed flow-log coverage was not found, include explicit follow-up questions for those VNets.
If any confirmed VNets are covered only by `NSGFlowLogsFallback`, include explicit questions that confirm whether that fallback evidence is acceptable for the production decision.
Do not ask remediation or enablement questions by default. Surface those only when the customer explicitly asks for remediation guidance.

Group questions into:

1. Platform dependencies.
2. East-west dependencies.
3. North-south egress.
4. Public inbound exposure.
5. Private connectivity alternatives.
6. Coverage gaps and uncovered VNets.