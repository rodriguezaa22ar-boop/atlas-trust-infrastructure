# GitHub Actions Event Proof Package M153

## Purpose

This proof package gives reviewers one place to inspect the GitHub Actions
run/check metadata receipt path introduced in M151 and security-tested in M152.

It packages the existing public proof surface only:

- M151 GitHub Actions run receipt candidate.
- M152 GitHub Actions event security regression.

This package does not add GitHub API calls, webhook collection, action
execution, network collection, a database, a server, a web UI, hidden state, a
new adapter, runtime behavior, receipt semantics, or any production approval
claim. It uses only the existing `generic.external_event.v1` adapter and the
existing receipt verify and replay commands.

Boundary statement:

```text
GitHub Actions metadata is an event source only.
Atlas is verifier only.
Human and policy remain authority.
```

## Reviewed Commit

```text
3a6ddccc3d9014ed41d5796a56be3503a60a0b4b
```

This is the merged M152 checkpoint on `main`. It includes the GitHub Actions
run/check candidate, security regression, examples, narrow fail-closed
hardening, and retained milestone notes that this package references.

## Package Map

Primary reviewer entry points:

- [docs/reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md)
- [docs/retention/milestones/MILESTONE_152.md](../retention/milestones/MILESTONE_152.md)
- [docs/adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md](../adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md)
- [schemas/generic-external-event.v1.schema.json](../../schemas/generic-external-event.v1.schema.json)

GitHub Actions run/check event examples:

- [examples/adapters/generic-external-event/github-actions-run-event.json](../../examples/adapters/generic-external-event/github-actions-run-event.json)
- [examples/adapters/generic-external-event/github-actions-check-event.json](../../examples/adapters/generic-external-event/github-actions-check-event.json)

Retained proof history:

- [docs/retention/milestones/MILESTONE_151.md](../retention/milestones/MILESTONE_151.md)
- [docs/retention/milestones/MILESTONE_152.md](../retention/milestones/MILESTONE_152.md)

## Import Workflow Run Event

Run from the repository root:

```bash
run_receipt=/tmp/atlas-m153-github-actions-run.receipt.json

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/github-actions-run-event.json \
  --out "$run_receipt"
```

Expected output:

```text
receipt: /tmp/atlas-m153-github-actions-run.receipt.json
```

## Verify Workflow Run Receipt

```bash
./tools/atlas/bin/atlas receipt verify "$run_receipt"
```

Expected verifier output shape:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

JSON verifier check:

```bash
./tools/atlas/bin/atlas receipt verify "$run_receipt" --json | jq -e '
  .schema_version == "atlas.receipt_verify.v1" and
  .status == "ok" and
  .metadata_only == true and
  .raw_artifacts_embedded == false
'
```

## Import Linked Check Run Event

```bash
check_receipt=/tmp/atlas-m153-github-actions-check.receipt.json
prev_hash="$(jq -r '.event_hash' "$run_receipt")"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/github-actions-check-event.json \
  --prev-hash "$prev_hash" \
  --out "$check_receipt"
```

Expected output:

```text
receipt: /tmp/atlas-m153-github-actions-check.receipt.json
```

## Verify Check Run Receipt

```bash
./tools/atlas/bin/atlas receipt verify "$check_receipt"
```

Expected verifier output shape:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

JSON verifier check:

```bash
./tools/atlas/bin/atlas receipt verify "$check_receipt" --json | jq -e '
  .schema_version == "atlas.receipt_verify.v1" and
  .status == "ok" and
  .metadata_only == true and
  .raw_artifacts_embedded == false
'
```

## Replay Linked Run And Check Receipts

```bash
./tools/atlas/bin/atlas receipt replay \
  "$run_receipt" \
  "$check_receipt"
```

Expected replay output shape:

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

## Security Boundary Evidence

M152 is the retained fail-closed security regression for this candidate:

- [../retention/milestones/MILESTONE_152.md](../retention/milestones/MILESTONE_152.md)

