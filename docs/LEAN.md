# Lean Operations

## Goal

Keep the builder and runtime environments focused on operator intent instead of
accumulating cloned repositories, installer leftovers, and cache-heavy noise.

## Rule Set

1. Prefer native modules over copied upstream projects.
2. If an existing tool is useful, distill its command shape instead of cloning
   its implementation.
3. Build runtime releases from selected tools only.
4. Do not carry tests, reports, old sessions, or builder-only notes into the
   runtime tree unless there is a clear operational reason.

## Distillation

Use:

```bash
./bin/labctl tool distill jq-shape jq --help
```

That creates a native tool scaffold with:

- a runnable local stub
- a captured help file
- a captured version file
- metadata describing the upstream command and the distill policy

What it does not keep:

- upstream source trees
- build scripts
- vendored dependencies
- caches
- docs you are not actively using

## Lean Releases

Use:

```bash
./bin/labctl release build usb-slim egress-check jq-shape
```

This creates a runtime tree under `releases/` that includes:

- `bin/labctl`
- `lib/common.sh`
- a minimal runtime `etc/lab.env`
- selected `tools/`
- empty release-local state directories
- shared runtime state pointers for targets, sessions, reports, logs, and intel

This intentionally excludes:

- `tests/`
- builder helper scripts
- prior sessions
- reports
- logs

Runtime releases compute a stable data root at startup:

```bash
LAB_PERSIST_DIR=<runtime-base>/shared
```

For local USB deployments where releases live under
`/run/media/ao/labvault/runtime/releases/`, mutable records live under
`/run/media/ao/labvault/runtime/shared/` while
`/run/media/ao/labvault/runtime/current` can move between release trees.

Activate a release with:

```bash
./bin/labctl deploy activate usb-slim /run/media/ao/labvault/runtime
```

That command copies the release, migrates any old release-local mutable state
into `shared/`, syncs local target records into `shared/targets/`, and moves
`current` to the selected release.

## Practical Benefit

This keeps the operating system and removable vault cleaner in three ways:

- less storage consumed by duplicate code and caches
- less memory pressure from unnecessary tooling layers
- less attention wasted on files that do not advance the current task
