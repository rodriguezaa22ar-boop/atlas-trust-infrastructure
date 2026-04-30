# Milestone 104: Independent Review Packet

## Commit

`0c529204d9072788bb119a3c7984c7a972958d87` Add independent review packet

## Purpose

Make the retained `atlas-v0.4.0-rc1` release-candidate SLSA and release-trust
evidence executable by an outside reviewer without trusting Atlas maintainers.

## Added

- `docs/retention/reviews/atlas-v0.4.0-rc1-review-packet.md`.
- Review scope for release artifact commit
  `59667bf875871c1e27dbd72de20c983ac262b43b` and retained evidence commit
  `23bc8353b4e56beb30fc157f22323951e389c117`.
- Artifact links, artifact SHA-256 values, GitHub attestation references, and
  official SLSA generic provenance references.
- Required reviewer commands for:
  - `gh attestation verify`
  - `slsa-verifier verify-artifact`
  - `atlas release slsa-verify --artifact --online`
  - `nix-shell --run './bin/dev-qa'`
  - `atlas release verify`
  - `atlas release manifest-verify`
- Reviewer checklist and expected reviewer output template.
- Documentation links from the SLSA claim, independent review readiness,
  documentation index, roadmap, blueprint, and known limitations.
- Regression coverage that the review packet is present, executable,
  metadata-only, and does not claim certification.

## Verified

- `git diff --check`: passed.
- focused Bats:
  `independent review packet makes v0.4.0-rc1 externally reviewable without overclaiming`,
  `official SLSA generic workflow and claim docs define external verification path`,
  and `retained release candidate SLSA reference records real artifact evidence`:
  3/3.
- `nix-shell --run './bin/dev-qa'`: 107/107, lint ok, stress ok.

## Trust Impact

Atlas now retains a reviewer-facing packet that explains exactly how an
independent reviewer can verify the release candidate artifact, SLSA
attestation, official SLSA provenance, Atlas SLSA reference, local QA gate, and
local release-trust baseline.

## Boundaries

- No independent review is claimed yet.
- No external SLSA certification is claimed.
- No external audit, enterprise certification, deployment certification, or
  tamper-proof guarantee is claimed.
- The review packet is metadata-only and does not embed artifacts, raw runtime
  data, secrets, credentials, tokens, customer data, or business records.
