# Atlas Capability Model

## Purpose

`capabilities.yaml` is the first machine-readable governance root for Atlas.
It names the meaningful actions Atlas recognizes before policy, approval, and
evidence planes expand.

Core rule:

```text
No meaningful ATLAS action exists unless it is named in capabilities.yaml.
```

## Manifest Contract

The M124 manifest is JSON-formatted YAML so Atlas can validate it with `jq`
without adding a new host-shell dependency.

Each capability records:

- stable `id`
- action `class`
- source `system`
- affected `resources`
- possible `effects`
- required `approval`
- evidence event types it must emit

Supported classes are:

- `read`
- `import`
- `verify`
- `export`
- `mutate`
- `bounded_exec`
- `admin`

`default_mode` must be `deny`. Mutating, bounded execution, and admin
capabilities must not use `approval: none`.

## Validation

Run:

```bash
./bin/dev-capabilities
```

Expected success output:

```text
capabilities: ok
```

The validator fails closed on duplicate IDs, unknown classes, missing approval,
missing evidence emissions, and unsafe approval settings for mutating or
bounded execution capabilities.

## Current Boundary

M124 defines the authority list. M125 builds on it with an import-only adapter
registry. M126 adds a policy decision contract for these capabilities. M127
adds approval workflow metadata for capability classes that policy gates.

These milestones do not add an evidence ledger, web UI, or agent execution
runtime.

Agent execution capabilities are governance contracts only unless a future
runtime explicitly implements them. Atlas records and verifies metadata; it
does not control agent execution.

Those layers build on this manifest in later milestones.
