# Atlas v1 Pillar Readiness

## Purpose

The v1 readiness gate reports whether each Atlas pillar has enough
implementation, tests, documentation, and verification coverage to be considered
ready for the current maturity stage.

This contract keeps `atlas v1 status` auditable: a pillar is not ready because
Atlas says it is ready. A pillar is ready because Atlas can point to the
commands, tests, artifacts, reasons, and known limitations behind the status.

## Status Values

- `ready`: implemented, covered by tests, documented, and available for the
  current maturity stage.
- `warning`: implemented, but the current operation or environment has a
  freshness, queue, or evidence condition that needs operator attention.
- `blocked`: required capability is missing, unreadable, stale, or otherwise
  not trustworthy enough for strict readiness.
- `planned`: intentionally not required for the current maturity stage.
- `disabled`: intentionally disabled by policy or environment and non-blocking
  when the pillar is optional.
- `not-implemented`: no usable implementation is present.

## Overall Readiness Rule

Overall `ready` requires all required pillars to be `ready` and all optional
pillars to be explicitly `ready`, `planned`, `disabled`, or otherwise
non-blocking.

`atlas v1 status --strict` exits nonzero when the overall state is not `ready`.
Required `blocked` and `not-implemented` pillars always make the command exit
nonzero. Optional `planned` or `disabled` pillars do not block readiness.

`atlas v1 status --json` emits the same pillar contract in machine-readable
form for CI gates, release trust packets, dashboards, or later provenance work.

## Pillar Criteria

Each pillar status must include:

- status
- reason
- test reference
- command reference
- artifact reference
- known limitations

### Core CLI

- Status: `ready`
- Reason: shell-native `atlas` entrypoint is executable and routes core
  subcommands.
- Tests: `tests/atlas.bats` help and v1 status tests.
- Commands: `atlas help`, `atlas v1 status`
- Artifacts: `tools/atlas/bin/atlas`
- Limitations: shell-native interface; no multi-user server yet.

### Target Registry

- Status: `ready`
- Reason: target env records support scope status, criticality, owner, and tags.
- Tests: `tests/atlas.bats` target metadata and operation snapshot tests.
- Commands: `atlas target add`, `atlas target update`, `atlas target show`
- Artifacts: `targets/*.env`
- Limitations: env-record storage remains intentionally simple.

### Ledger

- Status: `ready`
- Reason: operations have append-only ledger files and audit views.
- Tests: `tests/atlas.bats` operation lifecycle and v1 negative ledger tests.
- Commands: `atlas op status`, `atlas op audit`
- Artifacts: `sessions/<operation>/ledger.ndjson`
- Limitations: append-only file semantics, not immutable storage.

### ScopeGuard

- Status: `ready`
- Reason: operation scope snapshots, profiles, approvals, and preflight checks
  are recorded.
- Tests: `tests/atlas.bats` scopeguard and v1 negative snapshot tests.
- Commands: `atlas scope status`, `atlas scope check`
- Artifacts: `sessions/<operation>/scope.snapshot.env`
- Limitations: policy model remains profile/env based.

### Recon

- Status: `ready`
- Reason: `wiremap` remains available as the operation-aware recon adapter.
- Tests: `tests/atlas.bats` wiremap workflow tests.
- Commands: `atlas op recon`, `atlas recon workflow`
- Artifacts: `state/wiremap-runs/`
- Limitations: network probing still depends on operator authorization and
  local backends.

### Action Planner

- Status: `ready`
- Reason: `vector` remains available for ranked lanes, explainable plans, and
  bounded outcomes.
- Tests: `tests/atlas.bats` vector lane and action tests.
- Commands: `atlas action candidates`, `atlas op action plan`
- Artifacts: vector session and outcome records.
- Limitations: execution remains manual and approval-gated.

### Intel Graph

- Status: `ready`
- Reason: `intelctl` exposes shared-intel summaries, graph exports, and path
  views.
