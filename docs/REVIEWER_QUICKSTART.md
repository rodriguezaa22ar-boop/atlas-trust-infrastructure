# Reviewer Quickstart

## Purpose

Atlas supports a simplified reviewer path for a first local receipt review. Use
this when you want to see one receipt verify, one receipt replay, one local
GitHub Actions metadata import, and the reviewer decision path without reading
every schema first.

This quickstart reduces the adoption friction recorded in
[reviews/ADOPTION_FRICTION_DRY_RUN_M167.md](reviews/ADOPTION_FRICTION_DRY_RUN_M167.md):

- Nix setup friction;
- technical replay output;
- `prev_hash` command shape friction;
- risk that reviewers confuse evidence `present` with evidence sufficient.

## Start Here

Run these commands from a fresh clone:

```bash
git clone <repo> atlas-review
cd atlas-review
nix-shell --run './tools/atlas/bin/atlas receipt verify examples/receipt/minimal.json'
nix-shell --run './tools/atlas/bin/atlas receipt replay examples/receipt/demo-site/*.json'
```

Expected plain-English result:

```text
First verify: Atlas checked that one proof receipt is structurally valid and
its hashes match.

First replay: Atlas checked that the demo receipts link together in the
provided order.
```

This gives a first result before the full QA gate. When you need the complete
local proof gate, run:

```bash
nix-shell --run './bin/dev-qa'
nix-shell --run './bin/export-public-trust --check'
```

Expected output shape:

```text
qa: ok
Public Trust Export
Overall: ok
```

## First Receipt Verify

Copy and paste:

```bash
nix-shell --run './tools/atlas/bin/atlas receipt verify examples/receipt/minimal.json'
```

Expected output shape:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
```

Plain-English meaning:

```text
Atlas checked that the proof receipt is well-formed, metadata-only, and locally
hash-consistent.
```

## First Receipt Replay

Copy and paste:

```bash
nix-shell --run './tools/atlas/bin/atlas receipt replay examples/receipt/demo-site/*.json'
```

Expected output shape:

```text
receipt replay: ok
metadata-only boundary: ok
This replay verifies receipt hashes and provided-order prev_hash linkage only.
```

Plain-English meaning:

```text
Atlas checked that the receipt hashes match and that the caller-provided
receipt order links correctly. Replay does not prove external source-system
truth or show every possible outside event.
```

## GitHub Actions Metadata Import

Use the retained GitHub Actions run/check examples for a local CI release
review trial. These are local files. Atlas does not call the GitHub API, run a
webhook, collect from the network, or execute actions.

Copy and paste:

```bash
nix-shell --run './tools/atlas/bin/atlas receipt import-generic-event examples/adapters/generic-external-event/github-actions-run-event.json --out /tmp/github-actions-run.atlas.json'
nix-shell --run './tools/atlas/bin/atlas receipt verify /tmp/github-actions-run.atlas.json'
```

Expected output shape:

```text
receipt: /tmp/github-actions-run.atlas.json
receipt: ok
```

Plain-English meaning:

```text
Atlas imported local GitHub Actions run metadata into a metadata-only proof
receipt and verified the generated receipt.
```

## Linked Check Import And Replay

The linked check receipt needs the run receipt's event hash. That value becomes
the `prev_hash` for the next receipt.

`prev_hash` means:

```text
This receipt says it follows the previous event hash. During replay, Atlas
checks that the provided order matches that link.
```

Copy and paste:

```bash
nix-shell --run 'prev_hash="$(jq -r ".event_hash" /tmp/github-actions-run.atlas.json)" && ./tools/atlas/bin/atlas receipt import-generic-event examples/adapters/generic-external-event/github-actions-check-event.json --prev-hash "$prev_hash" --out /tmp/github-actions-check.atlas.json'
nix-shell --run './tools/atlas/bin/atlas receipt verify /tmp/github-actions-check.atlas.json'
nix-shell --run './tools/atlas/bin/atlas receipt replay /tmp/github-actions-run.atlas.json /tmp/github-actions-check.atlas.json'
```

Expected output shape:

```text
receipt: /tmp/github-actions-check.atlas.json
receipt: ok
receipt replay: ok
metadata-only boundary: ok
```

Plain-English meaning:

```text
Atlas verified the run receipt, verified the check receipt, and replayed the
run -> check chain in the provided order.
```

## Evidence Present Is Not Evidence Sufficient

Evidence `present` does not automatically mean evidence sufficient.

Use [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md)
to classify each evidence item:

| Status | Plain-English meaning |
| --- | --- |
| `present` | Evidence exists and can be referenced or verified locally. |
| `missing` | Required evidence is absent. |
| `stale` | Evidence exists but may no longer match the reviewed state. |
| `unverifiable` | Evidence exists but Atlas cannot verify it locally. |

Missing events may exist outside the proof chain. A present run/check receipt
does not prove that every source-system event was captured or that a human
approval was complete.

## Reviewer Decision Summary

Use [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md)
to turn the evidence status into a reviewer action:

- proceed with internal review;
- request missing evidence;
- rerun verification;
- refresh stale retained evidence;
- reject the release-readiness claim until required evidence is present;
- escalate to a reviewer, auditor, approver, or authority.

For a plain-English result, use
[reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md](reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md).

For the full one-day CI release workflow, use
[workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md).

## What To Do When Blocked

### Nix Shell Missing

If `nix-shell` is not available:

- use the host/runtime and portability docs to install or enter the reference
  environment;
- ask for a Nix-capable review environment;
- do not treat a missing local tool as proof that Atlas evidence failed.

Start here:

- [ops/HOST_SHELL_RUNTIME.md](ops/HOST_SHELL_RUNTIME.md)
- [ops/NIX_REFERENCE_ENVIRONMENT.md](ops/NIX_REFERENCE_ENVIRONMENT.md)
- [ops/PORTABILITY_CONTRACT.md](ops/PORTABILITY_CONTRACT.md)

### Command Failed

If a command fails:

- keep the command, exit code, and short summary;
- do not paste raw logs, secrets, request bodies, response bodies, or full
  terminal dumps into the review packet;
- rerun only after checking the path and command spelling.

### Replay Failed

If replay fails:

- confirm the receipt order;
- confirm the second receipt used the first receipt's `event_hash` as
  `prev_hash`;
- treat the linked chain as `unverifiable` until replay passes.

### Evidence Missing, Stale, Or Unverifiable

If evidence is missing, stale, or unverifiable:

- do not mark the objective sufficient by default;
- request missing evidence or refresh stale evidence;
- escalate to the reviewer, auditor, approver, or authority when outside
  Atlas determination is required.

## Related Review Docs

- [reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md)
- [reviews/REVIEWER_DECISION_PACKET_M160.md](reviews/REVIEWER_DECISION_PACKET_M160.md)
- [reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md](reviews/REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md)
- [workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md)
- [reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md)

## Known Limitations

- This quickstart uses synthetic examples and local files.
- It does not add a live integration, GitHub API call, webhook, network
  collector, database, server, web UI, or new adapter.
- Receipt replay verifies receipt hashes and caller-provided chain order, not
  external truth.
- Missing events may exist outside the proof chain.
- A present receipt does not prove approval completeness, source-system truth,
  legal sufficiency, deployment approval, or production readiness.
- Reviewers, approvers, auditors, and authorities still make final
  determinations.
