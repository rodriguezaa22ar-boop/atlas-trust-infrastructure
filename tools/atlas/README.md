# atlas

This module is the unified operator front-end for the toolkit.

It is intentionally not a monolith. The point is to expose one app while
keeping the underlying domains intact:

- `wiremap` owns recon, capture, and evidence interpretation
- `vector` owns ranking, bounded action, sessions, and outcomes
- `intelctl` owns direct shared-intel inspection
- `labctl` still owns builder and inventory administration

`atlas` is the shell around those domains.

## Commands

```bash
atlas menu
atlas target list
atlas target story 10.0.0.8
atlas target summary 10.0.0.8
atlas target next 10.0.0.8
atlas story demo-web-app
atlas op start april-review 10.0.0.8 bounded review
atlas op show april-review
atlas recon workflow list
atlas op recon perimeter-sweep
atlas capture creds ./state/wiremap-runs/<run>
atlas op action candidates
atlas op action plan credentials
atlas op action run posture
atlas op story
atlas op report april-review
atlas op close april-review
atlas session list
atlas loot list
atlas intel summary
```

## Target-First Workflow

Start with the target, then let shared intel choose the next action:

```bash
atlas target list
atlas target story <target>
atlas op start <name> <target> [notes...]
atlas op show
atlas op recon <workflow>
atlas op action candidates
atlas op action plan <lane>
atlas op action run <lane> [session-name]
atlas op story
atlas op report
atlas op close
```

`atlas target story <target>` is the fastest cross-tool view. It combines the
target record, current service and web surface, Vector outcomes, posture
findings, recent shared evidence, and ranked next actions.

`atlas target next <target>` and `atlas op next` keep the operator focused on
the ranked lanes produced from shared intel.

## Operation Scope

Atlas operations are bounded by default. `atlas op show [name]` prints the
operation summary, the target, the scope statement, allowed actions, explicit
out-of-scope actions, and tracked artifacts.

Allowed operation actions are:

- target-first recon against configured scope
- service validation and non-invasive fingerprint refresh
- HTTP/HTTPS probing of observed web surfaces
- HTTP posture review for headers, redirects, metadata routes, and common login/admin routes
- shared-intel summarization, story views, and report generation

Explicitly out of scope:

- exploitation, payload delivery, or persistence
- brute forcing, password guessing, credential stuffing, or session hijacking
- destructive testing, denial of service, fuzzing, or high-volume crawling
- access to third-party systems beyond the configured target
- data extraction beyond minimal service, route, header, and posture evidence

## Reports

`atlas op report [name] [report-name]` writes a Markdown report stub under
`$LAB_REPORTS_DIR`. The report includes:

- date, operation id, target, address, status, and notes
- scope, allowed actions, and out-of-scope actions
- reconstructed Atlas command history from the operation log
- tracked recon and action artifacts
- placeholders for reviewed findings and notes

## Demos

`atlas story demo-web-app` renders an anonymized built-in story fixture. Use it
when you need to demonstrate the Atlas story view without touching a live
target or depending on current shared intel.

## Intent

Use `atlas` as the operator-facing front door when you want:

- one command to remember
- target-first navigation instead of tool-first navigation
- unified runtime ergonomics without flattening the toolkit architecture

## Role

`atlas` stays relevant only if it does not absorb every behavior.

It should:

- unify navigation
- compose summaries across tools
- delegate work to the right domain tool
- preserve the boundary between evidence and action

It should not:

- reimplement `wiremap`
- reimplement `vector`
- become a second builder tool

## Runtime Packaging

When you stage `atlas` into a runtime release, include its dependencies too:

- `atlas`
- `wiremap`
- `vector`

`intelctl` and `labctl` are already carried by the release builder.
