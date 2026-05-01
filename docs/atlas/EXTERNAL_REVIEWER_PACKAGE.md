# Atlas External Reviewer Package

## Purpose

The external reviewer package is a metadata-only bundle that gives an outside
reviewer a focused starting point for inspecting Atlas' public trust model,
release-trust case study, vendor payment change case study, SLSA claim
boundaries, retained release packet, signed provenance, release artifact
manifest, production dry-run note, known limitations, and verification
commands.

It is a review aid. It is not itself a third-party review result.

## Command

Generate a package from the latest retained release artifact manifest:

```bash
./tools/atlas/bin/atlas reviewer package atlas-current-review
```

The command writes:

```text
docs/retention/reviewer-packages/<name>/
```

## Contents

Each package includes:

- package README
- verification command list
- package manifest with SHA-256 hashes
- public `README.md`
- `docs/ATLAS_ONE_PAGE.md`
- `docs/TRUST_LIFECYCLE.md`
- `docs/RELEASE_TRUST.md`
- `docs/atlas/SLSA_CLAIM.md`
- `docs/atlas/PRODUCTION_READINESS.md`
- `docs/KNOWN_LIMITATIONS.md`
- `docs/RESPONSIBLE_USE.md`
- `docs/case-studies/CASE_STUDY_RELEASE_TRUST.md`
- `docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md`
- `docs/schemas/external-reviewer-package.v1.md`
- latest retained release packet
- latest retained signed provenance packet
- latest retained release artifact manifest
- latest retained production dry-run note
- latest retained milestone note
- retained signing public key when referenced by the manifest
- retained SLSA provenance reference when referenced by the manifest
- SLSA-verifiable artifact digest, attestation reference, issuer identity, and
  verifier commands when a retained SLSA reference is present

## Source Of Truth

The latest release artifact manifest is the source of truth for retained release
evidence. The reviewer package reads that manifest and copies only the retained
metadata artifacts it references.

Referenced paths must resolve inside the repository. Package generation must
reject path traversal or outside-repository references.

Before writing the package, Atlas verifies:

- retained release packet
- retained release artifact manifest
- signed provenance packet
- release commit availability
- signed tag metadata

## Verification Commands

The package writes `VERIFICATION_COMMANDS.md` with commands such as:

```bash
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>
./tools/atlas/bin/atlas release manifest-verify <manifest> --commit <commit>
git tag -v <tag>
```

These checks remain local Atlas checks. They do not create external audit or
certification by themselves.

## Metadata-Only Boundary

Reviewer packages include documentation and retained metadata packets. They must
not include:

- secrets
- credentials
- session cookies
- raw target data
- raw customer data
- payment data
- raw invoices
- raw contracts
- packet captures
- full request or response bodies
- raw runtime artifacts
- unredacted evidence bodies
- sensitive business records

The package manifest records paths, hashes, commits, tags, verification
commands, and known limitations.

## Non-Guarantees

The reviewer package is:

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not external SLSA certification
- not enterprise deployment approval
- not production security approval outside the local Atlas contract

An independent review claim requires a reviewer to inspect the package, run the
verification commands, record results, and sign or otherwise attribute their
review conclusion.

## Missing Artifact Behavior

Package generation fails closed when required retained evidence is missing:

- missing release artifact manifest
- missing release packet
- missing signed provenance packet
- missing production dry-run note
- missing retained milestone note
- missing referenced signing public key

The failure is intentional. A reviewer package is only useful when it can point
to a complete retained proof chain.

## Known Limitations

- The package is generated from local retained files.
- It does not query GitHub, download artifacts, or validate online attestations
  unless the reviewer separately runs those workflows.
- It does not include raw runtime evidence by design.
- It records SLSA artifact/provenance metadata when referenced, but it does not
  download release artifacts or perform `gh attestation verify` by itself.
- It does not replace manual review, legal review, compliance review, or an
  independent audit.
