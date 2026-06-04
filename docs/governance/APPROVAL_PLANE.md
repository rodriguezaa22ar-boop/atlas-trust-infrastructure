# Atlas Approval Plane

## Purpose

M127 adds the first approval workflow contract for governed Atlas actions.
M178 adds the first draft approval-plane contract for future approval states,
review workflows, expiration, rejection, escalation, break-glass documentation,
and approval evidence outputs without adding workflow execution.

`approval/workflows.yaml` defines which capability classes require explicit
review metadata before policy can treat approval evidence as present.
`schemas/approval-event.v1.schema.json` defines the portable approval event
shape that reviewers can validate and replay.
`approval/approval-plane.yaml` defines the draft approval-plane vocabulary for
review and governance alignment.

Current draft detail: [APPROVAL_PLANE_M178.md](APPROVAL_PLANE_M178.md).

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
  --expiry 2099-12-31T00:00:00Z \
  --rationale "bounded tool execution request" \
  --rollback-plan "remove generated sandbox output" \
  --evidence-ref policy/tests/decisions.v1.json \
  --json
```

Verify, approve, or expire an approval event:

```bash
./tools/atlas/bin/atlas approval verify approval-event.json
./tools/atlas/bin/atlas approval approve approval-event.json --actor reviewer --json
./tools/atlas/bin/atlas policy evaluate atlas.agent.tool.exec --scope agent-runtime --approval-event approval-approved-event.json --json
./tools/atlas/bin/atlas approval expire approval-event.json --reason "window closed" --json
./bin/dev-approval
```

Expected validator output:

```text
approval: ok
```

## Boundary

M127 itself did not add an evidence ledger. M128 adds metadata-only evidence
envelope and hash-ledger contracts around approval and run metadata.

M178 is a governance contract, not workflow execution. It does not add an
approval engine, live approval workflows, automatic approval, break-glass
execution, credentials, API calls, webhooks, network collectors, mutation
authority, a database, a server, or a web UI. Approval records do not grant
authorization by themselves.

Approval records do not grant authorization by themselves.

This milestone does not add a signed approval bundle, external approval-tool
adapter, mutable cloud action, web UI, hidden database, or agent execution
runtime.

`approval request`, `approval verify`, `approval approve`, and
`approval expire` emit or validate metadata-only event objects and do not
create Atlas runtime directories. Approved policy evaluation at the CLI boundary
requires a verified approved approval event rather than a bare
`--approval approved` assertion. The older operation-specific `approval grant`
command remains the active-operation approval path for existing validation
workflows.
