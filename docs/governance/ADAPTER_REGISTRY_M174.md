# Adapter Registry Draft M174

## Purpose

M174 defines the first machine-readable Atlas adapter registry draft. It names
how external systems may be represented before Atlas adds live adapter
execution.

The registry lives at `adapters/registry.yaml`.

## Why Atlas Needs An Adapter Registry

Atlas is a metadata-first trust overlay. External systems remain in place, and
Atlas records proof metadata around them instead of replacing them.

The adapter registry helps reviewers understand which external systems Atlas
expects to normalize, which capabilities apply, which evidence should be
emitted, and which boundaries remain. This supports clearer review, fewer
ambiguous integrations, safer future connectors, lower evidence reconstruction
work, privacy-preserving integration design, stronger audit readiness, and a
lower cost of trust without lowering standards.

## Governance Contract, Not Runtime Execution

The adapter registry is a governance contract, not runtime execution. M174 does
not add runtime adapter execution.

M174 does not add live integrations, credentials, API calls, webhooks, network
collectors, mutation, a policy engine, an approval engine, a database, a
server, or a web UI.

The registry does not grant authorization by itself. Future adapters must be
capability-named, policy-covered, approval-aware when needed, and
evidence-emitting before they can move beyond a draft contract.

The registry does not grant mutation authority. Changing registry metadata
alone cannot make an adapter live, authorize runtime execution, configure
credentials, enable API calls, enable webhooks, start network collectors, or
make a production integration ready.

## Adapter Modes

Allowed M174 modes:

- `read`: inspect local metadata.
- `import`: normalize local-file metadata into Atlas metadata.
- `verify`: verify metadata references or retained proof evidence.
- `export`: produce reviewer-facing metadata outputs.
- `propose`: describe a future state-changing request without executing it.

M174 does not include an active `mutate` adapter. Future state-changing
workflows are represented as `propose` with `live_integration: false`.

## Default-Deny Posture

The registry uses `default_mode: deny`. Unknown adapters and unknown adapter
modes are unsupported. The registry's top-level `live_integrations_enabled`
value is `false`.

## Import-First Rule

Adapters are import-first. Initial draft entries normalize local metadata for
generic external events, GitHub Actions events, release verification metadata,
scanner finding metadata, ticket metadata, AI-agent action metadata, and
business workflow metadata.

## Metadata-Only Rule

Adapters must preserve metadata-only proof boundaries. They may store:

- source references
- artifact hashes
- generated receipt references
- verification results
- proposal references
- approval-required status
- known limitations

Adapters must not store:

- raw logs
- secrets
- private keys
- credentials
- tokens
- Authorization headers
- request bodies
- response bodies
- packet captures
- raw prompts
- raw model outputs
- customer data
- payment data
- private business records
- unredacted evidence bodies

## Relationship To `capabilities.yaml`

Every adapter entry references capability IDs from `capabilities.yaml`. The
registry connects external-system metadata to named Atlas capability contracts
without creating new execution authority.

## Relationship To Future Policy Plane

Future policy decisions may evaluate adapter capability requests. M174 does not
add policy enforcement. The policy plane remains a separate contract.

## Relationship To Future Approval Plane

Proposal adapters such as ticket transitions or cloud change requests are
approval-aware. M174 does not add approval execution. Future mutation requires
explicit approval evidence and operator review.

## Relationship To Future Evidence Envelope

Each adapter declares the metadata evidence it should emit. Evidence remains
referential and hash-based. The evidence envelope can later bind adapter
metadata to receipts, reviewer packages, release trust, or evidence
sufficiency reports.

## Initial Adapter List

M174 drafts these adapters:

| Adapter | Mode | Boundary |
| --- | --- | --- |
| `generic.external_event.import` | `import` | Local-file generic event metadata only. |
| `github.actions.import` | `import` | GitHub Actions metadata import with no GitHub API calls. |
| `github.release.verify` | `verify` | Release artifact/provenance metadata verification with no artifact download. |
| `scanner.finding.import` | `import` | Scanner finding metadata only; no raw scanner logs. |
| `ticket.issue.import` | `import` | Ticket metadata only; no ticket body dump by default. |
| `ticket.transition.propose` | `propose` | Future ticket transition proposal only; no mutation. |
| `ai_agent.action.import` | `import` | AI-agent action metadata only; no raw prompts or raw model outputs. |
| `cloud.change.propose` | `propose` | Future cloud change proposal only; no cloud API call. |
| `business_flow.event.import` | `import` | Business workflow metadata only; no private business records or payment data. |

## What Adapters May Store

Adapters may store metadata references, hashes, timestamps, receipt references,
verification summaries, proposal references, status labels, and known
limitations.

## What Adapters Must Not Store

Adapters must not store raw logs, secrets, private keys, credentials, tokens,
Authorization headers, request bodies, response bodies, packet captures, raw
prompts, raw model outputs, customer data, payment data, private business
records, or unredacted evidence bodies.

## Live Integration Boundary

M174 does not add live integrations. It does not add GitHub API calls,
webhooks, network collectors, credential handling, or remote mutation.

Existing external systems remain the source of their own operational truth.
Atlas records proof metadata around them.

## Future Mutating Adapter Boundary

Future mutating adapters must be capability-named, policy-covered,
approval-aware, and evidence-emitting. They must have explicit operator review
and must not be introduced by changing the registry alone. Proposal entries are
review targets, not execution authority.

## Reviewer/Auditor Value

The registry helps reviewers see which external systems are in scope for
metadata normalization, what Atlas expects to emit, what remains outside Atlas,
and which integrations are only future proposals. It lowers evidence
reconstruction work without lowering standards.

## Known Limitations

- M174 is a draft registry for review, testing, and governance alignment.
- No runtime adapter execution is implemented.
- No live integration is implemented.
- No credentials, API calls, webhooks, or network collectors are added.
- No adapter mutation is implemented.
- No production adapter readiness is claimed.
- The registry does not prove compliance, certification, external audit
  completion, production integration, enterprise deployment approval, complete
  event coverage, runtime safety, model correctness, or artifact correctness.
- The registry does not prove that actions outside Atlas did not happen.

## Future Milestones

Future milestones may add:

- adapter registry safety regression
- adapter schema expansion
- adapter permission registry refinement
- adapter fixture packets
- policy fixture coverage for adapter classes
- approval workflow expansion for proposal adapters
- evidence-envelope binding for adapter events
- reviewer-facing adapter summary output
- live adapter contracts only after capability, policy, approval, evidence,
  and reviewer packet contracts stabilize

## Validation

Run:

```bash
./bin/dev-adapters
./bin/dev-governance
nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "M174|Adapter Registry Draft"'
./bin/export-public-trust --check
nix-shell --run './bin/dev-qa'
```

Expected adapter validator output:

```text
adapters: ok
```
