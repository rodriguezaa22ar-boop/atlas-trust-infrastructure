# Milestone 88: Atlas Closeout Manifest JSON Parity

## Release Commit

`c575d23ee2294b0a9a1bcbf70e2b08d0a1c926bc` Add Atlas closeout manifest JSON parity

## Purpose

Give operation closeout manifests a machine-readable contract while preserving
the existing Markdown closeout manifest and read-only closeout verification
workflow.

## Added

- `atlas op closeout --json [name] [manifest-name]`.
- JSON closeout manifest schema `atlas.closeout_manifest.v1`.
- JSON manifest fields for:
  - operation identity
  - metadata-only and raw-artifact guardrails
  - close readiness and freshness state
  - latest report, evidence bundle, evidence manifest, and handoff references
  - operation ledger path, event count, and SHA-256 anchor
  - operation env, scope snapshot, evidence index, finding index, and
    validation index anchors
  - known limitations
- `atlas op verify` now accepts Markdown or JSON closeout manifests.
- JSON closeout verification checks:
  - schema version
  - operation id
  - metadata-only flags
  - forbidden raw-content markers
  - retained artifact SHA-256 anchors
  - operation ledger event count and SHA-256 anchor
  - later audit, archive, and accepted-risk review packet event tolerance when
    the recorded ledger prefix still matches
- Audit and archive paths consume the shared closeout verifier so downstream
  trust packets can anchor the latest JSON closeout manifest.
- Packet format parity docs now mark closeout manifests implemented and leave
  handoff packet JSON parity as the next packet gap.
- Schema docs, command references, operator walkthroughs, roadmap, blueprint,
  trust lifecycle, and Atlas README now reflect closeout JSON parity.

## Retained Evidence

- `docs/retention/releases/atlas-m88-closeout-manifest-json-parity.json`
- `docs/retention/releases/atlas-m88-closeout-manifest-json-parity.provenance.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-04-27_M88.md`
- Signed tag: `atlas-production-candidate-m88`

## Verified

- `bash -n tools/atlas/lib/closeout.sh tools/atlas/lib/audit.sh tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "operation readiness reports closure blockers and ready state|operation archive|trust lifecycle|packet format parity|schema docs pin|atlas help"'`: `6/6`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `97/97`, lint ok, stress ok
- `./tools/atlas/bin/atlas v1 status --strict`: ready
- `./tools/atlas/bin/atlas release packet atlas-m88-closeout-manifest-json-parity --json --qa-status pass --qa-command "nix-shell --run './bin/dev-qa'" --qa-note "dev-qa passed with 97/97 tests, lint ok, and stress ok before M88 closeout manifest JSON parity release packet"`
- `./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m88-closeout-manifest-json-parity.json --commit c575d23ee2294b0a9a1bcbf70e2b08d0a1c926bc`: verified
- `./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m88-closeout-manifest-json-parity.json --skip-qa`: verified
- `git tag -v atlas-production-candidate-m88`: good signature

## Repo State

- Release commit: `c575d23ee2294b0a9a1bcbf70e2b08d0a1c926bc`.
- Release packet retained.
- Release provenance packet retained.
- Production dry-run note retained.
- Closeout manifest JSON parity is implemented and verified.
- Handoff packet JSON parity remains the next packet-format gap.
- No production-ready claim is made.
