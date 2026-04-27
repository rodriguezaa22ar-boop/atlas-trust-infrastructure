# Milestone 37: Atlas Web Assessment Packetization

## Commit

`2326912 Add Atlas web assessment packetization`

## Purpose

Turn bounded public web posture checks into retained Atlas operations instead
of ad hoc terminal reports.

## Added

- `atlas web assess <url> [assessment-name]`
- Target creation/reuse for public web assessment URLs
- Operation-scoped route/header checks for root, HTTP origin, metadata routes,
  and common admin-style routes
- Retained web assessment packet under the operation directory
- Evidence records for route results and assessment summary
- Structured findings for browser headers, HTTP-to-HTTPS redirect gaps,
  metadata-route SPA fallthrough, and admin-style route exposure
- Evidence bundle, operation report, and handoff packet generation
- Shared intel observations for web probe and posture findings

## Verified

- `bash -n tools/atlas/bin/atlas`
- `bash -n tools/atlas/lib/web.sh`
- `git diff --check`
- `nix-shell --run './bin/dev-test'`: 65/65
- `nix-shell --run './bin/dev-lint'`: lint ok
- `nix-shell --run './bin/dev-qa'`: 65/65, lint ok, stress ok

## Live Smoke

Command:

```bash
atlas web assess https://execution-hub-27.emergent.host execution-hub-m37-live-verified --scope-status in-scope --criticality high --owner Alta --timeout 15
```

Result:

- operation: `execution-hub-m37-live-verified`
- target: `execution-hub-27.emergent.host`
- findings: 4
- retained packet: `sessions/execution-hub-m37-live-verified/web-assessment/summary.md`
- report: `reports/execution-hub-m37-live-verified-web-report.md`
- handoff: `sessions/execution-hub-m37-live-verified/handoff/execution-hub-m37-live-verified-web-handoff.md`
- evidence bundle: `sessions/execution-hub-m37-live-verified/evidence-bundles/execution-hub-m37-live-verified-web-assessment`

Observed findings:

- missing browser hardening headers
- HTTP origin does not redirect to HTTPS
- metadata routes return application HTML
- admin-style routes return successful responses

## Boundaries

`atlas web assess` is intentionally bounded. It does not fuzz, brute force,
exploit, crawl arbitrary content, bypass authentication, or collect raw secrets.
It records lightweight route/header posture evidence and creates review
findings for operator follow-up.

## Repo State

- implementation committed: `2326912 Add Atlas web assessment packetization`
- retention note committed: `42d81ba Record Atlas retention milestone 37`
- pushed to `origin/main`
- tagged: `atlas-retention-m37`
- repo clean and synced after milestone push
