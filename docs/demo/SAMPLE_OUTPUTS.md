# Atlas Demo Sample Outputs

## Purpose

These are abbreviated examples of the output shape an operator should expect
from the demo walkthrough. They are not retained proof by themselves. Real proof
comes from the generated operation artifacts and verification commands.

## Readiness

```text
Atlas Operation Readiness
Close Readiness: ready
Open Findings: 0
Pending Validation: 0
Report Freshness: current
Next Step: Operation is ready to close.
```

## Audit

```text
Atlas Operation Audit
Events: <count>
Audit Flags
No stale report
No stale closeout
No forced close
```

## Archive

```text
Atlas Operation Archive
Archive status: current
Report Freshness: current
Closeout verification: verified
Audit packet verification: verified
Archive packet freshness: current
```

## Trust Chain

```text
Atlas Operation Trust Chain
Trust Chain Status: current
Close Readiness: ready
Report: current
Closeout: verified
Audit Packet: verified
Archive Packet: verified
Next Trust Step: Operation trust chain is current.
```

## Trust Chain JSON

```json
{
  "schema_version": "atlas.operation_trust_chain.v1",
  "status": "current",
  "readiness": {
    "close": "ready"
  },
  "freshness": {
    "report": "current",
    "audit_packet": "current",
    "archive_packet": "current"
  },
  "verification": {
    "archive_packet": {
      "status": "verified"
    }
  }
}
```

## Release Verify

```text
Atlas Release Trust Verification
Schema: ok atlas.release_trust.v1
Metadata Only: ok true
Commit: ok <commit>
Repository State: ok clean
Upstream Sync: ok synced
QA Status: ok pass
Operation Trust Chain: ok current
Release trust packet verified
```

## Failure Shape

If a retained artifact is stale, expect a direct failure reason:

```text
Trust Chain Status: attention-required
Report: stale
Next Trust Step: Refresh the operation report before closure.
```
