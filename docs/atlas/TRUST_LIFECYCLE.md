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
| Evidence | `atlas evidence add`, `atlas evidence bundle` | evidence index, hashes, bundle manifest |
| Findings | `atlas finding add`, `atlas finding update` | finding lifecycle records |
| Validation | `atlas validation plan`, `atlas validation approve`, `atlas validation run`, `atlas validation retest` | approval record, validation plan, retest state |
| Report | `atlas op report`, `atlas op readiness` | current operation report and readiness state |
| Handoff | `atlas op handoff` | metadata-only handoff packet |
| Closeout | `atlas op close`, `atlas op closeout`, `atlas op verify` | closeout manifest and hash verification |
| Audit | `atlas op audit-packet`, `atlas op audit-verify` | audit packet and audit verification |
| Archive | `atlas op archive-packet`, `atlas op archive-verify` | archive packet and archive verification |
| Release | `atlas v1 status --strict`, `atlas release packet --json`, `atlas release verify` | v1 readiness and release trust JSON |

## Overall Rule

A lifecycle proof is current only when:

- operation readiness is `ready`
- report, handoff, closeout, audit packet, and archive packet freshness are current
- closeout, audit packet, archive packet, and release packet verification pass
- `atlas v1 status --strict` returns overall `ready`
- release trust JSON uses schema `atlas.release_trust.v1`

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
atlas v1 status trust-lifecycle-op --strict
atlas release packet trust-lifecycle-m36 --json --qa-status pass
atlas release verify trust-lifecycle-m36
```

## Boundaries

This lifecycle proves metadata integrity and freshness across the Atlas control
plane. It does not yet provide cryptographic signing, immutable external
storage, or third-party provenance attestations.
