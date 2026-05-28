# Milestone 147: AI Agent Event Quickstart

## Commit

`fd95fe54b0faba8d96fb9a0b0e0f023912b3db72` M147 add AI agent event quickstart

## Pull Request

PR #50

## Purpose

Make the AI-agent event receipt profile tryable by an outside reviewer without
requiring a model provider, network collector, webhook, scanner, backend, or
agent runtime.

## Added

- Added `docs/TRY_AI_AGENT_EVENT_RECEIPTS.md`.
- Added a metadata-only `atlas_node.local_model.used` generic external event
  example under `examples/adapters/generic-external-event/`.
- Documented the optional builder-backed local model helper boundary in the
  dual-node cockpit runbook.
- Extended the AI-agent receipt profile with `task_label`, `summary`, and the
  local model helper event rule.
- Linked the quickstart from the README and documentation index.
- Added focused Bats coverage for the quickstart, local model helper example,
  optional workstation command-policy labels, metadata-only receipt import,
  receipt verification, linked replay, no-hidden-runtime-state behavior, and
  README/index guards.

## Validation

- CodeQL: passed.
- Nix QA: passed.
- Release Trust: passed.
- GitHub Actions workflow analysis: passed.
- Builder pre-merge focused M147/root README Bats: passed, 2/2.
- Builder pre-merge `nix-shell --run './bin/dev-qa'`: passed with 139/139
  Bats plus lint, capabilities, adapters, policy, approval, evidence,
  portability, and stress.
- Local model smoke: `builder-api-status` active and `builder-chat` returned
  `TEST_OK`.
- Builder post-merge `nix-shell --run './bin/dev-qa'`: passed with 139/139
  Bats plus lint, capabilities, adapters, policy, approval, evidence,
  portability, and stress.

## Trust Impact

M147 turns the M146 AI-agent event profile into a copy-paste reviewer path
while keeping Atlas inside the verifier boundary. AI-agent and local-model
events remain metadata-only external events imported through the existing
generic adapter. Atlas does not call a model provider, run tools for an agent,
approve model output, collect network events, or treat the optional local model
helper as a trust source.

## Boundaries

- Docs, examples, and tests only.
- AI agents are event sources only.
- Optional local model helper is workflow support only.
- No agent execution.
- No agent authority.
- No approval-engine behavior.
- No network collector.
- No new adapter added.
- No runtime behavior changed.
- No receipt semantics changed.
- No raw prompts or raw model outputs embedded by default.
- No API keys, local tunnel secrets, raw logs, tool output bodies, tokens, or
  private files embedded.
- Generated AI-agent event receipts verify.
- Linked AI-agent event receipts replay.
- Generated local-model usage receipt verifies.
- No database, server, web UI, production claim, or live integration added.
- `metadata_only=true` preserved.
- `raw_artifacts_embedded=false` preserved.
- `known_limitations` required and visible.
- Tag target: `atlas-retention-m147`.
