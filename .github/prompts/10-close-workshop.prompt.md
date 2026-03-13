---
name: "10 Close Workshop"
description: "Close the workshop with a concise summary of chosen workspace, main findings, created artifacts, and pending approvals."
argument-hint: "Provide the final workshop findings, created artifacts, and region."
agent: "agent"
---
Produce the final workshop closeout.

If a prompt or instruction gap was found during the run, include recommendation-only workflow improvements in the closeout and do not imply that the repo was changed during execution.

Return:

1. The chosen workspace and why it was selected.
2. The authentication context validation result and any context mismatch that had to be resolved.
3. The confirmed VNet scope, evidence source by VNet, covered VNets analyzed, and uncovered VNets excluded from analysis.
4. The main internal, egress, and exposure findings.
5. The created artifacts under `requests/<datetime>/`, including any output-log artifact when one was requested.
6. Any recommendation-only workflow or prompt improvements identified during the run.
7. The explicit customer approvals still required before any firewall deployment.