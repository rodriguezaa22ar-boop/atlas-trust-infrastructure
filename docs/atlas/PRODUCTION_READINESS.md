# Atlas Production Readiness

## Purpose

Production readiness is stricter than v1 internal readiness.

`atlas v1 status` answers whether the Atlas pillars are ready for internal
testing, refinement, and release-trust hardening. `atlas production status`
answers whether Atlas has enough release evidence, repository discipline,
trust-chain coverage, operational proof, and known limitation handling to be
promoted as a production release.

Atlas is not production-ready until this contract reports `production-ready`.

## Command

```bash
atlas production status
atlas production status --strict
atlas production status --json
```

The command is read-only. It does not create packets, mutate operations, or
write ledger events.

Default text output is for operators. JSON output uses schema
`atlas.production_readiness.v1` so later CI, release, dashboard, or provenance
work can consume the same contract.

## Overall Rule

Overall `production-ready` requires every required gate to be `ready`.

Overall `not-ready` means at least one required gate is blocked, planned,
disabled, warning, or not implemented.

`--strict` is intended for future release promotion gates. It exits nonzero
unless the overall state is `production-ready`.

## Required Gates

### V1 Internal Readiness

- Required: yes
- Evidence: `docs/atlas/V1_PILLAR_READINESS.md`
- Commands: `atlas v1 status --strict`, `atlas v1 status --json`
- Production meaning: all current internal Atlas pillars are ready with no
  required gaps.
- Limitation: v1 internal readiness is not production certification.

### Repository Clean

- Required: yes
- Evidence: `git status --short`
- Command: `git status --short --branch`
- Production meaning: the release commit has no uncommitted tracked, staged, or
  untracked files.
- Limitation: ignored local runtime state can still exist outside tracked
  release evidence.

### Upstream Sync

- Required: yes
- Evidence: configured upstream branch
- Command: `git rev-list --left-right --count HEAD...@{u}`
- Production meaning: local release state is pushed and not behind upstream.
- Limitation: requires an upstream branch.

### Release Trust Packet

- Required: yes
- Evidence: latest packet under `docs/retention/releases/`
- Commands: `atlas release packet --json`, `atlas release verify`
- Production meaning: a current release packet verifies against the current
  commit, or against the retained release commit immediately before a
  packet-retention commit. It must prove clean/synced repo state, passing QA,
  retained milestone notes, known limitations, v1 readiness JSON, and any
  recorded operation trust chain.
- Limitation: release packets are metadata-only and are not signatures.

### Production Contract

- Required: yes
- Evidence: `docs/atlas/PRODUCTION_READINESS.md`
- Command: `atlas production status`
- Production meaning: the project defines what production-ready means before
  claiming it.
- Limitation: the contract must stay conservative as Atlas matures.

### Signing And Provenance

- Required: yes
- Evidence: future release signing and provenance artifacts
- Commands: future signing/provenance gate
- Production meaning: release trust packets and release artifacts can be tied to
  a verifiable identity and supply-chain record.
- Current state: blocked. Atlas has SHA-256 anchors, but no cryptographic
  release signing or SLSA-style provenance yet.

### Production Dry Run

- Required: yes
- Evidence: future retained production dry-run or external validation note
- Command: future production dry-run checklist
- Production meaning: Atlas has been exercised in retained, realistic operator
  dry runs or independent review before public production claims.
- Current state: blocked. Internal QA does not replace repeated operator dry
  runs or independent review.

## Current Interpretation

As of Milestone 55, Atlas can be called a release-trust candidate for internal
testing and refinement. It should not be called production-ready.

The current blockers are intentional:

- no cryptographic signing or provenance
- no retained production dry-run or independent validation packet
- release trust packets must be regenerated and verified after the final release
  commit

This is the correct state for a security control plane that values evidence
over marketing language.

## Promotion Standard

A future production release should include:

- clean, synced release commit
- all required v1 pillars ready
- full QA pass immediately before release
- current Markdown or JSON release trust packet
- verified operation trust-chain sample when the release claims operation-level
  retention coverage
- retained known limitations
- signing/provenance artifacts
- production dry-run or independent review note
- release notes that avoid production, enterprise, or audit claims beyond the
  retained evidence
