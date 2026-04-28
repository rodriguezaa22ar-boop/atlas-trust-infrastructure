# Release Trust

## Purpose

Release trust is Atlas' path from local readiness to retained release evidence.
It records a release packet, verifies it, replays it where needed, and binds it
to signed provenance.

The release trust system is metadata-only. It records commits, tags, hashes,
QA status, readiness JSON, retained milestone notes, known limitations, and
optional operation trust-chain state. It must not embed raw runtime artifacts,
target secrets, private keys, tokens, packet captures, or evidence bodies.

## Current Surfaces

```bash
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
./tools/atlas/bin/atlas release packet <name> --json --qa-status pass
./tools/atlas/bin/atlas release packet <name> --json --operation <operation> --qa-status pass
./tools/atlas/bin/atlas release verify <name>
./tools/atlas/bin/atlas release replay <name>
./tools/atlas/bin/atlas release manifest <name>
./tools/atlas/bin/atlas release manifest-verify <name>
```

## Release Packet

`atlas release packet` writes a retained packet under
`docs/retention/releases/`.

Normal packet generation requires:

- clean repository
- synced upstream
- v1 readiness overall `ready`
- current operation trust-chain when `--operation` is used

JSON release packets use schema `atlas.release_trust.v1`, documented at
[schemas/release-trust.v1.md](schemas/release-trust.v1.md).

## Release Verify

`atlas release verify` checks:

- schema or Markdown header
- metadata-only guardrail
- commit match
- clean repository state recorded in the packet
- synced upstream state recorded in the packet
- QA status
- v1 readiness JSON
- required retained milestone notes
- known limitations
- recorded operation trust-chain replay when present

Verification fails nonzero when the packet is stale, incomplete, malformed, or
inconsistent with retained state.

## Replay Verification

Historical packets should be checked against the commit recorded inside the
packet, not only against current `HEAD`.

```bash
./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m67-production-candidate.json --commit 3e2a8b734fed694b350c4916c242c5e2ffd80e76
./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m67-production-candidate.json
```

`atlas release replay` automates the clean-checkout replay path by creating a
temporary isolated replay checkout at the packet commit, running QA, checking
v1 readiness, verifying the release packet against the recorded commit, and
removing the checkout. `--skip-qa` is available for a faster metadata replay,
but skipped QA is not equivalent to full replay.

The manual clean-checkout replay procedure lives at
[retention/releases/REPLAY_VERIFICATION.md](retention/releases/REPLAY_VERIFICATION.md).

## Verify / Replay / Provenance Alignment

The release trust docs, tests, and schemas are aligned around three separate
checks:

- `atlas release verify`: validates a retained release packet against an
  expected commit.
- `atlas release replay`: checks that packet from a clean checkout of the
  packet's recorded commit, including QA unless `--skip-qa` is used.
- `atlas production status`: verifies the latest release packet, signed
  provenance packet, retained public key, and production dry-run note together.

The schema contracts that support those checks are:

- `atlas.release_trust.v1`
- `atlas.release_provenance.v1`
- `atlas.release_artifact_manifest.v1`
- `atlas.production_readiness.v1`

The parity matrix is tracked in
[atlas/PACKET_FORMAT_PARITY.md](atlas/PACKET_FORMAT_PARITY.md).

## Signing And Provenance

Milestone 67 added signed release provenance. The current retained evidence
includes:

- release packet: `docs/retention/releases/atlas-m67-production-candidate.json`
- provenance packet: `docs/retention/releases/atlas-m67-production-candidate.provenance.json`
- retained public key: `docs/retention/releases/atlas-m67-release-signing-public-key.asc`
- signed tag: `atlas-production-candidate-m67`

The provenance gate verifies:

- `atlas.release_provenance.v1` schema
- metadata-only flag
- release commit match
- release packet path and SHA-256
- release packet replay
- signed annotated tag target
- retained public key path and SHA-256
- `git tag -v` in a temporary keyring populated from the retained public key
- QA status
- known limitations
- no-production-overclaim flag

The schema is documented at
[schemas/release-provenance.v1.md](schemas/release-provenance.v1.md).

## Release Artifact Manifest

`atlas release manifest` writes a metadata-only JSON index of the retained
release evidence for a release commit:

- release packet path and SHA-256
- signed provenance packet path and SHA-256
- retained signing public key path and SHA-256
- production dry-run note path and SHA-256
- signed tag name, target, and tag object
- optional milestone note path and SHA-256

`atlas release manifest-verify` checks artifact hashes, release packet
verification, signed provenance, production dry-run evidence, and tag
verification with the retained public key. The schema is documented at
[schemas/release-artifact-manifest.v1.md](schemas/release-artifact-manifest.v1.md).

## Production Status

`atlas production status --strict` is the release promotion gate. It currently
requires:

- v1 internal readiness
- clean repository
- synced upstream
- current verified release trust packet
- production readiness contract
- signing/provenance
- retained production dry-run evidence

When it reports `production-ready`, that means the local Atlas production
contract passes for retained release evidence. It is not external audit,
enterprise certification, SLSA certification, deployment certification, or a
claim of tamper-proof infrastructure.
