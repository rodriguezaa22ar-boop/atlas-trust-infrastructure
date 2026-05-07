# Atlas Dual-Node Cockpit

## Purpose

This runbook defines the standard Atlas lab execution contract for the
dual-node cockpit workflow.

The cockpit controls. The builder computes.

The cockpit node is the operator-controlled environment for coordination,
review, browser work, GitHub, documentation, and light verification.

The builder node is the compute environment for Codex, Nix builds, Atlas QA,
release verification, reviewer package generation, and long-running tmux jobs.

Atlas records proof of work. Atlas does not control the lab. A private network
path, SSH, and tmux provide reachability, control, and job persistence. GitHub
commits, tags, and retained packets remain the truth boundary.

## Operating Rule

```text
The cockpit controls.
The builder computes.
Atlas records proof.
GitHub/commits/tags/retained packets remain the truth boundary.
```

Atlas is a metadata-first trust overlay for this lab workflow. It records,
verifies, and replays evidence about the work. It does not replace SSH, tmux,
a private network path, GitHub, Nix, Codex, shell tools, or human operator
approval.

## Canonical Control Path

Run from the cockpit node:

```bash
ssh <builder-host> -t 'tmux new-session -A -s atlas'
```

Recommended local aliases:

```bash
alias builder-ssh='ssh <builder-host>'
alias builder-tmux="ssh <builder-host> -t 'tmux new-session -A -s atlas'"
alias builder-qa="ssh <builder-host> -t 'tmux new-session -A -s atlas-qa'"
alias builder-codex="ssh <builder-host> -t 'tmux new-session -A -s codex'"
```

Use these aliases as operator convenience only. They are not Atlas control
features and they do not create retained evidence by themselves.

## Work Routing

| Work type | Machine | Reason |
| --- | --- | --- |
| ChatGPT, planning, review | Cockpit node | Coordination role |
| GitHub browser review | Cockpit node | Low compute, high coordination |
| Docs, editing, review | Cockpit node | Coordination role |
| Light terminal checks | Cockpit node | Acceptable when short |
| Codex jobs | Builder node | Heavy compute |
| Nix builds | Builder node | Stronger CPU/RAM |
| `./bin/dev-qa` | Builder node | Heavy QA path |
| Release verification | Builder node | Builder/verifier role |
| Reviewer package generation | Builder node | Trust artifact generation |
| Long tmux jobs | Builder node | Persistent compute session |

## Nix Remote Builder Rule

Use the remote-builder path only for Nix builds:

```text
The cockpit starts the Nix build.
The builder builds through ssh-ng://<builder-user>@<builder-host>.
The cockpit receives finished /nix/store paths.
```

Do not treat remote Nix building as a shared-machine model. For general compute,
enter the builder through SSH and tmux:

```bash
ssh <builder-host> -t 'tmux new-session -A -s atlas'
```

## Layer Boundary

| Layer | Tool |
| --- | --- |
| Reachability | Private network path |
| Control | SSH |
| Job persistence | tmux |
| Build execution | Nix / Codex / shell |
| Truth boundary | GitHub commits, tags, retained packets |
| Proof layer | Atlas records, release packets, reviewer packages |

Correct interpretation:

```text
Atlas observes and proves the workflow.
Atlas does not replace SSH, tmux, private networking, GitHub, or Nix.
```

## Standard Execution Order

1. The cockpit plans and reviews the patch scope.
2. The builder runs Codex, build, and long-running tmux work.
3. The builder runs `./bin/dev-qa`, release verification, and reviewer package
   checks.
4. The cockpit reviews diffs and GitHub PRs.
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
- not a claim that Atlas operates or controls the cockpit node, builder node,
  SSH, tmux, private networking, GitHub, Nix, Codex, shell tools, or the
  network

## Related Retention

The retained metadata-only validation record for the dual-node lab model is
[docs/retention/lab/ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md](../retention/lab/ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md).
