# GitHub Adapter

Status: import-only contract.

This adapter may ingest GitHub release, workflow, pull request, attestation, and
repository metadata into Atlas proof. It must not mutate GitHub state until a
future wrapper is capability-mapped, policy-checked, approval-aware, and
evidence-backed.

For a copyable target-repository integration path, see
`docs/workflows/GITHUB_REPO_TRUST_SURFACE.md` and
`examples/github-repo-trust-surface/`. That workflow emits local
`generic.external_event.v1` metadata files and imports them into linked Atlas
receipts without calling GitHub APIs or embedding raw logs, tokens, webhook
payloads, prompts, model outputs, or private artifacts.
