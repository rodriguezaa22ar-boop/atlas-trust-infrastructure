# Atlas v1 Internal RC

## Meaning

Atlas v1 Internal Release Candidate means the current Atlas public trust
infrastructure state is internally reviewable, retained, and verifiable under
the local Atlas contract.

The RC is based on retained evidence rather than a standalone status claim.

It is a release-candidate boundary for internal review. It is not externally
audited, not certification, not legal compliance, not tamper-proof
infrastructure, not external SLSA certification, not runtime safety proof, and
not production deployability proof.

## Included Trust Surfaces

The v1 Internal Release Candidate includes these current trust surfaces:

- release trust packets and release packet verification
- release replay JSON with `atlas.release_replay.v1`
- production status explainability with `atlas production status --strict --explain`
- CI Release Trust gate for retained release evidence
- external reviewer package generation
- SLSA-verifiable release artifact candidate path
- Business Flow Evidence optional-ready status
- synthetic metadata-only demo operation
- schema freeze candidate under `docs/schemas/SCHEMA_FREEZE_CANDIDATE.md`
- known limitations and non-guarantees

Business Flow Evidence is included as optional-ready and non-blocking. It is
not a required production-readiness pillar.

## What This Does Not Mean

The v1 Internal Release Candidate does not mean:

- not externally audited
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not external SLSA certification
- not runtime safety proof
- not production deployability proof
- not enterprise deployment approval
- not autonomous operation

## Verification Checklist

The RC state should be accepted only when these checks pass:

- `atlas v1 status --strict`: ready
- `atlas production status --strict`: production-ready under the local Atlas contract
- `atlas production status --strict --explain`: reviewer-readable
- `nix-shell --run './bin/dev-qa'`: full QA, lint, and stress pass
- release packet verification passes
- release artifact manifest verification passes
- release replay JSON reports verified
- signed production-candidate tag verifies
- retained SLSA reference verifies
- external reviewer package generation succeeds
- schema freeze candidate is present and linked
- synthetic demo operation docs are present and linked
- known limitations remain explicit
- GitHub QA, CodeQL, Release Trust, and Pages pass

## Verification Commands

Run from the repository root:

```bash
nix-shell --run './bin/dev-qa'
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
./tools/atlas/bin/atlas production status --strict --explain
./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m120-trust-schema-freeze-candidate.json --commit b15545aeb09494b2e60594f44afe4a8832c4d0ba
./tools/atlas/bin/atlas release manifest-verify docs/retention/releases/atlas-m120-trust-schema-freeze-candidate.manifest.json --commit b15545aeb09494b2e60594f44afe4a8832c4d0ba
./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m120-trust-schema-freeze-candidate.json --json
git tag -v atlas-production-candidate-m120
./tools/atlas/bin/atlas release slsa-verify docs/retention/releases/atlas-v0.4.0-rc1.slsa.json
./tools/atlas/bin/atlas reviewer package atlas-v1-internal-rc-review
```

After M121 retention, the release packet, manifest, signed production-candidate
tag, and retention tag should use the M121 names.

## Reviewer Path

A reviewer should inspect:

1. `docs/ATLAS_ONE_PAGE.md`
2. `docs/case-studies/CASE_STUDY_RELEASE_TRUST.md`
3. `docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md`
4. `docs/demo/DEMO_OPERATION.md`
5. `docs/demo/DEMO_REVIEWER_RUNBOOK.md`
6. `docs/atlas/EXTERNAL_REVIEWER_PACKAGE.md`
7. `docs/schemas/SCHEMA_FREEZE_CANDIDATE.md`
8. `docs/KNOWN_LIMITATIONS.md`

## Metadata-Only Boundary

The RC state remains metadata-only. Trust packets, reviewer packages, schemas,
and demo docs may store IDs, paths, hashes, timestamps, statuses, command
names, commit IDs, tag names, workflow identities, verification states, and
known limitations.

They must not embed secrets, credentials, tokens, private keys, session cookies,
raw target data, raw customer data, payment data, bank details, packet captures,
full request or response bodies, raw runtime artifacts, unredacted evidence
bodies, raw invoices, raw contracts, exploit payloads, or unauthorized-access
instructions.

## Known Limitations

- The RC is internal and local-contract based.
- The schema freeze candidate is an internal v1 review boundary, not external
  standards certification.
- The SLSA-verifiable release artifact candidate is a verifier path, not
  external SLSA certification.
- Release trust depends on retained files, Git history, signed tags, hashes,
  and local verification commands.
- The reviewer package is a review aid, not an outside review result.
- Atlas remains shell-native and local-first.
