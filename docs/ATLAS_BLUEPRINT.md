# Atlas Blueprint

## North Star

Atlas is the operator control plane for authorized security assessment work.

It should turn scattered tools, notes, and artifacts into a structured,
auditable, repeatable operation while staying shell-native and modular.

## Architecture

Atlas should remain the single operator-facing surface:

```text
atlas ...
```

The domain tools stay underneath it:

- `wiremap` owns recon, capture, and evidence interpretation
- `vector` owns ranking, bounded action lanes, sessions, and outcomes
- `intelctl` owns direct shared-intel inspection
- `labctl` owns build, release, target, and admin workflows

Atlas coordinates the operation instead of replacing those tools.

## Product Shape

Atlas should grow as a modular control plane:

- Atlas Core: CLI, config, state, command routing, common checks
- ScopeGuard: authorization boundaries, ROE, capability tiers, approvals
- Target Registry: richer target metadata, scope status, tags, criticality
- Operation Ledger: append-only audit events and tool invocations
- Evidence Vault: artifacts, hashes, redaction, bundles, evidence links
- Recon Orchestrator: operation-aware `wiremap` workflows
- Intel Graph: entities, relationships, paths, graph export
- Action Planner: ranked safe next steps through `vector`
- Validation Runner: bounded validation and retest workflows
- ReportForge: operator, technical, executive, evidence, and retest reports
- AI Advisor: state reader, summarizer, report drafter, and next-step advisor

Every module should answer one question:

```text
Does this help the operator stay authorized, organized, evidence-backed, and audit-ready?
```

## Safety Boundaries

Atlas belongs in the control plane, not in the exploit engine.

It should:

- enforce scope before target-touching actions
- distinguish observations, findings, and validated findings
- require approval for higher-risk validation
- record every meaningful operation event
- hash and preserve evidence
- redact sensitive data before summaries or AI usage
- keep the operator in control of execution

It should not become:

- a full exploit framework
- an autonomous attack platform
- a SIEM or EDR replacement
- a complex web app before the CLI workflow is stable

## Capability Tiers

Default policy should move toward:

- Tier 0: read-only
- Tier 1: passive recon
- Tier 2: active recon
- Tier 3: safe validation, explicit approval
- Tier 4: intrusive validation, explicit ROE required
- Tier 5: destructive, blocked by default

Every target-touching command should eventually pass through a preflight check
that knows the operation, target, capability tier, tool, and reason.

## State Direction

The current implementation uses shell-friendly env records and shared intel.
The next Atlas state model should add operation-owned records:

```text
state/atlas/
├── active.env
├── operations/<op-slug>/
│   ├── op.env
│   ├── ledger.ndjson
│   ├── scope.snapshot.env
│   ├── evidence/
│   ├── findings/
│   ├── actions/
│   └── reports/
└── graph/
    ├── entities.ndjson
    └── relationships.ndjson
```

Use append-only NDJSON first. Move to SQLite only after the event and graph
contracts are stable.

## Immediate Build Order

The near-term roadmap is:

1. Split Atlas into focused `lib/` modules over time. The first modules are
   `doctor.sh`, `scope.sh`, and `ledger.sh`.
2. Add `atlas doctor` for local health checks. This is implemented.
3. Add ScopeGuard records and preflight checks. The first operation snapshot,
   preflight path, and Tier 3 approval gate are implemented.
4. Add an append-only operation ledger. The first `ledger.ndjson` stream is
   implemented for operation lifecycle, preflight, report, and tool events.
5. Add an Evidence Vault with IDs and SHA-256 hashes. The first
   operation-owned add/list/show/hash flow is implemented, with append-only
   redaction metadata and redacted/public handoff bundles.
6. Strengthen target story around evidence, unknowns, and next safe steps.
   `atlas target brief`, `atlas target story`, `atlas op brief`, and reports
   now include an operator brief with surface counts, evidence/finding/
   validation state, latest outcome, and next-step guidance.
7. Add finding records that distinguish observed, inferred, and validated. The
   operation-owned add/list/show flow is implemented with evidence links,
   append-only lifecycle updates, validation links, notes, history rendering,
   and latest-state report/advisor views.
