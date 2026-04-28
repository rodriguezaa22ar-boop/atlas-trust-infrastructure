# Schema Contract: atlas.business_flow_verify.v1

## Purpose

`atlas.business_flow_verify.v1` describes the machine-readable verification
result emitted by:

```bash
atlas flow verify --json <flow> [packet-name]
```

The result verifies a metadata-only Business Flow Evidence JSON packet against
the active operation, global flow record, operation flow link, evidence links,
finding links, validation links, retained evidence records, retained evidence
files, hashes, freshness, and forbidden-content guardrails.

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.business_flow_verify.v1`. |
| `flow_id` | string | Stable flow ID being verified. |
| `flow_slug` | string | Flow slug being verified. |
| `operation` | string | Active operation slug. |
| `target` | string | Active operation target. |
| `packet` | string | JSON packet path being verified. |
| `packet_format` | string | Must be `json`. |
| `overall` | string | `current`, `stale`, or `blocked`. |
| `failures` | number | Count of non-`ok` checks. |
| `checks` | array of objects | Individual verification checks. |

## Check Object

Each `checks` item contains:

| Field | Type | Meaning |
| --- | --- | --- |
| `check` | string | Human-readable check name. |
| `status` | string | `ok`, `stale`, or `blocked`. |
| `detail` | string | Check-specific detail. |

## Overall Rules

- `current`: all checks are `ok`.
- `stale`: one or more checks are `stale` and no check is `blocked`.
- `blocked`: one or more checks are `blocked`.

The command exits nonzero for `stale` and `blocked`.

## Verification Rules

The JSON verifier checks:

- packet exists
- packet is valid JSON object
- forbidden raw-content markers are absent
- `schema_version` is `atlas.business_flow_packet.v1`
- `metadata_only` is `true`
- `raw_evidence_embedded` is `false`
- packet operation and target match the active operation
- packet flow ID matches the global flow record
- flow record hash is current
- operation flow link exists
- linked evidence count matches the packet
- linked evidence references are present in the packet
- linked evidence records still exist
- retained evidence metadata still matches
- retained evidence files still hash to recorded SHA-256 values
- linked finding references are present in the packet
- linked finding records still exist
- linked finding metadata still matches the linked snapshot
- linked validation references are present in the packet
- linked validation records still exist
- linked validation metadata still matches the linked snapshot

## Forbidden Content

The verification result must not embed raw evidence bodies, customer records,
request bodies, response bodies, tokens, credentials, private keys, session
cookies, authorization headers, payment data, or packet captures.

## Non-Goals

- This result is not a raw evidence bundle.
- This result is not a compliance certification.
- This result does not verify approval or retention links until those Business
  Flow Evidence link types exist.
