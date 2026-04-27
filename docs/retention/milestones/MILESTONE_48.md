# Milestone 48: Atlas Accepted-Risk Review Packets

## Commit

`f434e40 Add Atlas accepted-risk review packets`

## Purpose

Preserve accepted-risk review queues as durable, metadata-only retention
artifacts. Operators can now generate a packet that captures the review window,
queue counts, accepted-risk rows, finding-index hash, and operation-ledger
anchor, then verify that packet later.

## Added

- `atlas finding review-packet [packet-name] [--within days]`
- `atlas finding review-verify [packet]`
- Metadata-only Markdown packet under the active operation directory
- Review packet anchors for the operation finding index and ledger
- Read-only packet verification with nonzero failure on stale finding state or
  disallowed later ledger events
- Closeout verification allowance for later accepted-risk review packet ledger
  events
- README, Atlas README, blueprint, and v1 pillar contract updates
- Regression coverage for packet generation, successful verification, read-only
  verification, and stale packet failure after accepted-risk review changes

## Verified

- `bash -n tools/atlas/lib/findings.sh tools/atlas/bin/atlas tools/atlas/lib/closeout.sh tools/atlas/lib/v1.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "review-queue|accepted risk|expired accepted|help"'`: 3/3
- `nix-shell --run 'bats tests/atlas.bats'`: 29/29
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 72/72, lint ok, stress ok

## Behavior

`atlas finding review-packet` appends a `finding.review_packet.generated` ledger
event, writes the packet, and records operation history. The packet contains no
raw evidence or artifact bodies. `atlas finding review-verify` does not write
ledger events; it verifies the packet operation, finding-index hash, and ledger
anchor.

## Boundaries

This milestone does not renew or approve accepted risks. It preserves and
verifies the review queue snapshot. Renewal still requires `atlas finding
review` with a review reason.

## Repo State

- implementation committed: `f434e40 Add Atlas accepted-risk review packets`
- retention note present
- tag target: `atlas-retention-m48`
