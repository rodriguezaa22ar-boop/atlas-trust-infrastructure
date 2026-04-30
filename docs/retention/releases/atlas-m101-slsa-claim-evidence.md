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
- Release candidate `atlas-v0.4.0-rc1` was published from commit
  `59667bf875871c1e27dbd72de20c983ac262b43b`.
- `Release SLSA Provenance` succeeded:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272091`.
- `Official SLSA Generic Provenance` succeeded:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272179`.
- The retained release-candidate SLSA reference is
  `docs/retention/releases/atlas-v0.4.0-rc1.slsa.json`.
- The downloaded release artifact SHA-256 was verified as
  `a6fad42ced88648e49b8cbb9fcfe90533e2e389145277482f1000449108d0805`.
- `slsa-verifier verify-artifact` passed against the downloaded `.intoto.jsonl`
  provenance and identified the builder as
  `slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0`.

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

Authenticate GitHub CLI on a reviewer workstation, run
`atlas release slsa-verify --artifact --online`, and provide the reviewer
packet defined in `docs/atlas/INDEPENDENT_REVIEW_READINESS.md` to an
independent reviewer.
