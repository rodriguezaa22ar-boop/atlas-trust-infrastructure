# Milestone 118: Reviewer Flow and Verification Portability Polish

## Commit

`de90b442d43ade01d4f15754b5952d0615582cd6` Merge pull request #9 from rodriguezaa22ar-boop/m118-reviewer-flow-polish

## Purpose

Polish Atlas after the SLSA-verifiable release artifact candidate milestone by
improving GPG verification portability, public documentation accuracy, and the
external reviewer flow before schema freeze and v1 Internal RC.

## Added

- Ordered external reviewer flow from one-page overview through case studies,
  reviewer packages, release verification, replay JSON, production explain
  output, GitHub attestation verification, SLSA verifier checks, and known
  limitations
- Public documentation updates that reflect the retained M117
  SLSA-verifiable release artifact candidate path without claiming external
  SLSA certification
- Supported `nix-shell` verification guidance for reviewer-facing checks
- Portable signed-tag verification using a temporary `GNUPGHOME` and
  `gpg --batch --no-autostart --import`
- Clearer signed-tag/provenance failure reasons for missing `gpg`, missing
  retained public keys, bad temporary keyrings, public-key import failures, and
  signature verification failures
- Bats guardrails for reviewer-flow docs, M117 SLSA candidate wording,
  required non-guarantees, forbidden claim language, and portable GPG behavior

## Verified

- PR #9: merged.
- Public GitHub PR QA run: success.
- Public GitHub PR CodeQL workflow run: success.
- Public GitHub PR Release Trust run: success.
- Public GitHub workflow analysis: success.
- Direct host-shell M117 manifest verification after merge: passed.
- `nix-shell --run './bin/dev-qa'`: 110/110, lint ok, stress ok.

## Retained Artifacts

- `docs/retention/releases/atlas-m118-reviewer-flow-polish.json`
- `docs/retention/releases/atlas-m118-reviewer-flow-polish.provenance.json`
- `docs/retention/releases/atlas-m118-reviewer-flow-polish.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-02_M118.md`
- Signed tag: `atlas-production-candidate-m118`

## Trust Impact

Atlas now gives external reviewers a clearer ordered path for inspecting the
public trust surface and verifying retained release evidence. Signed-tag
verification is more portable because retained public keys are imported into a
temporary keyring instead of relying on a user's persistent keyring.

## Boundaries

- This milestone does not claim external SLSA certification.
- This milestone does not claim external audit, legal compliance, enterprise
  deployment approval, tamper-proof infrastructure, runtime safety, or
  production deployability.
- The M117 SLSA-verifiable release artifact candidate remains a candidate path,
  not a certification result.
- GPG verification imports retained public keys into a temporary keyring and
  does not persist keys to user keyrings.
- Reviewer-flow docs and verification output remain metadata-only and do not
  embed raw runtime artifacts, evidence bodies, customer data, target data,
  payment data, packet captures, credentials, tokens, private keys, invoices,
  contracts, or sensitive business records.
