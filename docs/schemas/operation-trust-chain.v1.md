# `atlas.operation_trust_chain.v1`

## Surface

```bash
atlas op trust-chain <operation> --json
```

## Purpose

Report the operation closeout trust chain in a machine-readable form while
preserving the read-only behavior of the text trust-chain command.

## Required Fields

- `schema_version`: must be `atlas.operation_trust_chain.v1`.
- `operation.slug`
- `operation.name`
- `operation.target`
- `operation.status`
- `status`: operation trust-chain status.
- `next_step`: next operator action.
- `readiness`: closeout readiness counts and next step.
- `v1`: operation-scoped v1 readiness summary.
- `freshness`: report, evidence bundle, handoff, closeout, accepted-risk
  review packet, audit packet, and archive packet freshness.
- `verification`: closeout, accepted-risk review packet, audit packet, and
  archive packet verification state.
- `artifacts`: paths or `none` values for retained operation artifacts.
- `ledger`: path, event count, SHA-256 anchor, latest event timestamp, and
  latest event name.

## Verification Rules

Consumers should treat the trust chain as current only when:

- `status` is `current`
- required freshness values are `current`
- closeout, audit packet, and archive packet verification states are verified
- operation ledger event count and SHA-256 match retained release references
- `v1.required_not_ready` is `0`

When used by `atlas release verify`, the operation trust chain must be replayed
from current retained operation state rather than trusted as a static claim.

## Metadata-Only Boundary

This output may include artifact paths, hashes, counts, statuses, and ledger
anchors. It must not embed raw runtime artifacts, target secrets, session
contents, packet captures, credential material, private keys, tokens,
unredacted evidence bodies, or exploit payloads.

## Non-Goals

- Creating or modifying operation artifacts.
- Replacing archive, audit, or closeout packet verification.
- Certifying production deployment readiness.
- Expanding operation scope.
