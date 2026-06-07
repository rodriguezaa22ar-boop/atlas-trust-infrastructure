# Milestone 184: Governance Decision Vocabulary

## Summary

M184 adds the first shared Atlas governance decision vocabulary.

The vocabulary gives the Capability Manifest, Adapter Registry, Policy Plane,
Approval Plane, Evidence Envelope, reviewer output, and future receipt/open-core
alignment work the same decision words and bounded meanings.

## Scope

- Added `governance/decision-vocabulary.yaml`.
- Added `docs/governance/GOVERNANCE_DECISION_VOCABULARY_M184.md`.
- Added `bin/dev-decisions` validation for the decision vocabulary contract.
- Updated governance validation to include decision vocabulary checks.
- Linked the vocabulary from the M182 integration map and docs index.
- Added focused Bats coverage for M184.

## Decision Categories

- `authorization_model`
- `capability_resolution`
- `adapter_resolution`
- `policy_decision`
- `approval_state`
- `evidence_sufficiency`
- `boundary_state`
- `reviewer_outcome`
- `replay_state`
- `system_state`

## Safety Boundary

M184 is a docs/schema/tests/validation milestone only.

It does not add a runtime decision engine, action router, runtime
orchestration, policy enforcement, approval workflow execution, automatic
approval, automatic escalation, break-glass execution, runtime evidence
collection, automatic evidence capture, evidence collector, evidence lake,
adapter execution, live integration, credentials, API calls, webhooks, network
collectors, database/server/web UI, receipt semantic changes, or
hashing/canonicalization/replay behavior changes.

Decision terms are metadata-only. They do not grant authorization by
themselves and do not prove legal compliance, legal sufficiency, production
deployability, complete event coverage, external audit completion, runtime
safety, model correctness, artifact correctness, immutable storage, or
tamper-proof infrastructure.

## Validation

- `bash -n bin/dev-decisions`: pass.
- `./bin/dev-decisions`: pass.
- `./bin/dev-governance`: pass.
- Focused M184 Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Retention

- Branch: `m184-governance-decision-vocabulary`
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m184`
