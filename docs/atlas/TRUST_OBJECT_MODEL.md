# Atlas Trust Object Model

## Purpose

This document defines the common trust model behind Atlas actors, objects,
packets, schemas, freshness, verification, replay, and retention.

The model exists so Atlas can grow as trust infrastructure without becoming a
scanner, SIEM, exploit framework, autonomous agent, hidden database, or web
dashboard as source of truth.

## Source Of Truth

Atlas remains local-first and shell-native.

The source of truth is file-backed state:

- global records under `state/atlas/`
- operation records under `sessions/<operation>/`
- retained release and milestone evidence under `docs/retention/`
- schema contracts under `docs/schemas/`
- high-level direction under `docs/atlas/`

SQLite, remote services, dashboards, and node runtimes are future layers. They
must not become hidden sources of truth until file-backed contracts are stable.

## Actors

| Actor | Role |
| --- | --- |
| Operator | Runs authorized assessment, evidence, packet, and verification workflows. |
| Business owner | Owns a business flow, control objective, approval, or risk decision. |
| Reviewer | Reviews findings, validation plans, reports, packets, and limitations. |
| Auditor | Checks retained proof, freshness, replay, packet integrity, and milestone history. |
| System owner | Owns the target environment, service, or asset under review. |
| Release owner | Owns release readiness, signed provenance, retained dry-run evidence, and release limitations. |

Actors may overlap in a small lab, but Atlas records the role behind the trust
decision where the workflow supports it.

## Trust Objects

| Object | Meaning | Primary State |
| --- | --- | --- |
| Target | Host, domain, service, or asset under declared scope. | `targets/*.env` |
| Operation | Scoped assessment or task against a target. | `sessions/<operation>/op.env` |
| Business flow | Business-critical process represented by metadata. | `state/atlas/flows/*.env` |
| Scope snapshot | Point-in-time scope and capability boundary. | `sessions/<operation>/scope.snapshot.env` |
| Ledger event | Append-only record of material state change. | `sessions/<operation>/ledger.ndjson` |
| Evidence record | Hashed artifact reference and metadata. | `sessions/<operation>/evidence/` |
| Finding | Interpreted issue or observation linked to evidence. | `sessions/<operation>/findings/` |
| Accepted risk | Reviewer or owner decision to accept a risk for review. | operation finding records |
| Validation | Bounded test plan and outcome for confirming/refuting a finding. | operation validation records |
| Approval | Explicit decision to allow a higher-risk validation or closeout. | operation records and ledger |
| Report | Human-readable operation summary. | `reports/` and operation report paths |
| Packet | Metadata-only retained state snapshot. | operation packet paths or `docs/retention/releases/` |
| Schema contract | Human-readable JSON or packet contract. | `docs/schemas/` |
| Milestone note | Retained project history and verification result. | `docs/retention/milestones/` |

## Packet Classes

Packets are metadata-only records that anchor trust state at a point in time.

| Packet | Purpose |
| --- | --- |
| Handoff packet | Transfers operation state and known limitations. |
| Closeout manifest | Records closure state, blockers, and freshness. |
| Audit packet | Records audit-oriented flags and verification state. |
| Archive packet | Records retained operation archive metadata. |
| Release packet | Records release commit, branch, tag state, readiness, QA, and retained notes. |
| Release provenance packet | Binds a release packet hash to a signed Git tag and retained public key. |
| Production dry-run note | Records local production-contract dry-run evidence. |
| Advisor packet | Carries metadata-only AI Advisor context. |
| Business-flow packet | Planned metadata-only flow proof linking flows to evidence, findings, validation, and retention. |

Packets must not embed raw runtime artifacts, secrets, customer records,
payloads, session contents, packet captures, private keys, tokens, credentials,
or unredacted evidence bodies.

## Schema Contracts

Every stable schema-versioned JSON output should have a contract under
`docs/schemas/`.

Each schema contract should define:

- schema version
- emitting command or retained surface
- required fields
- optional fields
- allowed values
- metadata-only boundary
- forbidden content
- verification rules
- replay expectations when applicable
- known limitations
- non-goals

Planned schemas must be marked as design contracts until stable commands emit
them.

## Freshness

Freshness describes whether a packet still represents the latest material state.

Allowed freshness states:

- `missing`: no packet exists for the relevant object.
- `current`: packet was generated after the latest material event it covers.
- `stale`: upstream material changed after the packet was generated.
- `blocked`: verification found a missing, malformed, tampered, or forbidden
  content condition.

Initial freshness can be timestamp and ledger-order based. More complex graph
freshness should come only after simple packet checks are reliable.

## Verification

Verification must fail closed when required proof is missing or inconsistent.

Atlas verification should check the strongest relevant subset of:

- schema version or Markdown header
- `metadata_only=true` where applicable
- expected commit, branch, tag, and repository state
- upstream sync status
- v1 readiness JSON
- QA status
- retained milestone references
- packet path existence
- SHA-256 hash anchors
- linked evidence, finding, validation, or approval references
- freshness state
- forbidden content markers
- known limitations

Verification should report concrete failures instead of turning uncertainty
into a pass.

## Replay

Replay means re-checking a retained packet against the state it claims to
represent.

Current Atlas replay support includes:

- release packet verification with `atlas release verify`
- operation trust-chain replay during release verification
- clean-checkout release replay procedure documented in
  `docs/retention/releases/REPLAY_VERIFICATION.md`

A future `atlas release replay` command may automate the documented runbook, but
the command does not exist yet. Documentation must not imply that it does.

## Invariants

- No secrets in packets or business-flow records.
- Read-only commands must not mutate state.
- Append-only ledger events record material operation state changes.
- Metadata-only packets store references, hashes, IDs, states, timestamps, and
  limitations instead of raw content.
- Tier 3 and higher validation requires explicit approval.
- Scope and capability checks must precede target-touching workflows.
- AI Advisor surfaces may summarize and suggest, but must not execute commands
  or expand scope.
- Domain tools remain separate: `wiremap` handles recon, `vector` handles
  action lanes and bounded validation, `intelctl` inspects shared intel, and
  `labctl` handles build/release/administration.

## Business-Flow Extension

Business-flow evidence is an optional trust object domain.

The business-flow chain is:

```text
business flow -> operation -> evidence -> findings -> validation -> report
-> handoff -> closeout -> audit -> archive -> release packet -> provenance
```

Business-flow records may store owner labels, data class labels, system aliases,
control objective labels, evidence IDs, finding IDs, validation IDs, hashes,
packet paths, freshness states, and known limitations.

They must not store customer records, payment card data, raw request or response
bodies, tokens, credentials, session cookies, private keys, or unredacted
business documents.

## Readiness Implication

Readiness language remains layered:

- internal readiness: ready-to-refine
- release-trust readiness: release candidate has verified retained proof
- local production readiness: Atlas local production contract passes
- external production certification: not claimed unless independently proven

Business Flow Evidence remains optional until the flow packet, verification,
negative tests, schemas, and readiness integration are stable.
