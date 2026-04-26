# atlas

This module is the unified operator front-end for the toolkit.

It is intentionally not a monolith. The point is to expose one app while
keeping the underlying domains intact:

- `wiremap` owns recon, capture, and evidence interpretation
- `vector` owns ranking, bounded action, sessions, and outcomes
- `intelctl` owns direct shared-intel inspection
- `labctl` still owns builder and inventory administration

`atlas` is the shell around those domains.

## Commands

```bash
atlas doctor
atlas menu
atlas profile list
atlas profile show htb-starting-point
atlas scope status
atlas approval grant safe-validation "approved bounded validation"
atlas evidence add ./artifact.txt --kind scan-output
atlas evidence redact ev_... ./artifact-redacted.txt
atlas evidence bundle review-bundle
atlas evidence list
atlas evidence show ev_...
atlas finding add "SSH reachable" --level observed --severity low --evidence ev_...
atlas finding update finding_... --level validated --validation vp_... --note "confirmed by validation run"
atlas finding resolve finding_... --validation vp_... --note "remediation confirmed"
atlas finding list
atlas finding show finding_...
atlas validation plan validate --finding finding_... --evidence ev_...
atlas validation approve vp_... "approved bounded validation"
atlas validation run vp_...
atlas validation retest vp_... --result resolved --evidence ev_... --note "remediation confirmed"
atlas advisor brief
atlas advisor prompt
atlas target list
atlas target update demo-node --scope-status in-scope --criticality high --tag lab
atlas target brief 10.0.0.8
atlas target story 10.0.0.8
atlas target summary 10.0.0.8
atlas target next 10.0.0.8
atlas story demo-web-app
atlas op start april-review 10.0.0.8 bounded review
atlas op show april-review
atlas recon workflow list
atlas op recon perimeter-sweep
atlas capture creds ./state/wiremap-runs/<run>
atlas op action candidates
atlas op action plan credentials
atlas op action run posture
atlas op story
atlas op report april-review
atlas op readiness april-review
atlas op handoff april-review
atlas op close april-review
atlas op closeout april-review
atlas op verify april-review
atlas op audit april-review
atlas op audit-packet april-review
atlas op audit-verify april-review
atlas op archive april-review
atlas op archive-packet april-review
atlas op archive-verify april-review
atlas session list
atlas loot list
atlas intel summary
atlas intel graph 10.0.0.8 --format dot
atlas intel paths 10.0.0.8
```

## Target-First Workflow

Start with the target, then let shared intel choose the next action:

```bash
atlas target list
atlas target update <target> --scope-status in-scope --criticality high --tag lab
atlas target brief <target>
atlas target story <target>
atlas profile show htb-starting-point
atlas op start [--profile profile] <name> <target> [notes...]
atlas op show
atlas op recon <workflow>
atlas op action candidates
atlas validation plan <lane>
atlas validation approve <id> <reason...>
atlas validation run <id> [session-name]
atlas validation retest <id> --result resolved|still-open [--evidence id]
atlas advisor brief
atlas op story
atlas op report
atlas op readiness
atlas op handoff
atlas op close [--force]
atlas op closeout <name>
atlas op verify <name>
atlas op audit <name>
atlas op audit-packet <name>
atlas op audit-verify <name>
atlas op archive <name>
atlas op archive-packet <name>
atlas op archive-verify <name>
```

`atlas target brief <target>` gives the fast operator readout: surface counts,
active-operation evidence/findings/validation counts when available, latest
outcome/finding/validation status, target registry metadata, and the next
practical step.

`atlas target story <target>` is the full cross-tool view. It starts with the
same operator brief, then expands into the target record, current service and
web surface, Vector outcomes, posture findings, recent shared evidence,
active-operation evidence/findings/validation plans when the target matches,
and ranked next actions. Target records can carry `scope_status`,
`criticality`, `owner`, and space-separated `tags`; Atlas snapshots that
metadata when an operation starts and refuses records explicitly marked
`out-of-scope`.

`atlas op brief` and `atlas op story` include operation-owned evidence and
finding records alongside validation plans and recon/action tracking. This
keeps operator views tied to the audit state instead of forcing separate
`evidence list`, `finding list`, or `validation list` lookups.

