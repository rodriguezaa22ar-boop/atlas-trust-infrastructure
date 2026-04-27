# `atlas.production_readiness.v1`

## Surface

```bash
atlas production status --json
```

## Purpose

Report conservative production readiness gates without implying that Atlas is
production-ready before the required trust artifacts exist.

## Required Fields

- `schema_version`: must be `atlas.production_readiness.v1`.
- `overall`: `ready` or `not-ready`.
- `commit`: current Git commit.
- `root`: repository root.
- `runtime_target`: runtime target label.
- `strict`: boolean strict-mode flag.
- `counts.blocked`: number of blocked gates.
- `counts.warning`: number of warning gates.
- `counts.required_not_ready`: number of required gates not ready.
- `gates`: keyed object of production gates.

Each `gates.<key>` value must include:

- `label`
- `required`
- `status`
- `reason`
- `evidence`
- `commands`
- `limitations`

## Verification Rules

Production status is read-only. Consumers should treat `overall: ready` as
valid only when:

- every required gate is `ready`
- `counts.required_not_ready` is `0`
- release trust packet verification is current
- production contract documentation exists
- signing/provenance evidence exists
- retained production dry-run or external validation evidence exists

## Metadata Boundary

This status output is not a packet archive. It may point to evidence,
commands, and limitations, but it must not embed raw evidence bodies, secrets,
tokens, packet captures, or private runtime data.

## Non-Goals

- Replacing `atlas v1 status`.
- Claiming external audit.
- Claiming deployment certification.
- Mutating repository or operation state.
