# Milestone 117: SLSA-Verifiable Release Artifact Candidate

## Commit

`3d8c444080a3c0b258d0c9a2ab101185f35c58f8` Fix official SLSA generator ref

## Purpose

Move Atlas from SLSA-adjacent documentation toward an actual
SLSA-verifiable public release artifact candidate. The milestone builds a
metadata-only source release artifact in GitHub Actions, records its digest,
verifies GitHub Artifact Attestation metadata, verifies official SLSA generic
provenance with `slsa-verifier`, and retains the SLSA reference in Atlas
without claiming external SLSA certification.

## Added

- Hardened release artifact workflows for public-safe metadata artifacts
- Path-level artifact contents manifest and forbidden runtime/sensitive path
  guardrails before artifact upload
- Immutable commit pins for normal third-party GitHub Actions used by the
  SLSA artifact path
- A documented official SLSA generic-generator exception: the upstream
  generator requires the `v2.1.0` tag ref, so Atlas records the resolved tag
  commit `f7dd8c54c2067bafc12ca7a55595d5ee9b75204a`
- Retained M117 SLSA reference with artifact digest, contents manifest hash,
  GitHub attestation metadata, issuer identity, official generic provenance
  hash, verifier commands, and known limitations

## Verified

- PR #8: merged.
- Hotfix commit `3d8c444080a3c0b258d0c9a2ab101185f35c58f8`: pushed to main.
- Public GitHub main QA run `25237932776`: success.
- Public GitHub main CodeQL workflow run `25237932765`: success.
- Public GitHub main Release Trust run `25237932761`: success.
- Public GitHub Pages run `25237932438`: success.
- Release SLSA Provenance run `25238002353`: success.
- Official SLSA Generic Provenance run `25238002419`: success.
- Artifact:
  `atlas-trust-infrastructure-atlas-release-m117-slsa-candidate-r2-3d8c444080a3.tar.gz`
- Artifact SHA-256:
  `db329583e423d067bc31dfd1485694e19e8ec98b371c59d90a9d239b180510df`
- Contents manifest SHA-256:
  `19d7327311d3e2c9860b23ae509c93aa0b05eab41d9c77d6668492ee6a715a1a`
- Official SLSA generic provenance SHA-256:
  `aaf09ddc1b371cfbb32e451de3dc30869c3ea285e23427d9c80286c0730e49ae`
- `gh attestation verify`: passed for the downloaded artifact.
- `slsa-verifier verify-artifact`: passed for the downloaded artifact and
  `.intoto.jsonl` provenance.
- `atlas release slsa-verify --artifact --online`: passed for the retained
  M117 SLSA reference.
- `git diff --check`: passed.
- `nix-shell -p actionlint --run 'actionlint .github/workflows/*.yml'`: passed.
- Focused Bats for CI, schema, and official SLSA workflow guardrails: passed.
- `nix-shell --run './bin/dev-lint'`: lint ok.
- `nix-shell --run './bin/dev-qa'`: 109/109, lint ok, stress ok.

## Retained Artifacts

- `docs/retention/releases/atlas-m117-slsa-verifiable-release-artifact.slsa.json`
- `docs/retention/releases/atlas-m117-slsa-verifiable-release-artifact.json`
- `docs/retention/releases/atlas-m117-slsa-verifiable-release-artifact.provenance.json`
- `docs/retention/releases/atlas-m117-slsa-verifiable-release-artifact.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_2026-05-01_M117.md`
- Signed tag: `atlas-production-candidate-m117`
- Release artifact tag: `atlas-release-m117-slsa-candidate-r2`

## Trust Impact

Atlas now has a real SLSA-verifiable release artifact candidate path for the
public trust infrastructure repo. The release artifact is tied to a source
commit and tag, GitHub-hosted attestation, official SLSA generic provenance,
artifact digest, contents manifest, issuer identity, retained Atlas metadata,
and verifier commands.

## Boundaries

- This milestone does not claim external SLSA certification.
- This milestone does not claim legal compliance, external audit, enterprise
  deployment approval, tamper-proof infrastructure, runtime safety, or
  production deployability.
- Artifact boundary checks are path-level metadata guardrails, not DLP.
- The official SLSA generic reusable workflow uses the upstream-required
  `v2.1.0` tag ref; Atlas records the resolved commit for reviewability.
- Retained SLSA references are metadata-only and do not embed raw runtime
  artifacts, evidence bodies, customer data, target data, packet captures,
  credentials, tokens, private keys, or sensitive business records.
