# Milestone 185: Governance Decision Vocabulary Safety Regression

## Summary

M185 protects the M184 Governance Decision Vocabulary from becoming more than
controlled terminology.

It preserves the value of shared decision words while making explicit that the
vocabulary does not execute decisions, grant authorization, approve production,
prove legal/compliance status, prove external truth, or replace human judgment.

## Scope

- Tightened `governance/decision-vocabulary.yaml` safety language.
- Tightened `docs/governance/GOVERNANCE_DECISION_VOCABULARY_M184.md`
  non-runtime and no-overclaim language.
- Extended `bin/dev-decisions` to validate M185 safety boundaries.
- Added focused Bats coverage for M185.
- Updated the milestone index.

## Safety Boundary

M185 adds no runtime decision engine, runtime orchestration, action router,
runtime policy enforcement, approval workflow execution, automatic approval,
automatic escalation, break-glass execution, runtime evidence collection,
automatic evidence capture, evidence collector, evidence lake implementation,
adapter execution, live integration, credentials, API calls, webhooks, network
collectors, database/server/web UI, receipt semantic changes, or
hashing/canonicalization/replay behavior changes.

Decision terms do not grant authorization by themselves. They do not execute
anything. They do not prove legal compliance, legal sufficiency, production
approval, production deployability, complete event coverage, external audit
completion, runtime safety, model correctness, artifact correctness, immutable
storage, tamper-proof infrastructure, external truth, or that actions outside
Atlas did not happen.

## Protected Terms

- `allow` remains a policy modeling term only.
- `approval_approved` remains recorded approval state only.
- `evidence_sufficient_for_stated_objective` remains scoped to the stated
  review objective only.
- `receipt_verified` remains receipt structure/hash verification only.
- `replay_verified` remains replay verification for supplied inputs only.
- `ready` remains an internal readiness/status term only.
- `unsupported`, `unknown_capability`, `unknown_adapter`, and
  `boundary_violation` remain visible non-support states.
- `human_judgment_required` remains explicit for high-risk, ambiguous, stale,
  unsupported, externally dependent, and business/legal decisions.

## Validation

- `bash -n bin/dev-decisions`: pass.
- `./bin/dev-decisions`: pass.
- `./bin/dev-governance`: pass.
- Focused M184/M185 Bats: pass.
- `./bin/export-public-trust --check`: pass.
- `nix-shell --run './bin/dev-qa'`: pass.

## Retention

- Branch: `m185-governance-decision-vocabulary-safety`
- Commit: pending
- Tag: not created
- Reserved tag: `atlas-retention-m185`
