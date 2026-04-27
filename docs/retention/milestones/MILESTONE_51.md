# Milestone 51: Atlas Release Candidate Trust-Chain Binding

## Commit

`26abbe425f82c7162fbfdeac1e7d9e94b3b87e3f` Bind Atlas release packets to operation trust chains

## Purpose

Require and record a current operation trust chain when a release candidate is
explicitly tied to a completed Atlas operation.

## Added

- `atlas release packet --operation <name>`.
- Release packet guard that requires operation trust-chain status `current` when
  `--operation` is supplied.
- Markdown release packet operation trust-chain summary.
- JSON release packet `operation_trust_chain` object.
- `atlas release verify` validation for any recorded operation trust-chain
  status.
- Regression coverage for:
  - release packets without operation trust-chain binding
  - failed release candidate packet generation when operation trust chain is not
    current
  - JSON release packet generation with a current operation trust chain
  - release verification of recorded operation trust-chain status
- README, Atlas CLI docs, trust lifecycle, blueprint, and v1 readiness contract
  updates.

## Behavior

Standard release packets remain supported and record `operation_trust_chain:
null` in JSON form. When `--operation <name>` is used, Atlas loads the
operation, evaluates `atlas op trust-chain`, embeds the trust-chain summary, and
fails packet generation unless the operation chain is current or an explicit
release override is used.

## Boundaries

This milestone does not add cryptographic signing, immutable storage, external
attestations, or a new release trust schema version. The release packet remains
metadata-only under schema `atlas.release_trust.v1`.

## Verified

- `bash -n tools/atlas/lib/release.sh tools/atlas/bin/atlas tests/atlas.bats`
- `git diff --check`
- Focused BATS: `4/4`
- Full BATS: `29/29`
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: `72/72`, lint ok, stress ok

## Repo State

- Implementation committed at `26abbe425f82c7162fbfdeac1e7d9e94b3b87e3f`.
- Retention note present.
- Tag target: `atlas-retention-m51`.
