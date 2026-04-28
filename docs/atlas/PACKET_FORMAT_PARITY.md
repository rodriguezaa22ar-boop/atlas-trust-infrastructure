# Atlas Packet Format Parity

## Purpose

Atlas uses human-readable Markdown packets and machine-readable JSON contracts.
This file records the current parity state so future work does not assume a
packet has JSON support before it actually does.

Markdown is for operators and retained review. JSON is for gates, replay,
dashboards, provenance, and future Atlas OS consumers.

## Parity Rule

A packet or status surface has JSON parity only when:

- the JSON output is implemented
- the JSON includes the same trust-critical status as the text or Markdown view
- the JSON remains metadata-only
- the JSON is covered by tests
- the JSON schema or schema name is documented
- verification commands can consume or validate the JSON when applicable

## Current Matrix

| Surface | Human Format | JSON Format | Schema | Current State | Notes |
| --- | --- | --- | --- | --- | --- |
| `atlas v1 status` | text | yes | implicit v1 readiness JSON | implemented | `--json` and `--strict` are tested. |
| `atlas production status` | text | yes | `atlas.production_readiness.v1` | implemented | Reports current production blockers without production overclaims. |
| `atlas release packet` | Markdown | yes | `atlas.release_trust.v1` | implemented | `atlas release verify` validates Markdown and JSON packets. |
| release provenance packet | JSON | yes | `atlas.release_provenance.v1` | implemented | Binds a retained release packet to a verified signed Git tag for production status. |
| `atlas release manifest` | JSON | yes | `atlas.release_artifact_manifest.v1` | implemented | Indexes retained release packet, provenance, signing key, dry-run note, signed tag, and optional milestone note hashes. |
| `atlas op trust-chain` | text | yes | `atlas.operation_trust_chain.v1` | implemented | JSON includes readiness, freshness, verification, artifacts, and ledger anchors. |
| `atlas op handoff` | Markdown | yes | `atlas.handoff_packet.v1` | implemented | `atlas op handoff --json` writes metadata-only JSON for gates, replay, dashboards, and downstream trust packets. |
| `atlas op closeout` | Markdown | yes | `atlas.closeout_manifest.v1` | implemented | `atlas op closeout --json` writes metadata-only JSON and `atlas op verify` consumes Markdown or JSON manifests. |
| `atlas op audit-packet` | Markdown | yes | `atlas.audit_packet.v1` | implemented | `atlas op audit-packet --json` writes metadata-only JSON and `atlas op audit-verify` consumes Markdown or JSON packets. |
| `atlas op archive-packet` | Markdown | yes | `atlas.archive_packet.v1` | implemented | `atlas op archive-packet --json` writes metadata-only JSON and `atlas op archive-verify` consumes Markdown or JSON packets. |
| `atlas finding review-packet` | Markdown | yes | `atlas.accepted_risk_review_packet.v1` | implemented | `atlas finding review-packet --json` writes metadata-only JSON and `atlas finding review-verify` consumes Markdown or JSON packets. |
| `atlas flow packet` | Markdown | yes | `atlas.business_flow_packet.v1`; `atlas.business_flow_verify.v1` | implemented | `atlas flow packet --json` and `atlas flow verify --json` are implemented and tested with metadata-only guardrails. |
| `atlas advisor prompt` | Markdown | yes | `atlas.advisor_prompt_packet.v1` | implemented | `atlas advisor prompt --json` writes metadata-only planning context; it remains non-executing and non-blocking. |

## Implemented JSON Schemas

- [`atlas.release_trust.v1`](../schemas/release-trust.v1.md)
- [`atlas.release_provenance.v1`](../schemas/release-provenance.v1.md)
- [`atlas.release_artifact_manifest.v1`](../schemas/release-artifact-manifest.v1.md)
- [`atlas.production_readiness.v1`](../schemas/production-readiness.v1.md)
- [`atlas.operation_trust_chain.v1`](../schemas/operation-trust-chain.v1.md)
- [`atlas.handoff_packet.v1`](../schemas/handoff-packet.v1.md)
- [`atlas.closeout_manifest.v1`](../schemas/closeout-manifest.v1.md)
- [`atlas.audit_packet.v1`](../schemas/audit-packet.v1.md)
- [`atlas.archive_packet.v1`](../schemas/archive-packet.v1.md)
- [`atlas.accepted_risk_review_packet.v1`](../schemas/accepted-risk-review-packet.v1.md)
- [`atlas.advisor_prompt_packet.v1`](../schemas/advisor-prompt-packet.v1.md)
- [`atlas.business_flow_packet.v1`](../schemas/business-flow-packet.v1.md)
- [`atlas.business_flow_verify.v1`](../schemas/business-flow-verify.v1.md)
- [`atlas.business_flow_trust_chain.v1`](../schemas/business-flow-trust-chain.v1.md)

## Missing JSON Packet Surfaces

No missing JSON packet surfaces remain for the current v1 trust-packet pipeline.

## Guardrails

JSON parity must not weaken existing Markdown behavior.

Do not add JSON fields that embed:

- raw runtime artifacts
- target secrets
- session contents
- packet captures
- credential material
- private keys
- tokens
- unredacted evidence bodies
- exploit payloads

If JSON cannot represent a field safely, record a path, hash, count, status,
or known limitation instead.

## Verification Expectation

Every new JSON packet format should include:

- positive generation test
- JSON schema/name assertion
- metadata-only assertion
- verifier success path when a verifier exists
- negative verifier path for stale or malformed JSON
- docs update in this parity matrix
- milestone index update

## Release Verify / Replay Alignment

Release trust currently has machine-readable coverage for the release packet,
release provenance packet, release artifact manifest, and production-readiness
status:

- `atlas release verify` consumes `atlas.release_trust.v1` packets and can
  verify against an explicit commit for historical replay.
- `atlas release manifest-verify` consumes
  `atlas.release_artifact_manifest.v1` and checks retained artifact hashes,
  signed provenance, retained public key, production dry-run evidence, and tag
  metadata.
- `docs/retention/releases/REPLAY_VERIFICATION.md` defines the clean-checkout
  replay procedure for retained packets.
- `atlas production status` consumes the latest release packet,
  `atlas.release_artifact_manifest.v1`, and `atlas.release_provenance.v1`
  provenance packet to report whether the local production contract is ready.

This alignment means release packet JSON, release artifact manifest JSON,
replay docs, production-readiness JSON, and signed provenance must be updated
together when any release trust field becomes trust-critical.
