# Atlas Trust Infrastructure Direction

## Purpose

Atlas should progress as trust infrastructure, not just as a security tool.

The product wedge is evidence-backed, metadata-only, verifiable operational
proof. Atlas should help an operator, business owner, reviewer, or auditor
answer:

- What was in scope?
- What operation or business flow was reviewed?
- What evidence exists?
- What findings, validation, reports, and packets support the claim?
- Is the retained packet current?
- Can the claim be verified or replayed later?
- What are the known limitations?

## Model

Atlas is a metadata-first trust control plane.

It coordinates operational proof across:

- security assessment trust chains
- business-flow trust chains
- release trust packets
- audit and archive packets
- readiness and production-status gates
- retention notes and signed release provenance

Atlas should store references, hashes, state, timestamps, packet paths, schema
versions, and verification output. It should not store sensitive business
content by default.

## Actors

- Operator: runs authorized assessment and verification workflows.
- Business owner: owns a business process, risk decision, or approval.
- Reviewer: checks evidence, findings, validation, packets, and limitations.
- Auditor: inspects retained proof, freshness, replay, and retention history.

## Objects

- target
- operation
- business flow
- scope snapshot
- ledger event
- evidence record
- finding
- accepted-risk record
- validation plan and result
- report
- handoff packet
- closeout manifest
- audit packet
- archive packet
- release packet
- release provenance packet
- retention milestone

## Guarantees

- Scope: Atlas records the target, operation, scope status, and relevant
  boundaries for authorized work.
- Operator control: Atlas records approvals and operator intent instead of
  assuming autonomous authority.
- Metadata-only by default: Atlas records references, labels, hashes, paths,
  IDs, timestamps, and packet metadata before raw content.
- Evidence references: Atlas points to evidence records and hashes without
  copying raw evidence into trust packets.
- Freshness: Atlas can report whether packets are missing, current, stale, or
  blocked when upstream material changes.
- Verification: Atlas can re-check packet metadata, hashes, JSON validity,
  release state, and known guardrails.
- Replay: Atlas can retain enough metadata to re-run local verification against
  a release or operation state.
- Retention: Atlas records milestone notes, packet paths, tags, and provenance
  so trust history remains inspectable.
- Known limitations: Atlas records what the proof does not claim.

## Non-Guarantees

- no external production certification
- no external audit by default
- no SLSA-certified provenance yet
- no cryptographic immutability of every local state file
- no tamper-proof storage
- no autonomous exploitation
- no inferred authorization
- no enterprise deployment certification
- no guarantee that a business process is correct just because a flow exists
- no guarantee that third-party payment, banking, identity, or hosting systems
  performed correctly outside retained metadata

Use precise readiness language:

- internal readiness
- ready-to-refine
- release-trust candidate
- local production contract
- not externally production-certified unless proven by separate evidence

## Metadata Boundary

Do not store these in trust packets or business-flow records:

- secrets
- raw customer records
- raw business records
- raw request or response bodies
- credentials
- tokens
- authorization headers
- session cookies
- private keys
- packet captures
- payment card data
- unredacted evidence bodies

Allowed by default:

- object IDs
- owner labels
- data class labels
- system aliases
- control objective labels
- evidence IDs
- finding IDs
- validation IDs
- report paths
- packet paths
- SHA-256 hashes
- timestamps
- freshness states
- verification status
- known limitations

## Business-Flow Trust Chain

Business-flow evidence extends Atlas from security-operation proof into
business-process proof:

```text
business flow -> operation -> evidence -> findings -> validation -> report
-> handoff -> closeout -> audit -> archive -> release packet -> provenance
```

Business-flow evidence remains optional until flow records, links, packets,
verification, negative tests, and readiness integration are stable.

## Readiness Language

- `atlas v1 status` reports internal pillar readiness.
- `atlas production status` reports whether the local production-readiness
  contract passes for retained release evidence.
- `production-ready` inside Atlas means the local Atlas contract passed. It is
  not an external audit, enterprise certification, deployment certification, or
  immutable infrastructure claim.

## Near-Term Milestones

1. Keep this trust-infrastructure direction current.
2. Continue Business Flow Evidence with metadata-only flow packets.
3. Add `atlas flow verify` for packet and link verification.
4. Add negative flow verification tests for missing, stale, tampered, or
   secret-bearing metadata.
5. Add optional Business Flow Evidence readiness integration.
6. Stabilize flow, packet, audit, archive, release, and trust-chain schemas.
7. Add packet/replay parity where retained proof needs machine-readable gates.

Do not jump to Atlas OS, web UI, kernel work, ISI runtime, fleet control, SQL
migration, or autonomous features before the metadata-first trust
infrastructure is stable and verifiable.

## Bottom Line

Atlas should become a trusted registry/control plane for operational proof:
metadata-first, evidence-backed, retention-aware, replayable, and clear about
what it does and does not prove.
