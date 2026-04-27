# Native Lab Toolkit

This toolkit is a local-first architecture for building native terminal tools
for the local USB-backed lab runtime without cloning third-party repositories
into the working tree.

The design goal is simple:

- keep operator state under one portable root
- generate your own tool modules instead of mirroring external projects
- make the tree easy to move to the encrypted USB lab vault when you are ready
- separate architecture, state, and execution cleanly

## Device Roles

- This device: architecture, authoring, release staging, runtime execution, and verification
- USB lab vault: removable cache, outputs, and deployment target

## Layout

- `bin/`: top-level entrypoints
- `lib/`: shared shell helpers
- `etc/`: local configuration overrides
- `docs/`: architecture notes
- `tools/`: native tool modules you author
- `targets/`: target records
- `sessions/`: per-session workspaces
- `reports/`: generated operation reports
- `logs/`: operator-side logs
- `state/`: shared state, run history, and cross-tool intel

## Current Entry Point

Run the toolkit from this directory:

```bash
./bin/labctl status
```

Useful commands:

```bash
./bin/labctl init
./bin/labctl target add edge-router 192.168.1.1 home-lab
./bin/labctl target list
./bin/labctl session open april-lab edge-router
./bin/labctl report new april-findings
./bin/labctl tool new egress-check "check direct and proxied egress"
./bin/labctl tool distill jq-shape jq --help
./bin/labctl tool list
./bin/labctl release build usb-slim egress-check
./bin/intelctl summary
./tools/atlas/bin/atlas doctor
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas v1 status --json
./tools/atlas/bin/atlas release packet atlas-current --qa-status pass
./tools/atlas/bin/atlas release packet atlas-current --json --qa-status pass
./tools/atlas/bin/atlas release verify atlas-current
./tools/atlas/bin/atlas web assess https://example.com example-web-review --scope-status in-scope
./tools/atlas/bin/atlas web validation-plan --all
./tools/atlas/bin/atlas web validation-approve --all --reason "approved bounded web validation"
./tools/atlas/bin/atlas profile list
./tools/atlas/bin/atlas profile show htb-starting-point
./tools/atlas/bin/atlas target update edge-router --scope-status in-scope --criticality high --tag lab
./tools/atlas/bin/atlas target story 10.0.0.8
./tools/atlas/bin/atlas target next 10.0.0.8
./tools/atlas/bin/atlas op start --profile htb-starting-point april-review 10.0.0.8 bounded review
./tools/atlas/bin/atlas op show april-review
./tools/atlas/bin/atlas op action candidates
./tools/atlas/bin/atlas op report april-review
./tools/atlas/bin/atlas op readiness april-review
./tools/atlas/bin/atlas op audit april-review
./tools/atlas/bin/atlas op archive april-review
./tools/atlas/bin/atlas story demo-web-app
./tools/wiremap/bin/wiremap workflow run perimeter-sweep 10.0.0.8
./tools/wiremap/bin/wiremap capture creds ./state/wiremap-runs/<run>
./tools/vector/bin/vector candidates 10.0.0.8
./tools/vector/bin/vector run research 10.0.0.8
./tools/vector/bin/vector session list
```

The local status view also reflects the current role model:

```bash
./bin/labctl status
```

## Development Environment

This device is the build node, so the project carries its own shell-native dev
environment.

Enter it with:

```bash
nix-shell
```

That shell provides the tooling needed for this project:

- `shellcheck`
- `shfmt`
- `bats`
- `git`
- `jq`
- `fd`
- `rg`
- `rsync`
- `tmux`

Development helpers:

```bash
./bin/dev-fmt
./bin/dev-lint
./bin/dev-test
./bin/dev-stress
./bin/dev-qa
```

This keeps the local system development-ready without forcing every dependency
into the base system profile.

Suggested local QA gate before staging to the local USB runtime:

```bash
nix-shell --run './bin/dev-qa'
```

## Lean Operation Model

This toolkit now has an explicit anti-bloat workflow:

- `tool new`: author a native module from scratch
- `tool distill`: capture only the upstream command shape and save it as intel
- `release build`: assemble a slim runtime tree with selected tools only

