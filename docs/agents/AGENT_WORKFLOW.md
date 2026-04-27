# Atlas Agent Workflow

## Purpose

This document turns the root `AGENTS.md` guidance into an operational workflow
for future coding agents working in `atlas-lab-toolkit`.

The goal is not to make agents autonomous. The goal is to keep agent work
bounded, testable, and honest while Atlas remains a local-first control plane
for authorized security assessment workflows.

## Required Sequence

Every agent change should follow this sequence:

1. Identify the exact milestone or objective.
2. Inspect the existing command, document, and test style before editing.
3. Classify the change against the Atlas safety boundary.
4. Preserve the domain split between `atlas`, `wiremap`, `vector`, `intelctl`,
   and `labctl`.
5. Make the smallest coherent change that satisfies the objective.
6. Update tests when behavior or guardrails change.
7. Update documentation when semantics, commands, or maturity claims change.
8. Run the strongest relevant QA gate.
9. Record what was changed, what was verified, and what limitations remain.
10. Avoid production, enterprise, autonomous, or audit-complete claims unless
    retained evidence proves them.

## Safety Classification

Before editing target-touching behavior, an agent must identify the capability
tier:

- Tier 0: read-only
- Tier 1: passive recon
- Tier 2: active recon
- Tier 3: safe validation, explicit approval required
- Tier 4: intrusive validation, explicit ROE required
- Tier 5: destructive, blocked by default

When unsure, classify higher.

Do not add features that enable autonomous exploitation, persistence,
credential spraying, denial-of-service workflows, stealth, scope expansion, or
destructive testing.

## Trust Rules

Agents must preserve these Atlas trust rules:

- Read-only commands must not mutate state.
- Metadata-only packets must not embed raw runtime artifacts or secrets.
- Release trust packets must remain verifiable.
- Production readiness must remain stricter than v1 internal readiness.
- SHA-256 anchors are integrity signals, not cryptographic signing.
- Limitations must stay visible.

## Documentation Rules

When changing Atlas behavior, review the likely affected docs:

- `README.md`
- `tools/atlas/README.md`
- `docs/ATLAS_BLUEPRINT.md`
- `docs/atlas/V1_PILLAR_READINESS.md`
- `docs/atlas/PRODUCTION_READINESS.md`
- `docs/agents/AGENT_VALIDATION.md`
- `docs/retention/milestones/MILESTONE_XX.md`

Use precise maturity language:

- `internal readiness`
- `ready-to-refine`
- `release-trust candidate`
- `metadata-only`
- `operator-controlled`
- `not-ready for production`

Avoid unsupported language:

- `production-ready`
- `enterprise-ready`
- `autonomous`
- `fully secure`
- `tamper-proof`
- `certified`

## QA Expectations

Use the repository's Nix development environment:

```bash
nix-shell
```

Preferred full gate:

```bash
nix-shell --run './bin/dev-qa'
```

For focused validation:

```bash
bash -n <changed-shell-file>
git diff --check
nix-shell --run './bin/dev-lint'
nix-shell --run './bin/dev-test tests/atlas.bats'
```

Do not claim a check passed unless it actually ran.

## Milestone Closeout

Milestone work should end with:

- implementation commit
- retention note under `docs/retention/milestones/`
- QA result recorded from actual output
- tag pushed to origin
- repo state checked clean and synced
- remaining limitations stated plainly
