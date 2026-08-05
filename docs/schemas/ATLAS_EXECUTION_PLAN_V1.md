# Atlas Execution Plan v1 Candidate

## Purpose

`atlas.execution_plan.v1` is the candidate public boundary between future Atlas
Language compilation and Atlas governance preflight. Its executable JSON Schema
is [`schemas/atlas.execution_plan.v1.schema.json`](../../schemas/atlas.execution_plan.v1.schema.json).

AL-001 defines structure only. A schema-valid plan is not authorization,
compiler output, an approval, an executable request, or proof that referenced
capabilities and adapters exist.

## Required Structure

| Field | Meaning |
| --- | --- |
| `schema_version` | Exact contract identifier `atlas.execution_plan.v1`. |
| `contract_status` | `candidate` during AL-001. |
| `language_version` | Source contract, initially `atlas/0.1`. |
| `execution_status` | `not_implemented` for AL-001. |
| `compiler` | Intended compiler identity and current implementation status. |
| `source` | Workspace-relative source reference, entry point, and digest status. |
| `contracts` | Capability, adapter, policy, and checked-in configuration references. |
| `workflow` | Sequential steps lowered from agents, tasks, and `workflow main`. |
| `expected_evidence` | Evidence classes later side effects must emit. |
| `privacy` | Required metadata-only and no-raw-content declarations. |
| `known_limitations` | Claims the plan explicitly does not make. |

Unknown fields are rejected. Artifact paths must begin with `./` and cannot
contain `..` traversal. Limits are positive and bounded. Required receipts
cannot be disabled.

## Source-to-Plan Mapping

The AL-001 fixture maps:

- agent name, provider reference, requested capabilities, and policy reference;
- task name, agent reference, artifact paths, approval mode, receipt
  requirement, and limits;
- workflow entry point and sequential run order.

Raw `goal` text is not embedded. The plan uses an instruction reference to the
source field. A later source digest can bind that content after source loading
and normalization rules are specified.

## Compile-Time Identity

Future deterministic plan identity includes logical behavior and checked-in
contract inputs: source and compiler identity, workflow structure, logical
provider/adapter/model references, requested capabilities, policy reference,
contract/configuration digests, limits, artifact-reference structure, and
receipt requirements.

It excludes secrets, raw prompts, raw model output, resolved endpoint values,
machine paths, temporary directories, timestamps, process identifiers, and
network-assigned addresses.

## Runtime Binding

Actual non-secret adapter, binary, model/runtime, endpoint class, runtime
configuration, and execution-node identities belong in later runtime events
and receipts. They are not silently substituted into deterministic plan
identity.

## Canonicalization and `plan_hash`

`canonicalization` and `plan_hash` are optional reserved fields. When
`plan_hash` appears, the schema requires a canonicalization reference and
contract digest. Schema acceptance alone does not make that hash authoritative.

AL-001 freezes no canonical byte representation. Its fixture omits both fields.
Portable authoritative plan hashing remains deferred until a later milestone
defines exact bytes, publishes golden vectors, and demonstrates cross-platform
parity.

## Validation

The candidate fixture is mechanically mapped in
[`schemas/schema-map.v1.json`](../../schemas/schema-map.v1.json). Validate it
with:

```bash
./bin/dev-schema
```

Validation proves only structural conformance to this candidate schema.
