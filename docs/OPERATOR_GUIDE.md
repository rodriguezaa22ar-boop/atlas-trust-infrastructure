# Operator Guide

## Purpose

This guide shows the normal end-to-end Atlas workflow. It assumes authorized
assessment work and a local shell-native environment.

For a longer demo with sample outputs, see
[docs/demo/DEMO_OPERATION.md](demo/DEMO_OPERATION.md).

## 1. Enter The Environment

```bash
nix-shell
./bin/labctl status
./tools/atlas/bin/atlas doctor
```

## 2. Register Or Update A Target

```bash
./bin/labctl target add demo-node 127.0.0.1 demo
./tools/atlas/bin/atlas target update demo-node --scope-status in-scope --criticality medium --tag demo
./tools/atlas/bin/atlas target brief demo-node
```

Do not mark a real target in scope unless you have authorization.

## 3. Start An Operation

```bash
./tools/atlas/bin/atlas profile list
./tools/atlas/bin/atlas op start --profile htb-starting-point demo-operation demo-node authorized local demo operation
./tools/atlas/bin/atlas op show demo-operation
```

The operation becomes the container for scope, ledger events, evidence,
findings, validation, reports, and retention packets.

## 4. Add Evidence And Findings

```bash
./tools/atlas/bin/atlas evidence add ./artifact.txt --kind scan-output --classification public
./tools/atlas/bin/atlas finding add "Demo observation requires owner review" --level observed --severity low --confidence medium --evidence ev_...
./tools/atlas/bin/atlas finding list
```

Use redacted derivatives for handoff when evidence contains sensitive data:

```bash
./tools/atlas/bin/atlas evidence redact ev_... ./artifact-redacted.txt
./tools/atlas/bin/atlas evidence bundle review-bundle
```

## 5. Plan And Approve Validation

```bash
./tools/atlas/bin/atlas validation plan validate --finding finding_... --evidence ev_...
./tools/atlas/bin/atlas validation approve vp_... "approved bounded validation"
./tools/atlas/bin/atlas validation run vp_...
./tools/atlas/bin/atlas validation retest vp_... --result resolved --evidence ev_... --note "remediation confirmed"
```

Validation remains approval-gated. Do not bypass that separation.

## 6. Report And Close

```bash
./tools/atlas/bin/atlas op report demo-operation demo-operation-report
./tools/atlas/bin/atlas op readiness demo-operation
./tools/atlas/bin/atlas op handoff demo-operation demo-operation-handoff
./tools/atlas/bin/atlas op close demo-operation
```

If readiness fails, fix the blocker or record explicit accepted-risk ownership
where appropriate. Forced closure should be exceptional and visible.

## 7. Retain And Verify

```bash
./tools/atlas/bin/atlas op closeout demo-operation demo-operation-closeout
./tools/atlas/bin/atlas op verify demo-operation
./tools/atlas/bin/atlas op audit demo-operation
./tools/atlas/bin/atlas op audit-packet demo-operation demo-operation-audit
./tools/atlas/bin/atlas op audit-packet --json demo-operation demo-operation-audit
./tools/atlas/bin/atlas op audit-verify demo-operation
./tools/atlas/bin/atlas op archive demo-operation
./tools/atlas/bin/atlas op archive-packet demo-operation demo-operation-archive
./tools/atlas/bin/atlas op archive-packet --json demo-operation demo-operation-archive
./tools/atlas/bin/atlas op archive-verify demo-operation
./tools/atlas/bin/atlas op trust-chain demo-operation --strict
```

## 8. Bind Release Trust

When the repo is clean, synced, and QA has passed:

```bash
nix-shell --run './bin/dev-qa'
./tools/atlas/bin/atlas v1 status demo-operation --strict
./tools/atlas/bin/atlas release packet demo-operation-release --json --operation demo-operation --qa-status pass
./tools/atlas/bin/atlas release verify demo-operation-release
./tools/atlas/bin/atlas production status --strict
```

Release trust is explained in [RELEASE_TRUST.md](RELEASE_TRUST.md).

## Stop Conditions

Stop and investigate before closeout when:

- scope is not explicitly in scope
- validation is pending or unapproved
- findings remain open without accepted-risk ownership
- accepted risks are expired
- report, handoff, closeout, audit, or archive freshness is stale
- `atlas op trust-chain --strict` does not report current
- `atlas production status --strict` fails for a release promotion
