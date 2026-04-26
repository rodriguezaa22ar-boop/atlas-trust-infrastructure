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
- `reports/`: generated report stubs
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
./tools/atlas/bin/atlas profile list
./tools/atlas/bin/atlas profile show htb-starting-point
./tools/atlas/bin/atlas target story 10.0.0.8
./tools/atlas/bin/atlas target next 10.0.0.8
./tools/atlas/bin/atlas op start --profile htb-starting-point april-review 10.0.0.8 bounded review
./tools/atlas/bin/atlas op show april-review
./tools/atlas/bin/atlas op action candidates
./tools/atlas/bin/atlas op report april-review
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
foundation in this order: doctor, scope, ledger, evidence, findings, reports,
validation, then AI advisor.

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

- `atlas target update <name>`: target registry metadata for scope status,
  criticality, owner, and tags
- `atlas target brief <target>`: concise surface, operation-state, validation,
  and next-step readout
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
- `atlas validation plan <lane>`: plan, approve, and run bounded validation
- `atlas op brief`: operation summary with evidence, findings, and validation counts
- `atlas op report [name] [report-name]`: Markdown assessment brief with
  executive summary, grouped findings, remediation priorities, and validation status
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