`atlas target next <target>` and `atlas op next` keep the operator focused on
the ranked lanes produced from shared intel.

`atlas advisor brief [name]` is a state-only AI Advisor readout. It summarizes
the current operation, highlights redaction status before external handoff,
ranks findings, shows the validation queue, and suggests operator moves without
running target-touching commands.

`atlas advisor prompt [name] [packet-name]` writes a metadata-only Markdown
packet under the operation directory for AI-assisted summarization and report
drafting. Raw artifact contents are not included, and the packet carries the
same scope and safety constraints as the CLI workflow.

`atlas intel graph [target] [--format dot|ndjson]` projects the shared
entity/relationship streams into a deterministic graph export. DOT is useful
for quick visualization, while NDJSON keeps nodes and edges machine-readable
for later graph tooling.

`atlas intel paths [target] [--format text|ndjson]` renders relationship paths
with entity labels so the operator can see host-to-service exposure without
reading raw JSONL records.

## Doctor

`atlas doctor` checks the local Atlas runtime before an operation. It verifies
core state paths, shared-intel files, evidence hashing support, required
adapters, and optional backend commands such as `nmap`, `tcpdump`, `tshark`,
`curl`, and `msfconsole`.

## ScopeGuard

`atlas op start` now writes a first scope snapshot beside the operation record.
`atlas scope status` shows the active operation boundary, allowed capability
tiers, and blocked capability classes. `atlas scope check <capability> <target>`
performs a manual preflight and appends the decision to the operation ledger.

Profiles let Atlas stamp operation-specific scope guidance into the snapshot:

```bash
atlas profile list
atlas profile show htb-starting-point
atlas op start --profile htb-starting-point htb-run htb-10-129-143-96
```

The built-in `default` profile keeps the conservative baseline. The
`htb-starting-point` profile narrows the operator view around authorized
Hack The Box Starting Point lab work and preserves that guidance in reports.

Operation-aware recon, capture review, and action commands pass through the
same preflight path before delegating to `wiremap` or `vector`.

Legacy direct execution routes are fail-closed or operation-bound. For
example, `atlas action run <lane> <target>` now requires an active operation,
matching scope, and the same Tier 3 approval used by `atlas op action run`.
Direct recon execution should use the operation-aware form:

```bash
atlas op recon <workflow>
```

Tier 3 `safe-validation` requires an explicit approval record before execution.
The preferred path is to create a validation plan, approve that plan, then run
it:

```bash
atlas validation plan validate --reason "confirm observed service evidence"
atlas validation approve vp_20260425T200000Z "approved bounded validation within scope"
atlas validation run vp_20260425T200000Z
atlas validation retest vp_20260425T200000Z --result resolved --note "remediation confirmed"
```

`atlas approval list` shows approval records for the active operation.

## Operation Ledger

Atlas operations now include `ledger.ndjson`, an append-only event stream for
operation lifecycle events, ScopeGuard preflights, approval records, report
generation, and successful delegated tool calls. The original
`notes/history.log` remains for human-readable command reconstruction while the
ledger becomes the structured audit spine.

## Evidence Vault

Evidence is stored inside the active operation. `atlas evidence add <path>`
copies the artifact into the operation evidence directory, records a SHA-256
hash, appends an `evidence.ndjson` record, and writes an `artifact.created`
ledger event. Evidence capture is scope-checked against the active operation
target before it mutates state.

```bash
atlas evidence hash ./artifact.txt
atlas evidence add ./artifact.txt --kind scan-output
atlas evidence redact ev_20260425T200000Z ./artifact-redacted.txt
atlas evidence bundle review-bundle
atlas evidence list
atlas evidence show ev_20260425T200000Z
```

The implementation keeps original artifacts immutable, then appends redaction
metadata when `atlas evidence redact <id> <redacted-path>` is used. The
redacted derivative is copied under the evidence record, hashed, linked to the
original evidence ID, and logged with an `artifact.redacted` ledger event.
`atlas evidence bundle [bundle-name]` then writes an operation-owned bundle
directory with copied redacted/public files, `manifest.ndjson`, and a Markdown
summary. Bundles fail closed when non-public unredacted evidence remains unless
the operator explicitly passes `--include-unredacted`.

## Findings

