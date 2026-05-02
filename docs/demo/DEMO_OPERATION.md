# Demo Operation

## Purpose

This is a metadata-only demo operation for showing the Atlas trust lifecycle
end to end with synthetic demo data. It is designed for reviewers who need to
see the shape of an operation without touching a live target or reading private
evidence bodies.

The demo shows:

1. target registration
2. scope state
3. operation setup
4. evidence reference and hash
5. finding
6. validation
7. report
8. handoff
9. closeout
10. audit packet
11. archive packet
12. release packet
13. release artifact manifest
14. release replay JSON
15. `production status --strict --explain`
16. optional business-flow summary
17. known limitations
18. non-guarantees

## Demo Boundary

All demo data is synthetic demo data. The demo must not include real target
data, customer data, payment data, bank details, credentials, tokens, private
keys, session cookies, packet captures, raw request or response bodies, raw
runtime artifacts, unredacted evidence bodies, exploit payloads, or
unauthorized-access instructions.

Do not run live target assessments for this demo. The local target record is a
placeholder used to exercise Atlas metadata, hashes, packet references, and
reviewer commands.

## Setup

Run from the repository root:

```bash
nix-shell
```

Register a synthetic local target and mark it in scope:

```bash
./tools/atlas/bin/atlas target add demo-local-node 127.0.0.1 synthetic local demo target
./tools/atlas/bin/atlas target update demo-local-node --scope-status in-scope --criticality low --tag synthetic-demo
./tools/atlas/bin/atlas target show demo-local-node
```

Start the operation:

```bash
./tools/atlas/bin/atlas op start --profile htb-starting-point demo-operation demo-local-node authorized synthetic metadata-only demo operation
./tools/atlas/bin/atlas op show demo-operation
./tools/atlas/bin/atlas scope status
```

Create a harmless local evidence reference:

```bash
mkdir -p .tmp/demo-operation
printf 'synthetic observation: local metadata-only demo placeholder\n' > .tmp/demo-operation/observation.txt
./tools/atlas/bin/atlas evidence hash .tmp/demo-operation/observation.txt
```

## Evidence And Finding

Record the evidence reference and create a finding tied to that evidence:

```bash
evidence_id="$(
  ./tools/atlas/bin/atlas evidence add .tmp/demo-operation/observation.txt --kind scan-output --classification public |
    awk -F': ' '$1 == "id" { print $2; exit }'
)"

finding_id="$(
  ./tools/atlas/bin/atlas finding add "Synthetic demo observation requires owner review" \
    --level observed \
    --severity low \
    --confidence medium \
    --evidence "$evidence_id" |
    awk -F': ' '$1 == "id" { print $2; exit }'
)"
```

Inspect the retained metadata:

```bash
./tools/atlas/bin/atlas evidence show "$evidence_id"
./tools/atlas/bin/atlas finding show "$finding_id"
```

## Validation

Plan, approve, run, and retest bounded validation:

```bash
plan_id="$(
  ./tools/atlas/bin/atlas validation plan validate --finding "$finding_id" --evidence "$evidence_id" |
    awk -F': ' '$1 == "id" { print $2; exit }'
)"

./tools/atlas/bin/atlas validation approve "$plan_id" "approved bounded synthetic demo validation"
./tools/atlas/bin/atlas validation run "$plan_id"
./tools/atlas/bin/atlas validation retest "$plan_id" --result resolved --evidence "$evidence_id" --note "synthetic demo remediation confirmed"
./tools/atlas/bin/atlas validation show "$plan_id"
```

## Report And Handoff

Generate operation review artifacts:

```bash
./tools/atlas/bin/atlas evidence bundle demo-operation-bundle
./tools/atlas/bin/atlas op report demo-operation demo-operation-report
./tools/atlas/bin/atlas op readiness demo-operation
./tools/atlas/bin/atlas op handoff demo-operation demo-operation-handoff
./tools/atlas/bin/atlas op handoff --json demo-operation demo-operation-handoff
```

