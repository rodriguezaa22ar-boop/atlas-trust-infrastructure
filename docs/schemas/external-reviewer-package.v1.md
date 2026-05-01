# `atlas.external_reviewer_package.v1`

## Surface

```bash
atlas reviewer package <name>
```

## Purpose

`atlas.external_reviewer_package.v1` records the contents of a generated
metadata-only external reviewer package. The package gives a reviewer a bounded
starting point for inspecting Atlas' public trust model, case studies, retained
release packet, signed provenance, release artifact manifest, production
dry-run note, milestone note, known limitations, and verification commands.

The package manifest is metadata-only. It stores paths, SHA-256 hashes, commit
IDs, tag names, verification command references, known limitations, and
non-guarantees. It does not embed raw runtime artifacts, target data, customer
data, payment data, raw invoices, raw contracts, packet captures, full request
or response bodies, credential material, private keys, tokens, session cookies,
or unredacted evidence bodies.

## Required Fields

- `schema_version`: must be `atlas.external_reviewer_package.v1`
- `generated`: timestamp when the reviewer package was generated
- `package`: package slug
- `metadata_only`: must be `true`
- `raw_artifacts_embedded`: must be `false`
- `source.commit`: repository commit that generated the package
- `source.branch`: repository branch that generated the package
- `output_path`: package directory path
- `package_manifest_path`: package manifest path
- `release.commit`: full retained release commit hash
- `release.tag`: signed retained release tag
- `latest_release_evidence.release_packet`
- `latest_release_evidence.signed_provenance`
- `latest_release_evidence.release_artifact_manifest`
- `latest_release_evidence.production_dry_run`
- `latest_release_evidence.milestone_note`
- `files[]`: included file records
- `files[].kind`
- `files[].source_path`
- `files[].package_path`
- `files[].sha256`
- `files[].required`
- `metadata_boundary.stores`
- `metadata_boundary.excludes`
- `verification_commands[]`
- `non_guarantees[]`
- `known_limitations[]`
- `no_external_audit_claim`: must be `true`
- `no_certification_claim`: must be `true`
- `no_legal_compliance_claim`: must be `true`
- `no_tamper_proof_claim`: must be `true`

## Required File Classes

The package must include:

- `package_readme`
- `verification_commands`
- `public_readme`
- `atlas_one_page`
- `trust_lifecycle`
- `release_trust`
- `slsa_claim`
- `production_readiness`
- `known_limitations`
- `responsible_use`
- `release_trust_case_study`
- `vendor_payment_change_case_study`
- `external_reviewer_package_contract`
- `release_packet`
- `release_provenance`
- `release_artifact_manifest`
- `production_dry_run`
- `milestone_note`

The package may include:

- `signing_public_key`
- `slsa_provenance`

## Verification Rules

`atlas reviewer package` checks:

- latest release artifact manifest exists
- manifest release commit resolves locally
- retained release packet exists and verifies
- retained release artifact manifest verifies
- signed provenance packet exists and verifies
- production dry-run note exists
- milestone note exists
- referenced files remain inside the repository
- forbidden sensitive path markers are not copied into the package
- package manifest records SHA-256 hashes for all included files
- package manifest uses the expected schema and metadata-only flags

Generation fails closed when required release evidence is missing, stale, or no
longer verifies against the retained release commit.

## Forbidden Content

The package manifest and copied package contents must not include raw sensitive
artifacts. Forbidden content classes include:

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
- private signing material

Sensitive terms may appear only as excluded content classes or known
limitations.

## Non-Goals

The package is not external audit, not certification, not legal compliance, and
not tamper-proof infrastructure.

- External audit
- Certification
- Legal compliance
- Tamper-proof infrastructure
- External SLSA certification
- Enterprise deployment approval
- Production security approval outside the local Atlas contract
