# Milestone 94: Business Flow Control Coverage Assurance

## Release Commit

`e8d0e6cdb60cd8f358655d58f72f422e27caddb0` Add business flow control coverage assurance

## Purpose

Deepen optional Business Flow Evidence by making declared flow control
objectives visible in `atlas flow assurance` without claiming per-control proof
or storing raw business data.

## Added

- Aggregate control objective coverage in `atlas flow assurance`.
- JSON `coverage_model: aggregate-flow-v1`.
- JSON `controls[]` entries for declared control objectives.
- Assurance counts for:
  - declared control objectives
  - aggregate evidence-covered controls
  - validation-covered controls
- Assurance checks for declared controls and aggregate control coverage.
- Documentation clarifying that Atlas does not yet map one evidence artifact to
  one control objective.
- Bats coverage for current and attention-required control coverage states.

## Verified

- `bash -n tools/atlas/lib/flows.sh`
- `bash -n tools/atlas/bin/atlas`
- `git diff --check`
- `nix-shell --run './bin/dev-test tests/atlas.bats --filter "atlas flow assurance reports business-process status read-only|business-flow evidence design stays optional and metadata-only"'`: wrapper ran `tests/atlas.bats`, `100/100`
- `nix-shell --run './bin/dev-qa'`: `100/100`, lint ok, stress ok

## Repo State

- Business Flow Evidence remains optional and non-blocking.
- Control coverage is aggregate in this milestone.
- No target-touching behavior was added.
- No production-ready, external audit, payment verification, legal compliance,
  or third-party assurance claim is made by this milestone.
