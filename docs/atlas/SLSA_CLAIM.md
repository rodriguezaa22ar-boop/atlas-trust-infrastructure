# Atlas SLSA Claim

## Purpose

This document states the current Atlas SLSA claim in precise terms so a
reviewer can separate implemented evidence from future certification work.

Atlas is targeting SLSA-verifiable release artifacts. The current claim is a
SLSA-verifiable release artifact candidate for GitHub-built source artifacts,
not an external SLSA certification.

## Claimed

Atlas claims:

- release artifacts are built by GitHub Actions from a resolved Git commit
- release-style tags must point at `origin/main`
- local Atlas QA and strict v1 readiness run before artifact creation
- release artifacts are SHA-256 hashed
- release artifact contents are checked for runtime-state paths and forbidden
  sensitive path markers before upload
- GitHub Artifact Attestations can produce provenance for the artifact
- an Official SLSA Generic Provenance workflow is available through the
  `slsa-framework/slsa-github-generator` generic generator
- SLSA-related GitHub Actions are pinned to immutable commit SHAs in the
  release artifact path
- the official SLSA generic reusable workflow uses the upstream-required
  `v2.1.0` tag ref, with its resolved commit recorded in workflow metadata
- retained Atlas SLSA references are metadata-only and locally verifiable with
  `atlas release slsa-verify`
- optional online verification can run `gh attestation verify` against a
  downloaded artifact

## Not Claimed

Atlas does not claim:

- external SLSA certification
- third-party audit completion
- enterprise deployment certification
- tamper-proof local state
- immutable release storage
- legal compliance
- that every historical Atlas artifact has official SLSA generator provenance

## Evidence

Current evidence includes:

- `.github/workflows/release-slsa.yml`
- `.github/workflows/release-slsa-generic.yml`
- `docs/atlas/SLSA_PROVENANCE.md`
- `docs/schemas/slsa-provenance.v1.md`
- `atlas release slsa-verify`
- retained SLSA smoke-run evidence in `docs/retention/milestones/MILESTONE_98.md`
- retained claim/evidence packet in
  `docs/retention/releases/atlas-m101-slsa-claim-evidence.md`

## Claim Matrix

| Claim | Required Evidence | Verification Command | Non-Claim |
| --- | --- | --- | --- |
| Release artifact was built from a named source ref. | Artifact path, source repository, source commit, source ref, and workflow path. | `gh run view <run-id>` or retained workflow metadata in `<reference>.slsa.json`. | Does not certify the repository or every historical artifact. |
| Artifact digest matches retained metadata. | Artifact SHA-256 and retained `artifact.sha256`. | `atlas release slsa-verify <reference>.slsa.json --commit <sha> --artifact <artifact>.tar.gz`. | Does not prove runtime deployment integrity. |
| GitHub attestation is verifiable for the artifact. | Attestation URL, issuer identity, repository, workflow, subject digest, and source ref. | `gh attestation verify <artifact>.tar.gz --repo rodriguezaa22ar-boop/atlas-trust-infrastructure`. | Does not claim external SLSA certification. |
| Official SLSA generic-generator provenance verifies when published. | `.intoto.jsonl` provenance, source URI, source tag, and artifact digest. | `slsa-verifier verify-artifact <artifact>.tar.gz --provenance-path <artifact>.intoto.jsonl --source-uri github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure --source-tag <tag>`. | Does not claim a stronger SLSA level unless a reviewer verifies that exact level. |
| Atlas retained SLSA reference is metadata-only and locally checkable. | `atlas.slsa_provenance.v1` reference with known limitations and no-certification boundary. | `atlas release slsa-verify <reference>.slsa.json --commit <sha>`. | Does not store raw build logs, target data, secrets, or private runtime artifacts. |

## Verification Commands

Local metadata reference verification:

```bash
atlas release slsa-verify <reference>.slsa.json --commit <sha>
```

Local artifact digest verification:

```bash
atlas release slsa-verify <reference>.slsa.json \
  --commit <sha> \
  --artifact <artifact>.tar.gz
```

Online GitHub attestation verification:

```bash
atlas release slsa-verify <reference>.slsa.json \
  --commit <sha> \
  --artifact <artifact>.tar.gz \
  --online
```

Official SLSA generic generator provenance verification, when the `.intoto.jsonl`
file is published with a release:

```bash
slsa-verifier verify-artifact <artifact>.tar.gz \
  --provenance-path <artifact>.intoto.jsonl \
  --source-uri github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure \
  --source-tag <tag>
```

## Independent Review

An independent review should verify:

- the workflow identities match this repository
- the artifact digest matches the retained reference
- the attestation or in-toto provenance verifies
- retained Atlas release packets and release manifests still verify
- no packet embeds secrets, credentials, raw evidence bodies, or customer data
- the claim language remains bounded to SLSA-verifiable readiness unless a
  third-party review explicitly grants a stronger conclusion

The retained review packet for this release candidate is:

```text
docs/retention/reviews/atlas-v0.4.0-rc1-review-packet.md
```

## Next External Step

The remaining official step is independent review. Submit the release packet,
artifact, provenance, manifest, SLSA reference, claim packet, and retained
review packet to a reviewer who can independently rerun `gh attestation
verify`, `slsa-verifier verify-artifact`, and Atlas release verification.
