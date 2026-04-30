# Milestone 102: Retained SLSA Release Candidate Evidence

## Commit

`c6516630cb37853f98c0b79e78a053ce24606a6c` Retain SLSA release candidate evidence

## Purpose

Retain real release-candidate SLSA evidence for `atlas-v0.4.0-rc1` instead of
leaving the official builder path as workflow-only preparation.

## Added

- Release-candidate tag: `atlas-v0.4.0-rc1`.
- Retained SLSA reference:
  `docs/retention/releases/atlas-v0.4.0-rc1.slsa.json`.
- GitHub Artifact Attestation reference:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/attestations/26040322`.
- GitHub attestation workflow success:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272091`.
- Official SLSA generic-generator workflow success:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272179`.
- Release artifact SHA-256:
  `a6fad42ced88648e49b8cbb9fcfe90533e2e389145277482f1000449108d0805`.
- Official generic-generator provenance SHA-256:
  `54e0f5f070192c2716d6923868fd43b2eeab64e588caad6ec11342fdb3d046e5`.
- Claim/evidence and SLSA provenance docs updated with the actual
  release-candidate evidence.
- Bats coverage for the retained release-candidate SLSA reference.

## Verified

- `Release SLSA Provenance` GitHub workflow: success.
- `Official SLSA Generic Provenance` GitHub workflow: success.
- Release assets downloaded from the public GitHub release.
- `./tools/atlas/bin/atlas release slsa-verify docs/retention/releases/atlas-v0.4.0-rc1.slsa.json --commit 59667bf875871c1e27dbd72de20c983ac262b43b --artifact <downloaded-artifact>`: verified.
- `slsa-verifier verify-artifact <downloaded-artifact> --provenance-path <downloaded-intoto> --source-uri github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure --source-tag atlas-v0.4.0-rc1`: passed.
- focused Bats:
  `retained release candidate SLSA reference records real artifact evidence`,
  `official SLSA generic workflow and claim docs define external verification path`,
  `atlas release slsa-verify checks local artifacts and optional online attestations`,
  and `atlas release slsa-verify checks retained SLSA provenance references`: 4/4.

## Limitations

- `gh attestation verify` could not be completed on this machine because the
  GitHub CLI requires an authenticated `gh auth login` session.
- No external SLSA certification is claimed.
- No independent third-party review is claimed yet.
- The retained reference is metadata-only and does not embed the artifact,
  `.intoto.jsonl` body, secrets, credentials, or raw runtime evidence.
