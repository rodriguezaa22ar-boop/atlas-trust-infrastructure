# GitHub Repo Trust Surface Example

This directory is a copyable starter kit for using Atlas receipts from another
GitHub repository.

It contains:

- `.github/workflows/atlas-receipts.yml`: GitHub Actions template that creates
  metadata-only Atlas receipts for the current workflow run.
- `.atlas/events/github-actions-run-event.json`: local sample workflow-run
  event.
- `.atlas/events/github-actions-check-event.json`: local sample check-run
  event.
- `scripts/import-github-actions-events.sh`: local helper for importing,
  verifying, and replaying the sample event chain.

The kit is intentionally metadata-only. It does not include raw workflow logs,
tokens, webhook payloads, prompts, model outputs, request bodies, response
bodies, customer data, or private artifacts.

## Local Tryout

Run from the Atlas repository root:

```bash
export ATLAS_ROOT="$PWD"
examples/github-repo-trust-surface/scripts/import-github-actions-events.sh \
  examples/github-repo-trust-surface/.atlas/events/github-actions-run-event.json \
  examples/github-repo-trust-surface/.atlas/events/github-actions-check-event.json \
  /tmp/atlas-github-repo-trust-surface
```

Expected output:

```text
atlas github repo trust surface: ok
receipts: /tmp/atlas-github-repo-trust-surface
```

## Target Repository Use

Copy the workflow into the target repository:

```bash
mkdir -p .github/workflows
cp examples/github-repo-trust-surface/.github/workflows/atlas-receipts.yml \
  .github/workflows/atlas-receipts.yml
```

The workflow checks out the target repository under `subject/`, checks out
Atlas under `atlas/`, writes `.atlas/events/*.json`, imports linked receipts,
verifies them, replays the chain, and uploads only metadata artifacts.

Before using it for a production-sensitive repository, pin workflow actions by
commit SHA and decide where retained receipts should live.
