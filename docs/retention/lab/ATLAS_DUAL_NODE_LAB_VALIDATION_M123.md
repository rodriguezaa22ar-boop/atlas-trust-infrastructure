# Atlas Dual-Node Lab Validation M123

## Purpose

M123 retains the HP/Surface dual-node lab model as an explicit,
metadata-only operational proof chain. It documents how a human operator can
use a control node, a terminal-first builder node, a recovery network, and
GitHub verification to review Atlas evidence without expanding Atlas beyond
the proof layer.

This record follows the M122 boundary: Atlas records and verifies evidence
about the lab workflow. Atlas does not operate the lab, orchestrate the hosts,
control runtime execution, guarantee safety, certify compliance, or approve
production deployment.

## Retained Roles

| Role | Retained Meaning | Boundary |
| --- | --- | --- |
| HP cockpit/verifier/control node | Human-controlled command and review plane | Not an Atlas-operated control plane |
| Surface builder | Terminal-first builder and reviewer execution node | Not an Atlas-managed runtime |
| SSH/tmux | Human-operated control session and resumable terminal surface | Not orchestration or autonomous operation |
| Tailscale | Recovery/control network path for reaching the builder | Not a production security guarantee |
| GitHub | Public retained verification surface for PRs, checks, commits, and tags | Not external audit or certification |
| Atlas | Metadata-only proof layer for readiness, trust-chain, release, and lab evidence | Not a lab operator or deployment platform |

## Observed Lab Model

- Cockpit/control host: `atlas-console`
- Builder/review host: `atlas-builder`
- Builder access model: SSH from cockpit to builder
- Builder terminal model: tmux session named `atlas`
- Recovery/control network: Tailscale node reachability
- Public verification surface: GitHub pull request checks, merge commit, and
  retention tags
- Retained prior milestone: `atlas-retention-m122`
- M122 merge commit:
  `95a93ca5521b162f3042383a453a2f6d491343cd`
- M122 retained external review validation branch head:
  `1e57da3024bba9c55fa52e028ec3ac79cf7660d1`

## Reviewer Reproduction Commands

Run these commands from the repository root on a clean M123 branch checkout.

Confirm terminal-first builder access:

```bash
ssh atlas-builder -t "tmux new -A -s atlas"
```

When the reviewer is running from a non-interactive automation shell that
cannot allocate a pseudo-terminal, use a non-attaching tmux reachability check:

```bash
ssh atlas-builder 'tmux has-session -t atlas 2>/dev/null || tmux new-session -d -s atlas; tmux display-message -p -t atlas "#{session_name}:#{session_windows}"'
```

Expected result:

```text
atlas:1
```

Confirm local branch hygiene:

```bash
git status --short
git diff --check
```

Run the focused M123 documentation and boundary test:

```bash
nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "dual-node lab validation"'
```

Inspect the local dual-node cockpit operation trust chain when local operation
state has been generated:

```bash
./tools/atlas/bin/atlas op trust-chain atlas-dual-node-cockpit --strict
```

Expected result:

```text
Trust Chain Status: current
```

Confirm Atlas v1 local readiness:

```bash
./tools/atlas/bin/atlas v1 status --strict
```

Expected result:

```text
Overall: ready
Required Not Ready: 0
```

Confirm Tailscale reachability when recovery/control network validation is in
scope:

```bash
tailscale status
```

Expected result:

```text
atlas-builder ... active
```

Confirm GitHub public verification state after the milestone PR is pushed:

```bash
gh pr checks <pr-number> --repo rodriguezaa22ar-boop/atlas-trust-infrastructure
gh pr view <pr-number> --repo rodriguezaa22ar-boop/atlas-trust-infrastructure \
  --json number,state,headRefName,headRefOid,mergeCommit,url
```

## Expected Reviewer Interpretation

M123 passes when a reviewer can see that:

- HP is documented as the cockpit/verifier/control node.
- Surface is documented as a terminal-first builder node.
- SSH/tmux is documented as the human-operated control plane.
- Tailscale is documented as a recovery/control network path.
- GitHub is documented as the public retained verification surface.
- Atlas is documented as the proof layer only.
- The local `atlas-dual-node-cockpit` trust chain can be current when the
  local operation state exists.
- Generated reviewer packages and local operation state remain outside the
  committed evidence boundary unless explicitly retained.

## Known Limitations

- The `atlas-dual-node-cockpit` operation state is local metadata unless a
  later milestone explicitly retains an operation packet or release packet for
  it.
- Tailscale reachability proves node connectivity for the reviewed moment; it
  does not prove production availability, network security, or access-control
  sufficiency.
- SSH/tmux proves a terminal-first operator workflow; it does not prove
  orchestration, remote management safety, or autonomous lab operation.
- `ssh -t` attachment requires an interactive terminal. Non-interactive review
  runners should use the non-attaching tmux reachability check above.
- GitHub checks prove the configured repository workflows passed for the PR;
  they do not create audit, certification, or legal compliance.
- Atlas v1 readiness and operation trust-chain checks remain local Atlas
  contracts based on metadata evidence.

## Non-Guarantees

M123 lab validation retention is:

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not external SLSA certification
- not runtime safety proof
- not production deployability proof
- not orchestration proof
- not a claim that Atlas operates the lab
- not a claim that Atlas controls HP, Surface, SSH, tmux, Tailscale, GitHub,
  or the network

## Metadata Boundary

This record may retain host role labels, command names, branch names, commit
IDs, tag names, PR/check references, verification states, local operation
names, and known limitations. It does not retain secrets, credentials, tokens,
private keys, session cookies, raw target data, raw customer data, packet
captures, full request or response bodies, raw runtime artifacts, unredacted
evidence bodies, exploit payloads, or unauthorized-access instructions.