Findings are operation-owned records. `atlas finding add <title>` writes to the
active operation, checks the target against ScopeGuard, validates optional
evidence links, and appends a `finding.recorded` ledger event.

```bash
atlas finding add "SSH management reachable" \
  --level observed \
  --severity low \
  --confidence high \
  --evidence ev_20260425T200000Z
atlas finding list
atlas finding update finding_20260425T201000Z \
  --level validated \
  --status validated \
  --validation vp_20260425T202000Z \
  --note "confirmed by validation run"
atlas finding show finding_20260425T201000Z
```

Finding levels are deliberately explicit:

- `observed`: raw signal or evidence-backed observation
- `inferred`: interpreted issue that still needs validation
- `validated`: confirmed issue with supporting evidence

`atlas finding update <id>` and `atlas finding resolve <id>` append lifecycle
records instead of rewriting history. List, story, report, and advisor views
show the latest state for each finding, while `atlas finding show <id>` includes
the full history with evidence, validation plan links, status, and notes.

Operation reports now render recorded findings instead of only leaving a
placeholder.

## Validation Plans

Validation plans are operation-owned records that sit between a finding and a
Vector lane run. `atlas validation plan <lane>` stores the Vector lane plan as
an artifact, links optional findings/evidence, writes a `validation.planned`
ledger event, and leaves the plan in `planned` status.

```bash
atlas validation plan validate \
  --finding finding_20260425T201000Z \
  --evidence ev_20260425T200000Z \
  --reason "confirm observed SSH service"
atlas validation approve vp_20260425T202000Z "approved safe validation"
atlas validation run vp_20260425T202000Z
atlas validation retest vp_20260425T202000Z --result resolved --evidence ev_20260425T210000Z
```

The run path requires both an approved validation plan and the normal
ScopeGuard Tier 3 approval check. Execution still delegates to `vector`; Atlas
records the validation status, linked action session, ledger events, and report
entries. Profiles can restrict validation lanes with `VALIDATION_LANES`, as the
`htb-starting-point` profile does.

After remediation, `atlas validation retest <id>` records whether the linked
finding is `resolved` or `still-open`, merges any new retest evidence into the
validation record, and appends a finding lifecycle update. Reports, briefs, and
`validation show` surface the latest retest result without rewriting the
original validation run.

## Operation Scope

Atlas operations are bounded by default. `atlas op show [name]` prints the
operation summary, the target, the scope statement, allowed actions, explicit
out-of-scope actions, and tracked artifacts.

Allowed operation actions are:

- target-first recon against configured scope
- service validation and non-invasive fingerprint refresh
- HTTP/HTTPS probing of observed web surfaces
- HTTP posture review for headers, redirects, metadata routes, and common login/admin routes
- shared-intel summarization, story views, and report generation

Explicitly out of scope:

- exploitation, payload delivery, or persistence
- brute forcing, password guessing, credential stuffing, or session hijacking
- destructive testing, denial of service, fuzzing, or high-volume crawling
- access to third-party systems beyond the configured target
- data extraction beyond minimal service, route, header, and posture evidence

## Reports

`atlas op report [name] [report-name]` writes a Markdown report stub under
`$LAB_REPORTS_DIR`. The report includes:

- date, operation id, target, address, status, and notes
- executive summary with evidence, finding, validation, severity, and next-step counts
- operator brief with surface, evidence, finding, validation, and next-step state
- finding review grouped into observed, inferred, and validated sections
- remediation priorities sorted by severity when recommendations are recorded
- scope, allowed actions, and out-of-scope actions
- reconstructed Atlas command history from the operation log
- tracked recon and action artifacts
- recorded findings when present
- validation plans and run status when present
- placeholders for operator notes

## Operation Readiness

`atlas op readiness [name]` is a read-only closure check. It summarizes evidence
records, unresolved findings, planned or approved validation, report freshness,
the latest material state change, evidence bundle freshness, latest handoff
freshness, latest closeout freshness, and the latest evidence bundle. The
readout also reports latest audit packet and archive packet freshness. It
returns `ready` when the operation has evidence, no unresolved findings, no
pending validation, and a current generated report; bundles, handoff packets,
closeout manifests, audit packets, and archive packets remain optional and
stale copies are called out as handoff, audit, or retention steps when needed.

