# `atlas.release_trust.v1`

## Surface

```bash
atlas release packet <packet-name> --json
```

## Purpose

Record release trust metadata for a specific commit without embedding raw
runtime artifacts or target data.

## Required Fields

- `schema_version`: must be `atlas.release_trust.v1`.
- `generated`: packet generation timestamp.
- `packet`: operator-selected packet name.
- `root`: repository root used during packet generation.
- `commit`: Git commit recorded by the packet.
- `branch`: Git branch name or `unknown`.
- `upstream`: configured upstream or `none`.
- `repository.state_before_packet`: expected `clean` for normal release use.
- `repository.upstream_sync_before_packet`: expected `synced` for normal release use.
- `runtime_target`: runtime target label.
- `metadata_only`: must be `true`.
- `qa.status`: expected `pass` for release use.
- `qa.command`: QA command associated with the packet.
- `qa.note`: retained QA note.
- `tags`: tags that point at the packet commit.
- `retention_notes`: retained milestone note paths.
- `known_limitations`: explicit limitation records.
- `operation_trust_chain`: operation trust-chain record or `null`.
- `readiness`: embedded v1 readiness JSON.

## Verification Rules

`atlas release verify <packet>` validates this schema by checking:

- schema version
- metadata-only flag
- commit match
- clean repository state
- synced upstream state
- passing QA status
- v1 readiness overall status and required gap count
- retained milestone note references
- known limitations
- operation trust-chain replay when an operation is recorded

## Metadata-Only Boundary

The packet must not include raw runtime artifacts, target secrets, session
contents, packet captures, credential material, private keys, tokens,
unredacted evidence bodies, or exploit payloads.

## Non-Goals

- Cryptographic signing.
- SLSA provenance.
- Production certification.
- Raw evidence archival.
- Autonomous release approval.
