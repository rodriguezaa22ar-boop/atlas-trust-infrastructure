# Milestone 148: AI-Agent Event Security Regression

## Commit

`a0e067734d5f6b941e97b311a70743d3e2144b4c` M148 harden AI agent event receipts

## Pull Request

PR #52

## Purpose

Prove the AI-agent event receipt profile fails closed against unsafe inputs
before adding any new agent or event surface.

## Added

- Added focused security regression coverage for AI-agent generic external
  events.
- Added rejection coverage for `raw_prompt`, `raw_model_output`,
  `raw_response`, `system_prompt`, `tool_output_body`, and `tool_call_raw`.
- Added rejection coverage for Authorization/Bearer markers,
  token/password/secret markers, and generic private-key markers.
- Added rejection coverage for `metadata_only=false`,
  `raw_artifacts_embedded=true`, missing `known_limitations`, missing actor
  identity, and missing AI-agent profile identity.
- Added rejection coverage for `approval_required=true` AI-agent events without
  approval references.
- Added checks that rejected imports do not create output receipts.
- Added checks that successful imports write only the requested receipt output
  and create no hidden runtime directories.
- Verified AI-agent proposed-action and result receipts still import, verify,
  and replay as a linked chain.
- Narrowly hardened generic event import validation for AI-agent profile fields
  and unsafe embedded AI-agent raw fields.

## Validation

- CodeQL: passed.
- Nix QA: passed.
- Release Trust: passed.
- GitHub Actions workflow analysis: passed.
- Local direct CLI smoke: passed.
- Builder pre-merge focused M148 Bats: passed.
- Builder pre-merge focused M137/M143-M148 Bats: passed, 8/8.
- Builder pre-merge `./bin/export-public-trust --check`: passed.
- Builder pre-merge `nix-shell --run './bin/dev-qa'`: passed with 140/140
  Bats plus lint, capabilities, adapters, policy, approval, evidence,
  portability, and stress.
- Builder post-merge `nix-shell --run './bin/dev-qa'`: passed with 140/140
  Bats plus lint, capabilities, adapters, policy, approval, evidence,
  portability, and stress.

## Trust Impact

M148 hardens the AI-agent event receipt profile by making unsafe AI-agent
generic event imports fail closed while keeping Atlas inside the verifier
boundary. AI agents remain event sources only. Atlas does not become an
approval authority, execution engine, network collector, or trust source for
model output.

## Boundaries

- Tests-first security regression with narrow runtime hardening.
- AI agents are event sources only.
- Atlas remains verifier, not authority.
- Human and policy remain authority.
- No agent runtime.
- No tool execution.
- No network collector.
- No second adapter.
- No database, server, or web UI.
- No hidden state.
- No production claim.
- Raw prompts, raw model outputs, system prompts, tool output bodies, and raw
  tool calls reject.
- Authorization/Bearer, token/password/secret, and generic private-key markers
  reject.
- `approval_required=true` AI-agent events require approval references.
- Rejected imports create no output receipts.
- Successful imports write only requested receipt output.
- Valid AI-agent proposed-action and result receipts verify.
- Linked AI-agent receipts replay.
- `metadata_only=true` preserved.
- `raw_artifacts_embedded=false` preserved.
- `known_limitations` required and visible.
- Tag target: `atlas-retention-m148`.