That means you can study existing tools without dragging their full source
trees, build chains, caches, and unused assets into your operating workflow.

Read more in [docs/LEAN.md](./docs/LEAN.md).

## Atlas Blueprint

Atlas is the operator control plane for authorized security assessment work.
The near-term product direction is captured in
[docs/ATLAS_BLUEPRINT.md](./docs/ATLAS_BLUEPRINT.md): keep Atlas as the
single front door, split its internals into focused modules, and build the next
foundation through doctor, scope, ledger, evidence, findings, validation,
reports, advisor, exposure-cycle views, retention packets, and v1 readiness
checks. The current v1 pillar contract is captured in
[docs/atlas/V1_PILLAR_READINESS.md](./docs/atlas/V1_PILLAR_READINESS.md).

## Safety Boundary

Atlas is designed for authorized assessment orchestration only.

Atlas does not provide autonomous exploitation, persistence, destructive
testing, credential spraying, denial-of-service workflows, or out-of-scope
target expansion.

Target-touching operation workflows are expected to pass through scope checks,
capability classification, operation logging, and evidence recording. Tier 3
safe-validation actions require an explicit approval record before execution.

## Shared Intel

The toolkit now has a shared memory layer for cross-tool recommendations.

- `state/intel/observations.jsonl`: tool-level facts such as open services
- `state/intel/entities.jsonl`: normalized hosts and services
- `state/intel/outcomes.jsonl`: run results and counts
- `state/intel/relationships.jsonl`: links such as host-to-service exposure

Inspect it with:

```bash
./bin/intelctl summary
./bin/intelctl observations
./bin/intelctl entities service
./bin/intelctl outcomes
./bin/intelctl graph 10.0.0.8 --format dot --output graph.dot
./bin/intelctl paths 10.0.0.8 --format ndjson
```

The first publisher is `wiremap`. That gives the next tool a stable shared
intel spine instead of coupling it to raw run files.

The first consumer is `vector`, which turns shared observations into ranked
action lanes, explainable plans, bounded runs, session-backed outcomes, and
Metasploit-backed research when the Framework is present.

The unified runtime front-end is `atlas`, which gives you one operator app
without flattening the domain tools:

- `atlas` is the front door
- `wiremap` remains the recon and packet-evidence engine
- `vector` remains the action and session engine
- `intelctl` remains the direct shared-intel inspector

That split is now sharper:

- `atlas` wraps both domains so the operator remembers one command instead of three
- `wiremap` owns discovery, packet evidence, and saved-run interpretation
- `wiremap capture creds` can publish `credential_hint` observations
- `wiremap capture anomalies` can publish `capture_anomaly` observations
- `vector` consumes those hints to keep credential and validation lanes relevant
- `vector` still stays the action console instead of becoming a packet tool

That gives the toolkit a full operator loop:

- `wiremap` discovers
- shared intel remembers
- `vector` ranks and acts
- `vector` writes outcomes back into shared intel

Atlas now also exposes the operator-level story and reporting layer:

- `atlas v1 status [--strict] [--json]`: read-only product-pillar readiness
  view for the core v1 surface and release-gate style checks
- `atlas release packet [packet-name] [--json]`: metadata-only release trust
  packet in Markdown or JSON schema form with commit, tags, v1 readiness JSON,
  QA status, retention notes, repo sync state, and known limitations; normal
  packet generation requires a clean, synced, v1-ready repository unless an
  explicit override flag is used
- `atlas release verify [packet-name]`: release trust packet verification for
  clean/synced state, passing QA status, required retention notes, known
  limitations, and embedded v1 readiness JSON in either packet format
- `atlas web assess <url> [assessment-name]`: bounded public web assessment
  packetization that creates an Atlas operation, stores route/header and
  API/CORS results as evidence, records posture findings, bundles evidence,
  and writes report and handoff packets; URLs with a path keep that base path
  for mounted apps such as `/bWAPP` or path-scoped training targets
- `atlas web validation-plan [--all]`: queue approval-gated posture validation
  plans for open web assessment findings without re-probing the target
- `atlas web validation-approve [--all] --reason <text>`: approve planned web
  validation items as a separate governance step before execution
