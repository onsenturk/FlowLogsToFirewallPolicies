# Production Dry-Run Checklist

Use this checklist before trusting an agent-generated Azure Firewall draft for a production environment.

This checklist is for read-only workshop execution and review-only draft artifacts. It is not a deployment checklist.

## Goal

Confirm that:

- the agent analyzed the correct tenant, subscriptions, workspace, region, and VNet scope
- the evidence source for each confirmed VNet is explicit
- the evidence is complete enough for the requested production decision
- the generated draft does not overstate confidence or imply deployment readiness

## How to use this checklist

For each item, mark one of these outcomes:

- `Pass`
- `Pass with note`
- `Fail`
- `Not applicable`

If any item marked `Fail` is also listed as a stop condition, do not trust the generated draft as a production-scope output.

---

## 1. Authentication And Context

1. The operator completed the full Azure logout and login reset before the workshop began.
2. Azure CLI identity is the intended production read-only identity.
3. Azure CLI tenant matches the intended customer tenant.
4. Azure CLI subscription context is either the intended subscription or intentionally tenant-scoped for discovery.
5. If extension-backed or MCP-backed Azure tooling was used, its tenant matches Azure CLI.
6. If extension-backed or MCP-backed Azure tooling was used, its subscription visibility matches Azure CLI for the relevant discovery and query steps.
7. Any context mismatch was treated as a blocking issue and resolved before workspace selection.

Stop condition:
Do not trust the draft if discovery or Log Analytics queries were executed with mixed or unresolved Azure contexts.

---

## 2. Workspace Selection

1. Candidate subscriptions were enumerated before workspace selection.
2. Candidate workspaces were evaluated for evidence quality, not only name or region.
3. Workspace freshness was checked before traffic analysis.
4. The chosen workspace was selected because it had the best evidence for the requested region and scope.
5. Secondary workspaces were recorded when evidence was split or incomplete.
6. If evidence was materially split across workspaces, the workshop either stopped or explicitly documented why a single-workspace draft was still acceptable.

Stop condition:
Do not trust the draft as full-scope if production evidence is split across workspaces and the flow did not explicitly reconcile that split.

---

## 3. Scope Confirmation

1. The target region was confirmed with the customer.
2. The intended VNet scope was explicitly confirmed with the customer.
3. The analysis timeframe was explicitly confirmed with the customer.
4. Any custom timeframe was normalized to a valid KQL duration.
5. The request artifacts persist the confirmed VNet scope.

---

## 4. Coverage Validation

1. The evidence source for each confirmed VNet was validated as `VNetFlowLogs`, `NSGFlowLogsFallback`, or `Uncovered`.
2. Covered VNets were listed explicitly.
3. Uncovered VNets were listed explicitly.
4. `NSGFlowLogsFallback` VNets were listed explicitly as lower-confidence legacy-backed evidence.
5. Exclusions were carried into the summary, questions, and firewall draft.
6. If a hub, transit, or shared-services VNet was uncovered, the workflow stopped the full-scope draft unless the customer explicitly narrowed the scope or accepted a partial review-only draft.
7. If a partial draft was accepted, that acceptance is explicit in the request artifacts.

Stop condition:
Do not trust the draft as a production-scope artifact if a requested hub, transit, or shared-services VNet is uncovered and no explicit partial-scope acceptance was recorded.

---

## 5. Query Reliability

1. The reusable queries ran successfully in the selected workspace.
2. If a query failed because of schema drift, a schema-safe variant was used.
3. Any schema-safe adaptation was recorded in the summary or closeout.
4. Query output was checked for obviously empty or misleading results.
5. The analysis did not rely on `NTARuleRecommendation` when that table was empty.

Stop condition:
Do not trust the draft if the analysis relied on failed queries, silent empty results, or unrecorded schema workarounds.

---

## 6. Per-VNet Analysis Quality

1. Internal traffic analysis stayed limited to covered VNets.
2. Egress and exposure analysis stayed limited to covered VNets.
3. When multiple covered VNets remained, findings were kept explicit per VNet or equivalent scope fragment.
4. The narrative preserves which VNets were backed by `VNetFlowLogs` and which were backed only by `NSGFlowLogsFallback`.
5. The final narrative does not blend unrelated VNet findings into one ambiguous recommendation.
6. Exclusions are visible anywhere the analysis might otherwise imply full regional coverage.

Stop condition:
Do not trust the draft if the analysis blends multiple covered VNets in a way that makes rule ownership or dependency location ambiguous.

---

## 7. Draft Translation Quality

1. The draft aligns with `infra/firewall-policy-rules.sample.bicepparam`.
2. HTTP or HTTPS destinations use Azure Firewall application rules when a defensible FQDN set is known.
3. Network rules are used only for non-HTTP, service-tag-based, internal RFC1918, or explicitly IP-based dependencies.
4. Address fields do not contain pseudo-FQDN labels or invalid constructs.
5. Unresolved CIDRs, FQDNs, or service tags remain explicit placeholders.
6. Public inbound findings remain review-only unless there is explicit owner validation.
7. `PublicIPOnly` and mixed `Other` buckets were not turned into broad allow rules without additional validation.
8. Dynamic RPC or ephemeral ports were not treated as approved ranges without an explicit review note.

Stop condition:
Do not trust the draft if it contains invalid Azure Firewall constructs, unresolved pseudo-destinations presented as real values, or broad allow rules derived from mixed evidence buckets.

---

## 8. Artifact Completeness

1. The request folder is under `requests/<datetime>/`.
2. The traffic summary exists.
3. The validation questions file exists.
4. The firewall draft exists.
5. The traffic summary clearly separates evidence, assumptions, recommendations, and unresolved questions.
6. The validation questions include coverage-gap questions when exclusions exist.
7. The draft file is clearly marked review-only and approval-pending.
8. The closeout states the explicit approvals still required before any deployment.
9. If remediation commands were generated, they are in a separate review-only artifact and are not presented as part of the default workshop output.
10. If an output log was requested, it exists as a separate review-only artifact and captures material workflow outputs without turning into a prompt transcript.

---

## 9. Go Or No-Go Decision

You can treat the draft as a trustworthy production review artifact only if all of the following are true:

- no stop condition failed
- the selected workspace and scope are correct
- the evidence source for each confirmed VNet is explicit and acceptable for the decision being made
- uncovered VNets are either non-blocking or explicitly accepted as partial scope
- the analysis stayed explicit per covered VNet where needed
- the generated firewall rules use valid Azure Firewall constructs
- unresolved placeholders are visible and not mistaken for final values

If any of those statements is false, treat the output as an incomplete workshop artifact that still requires correction before review by production stakeholders.