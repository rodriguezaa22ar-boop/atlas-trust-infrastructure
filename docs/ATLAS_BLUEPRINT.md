# Atlas Blueprint

## North Star

Atlas is the operator control plane for authorized security assessment work and
metadata-first trust infrastructure.

It should turn scattered tools, notes, and artifacts into a structured,
auditable, repeatable operation while staying shell-native and modular.

Atlas should progress as evidence-backed trust infrastructure before adding
flashy features. Its core asset is the retained chain of packets, schemas,
verification, replay, retention notes, signed release provenance, and known
limitations that make operational proof inspectable later.

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

The trust-infrastructure direction is recorded in
`docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md`.

The trust object model is recorded in
`docs/atlas/TRUST_OBJECT_MODEL.md`.

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
58. Add release replay verification guidance.
    `docs/retention/releases/REPLAY_VERIFICATION.md` now defines how to verify
    a retained release packet from a clean detached worktree at the packet's
    recorded commit. The procedure runs v1 readiness, full QA, and release
    packet verification against that checkout, and the test suite preserves the
    required replay commands and boundaries.
59. Add operation trust-chain JSON. `atlas op trust-chain --json` now emits the
    same read-only closeout state as machine-readable
    `atlas.operation_trust_chain.v1` JSON, including readiness, freshness,
    verification, artifacts, ledger anchors, and operation-scoped v1 readiness.
    Strict mode still fails nonzero unless the trust chain is current.
60. Add packet format parity tracking. `docs/atlas/PACKET_FORMAT_PARITY.md`
    now records which Atlas packet and status surfaces have machine-readable
    JSON contracts, which packet surfaces remain Markdown-only gaps, and what
    metadata-only guardrails each future JSON packet must preserve. The test
    suite checks that implemented schemas and missing packet gaps remain
    explicit.
61. Add trust schema contracts. `docs/schemas/` now documents the implemented
    schema-versioned JSON contracts for release trust packets, production
    readiness status, and operation trust-chain status. Each contract records
    required fields, verification rules, metadata boundaries, and non-goals so
    future JSON packet work has a stable pattern.
62. Add operator demo walkthrough. `docs/demo/` now explains a local
    end-to-end Atlas operation from scope and evidence through validation,
    report, handoff, closeout, audit, archive, trust-chain JSON, and
    release-bound verification. The docs include expected retained artifacts,
    trust-chain reading guidance, sample output shapes, and stop conditions.
63. Add external legibility docs. The repository now has explicit trust model,
    security model, responsible use, known limitations, and roadmap documents
    so Atlas can be explained without overclaiming production readiness or
    offensive autonomy.
64. Add CI QA gate. `.github/workflows/qa.yml` now runs whitespace checks,
    `nix-shell --run './bin/dev-qa'`, and `atlas v1 status --strict` on pushes,
    pull requests, and manual dispatch. `docs/CI.md` records local parity,
    current checks, non-goals, and future CI hardening.
65. Add retained production dry-run gate. `atlas production status` now checks
    `docs/retention/production/PRODUCTION_DRY_RUN_*.md` for a retained dry-run
    note with required fields, passing QA, v1 readiness, known blockers, and an
    explicit no-production-ready claim. The gate accepts the current commit or
    the retained release commit immediately before the dry-run retention commit.
66. Retain a current release trust packet. `docs/retention/releases/` now has
    `atlas-m66-current.json`, a verified JSON release trust packet for the M65
    release commit, paired with a matching production dry-run note for the same
    commit. Release verification now compares short/full commit IDs safely and
    checks retention notes from the expected packet commit, so later milestone
    notes do not invalidate historical packet replay. Production readiness
    remains blocked only by signing/provenance after the packet-retention commit
    is pushed and synced.
67. Add signed release provenance. `atlas production status` now checks the
    latest `docs/retention/releases/*.provenance.json` packet for a
    schema-versioned metadata-only record binding a retained release packet to
    a verified signed Git tag. The gate verifies packet SHA-256, release packet
    replay, signed tag target, retained public key SHA-256, `git tag -v`
    through the retained public key, QA status, known limitations, and
    no-overclaim metadata for the current commit or retained release commit.
    Release packet discovery now ignores `*.provenance.json` so provenance
    evidence does not masquerade as a release trust packet.
