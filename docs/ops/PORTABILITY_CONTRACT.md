# Atlas Portability Contract

## Core Rule

```text
ATLAS runs anywhere practical.
Nix proves it.
```

Atlas remains shell-native and local-first. The Nix shell is the reference proof
environment, but core read-only verification commands should produce clear
results on practical host shells when required dependencies are present.

## Required Runtime Targets

- NixOS
- generic Linux
- macOS
- WSL
- container
- CI runner
- source archive
- full Git clone

## Required Behavior

Portable read-only checks must:

- report missing required dependencies clearly
- distinguish required dependencies from optional tooling
- avoid creating Atlas runtime state
- work from a full Git clone
- produce readable not-ready output from a source archive
- preserve Nix as the strongest reproducible validation path

The minimum portable command set is:

```bash
./bin/dev-host-check
./tools/atlas/bin/atlas doctor
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status
```

## Proof Boundary

Host-shell success shows the runtime can execute. Nix QA remains the stronger
proof gate:

```bash
nix-shell --run './bin/dev-qa'
```

A release or high-risk trust claim is not complete until the exact clean commit
has both host/runtime evidence and Nix/Atlas verification evidence recorded.
