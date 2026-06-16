# External Project Receipt Reviewer Output

## Purpose

M192 adds reviewer-facing plain-English output guidance for external-project
receipts. The goal is to help a reviewer understand what Atlas verified, what
Atlas did not verify, which metadata references are present, and which decision
still remains outside Atlas.

This is a documentation and example-output milestone. It does not change receipt
semantics, hashing, canonicalization, replay behavior, runtime execution, UI, or
server state.

## Reviewer Output Shape

A reviewer-facing external receipt explanation should include:

- the receipt identifier and action label;
- the local receipt verification status;
- the metadata-only boundary status;
- evidence, artifact, and approval reference counts;
- selected reviewer-visible reference labels;
- the chain or replay posture when available;
- known limitations;
- the decision that remains outside Atlas.

The explanation should be plain English, but it must stay bounded. It must not
claim that Atlas proved the external action was correct or authorized by itself.

## What Atlas Verifies

For the M190 external-project fixture, Atlas can verify the local receipt file
it was given:

- the receipt JSON is parseable;
- the receipt has the expected Atlas receipt schema;
- `metadata_only=true`;
- `raw_artifacts_embedded=false`;
- the receipt hash matches the canonical receipt payload;
- the event hash is present;
- evidence, artifact, and approval references are present as metadata;
- replay can check provided-order `prev_hash` linkage when multiple receipts are
  supplied.

## What Atlas Does Not Verify

Atlas does not verify source-system truth, external artifact availability,
action correctness, artifact correctness, model correctness, legal compliance,
production approval, external audit completion, complete event coverage,
tamper-proof storage, immutable infrastructure, or replacement of human
judgment.

A reviewer must still decide whether the referenced source-system records,
approval references, evidence references, artifact references, and limitations
are sufficient for the review being performed.

## Metadata-Only Requirements

Reviewer-facing output must not embed raw logs, raw prompts, raw model outputs,
terminal buffers, request bodies, response bodies, packet captures, credentials,
tokens, private keys, session cookies, customer data, payment data, private
business records, private target records, or unredacted evidence bodies.

Use references and hashes instead of raw bodies.

## Example Fixture

The example reviewer output is retained at:

```text
examples/receipt/external-project/reviewer-output.md
```

It is synthetic and metadata-only. It is an explanation fixture, not a new Atlas
command output contract and not runtime evidence.
