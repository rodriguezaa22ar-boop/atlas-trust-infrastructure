# External Project Receipt Example

This directory contains the M190 synthetic external-project receipt pilot.

The fixture uses the existing `generic.external_event.v1` import path and the
existing `atlas.receipt.v1` verifier. It does not add a new receipt engine,
source-system integration, network collector, database, server, web UI, or
runtime authority.

## Files

| File | Purpose |
| --- | --- |
| `minimal-event.json` | Synthetic external-project event metadata. |
| `minimal-receipt.json` | Receipt generated from `minimal-event.json`. |

## Verify

```bash
./tools/atlas/bin/atlas receipt verify \
  examples/receipt/external-project/minimal-receipt.json
```

## Regenerate

```bash
./tools/atlas/bin/atlas receipt import-generic-event \
  examples/receipt/external-project/minimal-event.json \
  --out /tmp/atlas-external-project-receipt.json

./tools/atlas/bin/atlas receipt verify /tmp/atlas-external-project-receipt.json
```

## Boundary

This example is synthetic and metadata-only. It stores references, hashes,
labels, timestamps, and limitations only.

It does not embed raw logs, raw prompts, raw model outputs, request bodies,
response bodies, packet captures, customer data, payment data, private business
records, private target records, credentials, tokens, private keys, session
cookies, Authorization headers, or unredacted evidence bodies.

It does not prove source-system truth, external artifact availability, legal
compliance, production approval, external audit completion, certification,
complete event coverage, tamper-proof storage, action correctness, artifact
correctness, or replacement of human judgment.


## Negative Fixtures

M191 adds synthetic negative fixtures for reviewer education and safety
regression coverage:

| File | Expected result |
| --- | --- |
| `negative-metadata-only-false.json` | Import must fail because `metadata_only` is not true. |
| `negative-raw-artifacts-embedded.json` | Import must fail because `raw_artifacts_embedded` is not false. |
| `negative-missing-schema-version.json` | Import must fail because required schema metadata is missing. |

These fixtures are not runtime evidence. They are synthetic examples that help a
reviewer understand fail-closed behavior while preserving the metadata-only
boundary.

For reviewer-facing failure interpretation, see
`docs/receipts/EXTERNAL_PROJECT_RECEIPT_FAILURES.md`.
