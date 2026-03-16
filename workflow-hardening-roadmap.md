# Workflow Hardening Roadmap

## Purpose

This document captures the follow-up work needed after the strict end-to-end review of the Azure Firewall workshop flow.

The goal is to fix correctness issues, reduce workflow fragility, and make the request-folder artifacts reproducible without changing the approval-first and review-only design of the workshop.

This is a planning document only. It does not authorize live Azure changes or deployment behavior.

## Current Problem Summary

The workflow was refactored to use a single orchestrator script (`scripts/New-FirewallRulesFromTraffic.ps1`) that queries `NTANetAnalytics`, discovers subnets via `az network vnet list`, classifies traffic, and outputs JSON. Static Bicep templates consume the JSON output. The standalone KQL files and multi-script pipeline have been removed.

Remaining areas to harden:

- request artifacts are intentionally kept out of the public repo, which is good for privacy, but makes replay and regression testing harder unless a private artifact strategy exists

## Principles To Preserve

- keep Azure activity read-only during the workshop flow
- keep all generated firewall outputs review-only and approval-pending
- keep request artifacts inside the existing request folder for a run
- keep the request folder as the main audit trail for reproducibility
- do not add deployment or remediation execution into the default workshop path

## Resolved Phases

Phases 1-5 from the original roadmap have been addressed by consolidating the workflow into `scripts/New-FirewallRulesFromTraffic.ps1`:

- **Query persistence**: the script captures `az monitor log-analytics query` output cleanly and writes structured JSON
- **Subnet lookup**: the script uses `az network vnet list` directly and matches IPs to CIDRs in-memory
- **Placeholder replacement**: eliminated; the script outputs explicit IP/CIDR-based JSON rules, not placeholder-based drafts
- **Structured parsing**: all traffic classification uses parsed objects, not regex scanning
- **Single orchestration**: one command handles query, subnet discovery, classification, high-port prompting, and JSON output

## Remaining Phase: Guardrail Validation

### 6. Add basic guardrail validation

Problem:

- the new helper steps work, but there is no built-in check that the expected artifacts exist or that the draft still contains unresolved subnet placeholders unexpectedly

Why it matters:

- broken runs can look complete until much later in review

What to change:

- add simple validation checks after export and draft hydration
- confirm these artifacts exist in the request folder:
  - rendered KQL outputs
  - saved JSON query results
  - `query-results/subnet-cidrs.json`
  - `firewall-rules-draft-<region>.bicepparam`
- detect unresolved subnet placeholders separately from expected unresolved FQDN or service placeholders

Definition of done:

- the workflow can tell the operator whether the run is complete, partial, or broken before review starts

## Phase 4: Documentation And Reproducibility Cleanup

### 7. Clean up workflow docs

Problem:

- the workflow docs currently contain small inconsistencies such as duplicated numbering

Why it matters:

- small doc errors make operator guidance less trustworthy

What to change:

- fix numbering and ordering in `README.md`
- make the sequence explicit:
  - run queries
  - save rendered KQL and JSON
  - export subnet CIDR manifest
  - hydrate firewall draft from the saved manifest
  - record unresolved gaps in request artifacts

Definition of done:

- a new operator can follow the documented order without guessing

### 8. Decide how private request artifacts are retained for replay

Problem:

- the public repo correctly says request artifacts should not be committed
- but replayability and regression testing still need a private retention strategy

Why it matters:

- without retained artifacts, future validation depends on memory or rerunning Azure queries live

What to change:

- document the private retention approach for request folders
- optionally keep sanitized private fixtures for regression testing
- define which artifacts are mandatory for replay

Definition of done:

- a future operator knows where private request artifacts should live after a workshop run
- workflow replay does not depend on the public repo containing customer data

## Suggested Execution Order

1. Add validation checks for required request-folder artifacts.
2. Clean up README and deployment sequencing text.
3. Document the private artifact retention strategy.

## Validation Checklist For The Future Fix

- query result files remain valid JSON when Azure CLI prints warnings
- all generated files stay inside the current request folder
- no step creates or implies live Azure Firewall changes
- docs match the real execution order

## Nice-To-Have Follow-Ups

- add a small test fixture set with sanitized request artifacts for regression checks

## Out Of Scope For This Roadmap

- changing the workshop from review-only to deployment-enabled
- adding automatic remediation execution
- committing customer request artifacts to the public repository
- redesigning the overall workshop scope-selection model