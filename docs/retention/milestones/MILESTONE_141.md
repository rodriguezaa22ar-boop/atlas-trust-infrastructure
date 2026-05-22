# Milestone 141: Receipt Open-Core RC Packaging

## Commit

`235b22277e62233682be01fabea62dee631afe2f` M140 refresh release reviewer evidence

## Purpose

Package the current Atlas receipt, replay, and reviewer-proof surface into a
clear open-core release-candidate story without adding runtime behavior.

## Added

- Added `docs/RECEIPT_OPEN_CORE_RC.md`
- Updated `docs/INDEX.md`
- Added a concise root `README.md` link to the receipt RC package while
  preserving the README line limit
- Added focused Bats coverage for the receipt RC packaging document, links,
  retained M140 evidence references, reviewer package path, and non-overclaim
  language

## Validation

- `git diff --check`: passed.
- Focused builder docs/RC Bats filter: passed.
- Builder `nix-shell --run './bin/dev-qa'`: passed with 133/133 Bats plus
  lint, portability, and stress.
- `./bin/export-public-trust --check`: passed.

## Trust Impact

M141 makes the existing receipt core easier to review without expanding Atlas.
It gathers the five-minute receipt quickstart, Receipt v1 schema, replay
schema, canonicalization contract, synthetic demo receipt packet, security
regression suite, reviewer package path, and M140 retained release evidence into
one bounded reviewer-facing RC package.

## Boundaries

- This milestone is docs and tests only.
- This milestone does not add runtime behavior.
- This milestone does not add server, database, network, agent, or demo-site
  integration behavior.
- This milestone does not change receipt semantics.
- This milestone does not weaken release or reviewer gates.
- This milestone does not claim external audit, certification, legal
  compliance, tamper-proof infrastructure, production deployment approval, or
  external SLSA certification.
- Tag target: `atlas-retention-m141`.