68. Refocus the root README as a reviewer landing page. The README now keeps
    identity, quick start, safety boundary, current maturity, top commands, and
    a docs map in one short entry point. Heavy command and workflow material
    moves into top-level docs: `docs/COMMAND_REFERENCE.md`,
    `docs/TRUST_LIFECYCLE.md`, `docs/OPERATOR_GUIDE.md`,
    `docs/RELEASE_TRUST.md`, and `docs/WEB_ASSESSMENT.md`.
69. Add reviewability navigation docs. `docs/INDEX.md` now gives reviewers a
    single map through start-here material, operator workflow, trust lifecycle,
    release trust, production readiness, safety, schemas, milestones, agent
    guidance, and roadmap. `docs/ATLAS_ONE_PAGE.md` explains Atlas, its
    audience, problem statement, non-goals, ready-to-refine language,
    production-readiness meaning, and the trust chain. Release verify/replay
    docs, schema index, and packet parity now explicitly align release packet
    verification, clean-checkout replay, production status, and signed
    provenance.
70. Add metadata-only business-flow evidence design. Atlas now has a spec-first
    contract for optional Business Flow Evidence, defining how business-critical
    processes can point to evidence, findings, validation, approvals, freshness,
    and retention packets without storing raw business data, secrets, request
    bodies, response bodies, customer records, or payment data. The schema docs
    define planned `atlas.business_flow_evidence.v1` and
    `atlas.business_flow_packet.v1` contracts before runtime commands are added.
71. Add metadata-only business-flow records. `atlas flow add/list/show` now
    manages optional global Business Flow Evidence records under
    `state/atlas/flows/` using file-backed env records. The first runtime slice
    records flow identity, owner, criticality, environment, scope status, data
    class labels, system aliases, and control objective labels while rejecting
    obvious secret-bearing markers. Evidence links, flow packets, verification,
    and readiness integration remain planned later steps.
72. Add metadata-only business-flow evidence links. `atlas flow link-evidence`
    now connects an optional business flow to an existing evidence ID in the
    active operation by writing metadata-only NDJSON under
    `sessions/<operation>/business_flows.ndjson` and
    `sessions/<operation>/flow_evidence.ndjson`. The link records evidence ID,
    kind, retained path, SHA-256, classification, and redaction state without
    copying raw evidence or storing evidence bodies. Flow packets, verification,
    and readiness integration remain planned later steps.
73. Define Atlas trust infrastructure direction. Atlas now has a dedicated
    direction note for treating packets, schemas, verification, replay,
    retention, signed release provenance, and metadata-only business-flow
    evidence as the core asset. The roadmap, README, trust model, and one-page
    overview now frame Atlas as evidence-backed operational proof instead of a
    feature-first security tool. Business Flow Evidence remains optional and the
    next implementation path stays packet, verify, and readiness integration.
74. Add Atlas trust object model. Atlas now documents the common actor, object,
    packet, schema, freshness, verification, replay, and retention model behind
    trust infrastructure. The model keeps release replay wording accurate:
    `atlas release verify` exists today, operation trust-chain replay happens
    during release verification, and a future `atlas release replay` command is
    not claimed until implemented.
75. Add Atlas release replay command. `atlas release replay` now automates the
    retained clean-checkout replay runbook by creating a temporary isolated
    replay checkout at the packet commit, running QA unless `--skip-qa` is
    used, checking v1 strict readiness, verifying the packet against the
    recorded commit, and removing the checkout unless `--keep-worktree` is used.
76. Add metadata-only business-flow packets. `atlas flow packet` now generates
    an operation-scoped Markdown Business Flow Evidence packet under
    `sessions/<operation>/flow_packets/` after a flow is linked to evidence.
    The packet records flow labels, operation and target metadata, evidence
    IDs, retained evidence paths, SHA-256 hashes, classification, redaction
    state, freshness metadata, and known limitations without embedding raw
    evidence, source paths, customer records, secrets, request or response
    bodies, payment data, or credential material. Flow verification, JSON
    parity, finding/validation/approval/retention links, and readiness
    integration are now implemented in later retained milestones.
77. Add business-flow packet verification. `atlas flow verify` now checks the
    operation-scoped Markdown Business Flow Evidence packet against the active
    operation, flow record, operation link, evidence links, retained evidence
    records, retained evidence files, SHA-256 hashes, freshness timestamps, and
    forbidden-content guardrails. Verification is read-only and fails closed on
    missing packets, missing links, stale packets, missing retained evidence,
    hash mismatches, and forbidden raw-content markers. JSON parity,
    finding/validation/approval/retention links, and optional readiness
    integration are now implemented in later retained milestones.
