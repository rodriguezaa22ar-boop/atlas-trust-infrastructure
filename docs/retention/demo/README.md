# Demo Site Retention

## Purpose

This directory retains metadata-only demo-site records for the public Atlas
proof surface. It is for inventory snapshots, sanitized screenshot references,
deployment commit references, and local verification outputs that bind a
public demo site to Atlas proof without importing private runtime state.

## Retained Records

No demo-site retention records are retained yet.

The first retained record should capture:

- canonical site URL
- hosting provider
- source repository or deployment source
- latest deployed commit or immutable deployment identifier
- screenshot references with no private data
- receipt or packet example references
- verify and replay commands
- known limitations and non-guarantees

## Boundary

Demo-site retention records may include public URLs, public source references,
deployment identifiers, sanitized screenshots, synthetic receipt examples,
verification outputs, and known limitations.

They must not include credentials, tokens, private keys, cookies, session data,
private targets, customer data, raw packet captures, full request or response
bodies, unredacted runtime evidence, private implementation context, or local
runtime state from private `sessions/`, `state/`, `shared/`, `logs/`,
`reports/`, `releases/`, or `targets/`.

Demo-site retention is not external audit, not certification, not legal compliance, not tamper-proof infrastructure, not external SLSA certification, not runtime safety proof, and not production deployability proof.
