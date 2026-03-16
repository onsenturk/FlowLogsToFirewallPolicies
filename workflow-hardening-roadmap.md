# Workflow Hardening Roadmap

## Purpose

This document captures the follow-up work needed after the strict end-to-end review of the Azure Firewall workshop flow.

The goal is to fix correctness issues, reduce workflow fragility, and make the request-folder artifacts reproducible without changing the approval-first and review-only design of the workshop.

This is a planning document only. It does not authorize live Azure changes or deployment behavior.

## Current Problem Summary

The current workflow direction is sound, but several parts are still fragile:

- saved query JSON can be corrupted by Azure CLI warning text
- subnet CIDR export depends on the active Azure CLI subscription too much
- subnet placeholder replacement depends on naming heuristics instead of an explicit mapping
- the subnet export and draft-hydration steps are documented, but not yet enforced as one real workflow step
- request artifacts are intentionally kept out of the public repo, which is good for privacy, but makes replay and regression testing harder unless a private artifact strategy exists

## Principles To Preserve

- keep Azure activity read-only during the workshop flow
- keep all generated firewall outputs review-only and approval-pending
- keep request artifacts inside the existing request folder for a run
- keep the request folder as the main audit trail for reproducibility
- do not add deployment or remediation execution into the default workshop path

## Phase 1: Correctness Fixes

### 1. Fix query-result persistence

Problem:

- `scripts/Run-LogAnalyticsQuery.ps1` mixes Azure CLI stderr into the JSON output stream before writing the saved result file

Why it matters:

- non-fatal CLI warnings can make a saved `.json` file invalid even though the command succeeded
- downstream parsing and artifact reuse become unreliable

What to change:

- capture stdout and stderr separately
- write only stdout to the JSON artifact
- surface stderr as warning text in the terminal or a separate log path
- fail only when Azure CLI returns a non-zero exit code

Definition of done:

- saved query result files remain valid JSON even when Azure CLI emits warnings
- rendered KQL and JSON outputs still go to the same request folder structure

### 2. Fix subnet lookup subscription handling

Problem:

- `scripts/Export-AnalyzedSubnetCidrs.ps1` records a subscription ID, but subnet lookups still rely on the active Azure CLI context

Why it matters:

- wrong subscription context can return the wrong subnet, no subnet, or stale data
- the manifest can claim one subscription while the lookup actually came from another context

What to change:

- carry subscription ID per analyzed subnet record
- pass `--subscription` explicitly on every `az network vnet subnet show` call
- preserve the source subscription per manifest entry instead of using a single global fallback

Definition of done:

- subnet lookups are deterministic even when the Azure CLI default subscription is not the intended one
- each manifest row reflects the subscription actually used for the lookup

## Phase 2: Make Placeholder Replacement Deterministic

### 3. Replace naming heuristics with an explicit mapping contract

Problem:

- subnet placeholder names are currently inferred from VNet and subnet names

Why it matters:

- unusual subnet names, future draft variants, or naming drift can silently break replacement
- the workflow becomes dependent on conventions that are not formally documented

What to change:

- define an explicit placeholder mapping contract in the draft-generation flow
- store that mapping in the saved subnet manifest or a companion artifact
- make draft hydration consume that explicit mapping instead of guessing from names

Definition of done:

- every subnet placeholder used in the draft is traceable to an explicit manifest entry
- a rename in Azure does not silently change placeholder behavior unless the mapping changes too

### 4. Stop scanning raw JSON with regex when structured parsing is possible

Problem:

- analyzed subnets are currently discovered by regex-scanning raw saved JSON files

Why it matters:

- the export step can accidentally collect subnets that appear in incidental fields
- parsing becomes sensitive to formatting rather than data structure

What to change:

- parse the per-VNet JSON files as structured objects
- extract only the fields that are part of the supported artifact contract
- explicitly document which fields contribute to the analyzed subnet set

Definition of done:

- the analyzed subnet list is derived from structured JSON values only
- export behavior is stable if formatting of saved files changes

## Phase 3: Turn The Steps Into One Real Workflow

### 5. Add one orchestration step for draft preparation

Problem:

- the docs say to export subnet CIDRs and then hydrate the draft, but that still depends on a human doing both steps in the right order

Why it matters:

- operators can forget the subnet export or the draft hydration step
- docs and actual execution drift apart

What to change:

- add one wrapper script or one prompt-backed workflow step that:
  - exports subnet CIDRs into the current request folder
  - updates the firewall draft from the saved manifest
  - records any unresolved subnet placeholders in the request output log

Definition of done:

- there is one documented command or workflow step that produces the subnet manifest and hydrates the draft
- the request output log reflects whether subnet replacement was complete or partial

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

1. Fix query JSON persistence.
2. Fix explicit subscription handling in subnet lookup.
3. Replace subnet placeholder heuristics with an explicit mapping contract.
4. Move analyzed subnet discovery from regex scanning to structured parsing.
5. Add one orchestration step for subnet export plus draft hydration.
6. Add validation checks for required request-folder artifacts.
7. Clean up README and deployment sequencing text.
8. Document the private artifact retention strategy.

## Validation Checklist For The Future Fix

- query result files remain valid JSON when Azure CLI prints warnings
- subnet manifest rows include the correct subscription for each lookup
- multi-prefix subnets are represented correctly in the manifest
- unresolved subnet placeholders stay unresolved and are called out explicitly
- non-subnet placeholders are not touched by subnet hydration
- all generated files stay inside the current request folder
- no step creates or implies live Azure Firewall changes
- docs match the real execution order

## Nice-To-Have Follow-Ups

- add a small test fixture set with sanitized request artifacts for regression checks
- add a single `prepare-draft` style wrapper script for operators
- add a summary artifact that records whether the draft was hydrated fully or partially

## Out Of Scope For This Roadmap

- changing the workshop from review-only to deployment-enabled
- adding automatic remediation execution
- committing customer request artifacts to the public repository
- redesigning the overall workshop scope-selection model