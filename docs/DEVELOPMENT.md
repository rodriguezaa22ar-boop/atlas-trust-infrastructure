# Development

## Goal

Make this device the stable build and runtime environment for native lab tools
without coupling development to a separate runtime node.

## Approach

Use a project-local Nix shell instead of broad system mutation.

That gives you:

- reproducible shell tooling
- formatting and linting for shell-native modules
- a test harness for command behavior
- a portable development contract that can be shared later

## Commands

Enter the environment:

```bash
nix-shell
```

Run checks:

```bash
./bin/dev-fmt
./bin/dev-lint
./bin/dev-test
./bin/dev-stress
./bin/dev-qa
```

The preferred quality gate before staging anything to the local USB runtime is:

```bash
nix-shell --run './bin/dev-qa'
```

Build a lean runtime release:

```bash
./bin/labctl release build usb-slim egress-check
```

## What This Solves

Before this change, the machine was usable but not disciplined as a builder.
There was no project-defined formatter, linter, or test path.

Now the builder workflow has:

- a declared dependency set
- repeatable local checks
- synthetic stress coverage for workflow, analysis, prune, and the unified `atlas` front door
- a clear boundary between development, local runtime work, and USB staging
- a lean release path that avoids copying builder bloat into runtime