- [Atlas Trust Lifecycle](docs/atlas/TRUST_LIFECYCLE.md): the end-to-end
  proof path from scoped operation through evidence, validation, retention,
  archive, v1 readiness, and release trust JSON
- `atlas target update <name>`: target registry metadata for scope status,
  criticality, owner, and tags
- `atlas target brief <target>`: concise surface, operation-state, validation,
  and next-step readout
- `atlas cycle [target]`: read-only exposure-cycle view that ties discovery,
  findings, validation queue, report readiness, and ranked candidate lanes
  together
- `atlas target story <target>`: target record, surface, outcomes, findings,
  recent evidence, and ranked next actions
- `atlas op show [name]`: operation scope, allowed actions, out-of-scope
  actions, and tracked artifacts
- `atlas evidence add <path>`: operation-owned artifact copy with SHA-256 index
- `atlas evidence redact <id> <redacted-path>`: attach a redacted derivative
  while preserving original evidence hashes
- `atlas evidence bundle [bundle-name]`: create a redacted/public evidence
  handoff bundle with manifest hashes
- `atlas finding add <title>`: observed, inferred, or validated finding record
- `atlas finding update <id>` / `atlas finding resolve <id>`: append lifecycle
  updates with validation links and notes while preserving finding history
- `atlas validation plan <lane>`: plan, approve, run, and retest bounded validation
- `atlas op brief`: operation summary with evidence, findings, and validation counts
- `atlas op cycle [name]`: operation-owned exposure-cycle view for the active
  or named operation
- `atlas op report [name] [report-name]`: Markdown assessment brief with
  executive summary, grouped findings, remediation priorities, and validation status
- `atlas op readiness [name]`: closure readiness check for unresolved findings,
  pending validation, evidence, report, bundle, handoff, closeout, and audit
  packet and archive packet freshness
- `atlas op handoff [name] [handoff-name]`: metadata-only handoff packet with
  readiness, freshness state, report, bundle, findings, validation, and ledger pointers
- `atlas op closeout [name] [manifest-name]`: metadata-only audit manifest with
  closeout freshness states and SHA-256 anchors
- `atlas op verify [name] [closeout-manifest]`: read-only closeout manifest
  verification for recorded hashes and ledger event counts
- `atlas op audit [name]`: read-only operation ledger timeline with event
  counts, freshness flags, forced-close flags, and closeout verification status
- `atlas op audit-packet [name] [packet-name]`: metadata-only audit packet with
  event counts, audit flags, timeline, ledger and closeout hashes, and freshness state
- `atlas op audit-verify [name] [audit-packet]`: read-only audit packet
  verification for recorded ledger event count, ledger hash, and closeout hash
- `atlas op archive [name]`: read-only final archive snapshot with readiness,
  freshness, verification status, and artifact pointers
- `atlas op archive-packet [name] [packet-name]`: metadata-only archive packet
  with final archive status, freshness state, verification state, hashes, and
  artifact pointers
- `atlas op archive-verify [name] [archive-packet]`: read-only archive packet
  verification for recorded artifact hashes and ledger event count
- `atlas op close [name] [--force]`: close only when readiness passes unless an
  explicit forced closure is recorded
- `atlas advisor brief`: state-only AI advisor readout with redaction guardrails
- `atlas advisor prompt [name] [packet-name]`: metadata-only advisor packet for
  AI-assisted summarization and report drafting
- `atlas story demo-web-app`: canned anonymized demo story with no live target

## Why This Fits Better

Instead of installing or copying full offensive tool repositories, this gives
you a native control plane:

- target metadata stays yours
- session structure stays consistent
- tool modules are authored locally and intentionally
- later deployment to the USB is just a tree sync, not an install event

## Runtime Deployment

Build a lean release:

```bash
./bin/labctl release build usb-runtime atlas wiremap vector egress-check
```

Activate it on an unlocked local USB vault:

```bash
./bin/labctl deploy activate usb-runtime /run/media/ao/labvault/runtime
```

Activation syncs the selected release, migrates old release-local mutable state
into the runtime `shared/` directory, syncs target records, and switches the
runtime `current` pointer.
