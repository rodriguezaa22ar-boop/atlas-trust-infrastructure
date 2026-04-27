# Milestone 56: Atlas Agent Guidance Validation

## Commit

`63773156e376e018ed7de97788b54258e80cf04b` Validate Atlas agent guidance

## Purpose

Make the root `AGENTS.md` guidance testable and operational so future agent
sessions keep Atlas inside its safety, trust, and maturity boundaries.

## Added

- `docs/agents/AGENT_WORKFLOW.md`
- `docs/agents/AGENT_VALIDATION.md`
- Root `AGENTS.md` pointers to the agent workflow and validation docs.
- README reference for agent guidance.
- Blueprint milestone entry.
- Bats validation for the root agent safety contract.

## Validated Clauses

The test suite now verifies that `AGENTS.md` preserves guidance for:

- authorized assessment only
- no autonomous exploitation
- domain boundaries across `atlas`, `wiremap`, `vector`, `intelctl`, and
  `labctl`
- metadata-only packet boundaries
- read-only command non-mutation
- Nix QA command usage
- v1 readiness not being production certification
- production readiness remaining separate from v1 readiness
- AI Advisor not being an execution engine
- Atlas OS, ISI, and kernel work remaining future layers

## Verified

- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "root AGENTS guidance"'`: `1/1`
- `nix-shell --run './bin/dev-qa'`: `74/74`, lint ok, stress ok

## Repo State

- Implementation committed at `63773156e376e018ed7de97788b54258e80cf04b`.
- Retention note present.
- Tag target: `atlas-retention-m56`.