8. Add report brief generation from operation state. `atlas op brief`,
   `atlas op story`, and matching `atlas target story` views now surface
   operation-owned evidence and findings. Operation reports now include an
   executive summary, observed/inferred/validated finding review, remediation
   priorities, operator brief, and validation status.
9. Add validation planning and approval flow. The first validation plan ledger
   is implemented with plan/list/show/approve/run commands, finding/evidence
   links, profile lane restrictions, and report rendering.
10. Add AI Advisor last, after scope, evidence, and reports exist. The first
    advisor layer is implemented as read-only operation briefs and metadata-only
    prompt packets with scope constraints, redaction guardrails, priority
    findings, validation queues, and suggested operator moves.
11. Add an exposure-cycle view that ties shared intel, findings, validation
    queue, report readiness, and ranked candidate lanes together without
    executing actions. The first read-only `atlas cycle`, `atlas target cycle`,
    and `atlas op cycle` commands are implemented.
12. Add validation retest loops after remediation. `atlas validation retest`
    records resolved/still-open outcomes, links new evidence, updates the
    finding lifecycle, and renders the retest state in briefs and reports.
13. Add operation closure readiness. `atlas op readiness` checks evidence,
    unresolved findings, pending validation, latest report, and evidence bundle
    state before an operator closes an assessment.
14. Guard operation closeout with readiness. `atlas op close` now requires a
    ready operation unless `--force` is explicit, and records the readiness
    snapshot in the ledger.
15. Add operation handoff packets. `atlas op handoff` writes a metadata-only
    closeout packet that links readiness, reports, evidence bundles, manifest
    hashes, findings, validation plans, and ledger paths.
16. Add report freshness checks. Readiness and handoff state now compare the
    latest report against material operation changes and block normal closeout
    when the report is stale.
17. Add evidence bundle freshness checks. Readiness and handoff state now
    compare the latest bundle against evidence changes and warn when handoff
    bundles need regeneration.
18. Add handoff freshness checks. Readiness now compares the latest handoff
    packet against later report, bundle, and material operation changes.
19. Add closeout audit manifests. `atlas op closeout` writes a metadata-only
    manifest with readiness state, artifact pointers, ledger event counts, and
    SHA-256 anchors for final operation verification.
20. Add closeout manifest verification. `atlas op verify` reads a closeout
    manifest without mutating operation state and checks recorded SHA-256
    anchors plus ledger event counts for later audit confidence.
21. Add closeout freshness checks. Readiness now reports the latest closeout
    manifest and whether it is current or stale against later report, bundle,
    handoff, or material operation changes.
22. Add an operation audit trail view. `atlas op audit` renders the ledger as
    event counts, audit flags, closeout verification status, and a readable
    timeline without mutating operation state.
23. Add audit packets. `atlas op audit-packet` writes a metadata-only Markdown
    packet with event counts, audit flags, closeout verification status,
    timeline, and ledger hash for review or retention.
24. Add audit packet verification. `atlas op audit-verify` reads an audit
    packet without mutating operation state and checks the recorded ledger event
    count and SHA-256 hash against the current ledger.
25. Add audit packet freshness checks. Readiness now reports the latest audit
    packet and whether later ledger events have made that packet stale.
26. Add audit packet closeout anchors. Audit packets now record the closeout
    manifest SHA-256, and `atlas op audit-verify` checks it alongside the
    ledger anchor so file-level closeout tampering is visible even without a
    new ledger event.
27. Add operation archive snapshots. `atlas op archive` now renders a read-only
    final archive snapshot with readiness, freshness, closeout verification,
    audit packet verification, ledger details, and primary artifact pointers.
    Closeout ledger verification also tolerates later audit-packet ledger
    events when the anchored ledger prefix is unchanged.
28. Add operation archive packets. `atlas op archive-packet` now writes the
    final archive snapshot as a metadata-only Markdown packet with readiness,
    verification state, hashes, artifact paths, and retention notes. Audit
    packet verification and freshness tolerate later archive-packet ledger
    events when the anchored audit ledger prefix is unchanged.
29. Add archive packet verification. `atlas op archive-verify` now reads an
    archive packet without mutating operation state and checks recorded hashes
    for the report, evidence manifest, handoff, closeout manifest, audit
    packet, and operation ledger.
30. Add archive packet freshness checks. Readiness and archive snapshots now
    report the latest archive packet and whether later ledger events have made
    that final retention packet stale.
