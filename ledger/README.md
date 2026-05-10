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

`atlas ledger verify` also accepts Atlas operation ledgers written by active
operation commands. Those records use the existing `ts`, `event`, `op`,
`target`, `capability`, `tool`, `status`, and `detail` fields. Operation
ledger verification is structural and metadata-boundary validation; it does not
convert those operation ledgers into hash-linked run-event proof chains.

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

Evidence-envelope replay commands are verifier references, not command output
storage. They must not contain raw sensitive output, secrets, exploit payloads,
private prompts, or multiline transcripts. Future agent receipts should prefer
`command_ref`, `workflow_ref`, and `validation_ref` style references where a
stable reference exists.

## Commands

```bash
./bin/dev-evidence
./tools/atlas/bin/atlas evidence verify evidence-envelope.json
./tools/atlas/bin/atlas ledger verify ledger.ndjson
./tools/atlas/bin/atlas ledger checkpoint ledger.ndjson --json
```
