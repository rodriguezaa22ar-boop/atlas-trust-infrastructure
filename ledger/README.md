# Atlas Hash Ledger

## Purpose

M128 defines the first metadata-only hash-ledger contract for Atlas governance
events.

The ledger connects:

```text
approval event -> decision record -> run event -> evidence envelope -> checkpoint
```

Each `atlas.run_event.v1` record carries `prev_hash` and `event_hash` fields.
`atlas ledger verify` recomputes each event hash from canonical JSON without
the `event_hash` field and checks that each event points to the previous event.

## Contract

Ledger events are newline-delimited JSON. The first event uses:

```text
prev_hash = GENESIS
```

Every later event uses:

```text
prev_hash = previous event_hash
```

`atlas ledger checkpoint` emits `atlas.checkpoint.v1` with event count, head
event hash, and whole-ledger hash. This gives reviewers a compact anchor for a
known ledger state.

## Boundary

This is tamper-evident metadata, not tamper-proof infrastructure.

Atlas verifies that evidence metadata is well-formed, hash-linked, and
replayable. It does not guarantee that an action was valid, grant permission,
replace approval authorities, or certify compliance.

Ledger records must not contain raw secrets, raw request or response bodies,
packet captures, customer data, private keys, tokens, or unredacted runtime
evidence.

## Commands

```bash
./bin/dev-evidence
./tools/atlas/bin/atlas evidence verify evidence-envelope.json
./tools/atlas/bin/atlas ledger verify ledger.ndjson
./tools/atlas/bin/atlas ledger checkpoint ledger.ndjson --json
```
