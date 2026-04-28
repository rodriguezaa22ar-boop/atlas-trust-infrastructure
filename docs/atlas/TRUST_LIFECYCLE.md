# Atlas Trust Lifecycle

## Purpose

The Atlas trust lifecycle proves that a finished operation can move from
authorized scope through evidence, validation, retention, archive, and release
without relying on raw artifact contents or unverified claims.

The lifecycle is metadata-first. It records what happened, where the retained
artifacts live, which hashes anchor them, and which verification commands prove
the chain is still current.

## Lifecycle Stages

| Stage | Command Surface | Trust Output |
| --- | --- | --- |
| Scope | `atlas op start`, `atlas scope check` | operation scope snapshot and ledger preflights |
| Web Assessment | `atlas web assess` | retained route/header and API/CORS evidence, including mounted base-path targets, findings, report, and handoff packet |
| Evidence | `atlas evidence add`, `atlas evidence bundle` | evidence index, hashes, bundle manifest |
| Findings | `atlas finding add`, `atlas finding update` | finding lifecycle records |
| Validation | `atlas web validation-plan`, `atlas web validation-approve`, `atlas validation plan`, `atlas validation approve`, `atlas validation run`, `atlas validation retest` | approval record, validation plan, retest state |
| Report | `atlas op report`, `atlas op readiness` | current operation report and readiness state |
| Handoff | `atlas op handoff` | metadata-only handoff packet |
| Closeout | `atlas op close`, `atlas op closeout`, `atlas op verify` | closeout manifest and hash verification |
| Audit | `atlas op audit-packet`, `atlas op audit-verify` | audit packet and audit verification |
| Archive | `atlas op archive-packet`, `atlas op archive-verify` | archive packet and archive verification |
| Trust Chain | `atlas op trust-chain --strict`, `atlas op trust-chain --json` | consolidated operation trust-chain status, optional business-flow counts, and `atlas.operation_trust_chain.v1` JSON |
| Release | `atlas v1 status --strict`, `atlas release packet --json`, `atlas release verify` | v1 readiness and release trust JSON |

## Overall Rule

A lifecycle proof is current only when:

- operation readiness is `ready`
- report, handoff, closeout, audit packet, and archive packet freshness are current
- accepted-risk review packet verification passes when accepted risks exist
- closeout, audit packet, archive packet, and release packet verification pass
- `atlas op trust-chain --strict` returns `current`
- `atlas v1 status --strict` returns overall `ready`
- release trust packets record the operation trust chain when the release
  candidate is tied to a completed operation, and `atlas release verify` replays
  that operation's trust-chain, ledger, and archive packet state from current
  local operation state
- retained release packets can be replayed from a clean checkout of the packet
  commit using `docs/retention/releases/REPLAY_VERIFICATION.md`

## Verified Path

Milestone 36 adds automated coverage for the full path:

```bash
atlas op start --profile htb-starting-point trust-lifecycle-op demo-node authorized lifecycle proof
atlas evidence add ./artifact.txt --kind scan-output --classification public
atlas finding add "SSH management reachable" --level observed --severity low --confidence high --evidence <id>
atlas validation plan validate --finding <finding-id> --evidence <evidence-id>
atlas validation approve <plan-id> lifecycle validation approved
atlas validation run <plan-id>
atlas validation retest <plan-id> --result resolved --evidence <retest-evidence-id>
atlas evidence bundle trust-lifecycle-bundle
atlas op report trust-lifecycle-op trust-lifecycle-report
atlas op handoff trust-lifecycle-op trust-lifecycle-handoff
atlas op close trust-lifecycle-op
atlas op closeout trust-lifecycle-op trust-lifecycle-closeout
atlas op verify trust-lifecycle-op
atlas op audit-packet trust-lifecycle-op trust-lifecycle-audit
atlas op audit-verify trust-lifecycle-op
atlas op archive-packet trust-lifecycle-op trust-lifecycle-archive
atlas op archive-verify trust-lifecycle-op
atlas op trust-chain trust-lifecycle-op --strict
atlas v1 status trust-lifecycle-op --strict
atlas release packet trust-lifecycle-m53 --operation trust-lifecycle-op --qa-status pass
atlas release packet trust-lifecycle-m36 --json --operation trust-lifecycle-op --qa-status pass
atlas release verify trust-lifecycle-m36
```

## Operator Walkthrough

A practical local demo operation is documented in
[`docs/demo/DEMO_OPERATION.md`](../demo/DEMO_OPERATION.md). It shows the same
trust lifecycle with operator-facing commands, retained artifact expectations,
trust-chain reading guidance, and sample output shapes.

## Boundaries

This lifecycle proves metadata integrity and freshness across the Atlas control
plane. Release provenance now verifies a signed Git tag through a retained
public key, but operation packets are still hash-anchored metadata records, not
individually signed artifacts. The lifecycle does not provide immutable
external storage or third-party provenance attestations.
