# Atlas Demo

## Purpose

This directory contains the public-safe Atlas demo path. It is a synthetic demo
for reviewers and operators who want to inspect how Atlas connects target
registration, scope, evidence, findings, validation, reporting, handoff,
closeout, audit, archive, release trust, replay, and production explainability.

Start here:

- [DEMO_OPERATION.md](DEMO_OPERATION.md): metadata-only demo operation.
- [DEMO_REVIEWER_RUNBOOK.md](DEMO_REVIEWER_RUNBOOK.md): ordered reviewer
  runbook for inspecting the demo and retained release evidence.
- [TRUST_CHAIN_WALKTHROUGH.md](TRUST_CHAIN_WALKTHROUGH.md): how to read the
  operation trust-chain output.
- [SAMPLE_OUTPUTS.md](SAMPLE_OUTPUTS.md): abbreviated output shapes.

## Boundary

The demo uses synthetic/local-safe data only. It must not include real target
data, customer data, payment data, bank details, credentials, tokens, private
keys, session cookies, packet captures, raw request or response bodies, raw
runtime artifacts, unredacted evidence bodies, exploit payloads, or
unauthorized-access instructions.

The demo is not external audit, not certification, not legal compliance, not
tamper-proof infrastructure, not external SLSA certification, not runtime
safety proof, and not production deployability proof.
