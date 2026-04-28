# `atlas.advisor_prompt_packet.v1`

## Surface

`atlas advisor prompt --json [operation] [packet-name]`

## Purpose

`atlas.advisor_prompt_packet.v1` is the machine-readable AI Advisor prompt
packet contract for an operation. It records metadata-only planning context,
redaction status, priority finding references, validation queue references,
safety constraints, suggested operator moves, and known limitations without
embedding raw evidence, raw reports, raw validation output, secrets, tokens, or
session contents.

The Advisor Packet Interface is not an execution engine.

## Required Fields

- `schema_version`: must be `atlas.advisor_prompt_packet.v1`.
- `generated_at`: packet generation timestamp.
- `operation`: operation name, id, status, target, and optional address.
- `metadata_only`: must be `true`.
- `raw_artifacts_embedded`: must be `false`.
- `advisor_boundary`: execution and target-touching action boundaries.
- `safety_constraints`: required safety constraints for any external review.
- `redaction_status`: evidence counts and external handoff status.
- `priority_findings`: finding references and advisor cues.
- `validation_queue`: validation plan references and status labels.
- `suggested_operator_moves`: planning-only operator suggestions.
- `requested_output`: expected external-review response shape.
- `metadata_boundary`: explicit stores and excludes lists.
- `known_limitations`: explicit non-guarantees and packet boundaries.

## Verification Rules

Advisor prompt JSON packets are metadata-only planning packets. Consumers must:

- parse the JSON object and schema version
- confirm `metadata_only` is `true`
- confirm `raw_artifacts_embedded` is `false`
- confirm the packet operation id matches the operation being reviewed
- reject forbidden raw-content markers before sharing externally
- treat all suggested moves as planning text that still requires explicit Atlas
  operator commands

## Metadata Boundary

Advisor prompt JSON packets may include:

- counts
- ids
- status labels
- severity labels
- advisor cues
- suggested operator moves
- safety constraints
- known limitations

Advisor prompt JSON packets must not include:

- raw evidence bodies
- raw report bodies
- raw validation output
- target secrets
- credentials
- private keys
- tokens
- packet captures
- session contents
- customer data
- sensitive business records

## Non-Goals

This packet is not autonomous execution, external model execution, production
certification, legal compliance evidence, exploit guidance, or proof that
unredacted evidence is safe to share.
