# Linked Receipt Chain Example

This example replays the four metadata-only receipt files in
`examples/receipt/` as a canonical append-only chain:

```bash
./tools/atlas/bin/atlas receipt replay \
  examples/receipt/minimal.json \
  examples/receipt/software-action.json \
  examples/receipt/approval-workflow.json \
  examples/receipt/agent-action.json
```

Expected chain order:

| Index | Receipt | Linkage |
| --- | --- | --- |
| 1 | `minimal.json` | `prev_hash: null` |
| 2 | `software-action.json` | `prev_hash` equals `minimal.json` `event_hash` |
| 3 | `approval-workflow.json` | `prev_hash` equals `software-action.json` `event_hash` |
| 4 | `agent-action.json` | `prev_hash` equals `approval-workflow.json` `event_hash` |

The replay checkpoint is the final receipt's `event_hash` and `receipt_hash`.
It is reviewer-safe metadata only. It does not embed raw artifacts, secrets,
session contents, exploit payloads, or evidence bodies.
