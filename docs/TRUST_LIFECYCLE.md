# Trust Lifecycle

## Purpose

Atlas' trust lifecycle explains how an authorized operation moves from scope to
release without relying on raw artifact contents or hand-wavy status claims.

The lifecycle is metadata-first. Atlas records what happened, where retained
artifacts live, which hashes anchor them, and which commands prove the chain is
still current.

## Lifecycle Stages

| Stage | Command Surface | Trust Output |
| --- | --- | --- |
| Scope | `atlas op start`, `atlas scope check` | operation scope snapshot and ledger preflights |
| Web Assessment | `atlas web assess` | route/header evidence, API/CORS evidence, findings, report, handoff |
| Evidence | `atlas evidence add`, `atlas evidence bundle` | evidence records, hashes, bundle manifest |
| Findings | `atlas finding add`, `atlas finding update`, `atlas finding accept` | finding lifecycle records and accepted-risk ownership |
| Validation | `atlas validation plan`, `atlas validation approve`, `atlas validation run`, `atlas validation retest` | approval record, validation plan, run outcome, retest state |
| Report | `atlas op report`, `atlas op readiness` | assessment report and closure readiness |
| Handoff | `atlas op handoff`, `atlas op handoff --json` | metadata-only handoff packet |
| Closeout | `atlas op close`, `atlas op closeout`, `atlas op closeout --json`, `atlas op verify` | closeout manifest and hash verification |
| Audit | `atlas op audit-packet`, `atlas op audit-packet --json`, `atlas op audit-verify` | audit packet and audit verification |
| Archive | `atlas op archive-packet`, `atlas op archive-packet --json`, `atlas op archive-verify` | archive packet and archive verification |
| Trust Chain | `atlas op trust-chain --strict`, `atlas op trust-chain --json` | consolidated operation trust-chain status, optional business-flow counts, and `atlas.operation_trust_chain.v1` JSON |
| Release | `atlas v1 status --strict`, `atlas release packet --json`, `atlas release verify`, `atlas release replay` | v1 readiness and release trust JSON |
| Provenance | signed Git tag, retained public key, release provenance packet | signed release provenance tied to retained release evidence |

## Current Rule

A trust chain is current only when:

- operation readiness is `ready`
- report, handoff, closeout, audit packet, and archive packet freshness are current
- accepted-risk review packet verification passes when accepted risks exist
- closeout, audit packet, archive packet, and release packet verification pass
- `atlas op trust-chain --strict` returns `current`
- `atlas v1 status --strict` returns overall `ready`
- release packets record operation trust-chain state when a release candidate is
  tied to a completed operation
- `atlas release verify` replays recorded operation trust state instead of
  trusting packet fields alone
- retained release packets can be replayed from the commit recorded inside the
  packet
- production status verifies release packet, signing/provenance, and retained
  dry-run evidence together

## Minimal Verification Path

```bash
./tools/atlas/bin/atlas op readiness <operation>
./tools/atlas/bin/atlas op trust-chain <operation> --strict
./tools/atlas/bin/atlas v1 status <operation> --strict
./tools/atlas/bin/atlas release packet <release-name> --json --operation <operation> --qa-status pass
./tools/atlas/bin/atlas release verify <release-name>
./tools/atlas/bin/atlas release replay <release-name>
./tools/atlas/bin/atlas production status --strict
```

## Metadata Boundary

Trust packets may point to files, hashes, counts, commits, tags, and known
limitations. They must not embed raw secrets, private keys, tokens, packet
captures, credential material, session contents, exploit payloads, or
unredacted sensitive evidence bodies.

## Related Docs

- [OPERATOR_GUIDE.md](OPERATOR_GUIDE.md)
- [RELEASE_TRUST.md](RELEASE_TRUST.md)
- [WEB_ASSESSMENT.md](WEB_ASSESSMENT.md)
- [schemas/operation-trust-chain.v1.md](schemas/operation-trust-chain.v1.md)
- [atlas/TRUST_LIFECYCLE.md](atlas/TRUST_LIFECYCLE.md)
