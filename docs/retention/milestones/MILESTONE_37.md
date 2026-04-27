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

## Boundaries

`atlas web assess` is intentionally bounded. It does not fuzz, brute force,
exploit, crawl arbitrary content, bypass authentication, or collect raw secrets.
It records lightweight route/header posture evidence and creates review
findings for operator follow-up.

## Repo State

- implementation committed
- ready to push and tag after this retention note is committed