`atlas op close [name]` uses the same readiness state as a close guard. If the
operation still needs attention, close fails and prints the readiness checklist.
Operators can use `--force` to close anyway; Atlas records the forced readiness
snapshot in the operation ledger.

`atlas op handoff [name] [handoff-name]` writes a metadata-only Markdown packet
under the operation directory. It links the latest report, evidence bundle,
manifest hash, operation ledger, findings, validation plans, report freshness,
bundle freshness, handoff freshness, and close readiness state without embedding
raw artifact contents.

`atlas op closeout [name] [manifest-name]` writes a metadata-only audit manifest
under the operation directory. It captures the closeout readiness snapshot,
freshness states, latest report, bundle, handoff, ledger event count, and
SHA-256 anchors for the operation metadata without embedding raw artifacts.

`atlas op verify [name] [closeout-manifest]` reads a closeout manifest without
mutating operation state. It verifies recorded SHA-256 anchors and the operation
ledger event count, reporting each artifact as `verified`, `missing`, `changed`,
or `unverifiable`.

`atlas op audit [name]` reads the operation ledger without mutating state. It
prints event counts, audit flags for denied preflights, forced closeout, stale
freshness states, closeout verification status, and a chronological event
timeline.

`atlas op audit-packet [name] [packet-name]` writes a metadata-only Markdown
audit packet under the operation directory. It includes event counts, audit
flags, a timeline, closeout verification status, the operation ledger hash, and
the closeout manifest hash without embedding raw artifacts. Readiness reports
whether the latest packet is current or stale against later ledger events.

`atlas op audit-verify [name] [audit-packet]` reads an audit packet without
mutating operation state. It verifies the recorded ledger event count and
SHA-256 hash plus the recorded closeout manifest hash so operators can detect
later ledger or closeout-manifest changes.

`atlas op archive [name]` reads the operation without mutating state and prints
a compact final archive snapshot. It combines close readiness, freshness states,
closeout verification, audit packet verification, ledger details, and primary
artifact paths so operators can see what is ready for retention in one place.
The snapshot is incomplete until an archive packet has been generated and marks
the latest archive packet stale after later ledger events.

`atlas op archive-packet [name] [packet-name]` writes that final archive state
as a metadata-only Markdown packet under the operation directory. The packet
records readiness, verification state, hashes, artifact paths, and retention
notes without embedding raw artifacts. Readiness and archive snapshots report
whether the latest archive packet is current or stale. Archive packet ledger
events do not make the audit packet stale when the original audit ledger prefix
still verifies.

`atlas op archive-verify [name] [archive-packet]` reads an archive packet
without mutating operation state. It verifies the recorded hashes for the report,
evidence manifest, handoff, closeout manifest, audit packet, and operation
ledger so operators can detect later retention-file drift.

## AI Advisor

The first advisor layer is deliberately read-only. It consumes operation
metadata, evidence indexes, findings, validation plans, and the operator brief
to produce planning text and prompt packets. It does not call an AI backend or
execute any workflow by itself.

Use:

```bash
atlas advisor brief
atlas advisor prompt advisor-op advisor-packet
```

The advisor flags unredacted non-public evidence before external handoff. Once
a redacted derivative is attached with `atlas evidence redact`, the advisor
keeps the original hash trail while marking the metadata packet ready for
review. Suggested execution stays routed through explicit Atlas commands.

## Demos

`atlas story demo-web-app` renders an anonymized built-in story fixture. Use it
when you need to demonstrate the Atlas story view without touching a live
target or depending on current shared intel.

## Intent

Use `atlas` as the operator-facing front door when you want:

- one command to remember
- target-first navigation instead of tool-first navigation
- unified runtime ergonomics without flattening the toolkit architecture

## Role

`atlas` stays relevant only if it does not absorb every behavior.

It should:

- unify navigation
- compose summaries across tools
- delegate work to the right domain tool
- preserve the boundary between evidence and action

It should not:

- reimplement `wiremap`
- reimplement `vector`
- become a second builder tool

## Runtime Packaging

When you stage `atlas` into a runtime release, include its dependencies too:

- `atlas`
- `wiremap`
- `vector`

`intelctl` and `labctl` are already carried by the release builder.