M152 proves that unsafe GitHub Actions event imports fail closed before any
live GitHub integration is added. It covers rejection of:

- GitHub token-shaped markers
- `Authorization: Bearer`
- webhook secret markers
- `raw_logs`
- `raw_job_output`
- `raw_workflow_output`
- `raw_request`
- `raw_response`
- environment secret fields
- private-key markers
- `metadata_only=false`
- `raw_artifacts_embedded=true`
- missing `known_limitations`
- malformed artifact references
- missing repository, workflow, run, or check identity references

Expected failure text for unsafe raw or secret-bearing inputs includes:

```text
generic external event contains forbidden raw-content marker
```

Expected failure text for missing GitHub Actions identity references includes:

```text
invalid GitHub Actions event profile fields
```

## Metadata-Only Boundary

Allowed:

- read a caller-provided local `generic.external_event.v1` JSON file;
- write only the caller-requested receipt output file;
- verify the generated receipt;
- replay the caller-provided receipt chain;
- preserve `metadata_only=true`;
- preserve `raw_artifacts_embedded=false`.

Not allowed:

- No GitHub API calls.
- No webhook server.
- No network collector.
- No action execution.
- No action rerun, cancellation, approval, or dispatch behavior.
- No database.
- No new adapter.
- No hidden state.
- No runtime behavior added.
- No receipt semantics changed.
- no raw workflow logs, job output, check annotations, webhook payloads,
  artifacts, credentials, or secrets embedded;
- no production readiness, approval, certification, legal compliance, source
  truth, runtime safety, or external audit claim.

## What Atlas Proves

For the reviewed public path, Atlas proves:

- the GitHub Actions run/check examples are valid `generic.external_event.v1`
  imports;
- the existing generic adapter can produce GitHub Actions event receipts;
- generated receipts verify with `atlas receipt verify`;
- a workflow run receipt can be linked to a check run receipt through
  `prev_hash`;
- linked run/check receipts replay with `atlas receipt replay`;
- replay preserves `metadata_only=true`;
- replay preserves `raw_artifacts_embedded=false`;
- unsafe GitHub token-shaped, webhook secret, raw CI output, raw request,
  raw response, private-key, malformed artifact, and missing identity inputs
  reject;
- rejected unsafe imports do not create the requested output receipt;
- public documentation points to known limitations and non-guarantees.

## What Atlas Does Not Prove

This proof package does not prove:

- the GitHub Actions run exists;
- the GitHub Actions check exists;
- the reported conclusion is true;
- the workflow logs, job output, annotations, or artifacts are correct;
- the workflow was authorized;
- the run was safe;
- GitHub availability, authenticity, or API state;
- source-system truth;
- human intent;
- legal compliance;
- runtime safety;
- production approval;
- external audit;
- certification.

## Known Limitations

- The example GitHub Actions events are representative local metadata samples,
  not live GitHub queries.
- The package does not inspect GitHub logs, check annotations, webhook payloads,
  artifacts, credentials, or secrets.
- Atlas does not call GitHub, verify the run exists, verify check correctness,
  or prove source-system truth.
- Replay verifies local receipt hashes and caller-provided chain order only.
- A successful receipt is not a GitHub audit, certification, compliance result,
  runtime safety proof, artifact correctness proof, authorization proof, or
  production approval.
- This package does not add a GitHub adapter; it uses the existing generic
  external event adapter only.

## Reviewer Checklist

- Confirm both example files declare `schema_version:
  generic.external_event.v1`.
- Confirm both example files set `metadata_only=true`.
- Confirm both example files set `raw_artifacts_embedded=false`.
- Confirm M151 documents the local-file import-only GitHub Actions candidate.
- Confirm M152 documents fail-closed security regression coverage.
- Import the workflow run event.
- Verify the workflow run receipt.
- Import the check run event with `--prev-hash`.
- Verify the check run receipt.
- Replay the linked receipts.
- Confirm no GitHub API call, webhook server, network collector, action
  execution, database, hidden state, runtime behavior, new adapter, or receipt
  semantic change is added.
