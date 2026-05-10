# Atlas Policy Plane

## Purpose

M126 adds the first policy decision contract for Atlas capabilities.

`policy/atlas.authz.rego` defines the decision vocabulary and authorization
rules that sit above `capabilities.yaml` and `adapters/registry.yaml`.

Required decisions:

```text
allow
deny
approval_required
unsupported
not_in_scope
```

## Contract

Policy evaluation is capability-first:

1. The requested capability must exist in `capabilities.yaml`.
2. The capability class determines the default policy posture.
3. Scope can block otherwise valid capabilities with `not_in_scope`.
4. Higher-risk classes return `approval_required` unless approval evidence is
   already present.
5. The decision emits a metadata-only decision object.

Current default posture:

- `read`, `import`, and `verify`: `allow`
- `export`: constrained to public trust checks
- `bounded_exec`, `mutate`, and `admin`: `approval_required` until approved
- unknown capabilities: `unsupported`
- out-of-scope known capabilities: `not_in_scope`

## Commands

Evaluate one capability:

```bash
./tools/atlas/bin/atlas policy evaluate atlas.status.read
./tools/atlas/bin/atlas policy evaluate atlas.agent.tool.exec --json
./tools/atlas/bin/atlas policy evaluate atlas.agent.tool.exec --scope agent-runtime --approval-event approval-approved-event.json --json
```

Run the policy fixture suite:

```bash
./tools/atlas/bin/atlas policy test
./bin/dev-policy
```

Expected validator output:

```text
policy: ok
```

## Boundary

M127 builds on this policy contract with metadata-only approval workflow
events for `approval_required` decisions.

This milestone does not add an evidence ledger, external API client, mutation
wrapper, cloud action, web dashboard, hidden database, or agent execution
runtime.

The Rego file is the policy contract. The shell/JQ evaluator is the current
host-runtime implementation so Atlas stays portable outside Nix. A future OPA
or signed-policy-bundle runtime must preserve the same decision vocabulary and
metadata-only evidence boundary.

At the CLI boundary, `approval=approved` must come from a verified
`atlas.approval_event.v1` event supplied with `--approval-event`. Internal
policy fixtures may still exercise abstract approval states to verify the
decision vocabulary.
