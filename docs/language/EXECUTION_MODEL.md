# Atlas Language Execution Model

## Status

AL-001 defines the intended trust boundaries between language stages. AL-002
adds machine-checked safety regressions for those boundaries. Neither milestone
adds an executable language stage.

## Stage Model

```text
source
  -> parse
  -> check
  -> compile
  -> candidate execution plan
  -> governance preflight
  -> policy decision
  -> independent approval when required
  -> explicit execution
  -> append-only events
  -> metadata-only receipt
```

`parse` validates syntax and does not execute. `check` performs name, type,
path, and contract checks and does not execute. `compile` produces an
inspectable plan and does not execute. A plan requests evaluation; it does not
grant authority.

Governance preflight resolves the external capability manifest, adapter
registry, policy reference, and relevant checked-in configuration. Unknown
references fail closed. A policy decision must be explicit. An independent
approval is required when policy says so, and later approval records must bind
immutable plan and input identities.

Execution must be a separate, explicit action. It must revalidate the plan,
policy decision, approval, inputs, limits, and adapter registration before a
bounded adapter can run. Execution is not implemented by AL-001 or AL-002.

## Read-Only and Mutating Boundaries

Future `parse`, `check`, `compile --stdout`, `explain`, and `verify` operations
must be read-only. Writing a plan to a requested output path is a visible file
mutation but still does not execute it. Approval requests, execution, and
cancellation are separate mutating operations.

Read-only commands must not create run directories, decisions, approvals,
events, receipts, caches, or hidden state.

## Candidate Plan

The stable boundary is intended to be a versioned execution plan, not the
compiler's syntax tree. AL-001 defines a candidate structural schema and a
hand-reviewed fixture. AL-002 protects that fixture with negative schema
mutations. Neither milestone defines compiler output or guarantees that all
proposed capability, provider, adapter, or policy references currently resolve.

The plan records logical intended behavior. It excludes raw instructions,
secrets, environment-resolved endpoints, machine paths, timestamps, and other
runtime-only values.

## Compile-Time and Runtime Identity

Future plan identity binds deterministic source and checked-in contract inputs.
Runtime identity separately records the adapter binary, actual model/runtime,
non-secret endpoint identity or class, runtime configuration digest, and
execution node that performed the work.

Conceptually:

```text
plan identity = deterministic intended behavior
runtime binding identity = actual non-secret execution binding
```

AL-001 and AL-002 define neither hash. An authoritative portable `plan_hash`
requires a later canonicalization contract specifying exact bytes, exclusions,
Unicode, numbers, optional fields, and self-hash handling. The AL-002 schema
rejects `canonicalization` and `plan_hash`; the candidate fixture makes no
cross-platform determinism claim.

## Events and Receipts

Later side effects must create immutable attempt events rather than rewriting
history. A receipt may bind source, plan, governance, adapter, artifact, and
outcome metadata. Raw model input/output and private artifacts remain outside
the public receipt. Verification proves the recorded envelope and linkage, not
the factual correctness or authorization of the underlying action.
