# Command Reference

## Purpose

This is the detailed command reference for Native Lab Toolkit. The root
`README.md` is intentionally short; use this file when you need the broader
command surface.

Run commands from the repository root. Inside `nix-shell`, `bin/` is added to
`PATH`, but examples keep explicit paths for clarity.

## Development And QA

```bash
nix-shell
./bin/dev-fmt
./bin/dev-lint
./bin/dev-test
./bin/dev-stress
./bin/dev-qa
nix-shell --run './bin/dev-qa'
```

## Lab Administration

```bash
./bin/labctl status
./bin/labctl init
./bin/labctl target add edge-router 192.168.1.1 home-lab
./bin/labctl target list
./bin/labctl session open april-lab edge-router
./bin/labctl report new april-findings
./bin/labctl tool new egress-check "check direct and proxied egress"
./bin/labctl tool distill jq-shape jq --help
./bin/labctl tool list
./bin/labctl release build usb-runtime atlas wiremap vector egress-check
./bin/labctl deploy activate usb-runtime /run/media/ao/labvault/runtime
```

## Shared Intel

```bash
./bin/intelctl summary
./bin/intelctl observations
./bin/intelctl entities service
./bin/intelctl outcomes
./bin/intelctl graph 10.0.0.8 --format dot --output graph.dot
./bin/intelctl paths 10.0.0.8 --format ndjson
```

## Atlas Readiness And Release

```bash
./tools/atlas/bin/atlas doctor
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas v1 status --json
./tools/atlas/bin/atlas production status
./tools/atlas/bin/atlas production status --strict
./tools/atlas/bin/atlas production status --json
./tools/atlas/bin/atlas production status --strict --explain
./tools/atlas/bin/atlas reviewer package atlas-current-review
./tools/atlas/bin/atlas release packet atlas-current --qa-status pass
./tools/atlas/bin/atlas release packet atlas-current --json --operation april-review --qa-status pass
./tools/atlas/bin/atlas release verify atlas-current
./tools/atlas/bin/atlas release replay atlas-current
./tools/atlas/bin/atlas release replay atlas-current --json --skip-qa
./tools/atlas/bin/atlas release manifest atlas-current
./tools/atlas/bin/atlas release manifest atlas-current --slsa docs/retention/releases/atlas-current.slsa.json
./tools/atlas/bin/atlas release manifest-verify atlas-current
./tools/atlas/bin/atlas release slsa-verify docs/retention/releases/atlas-current.slsa.json --commit <sha>
./tools/atlas/bin/atlas release slsa-verify docs/retention/releases/atlas-current.slsa.json --commit <sha> --artifact <artifact>.tar.gz
./tools/atlas/bin/atlas release slsa-verify docs/retention/releases/atlas-current.slsa.json --artifact <artifact>.tar.gz --online
```

## Atlas Targets And Profiles

```bash
./tools/atlas/bin/atlas profile list
./tools/atlas/bin/atlas profile show htb-starting-point
./tools/atlas/bin/atlas target list
./tools/atlas/bin/atlas target update edge-router --scope-status in-scope --criticality high --tag lab
./tools/atlas/bin/atlas target brief 10.0.0.8
./tools/atlas/bin/atlas target story 10.0.0.8
./tools/atlas/bin/atlas target summary 10.0.0.8
./tools/atlas/bin/atlas target next 10.0.0.8
```

## Atlas Operations

