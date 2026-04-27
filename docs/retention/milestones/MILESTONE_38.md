# Milestone 38: Atlas API/CORS Web Assessment Evidence

## Commit

`cdfe693 Add Atlas API CORS web assessment evidence`

## Purpose

Extend `atlas web assess` beyond route/header posture so bounded API status and
CORS preflight behavior are retained as Atlas operation evidence.

## Added

- API/CORS TSV packet under each web assessment operation
- Default bounded API probes for common API status paths
- Repeated `--api-path <path>` support for explicit endpoint review
- `--cors-origin <origin>` support for preflight probe configuration
- `--skip-api` support for route-only review
- API/CORS evidence record kind: `web-assessment-api`
- Structured finding: `Credentialed CORS allows probe origin`
- Shared-intel observations for API probes and CORS posture findings
- Web assessment summary table for API/CORS checks
- Scope wording for bounded API status and CORS header evidence
- Test harness runtime-state scrub so live local Atlas operations do not leak
  into isolated Bats test copies

## Live Smoke

Command:

```bash
atlas web assess https://execution-hub-27.emergent.host execution-hub-m38-cors-live --scope-status in-scope --criticality high --owner Alta --timeout 15 --api-path /api/auth/me --api-path /api/billing/status --cors-origin https://example.com
```

Result:

- operation: `execution-hub-m38-cors-live`
- target: `execution-hub-27.emergent.host`
- evidence records: 3
- findings: 5
- retained packet: `sessions/execution-hub-m38-cors-live/web-assessment/summary.md`
- route evidence: `sessions/execution-hub-m38-cors-live/web-assessment/routes.tsv`
- API/CORS evidence: `sessions/execution-hub-m38-cors-live/web-assessment/api.tsv`
- report: `reports/execution-hub-m38-cors-live-web-report.md`
- handoff: `sessions/execution-hub-m38-cors-live/handoff/execution-hub-m38-cors-live-web-handoff.md`
- evidence bundle: `sessions/execution-hub-m38-cors-live/evidence-bundles/execution-hub-m38-cors-live-web-assessment`

Observed API/CORS facts:

- `/api/auth/me` GET returned `401`
- `/api/billing/status` GET returned `401`
- `/api/auth/me` OPTIONS allowed `https://example.com` with credentials
- `/api/billing/status` OPTIONS allowed `https://example.com` with credentials

Observed findings:

- credentialed CORS allows probe origin
- missing browser hardening headers
- HTTP origin does not redirect to HTTPS
- metadata routes return application HTML
- admin-style routes return successful responses

## Verified

- `bash -n tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/web.sh`
- `bash -n tools/atlas/lib/scope.sh`
- `git diff --check`
- `nix-shell --run 'bats tests/atlas.bats --filter "web assess"'`: 2/2
- `nix-shell --run './bin/dev-test'`: 66/66
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 66/66, lint ok, stress ok

## Boundaries

The API/CORS extension is still read-only and bounded. It performs configured
GET and OPTIONS requests only, stores headers and body hashes as local retained
artifacts, and does not fuzz, brute force, exploit, crawl arbitrary content,
bypass authentication, or embed raw response bodies in reports.

## Repo State

- implementation committed
- ready to push and tag after this retention note is committed
