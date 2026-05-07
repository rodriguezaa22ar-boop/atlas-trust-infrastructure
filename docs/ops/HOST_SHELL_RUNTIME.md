# Atlas Host Shell Runtime

## Purpose

The host shell runtime is the minimum practical environment for read-only Atlas
inspection outside the Nix reference shell.

Use it for:

- dependency discovery
- quick posture checks
- source archive smoke checks
- reviewer orientation

Do not treat it as stronger proof than Nix QA.

## Required Tools

`bin/dev-host-check` requires these commands:

- `bash`
- `git`
- `jq`
- `awk`
- `sed`
- `find`
- `sort`
- `wc`
- `mktemp`
- `cp`
- either `sha256sum` or `shasum`

## Optional Tools

These improve the developer and reviewer experience but are not required for
basic read-only inspection:

- `bats`
- `shellcheck`
- `shfmt`
- `rg`
- `fd`
- `rsync`
- `tmux`
- `nix-shell`

## Check Command

```bash
./bin/dev-host-check
```

The command is read-only. It prints required and optional dependency status and
exits nonzero only when required host-shell dependencies are missing.
