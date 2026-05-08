# Atlas Adapter Registry

## Purpose

`adapters/registry.yaml` is the M125 adapter-plane root. It lists the external
systems Atlas can ingest from without making Atlas the owner of those systems.

Core rule:

```text
Adapters are import-only by default.
Mutation requires capability + policy + approval + evidence.
```

## Contract

Each adapter declares:

- stable `id`
- external `system`
- `mode`
- capabilities used from `capabilities.yaml`
- input and output schema references
- evidence event types emitted
- secret handling boundary
- network policy
- owner

The registry is JSON-formatted YAML so the host-shell validator can use `jq`
without adding a new parser dependency.

## Current Adapters

M125 registers import-only contracts for:

- `github`
- `generic-webhook`
- `scanner`
- `ticketing`
- `cloud`
- `agent-runtime`

These are contracts only. The registry does not add external API clients,
mutation wrappers, cloud changes, ticket updates, or agent execution.

M126 policy decisions evaluate the capabilities referenced here before any
future adapter wrapper can move beyond import-only mode. M127 approval events
record the human-review metadata required for higher-risk capability classes.

## Validation

Run:

```bash
./bin/dev-adapters
```

Expected success output:

```text
adapters: ok
```

The validator fails closed on duplicate IDs, non-import modes, missing required
fields, unknown capabilities, missing evidence output, and schema paths outside
the adapter directory.