```bash
./tools/atlas/bin/atlas op start --profile htb-starting-point april-review 10.0.0.8 bounded review
./tools/atlas/bin/atlas op show april-review
./tools/atlas/bin/atlas op brief april-review
./tools/atlas/bin/atlas op story april-review
./tools/atlas/bin/atlas op cycle april-review
./tools/atlas/bin/atlas op report april-review
./tools/atlas/bin/atlas op readiness april-review
./tools/atlas/bin/atlas op handoff april-review
./tools/atlas/bin/atlas op handoff --json april-review
./tools/atlas/bin/atlas op close april-review
./tools/atlas/bin/atlas op close april-review --force
./tools/atlas/bin/atlas op closeout april-review
./tools/atlas/bin/atlas op closeout --json april-review
./tools/atlas/bin/atlas op verify april-review
./tools/atlas/bin/atlas op audit april-review
./tools/atlas/bin/atlas op audit-packet april-review
./tools/atlas/bin/atlas op audit-packet --json april-review
./tools/atlas/bin/atlas op audit-verify april-review
./tools/atlas/bin/atlas op archive april-review
./tools/atlas/bin/atlas op archive-packet april-review
./tools/atlas/bin/atlas op archive-packet --json april-review
./tools/atlas/bin/atlas op archive-verify april-review
./tools/atlas/bin/atlas op trust-chain april-review --strict
./tools/atlas/bin/atlas op trust-chain april-review --json
```

## Atlas Recon And Action

```bash
./tools/atlas/bin/atlas recon workflow list
./tools/atlas/bin/atlas op recon perimeter-sweep
./tools/atlas/bin/atlas capture creds ./state/wiremap-runs/<run>
./tools/atlas/bin/atlas op action candidates
./tools/atlas/bin/atlas op action plan credentials
./tools/atlas/bin/atlas op action run posture
```

## Atlas Evidence

```bash
./tools/atlas/bin/atlas evidence add ./artifact.txt --kind scan-output --classification public
./tools/atlas/bin/atlas evidence redact ev_... ./artifact-redacted.txt
./tools/atlas/bin/atlas evidence bundle review-bundle
./tools/atlas/bin/atlas evidence list
./tools/atlas/bin/atlas evidence show ev_...
```

## Atlas Business Flows

```bash
./tools/atlas/bin/atlas flow add customer-signup --type customer_onboarding --owner product --criticality high --environment staging --scope-status in-scope --data-class email --system web_app --control audit_logging
./tools/atlas/bin/atlas flow list
./tools/atlas/bin/atlas flow show customer-signup
./tools/atlas/bin/atlas flow link-evidence customer-signup ev_...
./tools/atlas/bin/atlas flow link-finding customer-signup finding_...
./tools/atlas/bin/atlas flow link-validation customer-signup vp_...
./tools/atlas/bin/atlas flow link-approval customer-signup safe-validation
./tools/atlas/bin/atlas flow link-retention customer-signup report reports/customer-signup.md
./tools/atlas/bin/atlas flow packet customer-signup customer-signup-flow
./tools/atlas/bin/atlas flow packet --json customer-signup customer-signup-flow
./tools/atlas/bin/atlas flow verify customer-signup customer-signup-flow
./tools/atlas/bin/atlas flow verify --json customer-signup customer-signup-flow
./tools/atlas/bin/atlas flow assurance customer-signup customer-signup-flow
./tools/atlas/bin/atlas flow assurance --json customer-signup customer-signup-flow
./tools/atlas/bin/atlas flow trust-chain customer-signup customer-signup-flow
./tools/atlas/bin/atlas flow trust-chain --json customer-signup customer-signup-flow
```

Business-flow records are metadata-only global flow records under
`state/atlas/flows/`. Operation links live under
`sessions/<operation>/flow_evidence.ndjson`,
`sessions/<operation>/flow_findings.ndjson`, and
`sessions/<operation>/flow_validation.ndjson`, and
`sessions/<operation>/flow_approvals.ndjson`, and
`sessions/<operation>/flow_retention.ndjson`; they reference existing Atlas IDs
without copying raw evidence, finding bodies, validation reasons, plan bodies,
session contents, approval reasons, operator notes, or retained artifact bodies. Flow packets are
metadata-only Markdown packets
under `sessions/<operation>/flow_packets/` and metadata-only JSON packets under
`sessions/<operation>/flow_packets_json/`. They include flow labels, evidence
IDs, retained paths, hashes, finding references, validation references,
approval metadata references, retention references,
freshness metadata, and known limitations. Flow verification checks packet
metadata, evidence links, finding links, validation links, approval links,
retention links, retained files, hashes, freshness, and forbidden-content
markers. Flow assurance and trust-chain output summarize one flow's link
counts, control coverage counts, reference health, packet presence, and
verification state without mutating operation state. Business Flow Evidence is
optional-ready and non-blocking for core v1 and production readiness.

