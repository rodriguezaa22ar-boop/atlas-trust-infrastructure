# Milestone 54: Atlas Root Agent Guidance

## Commit

`96ff1e53a9af3318d412ee963bff400867ec7f11` Add root agent guidance for Atlas

## Purpose

Add strict root-level repository guidance for future agent work across
`atlas-lab-toolkit`.

## Added

- Root `AGENTS.md`.
- Domain boundaries for `atlas`, `wiremap`, `vector`, `intelctl`, and `labctl`.
- Internal-readiness language and anti-overclaiming guidance.
- Authorized-assessment safety boundary.
- Capability-tier expectations.
- Nix development and QA expectations.
- Shell-native style rules.
- File-backed state and metadata-only packet rules.
- Read-only command rule, including `atlas op trust-chain` and
  `atlas release verify`.
- Release-trust consolidation guidance, including operation trust-chain binding,
  replay verification, and Markdown/JSON parity.
- Documentation, testing, AI Advisor, Atlas OS, web UI, command-design, and
  public-positioning boundaries.

## Behavior

This milestone does not change runtime command behavior. It gives future Codex
and agent sessions a strict repo-root contract for how to work safely and
accurately in the toolkit.

## Boundaries

The guidance explicitly avoids production-readiness claims, autonomous
execution, offensive overclaiming, raw artifact embedding, and premature Atlas
OS/ISI/kernel assumptions.

## Verified

- `git diff --cached --check`
- `nix-shell --run './bin/dev-qa'`: `72/72`, lint ok, stress ok

## Repo State

- Implementation committed at `96ff1e53a9af3318d412ee963bff400867ec7f11`.
- Retention note present.
- Tag target: `atlas-retention-m54`.
