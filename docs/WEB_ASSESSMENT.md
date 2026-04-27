# Web Assessment

## Purpose

`atlas web assess` packetizes bounded web posture checks into an Atlas
operation. It is designed for authorized, scoped assessment workflows where the
operator wants retained evidence, findings, report output, and handoff packets
without turning Atlas into an autonomous scanner.

## Safety Boundary

Use `atlas web assess` only for targets you are authorized to assess.

The command is intentionally bounded. It records route/header posture and
optional API/CORS observations. It does not fuzz, brute force, exploit,
perform denial-of-service testing, attempt persistence, or expand scope.

## Basic Flow

```bash
./tools/atlas/bin/atlas web assess https://example.com example-web-review --scope-status in-scope
```

The flow creates or updates an operation, records target metadata, stores
evidence, writes posture findings, generates a report, and writes handoff
artifacts.

## Mounted Applications

URLs with a path keep that base path for mounted apps:

```bash
./tools/atlas/bin/atlas web assess http://127.0.0.1:8085/bWAPP bwapp-review --scope-status in-scope --skip-api
```

This prevents a mounted application such as `/bWAPP` or a path-scoped training
target from being flattened to the origin root.

## API And CORS Checks

Use explicit API paths and CORS origins when they are authorized:

```bash
./tools/atlas/bin/atlas web assess https://example.com/app app-review \
  --scope-status in-scope \
  --api-path /api/auth/me \
  --api-path /api/billing/status \
  --cors-origin https://example.net
```

Credentialed CORS probes are flagged so the operator can review risk without
Atlas making exploit claims.

## Validation Governance

Web findings can be queued for approval-gated validation:

```bash
./tools/atlas/bin/atlas web validation-plan --all
./tools/atlas/bin/atlas web validation-approve --all --reason "approved bounded web validation"
```

Approval is a separate governance step. Validation should stay bounded by the
operation scope and capability tier.

## Expected Outputs

A web assessment may produce:

- operation record
- scope and ledger events
- route/header evidence
- API/CORS evidence when requested
- posture findings
- report
- evidence bundle
- handoff packet
- closeout, audit, archive, and trust-chain artifacts when the operation is
  carried through retention

## Follow-On Checks

```bash
./tools/atlas/bin/atlas op readiness <assessment-name>
./tools/atlas/bin/atlas op report <assessment-name>
./tools/atlas/bin/atlas op trust-chain <assessment-name> --strict
```

For the full operation flow, use [OPERATOR_GUIDE.md](OPERATOR_GUIDE.md).