31. Add v1 pillar readiness. `atlas v1 status` now renders a read-only
    product-pillar check for the core CLI, target registry, operation ledger,
    ScopeGuard, recon orchestration, action planning, intel graph, evidence,
    findings, validation, reports, retention packets, and AI Advisor surface.
32. Define the v1 pillar readiness contract. `docs/atlas/V1_PILLAR_READINESS.md`
    now records status values, pillar criteria, overall readiness rules,
    required evidence fields, and known limitations. `atlas v1 status` now has
    `--strict` and `--json` modes plus negative tests for missing/stale pillar
    evidence.
33. Add release trust packets. `atlas release packet` now writes a
    metadata-only Markdown packet with commit, branch, tags, repository
    cleanliness, upstream sync state, v1 readiness JSON, QA status, retained
    milestone notes, and known limitations without embedding raw runtime
    artifacts.
34. Add release trust verification. `atlas release packet` now fails closed for
    dirty, unsynced, or not-ready repository states unless an explicit override
    is used, and `atlas release verify` validates release packets for commit,
    clean/synced state, passing QA, retained milestone notes, known
    limitations, and embedded v1 readiness JSON.
35. Add release trust JSON schema. `atlas release packet --json` now emits the
    same metadata-only release trust record as machine-readable
    `atlas.release_trust.v1` JSON, and `atlas release verify` validates both
    Markdown and JSON release packets with the same release-gate rules.
36. Prove the end-to-end trust lifecycle. `docs/atlas/TRUST_LIFECYCLE.md` now
    defines the full path from scoped operation through evidence, findings,
    validation, report, handoff, closeout, audit, archive, v1 readiness, and
    release trust JSON. The test suite now exercises that full chain and
    verifies closeout, audit, archive, and release trust artifacts.
37. Add web assessment packetization. `atlas web assess <url>` now turns a
    bounded public web posture check into an Atlas operation with retained
    route/header evidence, structured findings, an evidence bundle, an
    operation report, and a handoff packet.
38. Add API/CORS web assessment packetization. `atlas web assess` now records
    bounded API route and CORS preflight evidence, supports explicit
    `--api-path` and `--cors-origin` probes, and raises a structured finding
    when credentialed CORS allows the configured probe origin.
39. Add web assessment validation queueing. `atlas web validation-plan` now
    turns open web assessment findings into approval-gated posture validation
    plans, links the original route/API evidence, and skips findings that
    already have validation plans.
40. Add web validation bulk approval. `atlas web validation-approve` now
    records approval for planned web validation items with an explicit reason
    and keeps validation execution as a separate gate.
41. Add mounted web target support. `atlas web assess` now preserves the input
    URL base path when probing route, HTTP redirect, and API/CORS checks so
    path-scoped applications such as local bWAPP labs and Gruyere instances are
    assessed at their real mounted path rather than the host root.
42. Add validation supersession. `atlas validation supersede` now marks an
    executed validation plan as superseded by an executed successful replacement
    plan in the same operation, target, lane, and finding, preserving failed or
    obsolete run history while making the current replacement explicit.
43. Promote retested findings to validated state. `atlas validation retest` now
    updates the linked finding to `validated/resolved` for resolved retests or
    `validated/open` for still-open retests, so reports reflect that a finding
    has been confirmed even when remediation is still outstanding.
44. Add explicit accepted-risk handling. `atlas finding accept` now records
    accepted-risk reason, operator, optional owner, optional expiry, and
    supporting evidence or validation links on the append-only finding history,
    making accepted findings auditable and non-blocking for readiness.
45. Add accepted-risk expiry review. Readiness now counts accepted findings with
    past expiry dates as expired accepted risks, blocks clean closure until they
    are reviewed, and surfaces the same review gate in audit flags, handoff,
    closeout, archive, and v1 status output.
46. Add accepted-risk renewal workflow. `atlas finding review` now provides an
    explicit governance command for re-reviewing accepted findings, renewing
    owner/expiry metadata, preserving review history, and recording a dedicated
    `finding.reviewed` ledger event.
47. Add accepted-risk review queue. `atlas finding review-queue` now lists
    accepted risks for the active operation by `expired`, `due-soon`,
    `no-expiry`, or `current` state using a configurable review window, giving
    operators a read-only workload view before expired acceptances block
    closeout.