- Tests: `tests/atlas.bats` intel graph and path tests.
- Commands: `atlas intel graph`, `atlas intel paths`
- Artifacts: `state/intel/*.jsonl`
- Limitations: graph is file-backed NDJSON, not a graph database.

### Evidence

- Status: `ready`
- Reason: evidence can be copied, hashed, redacted, bundled, and manifest-listed.
- Tests: `tests/atlas.bats` evidence vault, bundle, and v1 negative manifest
  tests.
- Commands: `atlas evidence add`, `atlas evidence bundle`, `atlas evidence hash`
- Artifacts: evidence records, copied artifacts, and bundle manifests.
- Limitations: no cryptographic signing yet.

### Findings

- Status: `ready`
- Reason: observed, inferred, validated, resolved, accepted, and lifecycle
  finding records are supported, including explicit accepted-risk metadata and
  accepted-risk expiry review, renewal, review queue triage, and review packet
  verification/freshness.
- Tests: `tests/atlas.bats` finding lifecycle, accepted-risk, and
  accepted-risk expiry/review queue packet tests.
- Commands: `atlas finding add`, `atlas finding update`,
  `atlas finding accept`, `atlas finding review`,
  `atlas finding review-queue`, `atlas finding review-packet`,
  `atlas finding review-verify`, `atlas finding resolve`,
  `atlas op readiness`
- Artifacts: operation finding index and accepted-risk review packets.
- Limitations: accepted-risk expiry is date-based and checked during readiness;
  Atlas does not yet send scheduled reminders before expiry.

### Validation

- Status: `ready`
- Reason: validation plans, approvals, bounded runs, and retests are recorded.
- Tests: `tests/atlas.bats` validation plan, run, and retest tests.
- Commands: `atlas validation plan`, `atlas validation approve`,
  `atlas validation retest`
- Artifacts: operation validation plan index.
- Limitations: validation execution is bounded by configured local backends.

### Reports

- Status: `ready`
- Reason: operation reports are generated and readiness detects missing or stale
  report state.
- Tests: `tests/atlas.bats` report freshness and v1 negative stale-report tests.
- Commands: `atlas op report`, `atlas op readiness`
- Artifacts: Markdown operation reports.
- Limitations: Markdown reports are not digitally signed.

### Retention

- Status: `ready`
- Reason: handoff, closeout, audit, archive, trust-chain closeout, release
  trust, release-candidate operation binding, release verify trust-chain replay,
  Markdown/JSON replay parity, verification, and freshness checks are
  implemented, including accepted-risk review packet freshness in readiness,
  audit, archive, and trust-chain views.
- Tests: `tests/atlas.bats` retention/archive tests, release packet tests, and
  end-to-end trust lifecycle test.
- Commands: `atlas op closeout`, `atlas op audit-packet`,
  `atlas op archive-verify`, `atlas op trust-chain`, `atlas release packet`,
  `atlas release verify`
- Artifacts: closeout manifest, audit packet, archive packet, release trust
  packet, optional operation trust-chain summary, accepted-risk review packet
  references, release trust JSON schema `atlas.release_trust.v1`.
- Limitations: no cryptographic signing yet.

### AI Advisor

- Status: `ready`, `planned`, or `disabled`
- Reason: metadata-only advisor briefs and prompt packets are available, or the
  optional pillar is explicitly disabled/planned.
- Tests: `tests/atlas.bats` advisor prompt and v1 advisor-disabled tests.
- Commands: `atlas advisor brief`, `atlas advisor prompt`
- Artifacts: advisor prompt packet.
- Limitations: external model execution is outside Atlas.

## Strict Mode

`atlas v1 status --strict` is intended for release gates and operator trust
checks. It should fail when a required pillar is `warning`, `blocked`,
`planned`, `disabled`, or `not-implemented`.

## JSON Mode

`atlas v1 status --json` emits:

```json
{
  "overall": "ready",
  "commit": "<current-short-sha>",
  "strict": false,
  "pillars": {
    "core_cli": {
      "status": "ready"
    }
  }
}
```

The JSON contract is intentionally stable enough for future CI gates, release
trust packets, dashboards, and provenance records.
