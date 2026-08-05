# AL-002: Protect Atlas Language Authority and Non-Execution Invariants

## Purpose

AL-002 converts AL-001's written authority and non-execution boundaries into
machine-checked schema, fixture, documentation, and QA regressions. AL-001 is
anchored by merge commit `880ce185f950db70e5369dfbf7e0ca82aa144ee4`.

## Protected Invariants

- Plans request capabilities and cannot grant them.
- Plans reference policy and cannot embed an allow decision.
- Agents cannot issue approvals for their own steps.
- Compiler and execution status remain `not_implemented`.
- Provider binding remains logical and `unresolved`.
- Shell/JQ remains the implemented policy evaluator; Rego remains a future
  target state.
- Credential-shaped values, endpoint URLs, runtime timestamps, process IDs,
  temporary paths, machine paths, runtime bindings, shell commands, and
  unknown fields are rejected.
- `canonicalization` and `plan_hash` remain absent until a frozen contract and
  golden vectors exist.

## Verification Surface

`bin/dev-language-safety` first validates the positive
`examples/language/hello.plan.json` fixture. It then applies every independent
mutation under `tests/fixtures/language/invalid/` and requires schema rejection.
It also checks the current policy-baseline, non-execution, and hashing claims in
the authoritative language documents.

The mutation format keeps each failure reason explicit while avoiding copied
plans drifting away from the positive fixture. The gate writes only to a
temporary directory and creates no Atlas runtime state.

## Non-Goals

AL-002 adds no Rust, parser, compiler, runtime, CLI language command, adapter,
network request, model invocation, policy behavior, approval enforcement,
canonicalization, hashing implementation, or capability/policy reference
resolver. The example references remain unresolved and non-executable.

## Verification

Required validation:

```bash
git diff --check
./bin/export-public-trust --check
nix-shell --run './bin/dev-language-safety'
nix-shell --run './bin/dev-qa'
nix-shell --run './tools/atlas/bin/atlas v1 status --strict'
```

Results must be reported from the implementing branch and must include a
negative-path test proving that the safety gate fails when a protected schema
lock or documentation claim is weakened.

## Retention State

- Language milestone: `AL-002`
- AL-001 closure anchor: `880ce185f950db70e5369dfbf7e0ca82aa144ee4`
- Implementation commit: pending
- Runtime change: no
- Retention tag: not created
- Production-readiness claim: none
