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
| `atlas op trust-chain` | text | yes | `atlas.operation_trust_chain.v1` | implemented | JSON includes readiness, freshness, verification, artifacts, and ledger anchors. |
| `atlas op handoff` | Markdown | no | planned | gap | Needs metadata-only JSON handoff packet. |
| `atlas op closeout` | Markdown | no | planned | gap | Needs JSON closeout manifest with the same anchors as Markdown. |
| `atlas op audit-packet` | Markdown | no | planned | gap | Needs JSON audit packet and verifier parity. |
| `atlas op archive-packet` | Markdown | no | planned | gap | Needs JSON archive packet and verifier parity. |
| `atlas finding review-packet` | Markdown | no | planned | gap | Needs JSON accepted-risk review packet and verifier parity. |
| `atlas flow packet` | Markdown | yes | `atlas.business_flow_packet.v1`; `atlas.business_flow_verify.v1` | implemented | `atlas flow packet --json` and `atlas flow verify --json` are implemented and tested with metadata-only guardrails. |
| `atlas advisor prompt` | Markdown | no | planned | non-blocking gap | Advisor packets remain metadata-only; JSON can come after trust packets. |

## Implemented JSON Schemas

- [`atlas.release_trust.v1`](../schemas/release-trust.v1.md)
- [`atlas.release_provenance.v1`](../schemas/release-provenance.v1.md)
- [`atlas.production_readiness.v1`](../schemas/production-readiness.v1.md)
- [`atlas.operation_trust_chain.v1`](../schemas/operation-trust-chain.v1.md)
- [`atlas.business_flow_packet.v1`](../schemas/business-flow-packet.v1.md)
- [`atlas.business_flow_verify.v1`](../schemas/business-flow-verify.v1.md)

## Missing JSON Packet Surfaces

Priority order:

1. archive packet
2. audit packet
3. closeout manifest
4. handoff packet
5. accepted-risk review packet
6. advisor prompt packet

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
release provenance packet, and production-readiness status:

- `atlas release verify` consumes `atlas.release_trust.v1` packets and can
  verify against an explicit commit for historical replay.
- `docs/retention/releases/REPLAY_VERIFICATION.md` defines the clean-checkout
  replay procedure for retained packets.
- `atlas production status` consumes the latest release packet and
  `atlas.release_provenance.v1` provenance packet to report whether the local
  production contract is ready.

This alignment means release packet JSON, replay docs, production-readiness
JSON, and signed provenance must be updated together when any release trust
field becomes trust-critical.
