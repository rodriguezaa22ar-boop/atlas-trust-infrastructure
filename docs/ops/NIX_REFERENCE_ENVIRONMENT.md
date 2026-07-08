# Atlas Nix Reference Environment

## Purpose

Nix is the reference environment for Atlas proof because it gives reviewers a
repeatable toolchain for tests, linting, release checks, and Atlas
self-verification.

The reference toolchain is pinned by [../../nix/nixpkgs.nix](../../nix/nixpkgs.nix).
Atlas does not rely on the caller's ambient `<nixpkgs>` or a moving
`nixos-unstable` channel for the default `nix-shell` path.

GitHub current-source workflows set `NIX_BUILD_SHELL=bash` for
`nix-shell --run` commands. That avoids Nix's fallback shell lookup through
`(import <nixpkgs> {}).bashInteractive` when `NIX_PATH` is empty. The package
set still comes from `shell.nix`, which imports the repository pin.

Retained release-trust replays are a special compatibility case. Historical
retained commits can contain older `shell.nix` files that still import
`<nixpkgs>`. CI points those old worktrees at the current source checkout's
pinned `nix/nixpkgs.nix` with a scoped `NIX_PATH` only for retained replay.
Current-source validation remains repo-pinned through `shell.nix`.

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
- check-jsonschema
- fd
- Git
- GnuPG
- jq
- Open Policy Agent
- ripgrep
- rsync
- shellcheck
- shfmt
- tmux

## Updating The Pin

Pin updates should be intentional review events, not incidental CI drift.

To update the reference toolchain:

```bash
nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<rev>.tar.gz
```

Then update both `rev` and `sha256` in `nix/nixpkgs.nix` and run:

```bash
nix-shell --run './bin/dev-qa'
```

## Relationship To Host Shell

Host shell checks prove practical execution. Nix checks prove the expected Atlas
developer and reviewer environment.

When results differ, the Nix result is the reference result until the host-shell
contract is updated and verified.
