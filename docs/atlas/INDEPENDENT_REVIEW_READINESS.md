# Atlas Independent Review Readiness

## Purpose

This document defines what Atlas should hand to an external reviewer for a
bounded third-party review of release trust and SLSA-verifiable artifact
evidence.

It is not itself a review result.

## Reviewer Packet

A reviewer packet should include:

- release tag
- source artifact
- source artifact checksum
- GitHub Artifact Attestation verification output
- Official SLSA generic generator provenance, when available
- Atlas SLSA reference JSON
- Atlas release packet
- Atlas release artifact manifest
- signed release provenance packet
- retained production dry-run note
- known limitations
- this claim document: `docs/atlas/SLSA_CLAIM.md`

The retained reviewer packet for `atlas-v0.4.0-rc1` lives at:

```text
docs/retention/reviews/atlas-v0.4.0-rc1-review-packet.md
```

## Review Questions

The reviewer should answer:

- Was the artifact built from the claimed repository and commit?
- Does the artifact hash match the retained Atlas SLSA reference?
- Does `gh attestation verify` pass for the artifact?
- If official generic provenance is attached, does `slsa-verifier
  verify-artifact` pass?
- Do Atlas release packet and manifest verification pass?
- Do retained packets avoid secrets, customer data, raw evidence bodies,
  credentials, tokens, and private keys?
- Are Atlas claims limited to what the evidence proves?

## Boundary

The review should be no secrets and metadata-only by default. Do not send:

- runtime secrets
- target credentials
- customer data
- payment data
- raw request or response bodies
- private keys
- packet captures
- raw operation evidence bodies

## Review Output

The expected third-party review output is a short signed or attributable report
stating:

- reviewer identity
- review date
- reviewed commit and tag
- artifact name and SHA-256
- commands run
- pass/fail result
- unresolved gaps
- whether Atlas may describe that release as independently reviewed

## Current Status

Atlas has assembled a reviewer packet for `atlas-v0.4.0-rc1` release-trust and
SLSA-verifiable artifact evidence. It still needs an actual independent
reviewer to perform the review before any third-party review claim is made.
