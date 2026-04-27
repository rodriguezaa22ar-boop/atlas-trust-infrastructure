# Atlas Release Replay Verification

## Purpose

Release replay verification proves that a retained release trust packet can be
checked from a clean checkout of the release commit instead of relying on the
current working tree.

This is different from normal `atlas release verify`:

- `atlas release verify <packet>` checks a packet against the current checkout.
- Replay verification checks the packet against the commit recorded inside the
  packet.

Replay matters because later milestones add retention notes, tests, and trust
rules that an older packet could not have known about.

## Safety

This procedure is read-only with respect to Atlas target operations. It creates
a temporary git worktree, runs local verification commands, and removes the
worktree afterward.

It does not touch targets, run recon, run validation, mutate operation ledgers,
or embed raw runtime artifacts.

## Inputs

- a retained release packet under `docs/retention/releases/`
- a clean current checkout
- Nix development environment support
- git worktree support

JSON packets are preferred for replay because the commit field is structured.
Markdown packets can be replayed too, but the commit must be extracted from the
`Commit:` header.

## JSON Replay

From the current repository root:

```bash
packet="$(pwd)/docs/retention/releases/atlas-m36-json.json"
commit="$(jq -r '.commit' "$packet")"
worktree="$(mktemp -d)"

git worktree add --detach "$worktree" "$commit"
(
  cd "$worktree"
  nix-shell --run './bin/dev-qa'
  ./tools/atlas/bin/atlas v1 status --strict
  ./tools/atlas/bin/atlas release verify "$packet" --commit "$commit"
)
git worktree remove "$worktree"
```

Expected result:

- the worktree checks out the packet commit
- `dev-qa` passes using the test suite and tooling at that commit
- `atlas v1 status --strict` is ready at that commit
- `atlas release verify` verifies the retained packet against the recorded
  commit

## Markdown Replay

For Markdown packets:

```bash
packet="$(pwd)/docs/retention/releases/atlas-m34.md"
commit="$(awk -F': ' '$1 == "Commit" { print $2; exit }' "$packet")"
worktree="$(mktemp -d)"

git worktree add --detach "$worktree" "$commit"
(
  cd "$worktree"
  nix-shell --run './bin/dev-qa'
  ./tools/atlas/bin/atlas v1 status --strict
  ./tools/atlas/bin/atlas release verify "$packet" --commit "$commit"
)
git worktree remove "$worktree"
```

## Replay Checklist

Record these results when replaying a release:

- packet path
- packet commit
- checkout command
- `git status --short --branch`
- `atlas v1 status --strict`
- `nix-shell --run './bin/dev-qa'`
- `atlas release verify <packet> --commit <commit>`
- retained limitations
- any replay failure and the first failing check

## Failure Meaning

Replay failure means one of the retained assumptions no longer holds in the
release checkout or packet:

- packet is missing or malformed
- commit cannot be checked out
- v1 readiness no longer passes at that commit
- QA no longer passes at that commit
- packet metadata does not match the release checkout
- retained notes, known limitations, or metadata-only guardrails are incomplete
- operation-bound release packet no longer replays against retained operation
  state

Do not repair a failed historical packet in place. Create a new retained replay
note describing the failure, root cause, and whether a corrected release packet
was generated.

## Current Boundary

Replay verification is still local verification. Atlas now retains signed
release provenance through a signed Git tag and retained public key, but replay
verification itself is not external provenance, SLSA attestation, immutable
storage, or third-party audit.

For the current release trust model, see
[`docs/RELEASE_TRUST.md`](../../RELEASE_TRUST.md).
