# Milestone 106: Readiness and Release Artifact Selection Tightening

## Commit

`576ec1620680c4dab5885e394fc3a47f52134f86` Harden release manifest default artifact matching

## Purpose

Close the remaining readiness cleanup items and harden release artifact
selection so retained release manifests do not accidentally combine packet,
provenance, dry-run, milestone, or SLSA evidence from different release
commits.

## Added

- `atlas op archive` verifies accepted-risk review packets through the
  Markdown/JSON parity-aware verifier.
- Regression coverage confirms JSON accepted-risk review packets remain
  verified in archive and trust-chain status.
- README language now states that production-ready status is conditional on
  the local Atlas production contract instead of implying a standing claim.
- CI documentation no longer repeats the SLSA non-certification boundary.
- `atlas release manifest` uses version-aware ordering for retained milestone
  and release artifacts.
- `atlas release manifest` skips non-release-packet Markdown files when
  resolving the default release packet.
- `atlas release manifest --slsa <reference>` selects packet, provenance, and
  dry-run evidence that match the SLSA reference commit.
- Fresh Ascend DNS recheck evidence was linked locally and the unresolved DNS
  finding was accepted as a time-bounded operational risk.
- M106 release packet, signed-tag provenance, production dry-run note, and
  release artifact manifest were retained for the M106 release commit.

## Verified

- Fresh DNS recheck: `ascendanddefendacademy.com` still did not resolve from
  the operator network.
- Ascend operation trust chain: current after accepted-risk review, closeout,
  audit, and archive regeneration.
- Focused Bats:
  `atlas finding review-queue classifies accepted risks by review state`,
  `ci workflow mirrors local Atlas QA gate`, and
  `root README stays a concise landing page with dedicated docs`: 3/3.
- Focused release-manifest Bats:
  `atlas release manifest indexes and verifies retained release artifacts`,
  `atlas release manifest records optional SLSA provenance references`, and
  `atlas release manifest verification fails closed on completeness gaps`: 3/3.
- `bash -n tools/atlas/lib/release.sh tools/atlas/lib/production.sh`: passed.
- `git diff --check`: passed.
- `nix-shell --run './bin/dev-qa'`: 107/107, lint ok, stress ok.
- `atlas release verify docs/retention/releases/atlas-m106-tightened-current.json --commit 576ec1620680c4dab5885e394fc3a47f52134f86`:
  verified.
- `atlas release manifest-verify docs/retention/releases/atlas-m106-tightened-current.manifest.json --commit 576ec1620680c4dab5885e394fc3a47f52134f86`:
  verified.

## Trust Impact

Atlas no longer treats JSON accepted-risk review packets as an archive
verification gap, and release artifact manifests now bind default packet,
provenance, dry-run, milestone, and SLSA evidence to the intended release
commit instead of relying on filename ordering alone.

## Boundaries

- The Ascend DNS issue is accepted as an operational risk; it is not remediated
  by Atlas.
- The release artifacts are metadata-only local trust records, not external
  audit, legal compliance, deployment certification, or external SLSA
  certification.
- The M106 production-candidate tag proves local signed-tag provenance only
  against the retained public key.
