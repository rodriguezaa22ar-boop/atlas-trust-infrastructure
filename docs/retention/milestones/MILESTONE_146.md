# Milestone 146: AI Agent Event Receipt Profile

## Commit

`f019e56b52c85a2b0eb5ef50d843cdda0605fe37` M146 add AI agent event receipt profile

## Pull Request

PR #48

## Purpose

Represent AI-agent activity as metadata-only receipts without giving the agent
execution authority.

## Added

- Added `docs/adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md`.
- Added synthetic AI-agent proposal and reported-result events under the
  existing `generic.external_event.v1` adapter examples.
- Linked the profile from the generic external event adapter docs and
  documentation index.
- Added focused Bats coverage for AI-agent profile import, receipt verify,
  linked replay, raw prompt/output rejection, secret marker rejection, and
  no-hidden-runtime-state behavior.

## Validation

- CodeQL: passed.
- Nix QA: passed.
- Release Trust: passed.
- GitHub Actions workflow analysis: passed.
- Builder pre-merge focused M143/M144/M145/M146 adapter/profile Bats: passed,
  4/4.
- Builder pre-merge `./bin/export-public-trust --check`: passed.
- Builder pre-merge `nix-shell --run './bin/dev-qa'`: passed with 138/138
  Bats plus lint, capabilities, adapters, policy, approval, evidence,
  portability, and stress.
- Builder post-merge `nix-shell --run './bin/dev-qa'`: passed with 138/138
  Bats plus lint, portability, and stress.

## Trust Impact

M146 extends the generic import-only event pattern to AI-agent activity while
keeping the agent outside the authority and execution boundary. Atlas imports
metadata-only proposal/report events, produces verifiable receipts, and replays
linked proof without calling model providers, running tools, approving actions,
or creating hidden runtime state.

## Boundaries

- Docs, examples, and tests only.
- AI agents are event sources only.
- No agent execution.
- No agent authority.
- No network collector.
- No hidden runtime state.
- Raw prompt, raw model response, system prompt, tool output body, secret, and
  bearer-token cases reject.
- Generated AI-agent event receipts verify.
- Linked AI-agent event receipts replay.
- No new adapter added.
- No runtime behavior changed.
- No receipt semantics changed.
- No database, server, web UI, production claim, or live integration added.
- `metadata_only=true` preserved.
- `raw_artifacts_embedded=false` preserved.
- `known_limitations` required and visible.
- Tag target: `atlas-retention-m146`.
