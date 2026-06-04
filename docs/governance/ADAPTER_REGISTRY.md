# Atlas Adapter Registry

## Purpose

`adapters/registry.yaml` is the adapter-plane root. M125 introduced the
import-only adapter contract. M174 expands it into the current draft adapter
registry for external systems, adapter modes, capabilities, approval posture,
metadata-only evidence, live-integration boundaries, and known limitations.

Current draft detail: [ADAPTER_REGISTRY_M174.md](ADAPTER_REGISTRY_M174.md).

Core rule:

```text
Adapters are default-deny and import-first.
Future mutation requires capability + policy + approval + evidence.
```

## Contract

Each M174 adapter declares:

- stable `id`
- title and status
- `mode`
- external `systems`
- resources and effects
- capabilities used from `capabilities.yaml`
- approval posture
- evidence emitted
- metadata-only and live-integration flags
- secrets policy and forbidden inputs
- test fixtures
- known limitations

The registry is JSON-formatted YAML so the host-shell validator can use `jq`
without adding a new parser dependency.

## Current Adapters

M174 drafts metadata-only contracts for:

- `generic.external_event.import`
- `github.actions.import`
- `github.release.verify`
- `scanner.finding.import`
- `ticket.issue.import`
- `ticket.transition.propose`
- `ai_agent.action.import`
- `cloud.change.propose`
- `business_flow.event.import`

These are contracts only. The registry does not add runtime adapter execution,
external API clients, credentials, webhooks, network collectors, mutation
wrappers, cloud changes, ticket updates, or agent execution.

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

The validator fails closed on duplicate IDs, unsupported modes, missing required
fields, unknown capabilities, missing evidence output, live integrations,
active mutation, unsafe proposal posture, and unsafe evidence outputs.
