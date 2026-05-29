# GitHub Actions Run Receipt Candidate M151

## Purpose

M151 introduces the first real-world import-only event candidate for Atlas
receipts: a GitHub Actions workflow run and a linked check run represented as
local metadata-only `generic.external_event.v1` files.

This candidate is intentionally narrow. It uses only the existing generic
external event adapter and existing receipt verify and replay behavior. In
short, it uses the existing generic external event adapter for local import
only.

It does not add GitHub API calls, webhook collection, action execution,
network collection, a database, a server, a web UI, hidden state, a new
adapter runtime, or any production approval claim.

## Reviewed Commit

```text
1a80a80439a08c41e34d87c3e8f1bdef1ecc4a3e
```

This is the retained M150 checkpoint on `main`.

## Candidate Map

Example event files:

- [examples/adapters/generic-external-event/github-actions-run-event.json](../../examples/adapters/generic-external-event/github-actions-run-event.json)
- [examples/adapters/generic-external-event/github-actions-check-event.json](../../examples/adapters/generic-external-event/github-actions-check-event.json)

Adapter and schema:

- [docs/adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](../adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md)
- [schemas/generic-external-event.v1.schema.json](../../schemas/generic-external-event.v1.schema.json)

Retention:

- [docs/retention/milestones/MILESTONE_151.md](../retention/milestones/MILESTONE_151.md)

## Import Workflow Run Event

Run from the repository root:

```bash
run_receipt=/tmp/atlas-m151-github-actions-run.receipt.json

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/github-actions-run-event.json \
  --out "$run_receipt"
```

Expected output:

```text
receipt: /tmp/atlas-m151-github-actions-run.receipt.json
```

## Verify Workflow Run Receipt

```bash
./tools/atlas/bin/atlas receipt verify "$run_receipt"
```

Expected output includes:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Import Linked Check Run Event

```bash
check_receipt=/tmp/atlas-m151-github-actions-check.receipt.json
prev_hash="$(jq -r '.event_hash' "$run_receipt")"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/github-actions-check-event.json \
  --prev-hash "$prev_hash" \
  --out "$check_receipt"
```

Expected output:

```text
receipt: /tmp/atlas-m151-github-actions-check.receipt.json
```

## Verify Check Run Receipt

```bash
./tools/atlas/bin/atlas receipt verify "$check_receipt"
```

Expected output includes:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

## Replay Linked Receipts

```bash
./tools/atlas/bin/atlas receipt replay \
  "$run_receipt" \
  "$check_receipt"
```

Expected output includes:

```text
receipt replay: ok
receipts: 2
ledger binding: ok prev_hash -> event_hash
metadata-only boundary: ok
This replay verifies receipt hashes and provided-order prev_hash linkage only.
It does not prove external artifact availability, human intent, legal compliance, artifact correctness, authorization, or production readiness.
```

JSON replay check:

```bash
./tools/atlas/bin/atlas receipt replay \
  "$run_receipt" \
  "$check_receipt" \
  --json | jq -e '
    .schema_version == "atlas.receipt_replay.v1" and
    .status == "ok" and
    .metadata_only == true and
    .raw_artifacts_embedded == false and
    .receipt_count == 2 and
    .ledger_binding.status == "ok"
  '
```

Expected output:

```text
true
```

## Import-Only Boundary

M151 is local-file input only.

Allowed:

- read a caller-provided local `generic.external_event.v1` JSON file;
- write only the caller-requested receipt output file;
- verify the generated receipt;
- replay the caller-provided receipt chain;
- preserve `metadata_only=true`;
- preserve `raw_artifacts_embedded=false`.

Not allowed:

- no GitHub API calls;
- no webhook server;
- no network collector;
- no GitHub Actions execution;
- no action rerun, cancellation, approval, or dispatch behavior;
- no database;
- no new adapter runtime;
- no hidden state;
- no raw workflow logs, check annotations, webhook payloads, artifacts,
  credentials, or secrets embedded;
- no production readiness, approval, certification, legal compliance, source
  truth, or external audit claim.

## What Atlas Proves

For this candidate, Atlas proves:

- the GitHub Actions run/check examples fit `generic.external_event.v1`;
- the existing generic adapter can import each local event file;
- generated receipts verify with `atlas receipt verify`;
- a workflow run receipt can be linked to a check run receipt through
  `prev_hash`;
- the linked receipt chain replays with `atlas receipt replay`;
- `metadata_only=true` is preserved;
- `raw_artifacts_embedded=false` is preserved;
- only the requested receipt output files are written.

## What Atlas Does Not Prove

Atlas does not prove:

- the GitHub Actions run exists;
- the GitHub Actions check exists;
- the reported conclusion is true;
- the workflow logs or artifacts are correct;
- the workflow was authorized;
- the run was safe;
- the repository is production-ready;
- the event source is authoritative;
- a human approved anything;
- GitHub availability, authenticity, or API state.

## Known Limitations

- The examples are representative local metadata samples, not live GitHub
  queries.
- No raw logs, annotations, artifacts, webhook payloads, credentials, or secrets
  are embedded.
- Replay verifies local receipt hashes and caller-provided chain order only.
- A successful receipt is not a GitHub audit, certification, compliance result,
  runtime safety proof, artifact correctness proof, or production approval.
- This candidate does not add a GitHub adapter; it uses the existing generic
  external event adapter only.

## Reviewer Checklist

- Confirm both example files declare `schema_version:
  generic.external_event.v1`.
- Confirm both example files set `metadata_only=true`.
- Confirm both example files set `raw_artifacts_embedded=false`.
- Import the workflow run event.
- Verify the workflow run receipt.
- Import the check run event with `--prev-hash`.
- Verify the check run receipt.
- Replay the linked receipts.
- Confirm no GitHub API call, webhook server, network collector, action
  execution, database, hidden state, or new adapter runtime is added.
