# Atlas Milestone Index

## Purpose

This index makes the retained Atlas milestone chain readable without opening
every milestone note individually.

The index is a navigation aid, not a replacement for the retained milestone
notes. Each row points to the source note that contains the full purpose,
changes, verification output, repo state, and boundaries for that milestone.

## Columns

- Milestone: retained milestone note.
- Commit: implementation commit recorded by the note.
- Title: milestone title.
- Category: primary project area.
- Runtime Change?: whether the milestone changed command/runtime behavior.
- Trust Impact: why the milestone matters to Atlas' trust model.
- Verification: strongest retained verification summary.
- Tag: retained git tag.

## Index

| Milestone | Commit | Title | Category | Runtime Change? | Trust Impact | Verification | Tag |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [30](MILESTONE_30.md) | `8974616` | Archive packet freshness checks | retention | yes | Makes stale archive packets visible in readiness, archive, and audit surfaces. | `tests/atlas.bats`: 60/60; dev-lint; dev-qa | `atlas-retention-m30` |
| [31](milestones/MILESTONE_31.md) | `67c09be` | v1 pillar readiness status | release-trust | yes | Adds an internal readiness view across Atlas platform pillars. | `tests/atlas.bats`: 61/61; dev-qa; lint ok; stress ok | `atlas-retention-m31` |
| [32](milestones/MILESTONE_32.md) | `870ae51` | v1 pillar readiness contract | release-trust | yes | Turns readiness into an auditable contract with strict/json modes and negative tests. | `tests/atlas.bats`: 62/62; dev-qa; lint ok; stress ok | `atlas-retention-m32` |
| [33](milestones/MILESTONE_33.md) | `93ca144` | release trust packets | release-trust | yes | Exports release readiness as a metadata-only trust packet. | `tests/atlas.bats`: 63/63; dev-qa; lint ok; stress ok | `atlas-retention-m33` |
| [34](milestones/MILESTONE_34.md) | `f2c3572` | release trust verification | release-trust | yes | Makes release packets fail closed and independently verifiable. | `tests/atlas.bats`: 63/63; dev-qa; lint ok; stress ok | `atlas-retention-m34` |
| [35](milestones/MILESTONE_35.md) | `29f7adc` | release trust JSON schema | release-trust | yes | Adds machine-readable release trust packets under `atlas.release_trust.v1`. | `dev-test`: 63/63; dev-lint; dev-qa | `atlas-retention-m35` |
| [36](milestones/MILESTONE_36.md) | `e15c9e5` | trust lifecycle proof | release-trust | yes | Proves scoped operation through evidence, validation, retention, archive, and release trust. | `dev-test`: 64/64; dev-lint; dev-qa | `atlas-retention-m36` |
| [37](milestones/MILESTONE_37.md) | `2326912` | web assessment packetization | evidence | yes | Turns bounded public web posture checks into retained Atlas operations. | `dev-test`: 65/65; dev-lint; dev-qa | `atlas-retention-m37` |
| [38](milestones/MILESTONE_38.md) | `cdfe693` | API/CORS web assessment evidence | evidence | yes | Retains bounded API status and CORS posture evidence. | focused web assess: 2/2; `dev-test`: 66/66; dev-qa | `atlas-retention-m38` |
| [39](milestones/MILESTONE_39.md) | `2fea85b` | web validation queue | validation | yes | Converts web findings into approval-gated validation plans without touching the target. | focused web assess: 2/2; `dev-test`: 66/66; dev-qa | `atlas-retention-m39` |
| [40](milestones/MILESTONE_40.md) | `db49735` | web validation approval | validation | yes | Separates validation planning, approval, execution, and retest. | focused web assess: 2/2; `dev-test`: 66/66; dev-qa | `atlas-retention-m40` |
| [41](milestones/MILESTONE_41.md) | `81a3ee8` | mounted web target assessment | evidence | yes | Keeps path-scoped web targets assessed at their mounted base path. | focused web assess coverage; dev-qa | `atlas-retention-m41` |
| [42](milestones/MILESTONE_42.md) | `bdfa1de` | validation supersession | validation | yes | Preserves obsolete validation runs while linking successful replacements. | focused validation coverage; dev-qa | `atlas-retention-m42` |
| [43](milestones/MILESTONE_43.md) | `b005127` | validated open retest state | validation | yes | Makes retested still-open findings explicitly validated/open. | focused retest coverage; dev-qa | `atlas-retention-m43` |
| [44](milestones/MILESTONE_44.md) | `6a82074` | accepted risk workflow | findings | yes | Records accepted-risk ownership, reason, expiry, and evidence links. | focused accepted-risk coverage; dev-qa | `atlas-retention-m44` |
| [45](milestones/MILESTONE_45.md) | `8e18f0c` | accepted-risk expiry gate | findings | yes | Makes expired accepted risks block clean closeout and surface in audit/v1 views. | focused accepted-risk expiry coverage; dev-qa | `atlas-retention-m45` |
| [46](milestones/MILESTONE_46.md) | `7dd0907` | accepted-risk review workflow | findings | yes | Adds explicit accepted-risk review and renewal governance. | focused accepted-risk review coverage; `dev-qa`: 71/71 | `atlas-retention-m46` |
| [47](milestones/MILESTONE_47.md) | `8af1dd8` | accepted-risk review queue | findings | yes | Shows expired, due-soon, no-expiry, and current accepted-risk review workload. | focused review queue coverage; `dev-qa`: 72/72 | `atlas-retention-m47` |
| [48](milestones/MILESTONE_48.md) | `f434e40` | accepted-risk review packets | retention | yes | Preserves accepted-risk review queues as metadata-only retention packets. | focused review packet coverage; `dev-qa`: 72/72 | `atlas-retention-m48` |
| [49](milestones/MILESTONE_49.md) | `3c15fefe1b7d0d9831bfabda8ac97b0a5d6f89c7` | accepted-risk review packet freshness | retention | yes | Adds accepted-risk review packet freshness to readiness, audit, and archive. | focused BATS: 5/5; full BATS: 29/29; dev-qa | `atlas-retention-m49` |
| [50](milestones/MILESTONE_50.md) | `bc6320a52304c7cee7b6f9a948f76928b194d7bc` | operation trust-chain closeout | release-trust | yes | Provides one read-only operation closeout chain across readiness and retention artifacts. | focused BATS: 5/5; full BATS: 29/29; dev-qa | `atlas-retention-m50` |
| [51](milestones/MILESTONE_51.md) | `26abbe425f82c7162fbfdeac1e7d9e94b3b87e3f` | release candidate trust-chain binding | release-trust | yes | Requires and embeds current operation trust-chain state for operation-bound releases. | focused BATS: 4/4; full BATS: 29/29; dev-qa | `atlas-retention-m51` |
| [52](milestones/MILESTONE_52.md) | `cceeecc2d8fcb5961056ac318178c2216ab8f8e7` | release candidate trust-chain replay verification | release-trust | yes | Replays operation trust-chain, ledger, and archive state during release verification. | focused BATS: 2/2; full BATS: 29/29; dev-qa | `atlas-retention-m52` |
| [53](milestones/MILESTONE_53.md) | `e5c0e0ed22a2c2c852fec4370b9ff8e1042ab5bd` | Markdown release trust-chain replay parity | release-trust | yes | Gives Markdown release packets the same operation replay standard as JSON packets. | focused BATS: 2/2; full BATS: 29/29; dev-qa | `atlas-retention-m53` |
| [54](milestones/MILESTONE_54.md) | `96ff1e53a9af3318d412ee963bff400867ec7f11` | root agent guidance | agent-governance | no | Adds strict repo-root guidance for safe future agent work. | `dev-qa`: 72/72, lint ok, stress ok | `atlas-retention-m54` |
| [55](milestones/MILESTONE_55.md) | `4bd10fff7439cce1012744eaad9cccce069dedd9` | production readiness gate | release-trust | yes | Makes production readiness measurable and conservative. | production focused test: 1/1; `dev-test`: 73/73; `dev-qa`: 73/73 | `atlas-retention-m55` |
| [56](milestones/MILESTONE_56.md) | `63773156e376e018ed7de97788b54258e80cf04b` | agent guidance validation | agent-governance | no | Makes the root agent safety contract testable. | agent focused test: 1/1; `dev-qa`: 74/74 | `atlas-retention-m56` |

## Category Notes

- `retention`: closeout, audit, archive, freshness, and retained artifact work.
- `release-trust`: v1 readiness, release trust, production readiness, and replay gates.
- `evidence`: retained assessment evidence and packetized assessment surfaces.
- `validation`: approval-gated validation planning, execution state, and retest governance.
- `findings`: finding lifecycle, accepted risk, and review governance.
- `agent-governance`: repository guidance that constrains future agent work.

## Update Rule

When a milestone is retained, update this index in the same retention closeout
or in the immediately following retention note commit. The test suite checks
that every retained milestone note is represented here with its retention tag.
