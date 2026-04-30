# Atlas SLSA Claim/Evidence Packet

## Purpose

Retain a metadata-only claim/evidence packet for the Atlas SLSA-verifiable
release path.

This packet records what Atlas can currently prove and what remains external.
It does not store release artifacts, secrets, customer data, raw evidence
bodies, credentials, tokens, or packet captures.

## Claim

Atlas has a release-artifact path prepared for SLSA-verifiable evidence:

- GitHub Artifact Attestations workflow:
  `.github/workflows/release-slsa.yml`
- Official SLSA generic generator workflow:
  `.github/workflows/release-slsa-generic.yml`
- Local retained reference verifier:
  `atlas release slsa-verify`
- Optional online verification:
  `atlas release slsa-verify <reference>.slsa.json --artifact <artifact>.tar.gz --online`
- Official generic provenance verification:
  `slsa-verifier verify-artifact <artifact>.tar.gz --provenance-path <artifact>.intoto.jsonl`

## Existing Evidence

- Milestone 98 retained a successful tag-triggered GitHub/Sigstore attestation
  smoke run.
- Milestone 99 added optional SLSA references to release artifact manifests.
- Milestone 100 added local verification for retained SLSA reference metadata.
- Milestone 101 adds official generic-generator workflow alignment, local
  artifact digest checks, online `gh attestation verify` execution support, and
  independent-review readiness documentation.

## Verification Commands

```bash
atlas release slsa-verify <reference>.slsa.json --commit <sha>
atlas release slsa-verify <reference>.slsa.json --commit <sha> --artifact <artifact>.tar.gz
atlas release slsa-verify <reference>.slsa.json --commit <sha> --artifact <artifact>.tar.gz --online
gh attestation verify <artifact>.tar.gz --repo rodriguezaa22ar-boop/atlas-trust-infrastructure
slsa-verifier verify-artifact <artifact>.tar.gz --provenance-path <artifact>.intoto.jsonl --source-uri github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure --source-tag <tag>
```

## Non-Claims

This packet does not claim:

- external SLSA certification
- completed independent review
- enterprise certification
- deployment certification
- tamper-proof local state
- immutable artifact hosting

## Remaining External Step

Publish a real release candidate tag, retain the downloaded artifact and
provenance references, run online verification, and provide the reviewer packet
defined in `docs/atlas/INDEPENDENT_REVIEW_READINESS.md` to an independent
reviewer.