## Closeout, Audit, And Archive

Close and verify the operation:

```bash
./tools/atlas/bin/atlas op close demo-operation
./tools/atlas/bin/atlas op closeout demo-operation demo-operation-closeout
./tools/atlas/bin/atlas op closeout --json demo-operation demo-operation-closeout
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
./tools/atlas/bin/atlas op trust-chain demo-operation --json
```

## Optional Business-Flow Summary

If the business-flow commands are available, add a synthetic business-flow
summary that references the same metadata without storing sensitive business
records:

```bash
./tools/atlas/bin/atlas flow add demo-approval-flow \
  --type operational_review \
  --owner demo-ops \
  --criticality medium \
  --environment local \
  --scope-status in-scope \
  --data-class metadata \
  --system demo-ledger \
  --control dual_review

./tools/atlas/bin/atlas flow link-evidence demo-approval-flow "$evidence_id"
./tools/atlas/bin/atlas flow link-finding demo-approval-flow "$finding_id"
./tools/atlas/bin/atlas flow link-validation demo-approval-flow "$plan_id"
./tools/atlas/bin/atlas flow link-approval demo-approval-flow safe-validation
./tools/atlas/bin/atlas flow packet demo-approval-flow demo-approval-flow-packet
./tools/atlas/bin/atlas flow packet --json demo-approval-flow demo-approval-flow-packet
./tools/atlas/bin/atlas flow verify demo-approval-flow demo-approval-flow-packet
./tools/atlas/bin/atlas flow assurance demo-approval-flow demo-approval-flow-packet
./tools/atlas/bin/atlas flow trust-chain demo-approval-flow demo-approval-flow-packet
```

## Release Trust

When the repository is clean and synced, bind the demo operation to a release
packet:

```bash
./tools/atlas/bin/atlas v1 status demo-operation --strict
./tools/atlas/bin/atlas release packet demo-operation-release --json --operation demo-operation --qa-status pass
./tools/atlas/bin/atlas release verify demo-operation-release
```

Review the currently retained public release evidence with exact commands:

```bash
./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m118-reviewer-flow-polish.json --commit de90b442d43ade01d4f15754b5952d0615582cd6
./tools/atlas/bin/atlas release manifest-verify docs/retention/releases/atlas-m118-reviewer-flow-polish.manifest.json --commit de90b442d43ade01d4f15754b5952d0615582cd6
./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m118-reviewer-flow-polish.json --json
./tools/atlas/bin/atlas production status --strict --explain
```

The passing production explain output may use the full phrase
`production-ready under the local Atlas contract`. Do not shorten that phrase.

## Expected Retained Artifacts

- target record
- scope snapshot
- operation ledger
- evidence record and SHA-256 hash
- finding record
- validation plan, approval, run, and retest state
- operation report
- handoff packet
- closeout manifest
- audit packet
- archive packet
- operation trust-chain JSON
- optional business-flow packet, assurance output, and trust-chain output
- release packet
- release artifact manifest
- release replay JSON output
- production status explanation

## Known Limitations

- This is a synthetic demo, not a live target assessment.
- The demo demonstrates metadata handling, not scanner coverage.
- Release replay checks retained release trust evidence; it does not prove
  runtime safety.
- Production explainability is a reviewer aid under the local Atlas contract;
  it does not create external approval.
- Business Flow Evidence is optional-ready and non-blocking for core v1 and
  production readiness.

## Non-Guarantees

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not external SLSA certification
- not runtime safety proof
- not production deployability proof

## Stop Conditions

Stop and investigate before closeout if any of these appear:

- scope is not in scope
- validation is pending or unapproved
- findings remain open without accepted-risk ownership
- accepted risks are expired
- report, handoff, closeout, audit, or archive freshness is stale
- `atlas op trust-chain demo-operation --strict` does not report current
