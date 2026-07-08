# Retained Release Evidence Refresh

## Purpose

This runbook defines the safe path for refreshing Atlas retained release
evidence after main advances.

It does not make Atlas production-ready by itself. It explains how a future
operator can create real retained evidence so `atlas production status` can
evaluate the current release commit honestly.

M197 is documentation and regression coverage only. It does not generate a new
release packet, signed tag, provenance packet, production dry-run note, release
artifact manifest, SLSA reference, or production-ready claim.

M197 does not generate a new release packet or any other retained release
evidence.

M197 does not generate a release artifact manifest.

## Current Blocker Pattern

`atlas v1 status --strict` can pass while `atlas production status --strict`
remains `not-ready`.

That is expected when retained release evidence is stale. V1 readiness answers
whether Atlas' internal pillars are ready. Production status requires fresh
retained evidence for the current release commit.

The current retained production-candidate evidence is M140-era evidence. It is
bound to commit:

```text
18430ce9b00191d536096779d88398b2df01e320
```

When current `main` is a later commit, that retained evidence must keep
production blocked until a real refresh is performed.

In short: stale retained evidence must keep production blocked.

## Concepts

- V1 readiness: internal Atlas pillar readiness from `atlas v1 status`.
- Release trust: release packet verification and replay for a release commit.
- Retained evidence freshness: whether packet, manifest, provenance, dry-run,
  public key, signed tag, and optional SLSA metadata match the current release
  commit.
- Production status: the local Atlas production contract that combines V1
  readiness, repository discipline, release trust, retained evidence freshness,
  signing/provenance, and dry-run evidence.
- Reviewer judgment: the human decision to accept or reject retained evidence
  after reviewing commands, outputs, known limitations, and non-guarantees.

Reviewer judgment is not replaced by passing commands.

## Non-Negotiable Rules

- Do not force production-ready.
- Do not weaken production status gates.
- Do not bypass retained evidence requirements.
- Do not rewrite historical retained evidence.
- Do not fake provenance.
- Do not fake signatures.
- Do not fake production dry-runs.
- Do not create a forced production-ready claim.
- Do not store raw evidence, logs, prompts, outputs, secrets, packet captures,
  request bodies, response bodies, private target data, or customer data in
  retained evidence.

## Identify The Current Release Commit

Start from clean, synced `main`:

```bash
git switch main
git pull --ff-only
git status --short
git rev-parse HEAD
```

The `git rev-parse HEAD` value is the candidate release commit. Use the full
commit SHA in retained evidence commands and notes.

If `git status --short` prints anything, stop. A release evidence refresh
requires a clean worktree.

## Verify Clean Synced Main

Check upstream sync:

```bash
git rev-list --left-right --count HEAD...@{u}
```

Expected synced output:

```text
0	0
```

If local or remote commits are pending, stop and resolve the branch state
before generating retained evidence.

## Run QA

Run the full local gate:

```bash
nix-shell --run './bin/dev-qa'
```

Only a passing QA run may be recorded in the release packet. Do not summarize
failed QA as pass.

## Run V1 Readiness

Run:

```bash
nix-shell --run './tools/atlas/bin/atlas v1 status --strict'
```

V1 readiness must pass before production evidence can be refreshed. Passing V1
readiness is still not production readiness.

## Create A Real Production Dry-Run Note

Create a new retained note under:

```text
docs/retention/production/PRODUCTION_DRY_RUN_<date>_<milestone>.md
```

The note must be based on actual operator execution for the candidate release
commit. It must include the required production dry-run fields:

```text
# Atlas Production Dry Run

Commit: <full release commit>
Result: retained
QA status: pass
V1 readiness: pass
Production status observed: not-ready

Known blockers:
- <specific blockers observed before the final evidence refresh>

No production-ready claim is made beyond the local Atlas contract.
```

Do not invent a dry-run. Do not paste raw logs, prompts, outputs, target data,
customer data, packet captures, request bodies, or response bodies.

## Generate A Real Release Packet

After QA and V1 readiness pass on clean synced `main`, generate a release
packet for the candidate commit:

```bash
nix-shell --run './tools/atlas/bin/atlas release packet atlas-m198-retained-release-evidence-refresh --json --qa-status pass --qa-command "nix-shell --run '\''./bin/dev-qa'\''" --qa-note "dev-qa passed before retained release evidence refresh for <commit>"'
```

Then verify it:

```bash
nix-shell --run './tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m198-retained-release-evidence-refresh.json --commit <full release commit>'
```

The release packet is metadata-only. It must not embed raw QA output.

## Create And Verify A Signed Production-Candidate Tag

Create a signed annotated production-candidate tag only when the release commit
is final and the signing key is intentionally available:

```bash
git tag -s atlas-production-candidate-m198 <full release commit> -m "Atlas production candidate M198"
git tag -v atlas-production-candidate-m198
```

Do not create unsigned replacement tags. Do not claim verification unless
`git tag -v` succeeds with the retained public key path used by Atlas
production checks.

## Create Real Signed Provenance

Create a signed release provenance packet that binds:

- schema `atlas.release_provenance.v1`
- metadata-only flag
- release commit
- signed tag name and target
- signer fingerprint
- retained public key path and SHA-256
- release packet path and SHA-256
- QA status
- observed production status
- known limitations
- `no_production_overclaim: true`

The provenance packet must reference real files and a real signed tag. Do not
create fake provenance to satisfy a gate.

## Generate A Release Artifact Manifest

Generate the manifest only after the release packet, production dry-run note,
signed tag, retained public key, and provenance packet exist:

```bash
nix-shell --run './tools/atlas/bin/atlas release manifest atlas-m198-retained-release-evidence-refresh --packet docs/retention/releases/atlas-m198-retained-release-evidence-refresh.json --provenance docs/retention/releases/atlas-m198-retained-release-evidence-refresh.provenance.json --dry-run docs/retention/production/PRODUCTION_DRY_RUN_<date>_M198.md --milestone-note docs/retention/milestones/MILESTONE_198.md --tag atlas-production-candidate-m198'
```

Include `--slsa <reference>` only when a real retained SLSA reference exists
and verifies for the same release commit.

## Verify The Refreshed Evidence

Run all checks before claiming the refresh is complete:

```bash
nix-shell --run './tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m198-retained-release-evidence-refresh.json --commit <full release commit>'
nix-shell --run './tools/atlas/bin/atlas release manifest-verify docs/retention/releases/atlas-m198-retained-release-evidence-refresh.manifest.json --commit <full release commit>'
git tag -v atlas-production-candidate-m198
nix-shell --run './tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m198-retained-release-evidence-refresh.json --json'
nix-shell --run './tools/atlas/bin/atlas production status --strict --explain'
```

If production status still reports `not-ready`, do not override it. The output
is the authoritative local contract result.

## Retained Metadata Boundary

Retained release evidence may store:

- paths
- SHA-256 hashes
- commit IDs
- tag IDs
- verification states
- known limitations
- no-overclaim statements
- command names and bounded summaries

Retained release evidence must not store:

- raw evidence
- raw logs
- prompts
- model outputs
- tokens
- secrets
- private keys
- packet captures
- request bodies
- response bodies
- private target data
- customer data
- unredacted business records

## M197 Boundary

M197 defines and tests this refresh path. It does not execute it.

M198 or a later approved milestone may perform the real retained release
evidence refresh. Until then, stale retained evidence must keep production
status blocked.
