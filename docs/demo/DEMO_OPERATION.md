# Atlas Demo Operation

## Purpose

This walkthrough shows a complete local Atlas operation lifecycle using a demo
target and metadata-only retained artifacts.

The goal is operator understanding, not target testing. The demo uses local
evidence files and bounded validation records so another operator can see how
scope, evidence, findings, validation, reports, closeout, audit, archive, and
release trust fit together.

## Boundary

- Use only targets you are authorized to assess.
- Do not replace the demo target with a real system unless the operation is in
  scope.
- Do not add raw secrets, packet captures, credentials, tokens, or unredacted
  sensitive evidence to retained packets.
- Treat `ready` as internal readiness for refinement, not production
  certification.

## Setup

Run from the repository root:

```bash
nix-shell
```

Create a local demo target and operation:

```bash
./bin/labctl target add demo-node 127.0.0.1 demo
./tools/atlas/bin/atlas target update demo-node --scope-status in-scope --criticality medium --tag demo
./tools/atlas/bin/atlas op start --profile htb-starting-point demo-operation demo-node authorized local demo operation
```

Create a harmless local evidence file:

```bash
mkdir -p .tmp/demo-operation
printf 'demo observation: local service review placeholder\n' > .tmp/demo-operation/observation.txt
```

## Operation Flow

Add evidence and a finding:

```bash
evidence_id="$(
  ./tools/atlas/bin/atlas evidence add .tmp/demo-operation/observation.txt --kind scan-output --classification public |
    awk -F': ' '$1 == "id" { print $2; exit }'
)"

finding_id="$(
  ./tools/atlas/bin/atlas finding add "Demo observation requires owner review" \
    --level observed \
    --severity low \
    --confidence medium \
    --evidence "$evidence_id" |
    awk -F': ' '$1 == "id" { print $2; exit }'
)"
```

Plan, approve, run, and retest validation:

```bash
plan_id="$(
  ./tools/atlas/bin/atlas validation plan validate --finding "$finding_id" --evidence "$evidence_id" |
    awk -F': ' '$1 == "id" { print $2; exit }'
)"

./tools/atlas/bin/atlas validation approve "$plan_id" "approved bounded demo validation"
./tools/atlas/bin/atlas validation run "$plan_id"
./tools/atlas/bin/atlas validation retest "$plan_id" --result resolved --evidence "$evidence_id" --note "demo remediation confirmed"
```

Generate retained operation artifacts:

```bash
./tools/atlas/bin/atlas evidence bundle demo-operation-bundle
./tools/atlas/bin/atlas op report demo-operation demo-operation-report
./tools/atlas/bin/atlas op handoff demo-operation demo-operation-handoff
./tools/atlas/bin/atlas op readiness demo-operation
```

Close and verify the operation:

```bash
./tools/atlas/bin/atlas op close demo-operation
./tools/atlas/bin/atlas op closeout demo-operation demo-operation-closeout
./tools/atlas/bin/atlas op verify demo-operation
./tools/atlas/bin/atlas op audit demo-operation
./tools/atlas/bin/atlas op audit-packet demo-operation demo-operation-audit
./tools/atlas/bin/atlas op audit-verify demo-operation
./tools/atlas/bin/atlas op archive demo-operation
./tools/atlas/bin/atlas op archive-packet demo-operation demo-operation-archive
./tools/atlas/bin/atlas op archive-verify demo-operation
./tools/atlas/bin/atlas op trust-chain demo-operation --strict
./tools/atlas/bin/atlas op trust-chain demo-operation --json
```

When the repository is clean and synced, bind a release packet to the operation:

```bash
./tools/atlas/bin/atlas v1 status demo-operation --strict
./tools/atlas/bin/atlas release packet demo-operation-release --json --operation demo-operation --qa-status pass
./tools/atlas/bin/atlas release verify demo-operation-release
```

## Expected Retained Artifacts

- operation env record
- scope snapshot
- `ledger.ndjson`
- evidence record and evidence bundle
- finding and validation records
- operation report
- handoff packet
- closeout manifest
- audit packet
- archive packet
- operation trust-chain JSON
- release trust packet when generated from a clean synced repository

## Stop Conditions

Stop and investigate before closeout if any of these appear:

- scope is not in-scope
- validation is pending or unapproved
- findings remain open without accepted-risk ownership
- accepted risks are expired
- report, handoff, closeout, audit, or archive freshness is stale
- `atlas op trust-chain --strict` does not report current
