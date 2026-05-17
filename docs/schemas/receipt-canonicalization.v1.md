# Atlas Receipt Canonicalization v1

`atlas.receipt.canonicalization.v1` documents how Atlas computes
`atlas.receipt.v1` hashes.

Atlas canonicalization is deterministic, local, and boring. It exists so
another reviewer can recompute the same hash from the same receipt content. It
does not prove external artifact truth, human intent, legal compliance, or
runtime correctness.

## Scope

This contract applies to:

- `atlas receipt create`
- `atlas receipt verify`
- `atlas receipt replay`
- example `atlas.receipt.v1` files under `examples/receipt/`

It describes hash input only. It does not add a database, server, network
collector, runtime cache, execution engine, or hidden state.

## Canonical Form

Atlas computes receipt hashes from JSON after parsing and re-emitting the
receipt through `jq -cS`.

The canonical byte stream is:

```text
jq -cS <filter output> plus the trailing LF emitted by jq
```

The rules are:

- parse the receipt as JSON
- apply the hash-specific deletion filter
- sort object keys recursively with `jq -S`
- emit compact JSON with `jq -c`
- hash the emitted bytes with SHA-256
- record the lowercase hexadecimal digest

Whitespace outside JSON string values is not semantic.
Object key order is not semantic.
Array item order is semantic.
String values, numbers, booleans, `null`, object membership, array membership,
and array order are semantic.

## Event Hash

`event_hash` binds the receipt event metadata while excluding both top-level
hash fields:

```bash
jq -cS 'del(.event_hash, .receipt_hash)' receipt.json | sha256sum
```

Excluded during `event_hash` computation:

- top-level `event_hash`
- top-level `receipt_hash`

Included during `event_hash` computation:

- `schema_version`
- `receipt_id`
- `timestamp`
- `metadata_only`
- `raw_artifacts_embedded`
- `action`
- `actor`
- `subject`
- `evidence_refs`
- `artifact_refs`
- `approval_refs`
- `prev_hash`
- `known_limitations`
- `verifier`

## Receipt Hash

`receipt_hash` binds the full receipt record after `event_hash` has been set.
It excludes only its own top-level hash field:

```bash
jq -cS 'del(.receipt_hash)' receipt.json | sha256sum
```

Excluded during `receipt_hash` computation:

- top-level `receipt_hash`

Included during `receipt_hash` computation:

- top-level `event_hash`
- all other valid receipt fields

This means changing `event_hash` does not change the computed `event_hash`, but
does change the computed `receipt_hash`. Changing `receipt_hash` alone does not
change either computed hash; verification still fails because the stored
`receipt_hash` no longer matches the recomputed value.

## Golden Vector

The canonical example at `examples/receipt/minimal.json` has these hashes:

```text
event_hash: e6df3946ad774c9db61195656f81e458ecb0b794271b7a466f3b951767ef8db4
receipt_hash: 6a8a78fb13ca051b593f5baa8babeb58c4a6d023bfad03cf71c7eb421f2490d8
```

Reviewers can recompute them with:

```bash
event_hash="$(
  jq -cS 'del(.event_hash, .receipt_hash)' examples/receipt/minimal.json |
    sha256sum |
    awk '{ print $1 }'
)"

receipt_hash="$(
  jq -cS 'del(.receipt_hash)' examples/receipt/minimal.json |
    sha256sum |
    awk '{ print $1 }'
)"

printf '%s\n%s\n' "$event_hash" "$receipt_hash"
```

## Verification Rules

Receipt verification fails closed when:

- the receipt is not valid JSON
- required receipt fields are missing or have invalid types
- forbidden raw-content markers are present
- `metadata_only` is not `true`
- `raw_artifacts_embedded` is not `false`
- `known_limitations` is missing or empty
- stored `event_hash` does not match the recomputed event hash
- stored `receipt_hash` does not match the recomputed receipt hash

Receipt replay first applies these receipt verification rules to every provided
receipt, then checks caller-provided chain order with `prev_hash ->
event_hash`.

## Non-Guarantees

Canonicalization proves only that the same valid receipt content produces the
same local hash under this contract.

It does not prove:

- external artifact availability
- external artifact truth
- artifact correctness
- human intent
- legal compliance
- authorization
- runtime correctness
- production readiness
- tamper-proof infrastructure
- external audit or certification
