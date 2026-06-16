# GitHub Repository Trust Surface

## Purpose

This workflow shows how a GitHub repository can use Atlas as a
metadata-only trust overlay without turning Atlas into a live GitHub
integration.

Use it when another repository wants replayable proof for CI, release, or
AI-agent activity while keeping raw logs, tokens, prompts, model outputs,
customer data, and private artifacts outside Atlas receipts.

Atlas verifies the shape, hashes, linkage, and replayability of local proof
metadata. It does not prove GitHub source-system truth, grant authorization,
certify compliance, or replace reviewer judgment.

## Repository Layout

Add this local trust surface to each repository that wants Atlas receipts:

```text
.atlas/
  events/
  receipts/
  releases/
.github/
  workflows/
    atlas-receipts.yml
```

The target repository owns the `.atlas/events/` files that describe what
happened. Atlas imports those files and writes `.atlas/receipts/` outputs.

The recommended starting template lives at:

```text
examples/github-repo-trust-surface/
```

Copy the example workflow into a target repository:

```bash
mkdir -p .github/workflows
cp examples/github-repo-trust-surface/.github/workflows/atlas-receipts.yml \
  .github/workflows/atlas-receipts.yml
```

For a local dry run, keep Atlas outside the target repository and point
`ATLAS_ROOT` at the Atlas checkout:

```bash
export ATLAS_ROOT=/path/to/atlas-trust-infrastructure
examples/github-repo-trust-surface/scripts/import-github-actions-events.sh \
  examples/github-repo-trust-surface/.atlas/events/github-actions-run-event.json \
  examples/github-repo-trust-surface/.atlas/events/github-actions-check-event.json \
  /tmp/atlas-github-repo-receipts
```

## What To Record

Record metadata references, not raw evidence bodies.

Good fields:

- repository name
- workflow name
- workflow run id
- check name
- check or job conclusion
- commit SHA
- branch or pull request reference
- release packet path
- artifact path plus SHA-256
- reviewer-visible limitation notes
- approval reference identifiers
- AI-agent action/result hashes

Forbidden fields:

- `GITHUB_TOKEN` or any other token
- Authorization headers
- raw workflow logs
- raw check annotations
- webhook payload bodies
- request or response bodies
- cookies or sessions
- raw prompts
- raw model outputs
- tool output bodies
- private keys
- customer or payment data
- unredacted evidence bodies

## GitHub Actions Mode

The example workflow checks out the subject repository and this Atlas
repository, creates two local `generic.external_event.v1` metadata files, and
imports them into linked Atlas receipts:

```text
github.actions.workflow_run.completed
github.actions.check_run.completed
```

The workflow uploads only event and receipt JSON artifacts. It does not upload
raw logs, webhook payloads, secrets, prompts, or model outputs.

Before using the workflow for a production-sensitive repository, pin external
actions by commit SHA and decide whether receipt artifacts should be retained
in GitHub Actions artifacts, committed under `.atlas/receipts/`, copied to an
internal evidence store, or packaged into a release packet.

## Local Reviewer Mode

A reviewer can clone Atlas and the target repository, then run:

```bash
atlas_root=/path/to/atlas-trust-infrastructure
target_root=/path/to/target-repository

"$atlas_root/tools/atlas/bin/atlas" receipt import-generic-event \
  "$target_root/.atlas/events/github-actions-run-event.json" \
  --out "$target_root/.atlas/receipts/github-actions-run.receipt.json"

prev_hash="$(jq -r '.event_hash' \
  "$target_root/.atlas/receipts/github-actions-run.receipt.json")"

"$atlas_root/tools/atlas/bin/atlas" receipt import-generic-event \
  "$target_root/.atlas/events/github-actions-check-event.json" \
  --prev-hash "$prev_hash" \
  --out "$target_root/.atlas/receipts/github-actions-check.receipt.json"

"$atlas_root/tools/atlas/bin/atlas" receipt verify \
  "$target_root/.atlas/receipts/github-actions-run.receipt.json"

"$atlas_root/tools/atlas/bin/atlas" receipt verify \
  "$target_root/.atlas/receipts/github-actions-check.receipt.json"

"$atlas_root/tools/atlas/bin/atlas" receipt replay \
  "$target_root/.atlas/receipts/github-actions-run.receipt.json" \
  "$target_root/.atlas/receipts/github-actions-check.receipt.json"
```

## AI-Agent Repositories

For Codex or other agent-assisted repositories, use the same `.atlas/` surface
with the AI-agent profile:

- `ai_agent.action.proposed`
- `ai_agent.action.reported`

Keep only action summaries, capability references, approval references, and
input/output hashes. Do not store raw prompts, raw model outputs, or raw tool
output bodies in the event file or receipt.

Use:

```bash
"$ATLAS_ROOT/tools/atlas/bin/atlas" receipt import-generic-event \
  .atlas/events/ai-agent-action-event.json \
  --out .atlas/receipts/ai-agent-action.receipt.json
```

Then link the result event with `--prev-hash` and replay both receipts.

## Reviewer Output

A target repository can summarize the result without copying raw CI logs:

```text
repository: owner/name
commit: <sha>
workflow_run_receipt: .atlas/receipts/github-actions-run.receipt.json
check_receipt: .atlas/receipts/github-actions-check.receipt.json
verification:
  run_receipt: present
  check_receipt: present
  linked_replay: present
known_limitations:
  - Atlas verified local metadata shape and receipt linkage.
  - Atlas did not call GitHub or prove source-system truth.
  - Raw logs, tokens, webhook payloads, prompts, and model outputs were not embedded.
```

Missing, stale, or unverifiable evidence should drive follow-up review. It
should not be treated as sufficient by default.
