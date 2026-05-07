# Atlas Nix Reference Environment

## Purpose

Nix is the reference environment for Atlas proof because it gives reviewers a
repeatable toolchain for tests, linting, release checks, and Atlas
self-verification.

Enter the shell with:

```bash
nix-shell
```

Run the full local gate with:

```bash
nix-shell --run './bin/dev-qa'
```

## Included Tooling

The reference shell is expected to provide:

- Bash
- Bats
- Git
- GnuPG
- jq
- ripgrep
- rsync
- shellcheck
- shfmt
- tmux

## Relationship To Host Shell

Host shell checks prove practical execution. Nix checks prove the expected Atlas
developer and reviewer environment.

When results differ, the Nix result is the reference result until the host-shell
contract is updated and verified.
