# Atlas Receipt Open-Core RC

## Purpose

The Atlas Receipt Open-Core RC packages the current receipt, replay, and
reviewer-proof surface into one reviewer path. It is meant to help an outside
reviewer understand what Atlas receipts prove, run the local checks, and inspect
the retained evidence without adding a new engine or runtime surface.

This is packaging for the current proof layer. It does not change receipt
semantics, verifier behavior, replay behavior, release gates, or reviewer
package checks.

## Review Value

Atlas supports reviewer inspection of critical actions by producing replayable
metadata-only proof receipts. A reviewer can verify receipt structure, hashes,
known limitations, and replay order locally, then use the Trust Claim Ladder,
Evidence Sufficiency Report, and Reviewer Decision Packet to decide what the
evidence supports.

## What Atlas Proves

Atlas can currently prove these local properties for receipt records and
reviewer evidence:

- receipt files conform to the `atlas.receipt.v1` metadata-only contract
- receipt verification recomputes deterministic `event_hash` and
  `receipt_hash` values
- receipt replay verifies caller-provided `prev_hash -> event_hash` linkage
  across a provided sequence
- replay output is deterministic and reviewer-safe
- unsafe receipt content fails closed in the regression suite
- read-only receipt verification and replay do not create runtime state
- reviewer packaging succeeds only when current retained release evidence
  verifies

## What Atlas Does Not Prove

Atlas receipts and reviewer packages do not prove:

- external artifact availability
- human intent
- legal compliance
- artifact correctness
- runtime safety
- production deployment approval
- tamper-proof infrastructure
- external audit or certification
- external SLSA certification

Receipts are metadata-only proof records. They preserve hashes, references,
known limitations, and replay instructions; they do not embed raw artifacts,
credentials, request or response bodies, packet captures, or private runtime
state.

## Five-Minute Path

Start with the copy-paste quickstart:

```bash
nix-shell
sed -n '1,240p' docs/TRY_RECEIPTS.md
./tools/atlas/bin/atlas receipt verify examples/receipt/minimal.json
./tools/atlas/bin/atlas receipt replay examples/receipt/demo-site/*.json
```

See [TRY_RECEIPTS.md](TRY_RECEIPTS.md) for expected verifier and replay output,
including `metadata_only=true`, `raw_artifacts_embedded=false`, known
limitations, and non-guarantee language.

## Receipt Surface

Primary receipt contracts:

- [RECEIPTS.md](RECEIPTS.md): Receipt v1 behavior, verifier output, and
  boundaries
- [schemas/atlas.receipt.v1.schema.json](../schemas/atlas.receipt.v1.schema.json):
  JSON Schema for metadata-only receipt records
- [schemas/receipt-replay.v1.md](schemas/receipt-replay.v1.md): deterministic
  `atlas.receipt_replay.v1` output shape
- [schemas/receipt-canonicalization.v1.md](schemas/receipt-canonicalization.v1.md):
  canonicalization rules for `event_hash` and `receipt_hash`
- [schemas/README.md](schemas/README.md): schema classification and stable
  contract list

## Demo Receipt Packet

The synthetic demo receipt packet is intentionally local and metadata-only:

- [demo/DEMO_RECEIPT_PACKET.md](demo/DEMO_RECEIPT_PACKET.md): reviewer-facing
  demo receipt packet path
- [../examples/receipt/demo-site/](../examples/receipt/demo-site/): linked
  synthetic receipt chain

Run:

```bash
./tools/atlas/bin/atlas receipt verify examples/receipt/demo-site/demo-site-boundary.json
./tools/atlas/bin/atlas receipt replay examples/receipt/demo-site/*.json --json
```

The demo packet does not add a backend, live integration, web UI, network
collector, production deployment claim, or hidden state.

## Security Regressions

The receipt security regression suite proves the boundary fails safely for:

- secret markers
- raw request or response body markers
- embedded raw artifacts
- `metadata_only=false`
- `raw_artifacts_embedded=true`
- missing `known_limitations`
- event hash tampering
- `prev_hash` chain tampering
- read-only mutation attempts
- verifier/replay non-guarantee language

Run focused coverage:

```bash
nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "receipt|canonicalization|demo|M139|M141"'
```

Run the full gate:

```bash
nix-shell --run './bin/dev-qa'
```

## Reviewer Package Path

M140 refreshed the retained release evidence required by reviewer packages. The
current retained evidence is:

- release packet:
  `docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.json`
- signed provenance:
  `docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.provenance.json`
- artifact manifest:
  `docs/retention/releases/atlas-m140-refresh-release-reviewer-evidence.manifest.json`
- signed tag: `atlas-production-candidate-m140`
- milestone note: `docs/retention/milestones/MILESTONE_140.md`

Generate a reviewer package:

```bash
./tools/atlas/bin/atlas reviewer package full-capability-review
```

Expected generated path:

```text
docs/retention/reviewer-packages/full-capability-review/
```

Reviewer packages are generated metadata-only review aids. The generated
package directory is not a third-party review result and does not create an
external audit, certification, production approval, legal compliance statement,
or external SLSA certification.

## RC Boundary

This RC is an open-core packaging checkpoint for the receipt proof surface. It
is useful because the proof path is local, deterministic, replayable, and
reviewer-verifiable.

It does not add:

- runtime behavior
- receipt semantics
- server state
- database state
- network collection
- agent execution
- demo-site integration
- weakened release or reviewer gates

The correct interpretation is narrow:

```text
Atlas can generate and replay metadata-only receipt proof records, and it can
package current retained release evidence for reviewer inspection.
```

The incorrect interpretation is broader than the evidence supports:

```text
The incorrect interpretation would treat this package as external audit or
certification, legal compliance, tamper-proof infrastructure, production
approval, or external SLSA certification.
```
