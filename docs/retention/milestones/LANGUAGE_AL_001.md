# AL-001: Atlas Language Charter and Execution-Plan Boundary

## Purpose

AL-001 defines the public charter, candidate source language, execution-stage
boundaries, security model, and candidate `atlas.execution_plan.v1` structure
before any language implementation exists.

## Changes

- Added one authoritative document for each language concern: charter, source
  specification, grammar, execution model, security model, and limitations.
- Added a candidate execution-plan JSON Schema and explanatory schema contract.
- Added one synthetic `.atlas` source file and one hand-reviewed,
  schema-valid candidate plan fixture.
- Clarified the existing public implementation/private runtime repository
  boundary.
- Added the fixture to the existing mechanical schema map and surfaced AL-001
  through the documentation and milestone indexes.

## Architectural Locks

- Source requests authority and cannot grant capabilities or approvals.
- The external capability manifest remains authoritative.
- Shell/JQ remains the implemented policy evaluator; Rego authority is only a
  future target state.
- Parse, check, and compile stages are non-executing.
- No arbitrary shell or executable source construct is defined.
- Compile-time intended behavior is separate from actual runtime binding.
- Environment-resolved and machine-specific values are excluded from future
  deterministic plan identity.
- No authoritative `plan_hash` exists until canonicalization is frozen. The
  AL-001 fixture omits `plan_hash`.

## Public/Private Boundary

Language specifications, schemas, synthetic fixtures, and public verification
contracts belong in `atlas-trust-infrastructure`. Private runtime artifacts,
model inputs and outputs, secrets, host configuration, approval credentials,
and operator history remain outside the public repository.

## Non-Goals

AL-001 adds no Rust, parser, compiler, CLI behavior, runtime, adapter, policy
behavior, approval engine, network access, model invocation, canonicalization,
or receipt emission. The example capability and provider references remain
unregistered and must fail closed in any future preflight until separately
approved.

## Verification

Required validation:

```bash
git diff --check
./bin/export-public-trust --check
nix-shell --run './bin/dev-qa'
nix-shell --run './tools/atlas/bin/atlas v1 status --strict'
```

Validation results must be reported from the implementing branch. AL-001 does
not treat an unavailable or unrun gate as passing.

## Retention State

- Language milestone: `AL-001`
- Implementation commit: pending
- Runtime change: no
- Retention tag: not created
- Production-readiness claim: none