48. Add accepted-risk review packets. `atlas finding review-packet` now writes
    the review queue as a metadata-only retention packet with finding-index and
    ledger anchors, while `atlas finding review-verify` proves the packet still
    matches retained accepted-risk state.
49. Add accepted-risk review packet freshness. Readiness now reports latest
    accepted-risk review packet freshness, audit flags missing or stale review
    packets when accepted risks exist, and archive snapshots/packets include
    accepted-risk review packet verification and hashes.
50. Add operation trust-chain closeout. `atlas op trust-chain` now provides a
    read-only final closeout check across readiness, artifact freshness,
    accepted-risk review packets, closeout verification, audit packet
    verification, archive packet verification, and operation-scoped v1
    readiness, with `--strict` failing unless the chain is current.
51. Add release candidate trust-chain binding. `atlas release packet` now
    accepts `--operation <name>` to require a current operation trust chain
    before writing the release trust packet, embeds the operation trust-chain
    summary in Markdown and JSON release packets, and verifies any recorded
    operation trust-chain status during `atlas release verify`.
52. Add release candidate trust-chain replay verification. `atlas release
    verify` now reloads any operation recorded in a release packet, recomputes
    the current operation trust-chain result, compares ledger and archive packet
    replay state, and fails if the packet's recorded trust-chain claim no
    longer matches live retained operation state.
53. Add Markdown release candidate replay parity. Markdown release packets now
    record the operation ledger event count and SHA alongside the operation
    trust-chain summary, and `atlas release verify` replays ledger and archive
    packet state for Markdown packets with the same retained-result standard as
    JSON release packets.
54. Add repository agent guidance. Root `AGENTS.md` now records Atlas'
    shell-native development rules, safety boundary, metadata-only packet
    rules, read-only command expectations, release-trust priorities, and
    current maturity language so automated coding agents do not overclaim or
    collapse the domain boundaries.
55. Add the production-readiness gate. `docs/atlas/PRODUCTION_READINESS.md`
    now defines the stricter standard for production readiness, and
    `atlas production status [--strict] [--json]` reports required gates across
    v1 readiness, repository hygiene, release trust, the production contract,
    signing/provenance, and retained production dry-run evidence. The current
    expected result is `not-ready`, because Atlas is still an internal
    release-trust candidate rather than a production-certified product.
56. Validate agent guidance. `docs/agents/AGENT_WORKFLOW.md` and
    `docs/agents/AGENT_VALIDATION.md` now turn the root `AGENTS.md` guidance
    into an explicit workflow and a testable contract. The Bats suite checks
    that root guidance still covers authorized assessment, no autonomous
    exploitation, domain boundaries, metadata-only packet rules, read-only
    command non-mutation, Nix QA, v1/production readiness separation, AI Advisor
    limits, and future Atlas OS/ISI/kernel boundaries.
57. Add milestone retention navigation. `docs/retention/MILESTONE_INDEX.md`
    now indexes retained milestones by commit, title, category, runtime impact,
    trust impact, verification, and tag so the trust history is externally
    legible. The Bats suite checks that every retained milestone note is present
    in the index with its `atlas-retention-mXX` tag.

## First Serious Version

Atlas v1 should be a shell-native assessment orchestration console with:

- targets
- operations
- scope
- recon
- evidence
- findings
- actions
- reports

The target registry now stores optional scope status, criticality, owner, and
tags in target env records. Atlas carries that metadata into operation records,
scope snapshots, briefs, stories, and reports, and refuses operation start for
targets explicitly marked `out-of-scope`.

The first Intel Graph slice is implemented as a read-only shared-intel graph
export. `intelctl graph` and `atlas intel graph` project current entities and
relationships into DOT or node/edge NDJSON without changing operation state.
`intelctl paths` and `atlas intel paths` add a first operator path view over
those same relationship records.

The first exposure-cycle slice is implemented as a read-only operator view.
`atlas cycle`, `atlas target cycle`, and `atlas op cycle` connect discovery,
assessment, validation queue, report readiness, and candidate lanes without
adding autonomous execution.

That foundation can later grow into deeper attack graph views, validation
loops, and AI-assisted summaries without losing operator control.
