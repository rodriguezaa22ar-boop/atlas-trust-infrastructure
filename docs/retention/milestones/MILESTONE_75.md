# Milestone 75: Atlas Release Replay Command

## Release Commit

`94d6dccc9bea016822a30e80a930ab9d35e77e10` Harden Atlas release replay checkout isolation

## Purpose

Promote release replay from a documented runbook to an implemented Atlas
command that checks a retained release packet from the commit recorded inside
the packet.

## Added

- `atlas release replay [packet]`.
- `--skip-qa` for faster metadata replay when full QA is handled separately.
- `--keep-worktree` to preserve the temporary replay checkout for debugging.
- Replay commit extraction for JSON and Markdown release packets.
- Isolated temporary replay checkout so replay QA cannot mutate the parent
  repository's Git refs or Atlas state paths.
- Environment scrubbing for replayed Atlas commands so child checkouts do not
  inherit parent `LAB_*` paths.
- Replay checks for QA, v1 strict readiness, and `atlas release verify
  <packet> --commit <commit>`.
- Negative tests for missing packet commit and unavailable Git commit.
- Documentation updates across release trust, command reference, replay runbook,
  Atlas README, trust lifecycle, trust object model, roadmap, and blueprint.

## Retained Evidence

- `docs/retention/releases/atlas-m75-release-replay-command.json`
- `docs/retention/releases/atlas-m75-release-replay-command.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M75.md`
- Signed tag: `atlas-production-candidate-m75`

## Verified

- `bash -n tools/atlas/lib/release.sh tools/atlas/bin/atlas`
- `git diff --check`
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m74-trust-object-model.json --skip-qa`: verified
- `nix-shell --run 'bats --filter "release replay|release packet writes|atlas help|schema docs|trust object model" tests/atlas.bats'`: `6/6`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `88/88`, lint ok, stress ok
- `./tools/atlas/bin/atlas release packet atlas-m75-release-replay-command --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed before M75 release replay command release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m75-release-replay-command.json --commit 94d6dcc`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m75-release-replay-command.json`: QA ok, v1 status ok, release verify ok
- `git tag -v atlas-production-candidate-m75`: good signature

## Repo State

- Release commit: `94d6dccc9bea016822a30e80a930ab9d35e77e10`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- `atlas release replay` is implemented and covered by tests.
- Business Flow Evidence remains optional.
- `atlas flow packet`, `atlas flow verify`, and optional readiness integration
  remain the next planned Business Flow Evidence steps.
