# Atlas Evidence Plane

## Purpose

M128 added metadata-only evidence envelope and ledger verification for the
current local CLI proof chain. M180 adds the first governance evidence-envelope
schema draft for future capability, adapter, policy, approval, workflow, and
receipt decisions.

Current draft detail:
[EVIDENCE_ENVELOPE_SCHEMA_M180.md](EVIDENCE_ENVELOPE_SCHEMA_M180.md).

## Contract

Evidence records remain metadata-only. They may record references, hashes,
statuses, sufficiency states, replay hints, and known limitations. They must
not embed raw logs, secrets, private keys, tokens, Authorization headers,
request bodies, response bodies, packet captures, raw prompts, raw model
outputs, customer data, payment data, private business records, unredacted
evidence bodies, raw artifacts, full tool output bodies, browser session
material, or session cookies by default.

## Validation

Run:

```bash
./bin/dev-evidence
```

Expected output:

```text
evidence: ok
```

The validation gate preserves the existing M128 evidence verifier checks and
adds M180 governance schema/example checks.

## Boundary

M180 is a schema contract, not runtime collection. It does not add automatic
evidence capture, an evidence lake implementation, live integrations, adapter
execution, policy enforcement, approval execution, a database, a server, a web
UI, or receipt semantic changes.

M180/M181 do not add runtime evidence collection, automatic evidence capture,
an evidence collector, an evidence lake implementation, live integrations,
credentials, API calls, webhooks, network collectors, adapter execution, policy
enforcement, approval execution, a database, a server, a web UI, or changed
receipt semantics. `bin/dev-evidence` is validation tooling only.

Existing external systems remain their own operational source of truth. Atlas
records proof metadata around them.
