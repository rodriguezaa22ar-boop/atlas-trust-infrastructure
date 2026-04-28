# `atlas.closeout_manifest.v1`

## Surface

`atlas op closeout --json [operation] [manifest-name]`

The verifier consumes this manifest with:

```bash
atlas op verify [operation] [closeout-manifest]
```

## Purpose

`atlas.closeout_manifest.v1` is the machine-readable closeout manifest
contract for an operation. It records operation identity, close readiness,
freshness states, retained artifact references, SHA-256 anchors, and known
limitations without embedding report bodies, evidence bodies, handoff contents,
ledger contents, or raw runtime artifacts.

## Required Fields

- `schema_version`: must be `atlas.closeout_manifest.v1`.
- `generated_at`: manifest generation timestamp.
- `operation`: operation name, id, status, close timestamp, target, optional
  address, and scope profile.
- `metadata_only`: must be `true`.
- `raw_artifacts_embedded`: must be `false`.
- `readiness`: close readiness, next step, counts, and freshness values.
- `artifacts`: latest report, evidence bundle, evidence manifest, and latest
  handoff references.
- `integrity`: operation ledger, operation env, scope snapshot, evidence index,
  finding index, and validation index paths with SHA-256 anchors where present.
- `known_limitations`: explicit non-guarantees and metadata-only boundaries.

## Verification Rules

`atlas op verify` must:

- parse the JSON object and schema version
- confirm `metadata_only` is `true`
- confirm `raw_artifacts_embedded` is `false`
- confirm the manifest operation id matches the loaded operation
- reject forbidden raw-content markers
- verify retained artifact SHA-256 anchors where paths are recorded
- verify the operation ledger event count and SHA-256 anchor
- tolerate later audit, archive, and accepted-risk review packet ledger events
  when the recorded ledger prefix still matches
- report missing optional anchors as gaps rather than hard failures

## Metadata Boundary

Closeout JSON manifests may include:

- local paths
- hashes
- counts
- timestamps
- freshness states
- readiness states
- known limitations

Closeout JSON manifests must not include:

- raw report bodies
- raw handoff bodies
- raw ledger contents
- unredacted evidence bodies
- target secrets
- credentials
- private keys
- tokens
- packet captures
- request or response bodies
- customer data
- sensitive business records

## Non-Goals

This manifest is not external audit, legal compliance evidence, enterprise
certification, cryptographic immutability, or proof that retained artifact
contents are safe to disclose.
