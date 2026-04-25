# Architecture

## Intent

This project is a portable shell-native framework for a terminal-only security
lab. It is not a package mirror and it is not a repo cache. The point is to
own the structure, then selectively implement the behaviors you actually want.

## Core Principles

1. The toolkit root is portable.
2. State is explicit and human-readable.
3. Tool modules are generated as stubs, then implemented by hand.
4. Targets, sessions, and reports are first-class records.
5. Runtime state can live on the local encrypted USB vault.
6. Tools share explicit intel, not hidden automation state.

## Role Split

### This Device

Use this machine to:

- design command layout
- author native shell modules
- review structure before deployment
- assemble staged releases for the local USB runtime
- execute and verify runtime releases while the USB vault is attached

### Retired HP Lab Node

The HP previously served as the runtime node. It is retired from active
configuration after a no-power hardware failure. Its target record is archived
under `docs/retired-targets/`.

Runtime work now stays local to this device and the encrypted USB vault.

### USB Lab Vault

Use the removable vault to:

- carry deployable tool trees
- hold cached datasets and outputs
- preserve a lab state that can be detached from the host

## Shared Intel Spine

Tools write structured records under `state/intel/`:

- `observations.jsonl`: direct findings from tools
- `entities.jsonl`: normalized hosts, services, credentials, or sessions
- `outcomes.jsonl`: success, failure, and run-level summaries
- `relationships.jsonl`: links between entities

The goal is not to let tools silently improvise. The goal is to let them reuse
operator-visible facts and outcomes.

That means:

- `wiremap` can publish hosts, services, web surface, and lateral surface
- `wiremap` can also publish packet-derived `credential_hint` and `capture_anomaly` observations
- later tools can rank actions from those facts instead of re-parsing raw text
- recommendations can explain which observations led to the suggestion

The first consumer is `vector`, which reads the shared intel store and turns
it into ranked operator lanes such as `web`, `credentials`, and `lateral`.

That boundary is deliberate:

- `wiremap` owns recon, capture, packet evidence, and saved-run interpretation
- `vector` owns ranking, bounded action lanes, sessions, and backend control
- `vector` should stay relevant by consuming better evidence, not by absorbing `wiremap`
- `atlas` gives the operator one front door while preserving those internal domains

It now also closes the loop:

- plans lanes from shared evidence
- runs bounded backends for those lanes
- stores artifacts under `sessions/`
- records success or failure back into `outcomes.jsonl`

The first backend bridge to an external framework is in the `research` lane:

- `vector` stays the operator interface
- `msfconsole search` is used as a bounded backend when available
- mapped fallbacks keep the lane portable on builder and runtime nodes that do
  not carry Metasploit locally

## Data Model

### Targets

Each target is an env-style record in `targets/`.

Fields:

- `NAME`
- `ADDRESS`
- `NOTES`
- `CREATED_AT`

This keeps scope metadata simple and shell-friendly.

### Sessions

Each session gets its own directory in `sessions/<name>/` with:

- `session.env`
- `loot/`
- `pcaps/`
- `notes/`
- `logs/`
- `tmp/`

The session becomes the working boundary for an engagement or test cycle.

`vector` reuses this session model directly, so action runs and follow-up loot
stay inside the same operator-visible structure instead of disappearing into
tool-specific scratch space.

### Tools

Each native tool lives in `tools/<name>/`.

Expected shape:

- `tool.env`
- `README.md`
- `bin/<name>`

This lets you keep per-tool metadata and its executable together without
turning the entire toolkit into a package manager clone.

## Suggested Growth Path

Start with wrappers and operators before you build protocol logic.

Good first native modules:

- target inventory and tagging
- egress checks
- capture file naming and rotation
- parser and report helpers
- result normalizers for tools you already trust
- shared intel publishers and consumers

Build exploit or scan orchestration only after the surrounding data model is
stable, otherwise you end up with brittle scripts and no operational memory.

The next backend step should keep that rule:

- use shared intel to narrow the action space
- run bounded backends behind `vector`
- write outcomes back into the shared store
- only expose raw backend sprawl when the operator deliberately asks for it

The next interface step should follow the same rule:

- put `atlas` in front of the runtime experience
- ship `atlas`, `wiremap`, and `vector` together when you want the single-app path
- keep the underlying domains separate even when the operator only sees one app

## Deployment Model

### Design Phase

Develop the tree locally on this device.

### Staging Phase

Build lean releases locally and activate them into the unlocked USB vault.

### Runtime Phase

Run the release from this device, with the removable vault as the runtime data
root when it is unlocked. That keeps the vault as the portable source of truth
without depending on the retired HP node.

Runtime releases are immutable except for compatibility placeholders. Mutable
operator records are resolved through `LAB_PERSIST_DIR`, which defaults to a
shared directory beside the release store:

- `/run/media/ao/labvault/runtime/releases/<release>/native/` holds the active tools
- `/run/media/ao/labvault/runtime/shared/targets/` holds target records
- `/run/media/ao/labvault/runtime/shared/state/` holds shared intel and recon runs
- `/run/media/ao/labvault/runtime/shared/sessions/` holds Atlas and Vector sessions
- `/run/media/ao/labvault/runtime/current` can switch releases without losing runtime state

The activation path is first-class:

```bash
./bin/labctl deploy activate <release> /run/media/ao/labvault/runtime
```

Activation prepares the shared tree, migrates release-local state from the old
`current` tree when present, syncs builder target records, copies the selected
release, and then switches `current`.