78. Add optional Business Flow Evidence readiness integration. `atlas v1 status`
    now reports Business Flow Evidence as an optional non-blocking pillar, and
    `atlas production status` now reports it as an optional non-blocking gate.
    The status records command availability, flow record counts, and
    operation-scoped flow link/packet counts when an operation is loaded. This
    makes the flow module visible in readiness and production views without
    making business-flow packets required for strict v1 or production readiness.
    Finding/validation links, JSON packet parity, and promotion to a required
    pillar remain later steps.
79. Stabilize Business Flow Evidence schemas. The schema directory now records
    contracts for implemented Business Flow Evidence state surfaces:
    `atlas.business_flow.v1` flow env records,
    `atlas.business_flow_link.v1` operation flow links,
    `atlas.flow_evidence_link.v1` evidence-reference links, and
    `atlas.business_flow_packet.v1` Markdown packet parity. The docs clarify
    required fields, metadata-only boundaries, forbidden content, verification
    rules, and remaining gaps before JSON parity or required-pillar promotion.
80. Add Business Flow Evidence JSON packet parity. `atlas flow packet --json`
    now writes metadata-only JSON packets under
    `sessions/<operation>/flow_packets_json/`, and
    `atlas flow verify --json` emits `atlas.business_flow_verify.v1` results
    while verifying packet metadata, flow record hashes, operation links,
    evidence links, retained evidence files, freshness, and forbidden-content
    guardrails. The Markdown packet remains the human review surface; JSON is
    now available for gates, replay, dashboards, and future trust-chain
    integration.
81. Add Business Flow Evidence finding and validation links.
    `atlas flow link-finding` now writes `atlas.flow_finding_link.v1`
    metadata-only records under `sessions/<operation>/flow_findings.ndjson`,
    and `atlas flow link-validation` writes `atlas.flow_validation_link.v1`
    records under `sessions/<operation>/flow_validation.ndjson`. Flow packets
    and Markdown/JSON verification now include finding and validation
    references, freshness counts, current-record checks, and stale-state
    detection without embedding finding bodies, validation reasons, plan
    contents, session contents, or raw evidence.
82. Add Business Flow Evidence approval links. `atlas flow link-approval` now
    links a business flow to the latest approved operation capability for the
    active target and writes `atlas.flow_approval_link.v1` metadata-only records
    under `sessions/<operation>/flow_approvals.ndjson`. Flow packets and
    Markdown/JSON verification now include approval references, approval
    freshness counts, current approval-record checks, and stale-state detection
    without embedding approval reasons, reviewer rationale, operator notes, or
    raw evidence.
83. Add Business Flow Evidence operation trust-chain visibility. `atlas op
    trust-chain` and `atlas op trust-chain --json` now summarize optional
    Business Flow Evidence operation links, evidence links, finding links,
    validation links, approval links, Markdown packet counts, and JSON packet
    counts. This keeps Business Flow Evidence visible in the operation trust
    chain without making it required, mutating state, or embedding raw evidence,
    approval reasons, operator notes, or sensitive business data.
84. Add Business Flow Evidence retention links. `atlas flow link-retention`
    now links a business flow to retained operation or release artifacts by
    kind and writes `atlas.flow_retention_link.v1` metadata-only records under
    `sessions/<operation>/flow_retention.ndjson`. Flow packets and
    Markdown/JSON verification now include retention references, retention
    freshness counts, retained artifact hash checks, and stale/blocking
    outcomes without embedding report bodies, packet bodies, raw evidence,
    approval reasons, operator notes, or sensitive business data.
85. Add Business Flow Evidence flow trust-chain visibility. `atlas flow
    trust-chain` and `atlas flow trust-chain --json` now report a single flow's
    operation, evidence, finding, validation, approval, and retention link
    counts; Markdown and JSON packet presence; and packet verification state.
    The JSON view emits `atlas.business_flow_trust_chain.v1`. The command is
    read-only and does not write ledger events or embed raw evidence, retained
    artifact bodies, approval reasons, operator notes, or sensitive business
    data.
86. Add archive packet JSON parity. `atlas op archive-packet --json` now writes
    metadata-only `atlas.archive_packet.v1` packets with archive status,
    readiness freshness, verification state, retained artifact paths, SHA-256
    anchors, and the operation ledger anchor. `atlas op archive-verify` now
    accepts Markdown or JSON archive packets, checks JSON metadata-only flags,
    rejects forbidden raw-content markers, and verifies retained artifact and
    ledger anchors without mutating operation state.

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
