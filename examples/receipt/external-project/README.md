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

