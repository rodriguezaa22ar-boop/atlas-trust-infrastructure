# Atlas Agent Guidance Validation

## Purpose

`AGENTS.md` is part of the Atlas trust boundary. It tells future coding agents
how to work in the repository without overclaiming maturity, weakening safety
controls, or collapsing the toolkit domains.

This validation file defines the minimum clauses that must remain present.

## Required Clauses

The root `AGENTS.md` must remain present and must include guidance for:

- authorized assessment only
- no autonomous exploitation
- domain split between `atlas`, `wiremap`, `vector`, `intelctl`, and `labctl`
- no production-readiness overclaims
- metadata-only packet boundaries
- read-only command non-mutation
- Nix QA command: `nix-shell --run './bin/dev-qa'`
- v1 readiness not being production certification
- production readiness being stricter than v1 readiness
- AI Advisor not being an execution engine
- Atlas OS, ISI, and kernel work being future layers

## Test Coverage

The Bats suite includes a root guidance validation test. Run it directly with:

```bash
nix-shell --run 'bats tests/atlas.bats --filter "root AGENTS guidance"'
```

The full QA gate also runs it:

```bash
nix-shell --run './bin/dev-qa'
```

## Failure Policy

If the validation test fails, do not weaken the test to pass.

Instead:

1. Confirm whether the root guidance was intentionally changed.
2. Restore equivalent safety or maturity language.
3. Update this document only if the required contract has genuinely changed.
4. Run the focused test and full QA gate.

## Non-Goals

This validation does not prove that every future agent will behave correctly.
It proves the repository still carries the minimum written operating contract
that future agent sessions are expected to follow.

The guidance is a control, not a substitute for tests, code review, or retained
release evidence.
