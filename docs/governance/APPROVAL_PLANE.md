# Atlas Approval Plane

## Purpose

M127 adds the first approval workflow contract for governed Atlas actions.

`approval/workflows.yaml` defines which capability classes require explicit
review metadata before policy can treat approval evidence as present.
`schemas/approval-event.v1.schema.json` defines the portable approval event
shape that reviewers can validate and replay.

## Contract

Approval events are metadata-only. They record:

- requester
- capability
- risk
- scope
- approver
- expiry
- rationale
- rollback plan
- evidence references

The current workflows cover `bounded_exec`, `mutate`, and `admin` capability
classes. Lower-risk read, import, verify, and constrained export capabilities
do not use the approval plane unless policy changes in a later milestone.

## Commands

Create an approval request event:

```bash
./tools/atlas/bin/atlas approval request atlas.agent.tool.exec \
  --scope agent-runtime \
  --risk medium \
  --requester operator \
  --approver reviewer \
  --expiry 2026-12-31T00:00:00Z \
  --rationale "bounded tool execution request" \
  --rollback-plan "remove generated sandbox output" \
  --evidence-ref policy/tests/decisions.v1.json \
  --json
```

Verify or expire an approval event:

```bash
./tools/atlas/bin/atlas approval verify approval-event.json
./tools/atlas/bin/atlas approval expire approval-event.json --reason "window closed" --json
./bin/dev-approval
```

Expected validator output:

```text
approval: ok
```

## Boundary

This milestone does not add an evidence ledger, signed approval bundle, external
approval-tool adapter, mutable cloud action, web UI, hidden database, or agent
execution runtime.

`approval request`, `approval verify`, and `approval expire` emit or validate
metadata-only event objects and do not create Atlas runtime directories. The
older operation-specific `approval grant` command remains the active-operation
approval path for existing validation workflows.
