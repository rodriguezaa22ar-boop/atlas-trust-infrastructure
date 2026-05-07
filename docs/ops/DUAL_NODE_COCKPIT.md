# Atlas Dual-Node Cockpit

## Purpose

This runbook defines the standard Atlas lab execution contract for the
HP/Surface dual-node workflow.

HP controls. Surface computes.

`atlas-console` is the cockpit for coordination, review, browser work, GitHub,
documentation, and light verification.

`atlas-builder` is the compute engine for Codex, Nix builds, Atlas QA, release
verification, reviewer package generation, and long-running tmux jobs.

Atlas records proof of work. Atlas does not control the lab. Tailscale, SSH,
and tmux provide reachability and control. GitHub commits, tags, and retained
packets remain the truth boundary.

## Operating Rule

```text
HP controls.
Surface computes.
Atlas records proof.
GitHub/commits/tags/retained packets remain the truth boundary.
```

Atlas is a metadata-first trust overlay for this lab workflow. It records,
verifies, and replays evidence about the work. It does not replace SSH, tmux,
Tailscale, GitHub, Nix, Codex, shell tools, or human operator approval.

## Canonical Control Path

Run from `atlas-console` on HP:

```bash
ssh atlas-builder -t 'tmux new-session -A -s atlas'
```

Recommended HP aliases:

```bash
alias atlas-builder='ssh atlas-builder'
alias atlas-tmux="ssh atlas-builder -t 'tmux new-session -A -s atlas'"
alias atlas-qa="ssh atlas-builder -t 'tmux new-session -A -s atlas-qa'"
alias atlas-codex="ssh atlas-builder -t 'tmux new-session -A -s codex'"
```

Use these aliases as operator convenience only. They are not Atlas control
features and they do not create retained evidence by themselves.

## Work Routing

| Work type | Machine | Reason |
| --- | --- | --- |
| ChatGPT, planning, review | HP / `atlas-console` | Cockpit role |
| GitHub browser review | HP | Low compute, high coordination |
| Docs, editing, review | HP | Cockpit role |
| Light terminal checks | HP | Acceptable when short |
| Codex jobs | Surface / `atlas-builder` | Heavy compute |
| Nix builds | Surface | Stronger CPU/RAM |
| `./bin/dev-qa` | Surface | Heavy QA path |
| Release verification | Surface | Builder/verifier role |
| Reviewer package generation | Surface | Trust artifact generation |
| Long tmux jobs | Surface | Persistent compute session |

## Nix Remote Builder Rule

Use the HP remote-builder path only for Nix builds:

```text
HP starts the Nix build.
Surface builds through ssh-ng://ao@atlas-builder.
HP receives finished /nix/store paths.
```

Do not treat remote Nix building as a shared-machine model. For general compute,
enter the builder through SSH and tmux:

```bash
ssh atlas-builder -t 'tmux new-session -A -s atlas'
```

## Layer Boundary

| Layer | Tool |
| --- | --- |
| Reachability | Tailscale |
| Control | SSH |
| Job persistence | tmux |
| Build execution | Nix / Codex / shell |
| Truth boundary | GitHub commits, tags, retained packets |
| Proof layer | Atlas records, release packets, reviewer packages |

Correct interpretation:

```text
Atlas observes and proves the workflow.
Atlas does not replace SSH, tmux, Tailscale, GitHub, or Nix.
```

## Standard Execution Order

1. HP plans and reviews the patch scope.
2. Surface runs Codex, build, and long-running tmux work.
3. Surface runs `./bin/dev-qa`, release verification, and reviewer package
   checks.
4. HP reviews diffs and GitHub PRs.
5. Atlas retains proof through commits, tags, release packets, and reviewer
   artifacts.

## Evidence Handling

When local operation state exists for this workflow, use the Atlas operation
trust chain as proof-layer evidence:

```bash
./tools/atlas/bin/atlas op trust-chain atlas-dual-node-cockpit --strict
```

That operation state is local metadata unless a release, review, or retention
milestone explicitly retains it. The public truth boundary remains the committed
repository state, tags, retained release packets, reviewer package manifests,
and other explicitly retained artifacts.

## Non-Guarantees

This runbook is:

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not runtime safety proof
- not production deployability proof
- not orchestration proof
- not a claim that Atlas operates or controls HP, Surface, SSH, tmux,
  Tailscale, GitHub, Nix, Codex, shell tools, or the network

## Related Retention

The retained metadata-only validation record for the dual-node lab model is
[docs/retention/lab/ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md](../retention/lab/ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md).