## Atlas Findings

```bash
./tools/atlas/bin/atlas finding add "SSH reachable" --level observed --severity low --evidence ev_...
./tools/atlas/bin/atlas finding update finding_... --level validated --validation vp_... --note "confirmed by validation run"
./tools/atlas/bin/atlas finding resolve finding_... --validation vp_... --note "remediation confirmed"
./tools/atlas/bin/atlas finding accept finding_... --reason "owner accepts residual exposure" --owner Alta --expires 2026-12-31
./tools/atlas/bin/atlas finding review finding_... --reason "owner renewed acceptance" --owner Alta --expires 2027-03-31
./tools/atlas/bin/atlas finding review-queue --within 30
./tools/atlas/bin/atlas finding review-packet accepted-risk-review --within 30
./tools/atlas/bin/atlas finding review-packet --json accepted-risk-review --within 30
./tools/atlas/bin/atlas finding review-verify accepted-risk-review
./tools/atlas/bin/atlas finding list
./tools/atlas/bin/atlas finding show finding_...
```

## Atlas Validation

```bash
./tools/atlas/bin/atlas validation plan validate --finding finding_... --evidence ev_...
./tools/atlas/bin/atlas validation approve vp_... "approved bounded validation"
./tools/atlas/bin/atlas validation run vp_...
./tools/atlas/bin/atlas validation retest vp_... --result resolved --evidence ev_... --note "remediation confirmed"
./tools/atlas/bin/atlas validation supersede vp_... --by vp_... --reason "successful rerun replaces old result"
```

## Atlas Web Assessment

```bash
./tools/atlas/bin/atlas web assess <url> [assessment-name] --scope-status in-scope
./tools/atlas/bin/atlas web assess https://example.com example-web-review --scope-status in-scope
./tools/atlas/bin/atlas web assess https://example.com/app app-review --scope-status in-scope --api-path /api/auth/me --cors-origin https://example.net
./tools/atlas/bin/atlas web validation-plan --all
./tools/atlas/bin/atlas web validation-approve --all --reason "approved bounded web validation"
```

See [WEB_ASSESSMENT.md](WEB_ASSESSMENT.md) for the full flow and boundaries.

## Advisor And Demo

```bash
./tools/atlas/bin/atlas advisor brief
./tools/atlas/bin/atlas advisor prompt
./tools/atlas/bin/atlas advisor prompt --json
./tools/atlas/bin/atlas story demo-web-app
```

## Wiremap

```bash
./tools/wiremap/bin/wiremap workflow list
./tools/wiremap/bin/wiremap workflow run perimeter-sweep 10.0.0.8
./tools/wiremap/bin/wiremap profile show htb-starting-point
./tools/wiremap/bin/wiremap capture creds ./state/wiremap-runs/<run>
./tools/wiremap/bin/wiremap capture anomalies ./state/wiremap-runs/<run>
./tools/wiremap/bin/wiremap analyze brief ./state/wiremap-runs/<run>
./tools/wiremap/bin/wiremap analyze services ./state/wiremap-runs/<run>
./tools/wiremap/bin/wiremap analyze web-focus ./state/wiremap-runs/<run>
./tools/wiremap/bin/wiremap analyze lateral-trace ./state/wiremap-runs/<run>
./tools/wiremap/bin/wiremap analyze service-diff <old-run> <new-run>
```

## Vector

```bash
./tools/vector/bin/vector candidates 10.0.0.8
./tools/vector/bin/vector plan posture 10.0.0.8
./tools/vector/bin/vector run posture 10.0.0.8
./tools/vector/bin/vector run research 10.0.0.8
./tools/vector/bin/vector session list
./tools/vector/bin/vector target summary 10.0.0.8
```

## Notes

- Read-only commands must stay read-only.
- Packet commands remain metadata-only unless the project owner explicitly
  changes the rule.
- Target-touching commands require authorization and accurate scope records.
- Production readiness is reported by `atlas production status`; do not infer
  it from individual command success or a single release packet.
