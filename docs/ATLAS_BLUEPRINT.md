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

That foundation can later grow into CTEM cycles, attack graph views,
validation loops, and AI-assisted summaries without losing operator control.
