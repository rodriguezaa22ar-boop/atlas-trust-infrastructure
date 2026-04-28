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

### Release Artifact Manifest

- Required: yes
- Evidence: latest `*.manifest.json` under `docs/retention/releases/`
- Commands: `atlas release manifest`, `atlas release manifest-verify`
- Production meaning: the retained release packet, signed provenance packet,
  retained signing public key, production dry-run note, signed tag metadata, and
  optional milestone note are indexed with SHA-256 hashes and verify against
  the current commit or the retained release commit immediately before a
  manifest-retention commit.
- Limitation: release artifact manifests are metadata-only local indexes, not
  external audit attestations or deployment certification.

### Production Contract

- Required: yes
- Evidence: `docs/atlas/PRODUCTION_READINESS.md`
- Command: `atlas production status`
- Production meaning: the project defines what production-ready means before
  claiming it.
- Limitation: the contract must stay conservative as Atlas matures.

### Signing And Provenance

- Required: yes
- Evidence: `docs/retention/releases/*.provenance.json` and signed Git tag
- Commands: `git tag -v`, `atlas release verify`, `atlas production status`
- Production meaning: release trust packets and release artifacts can be tied to
  a verifiable identity and supply-chain record.
- Current state: ready only when the latest release provenance packet verifies
  a signed annotated Git tag, a matching release commit, a retained release
  packet SHA-256 hash, a retained public key SHA-256 hash, signature
  verification through that retained public key, and successful release packet
  replay for the current commit or retained release commit immediately before
  the provenance-retention commit.
- Limitation: local signing is not an external audit, SLSA certification, or
  deployment certification.

Required provenance fields:

- `schema_version: atlas.release_provenance.v1`
- `metadata_only: true`
- `commit: <commit>`
- `signed_tag.name`
- `signed_tag.target`
- `signed_tag.verification: verified`
- `signed_tag.signer_fingerprint`
- `signed_tag.public_key_path`
- `signed_tag.public_key_sha256`
- `release_packet.path`
- `release_packet.sha256`
- `qa.status: pass`
- `production_status.observed`
- `known_limitations`
- `no_production_overclaim: true`

### Production Dry Run

- Required: yes
- Evidence: `docs/retention/production/PRODUCTION_DRY_RUN_*.md`
- Command: `atlas production status`
- Production meaning: Atlas has been exercised in retained, realistic operator
  dry runs or independent review before public production claims.
- Current state: ready only when the latest dry-run note has the required
  production dry-run fields and matches the current commit or the retained
  release commit immediately before the dry-run retention commit. Internal QA
  does not replace repeated operator dry runs or independent review.

Required dry-run note fields:

- `# Atlas Production Dry Run`
- `Commit: <commit>`
- `Result: retained`
- `QA status: pass`
- `V1 readiness: pass`
- `Production status observed: not-ready`
- `Known blockers:`
- `No production-ready claim is made`

## Current Interpretation

Atlas should be described using the exact state reported by
`atlas production status`. When the command reports `not-ready`, do not claim
production readiness. When it reports `production-ready`, that means the local
contract gates pass for the retained release evidence; it still does not imply
external audit, enterprise certification, or deployment certification.

This is the correct state for a security control plane that values evidence
over marketing language.

## Promotion Standard

A future production release should include:

- clean, synced release commit
- all required v1 pillars ready
- full QA pass immediately before release
- current Markdown or JSON release trust packet
- current release artifact manifest
- replay verification from a clean checkout of the packet commit
- verified operation trust-chain sample when the release claims operation-level
  retention coverage
- retained known limitations
- signing/provenance artifacts
- production dry-run or independent review note
- release notes that avoid production, enterprise, or audit claims beyond the
  retained evidence
