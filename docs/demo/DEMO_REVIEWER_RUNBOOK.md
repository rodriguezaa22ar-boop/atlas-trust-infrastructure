# Demo Reviewer Runbook

## Purpose

This reviewer runbook gives an ordered path for inspecting the metadata-only
demo operation and the currently retained release-trust evidence. It is
designed to be repeatable from the repository root with synthetic demo data.

## Ordered Reviewer Flow

1. Read [DEMO_OPERATION.md](DEMO_OPERATION.md).
2. Confirm the demo-data boundary in [README.md](README.md).
3. Register the synthetic target and start `demo-operation`.
4. Add the synthetic evidence reference and confirm its hash.
5. Create the finding, validation plan, validation approval, validation run,
   and retest state.
6. Generate the report and handoff packet.
7. Generate and verify closeout, audit, archive, and operation trust-chain
   packets.
8. Inspect the optional business-flow summary if the flow commands are present.
9. Generate the demo release packet when the repository is clean and synced.
10. Verify the retained M118 release packet and release artifact manifest.
11. Run release replay JSON.
12. Run production status explainability.
13. Inspect known limitations and non-guarantees before recording a conclusion.

## Operation Commands

Use the exact commands in [DEMO_OPERATION.md](DEMO_OPERATION.md) for target
registration, scope state, operation setup, evidence, finding, validation,
report, handoff, closeout, audit, archive, and optional business-flow summary.

The core verification commands are:

```bash
./tools/atlas/bin/atlas op readiness demo-operation
./tools/atlas/bin/atlas op trust-chain demo-operation --strict
./tools/atlas/bin/atlas op trust-chain demo-operation --json
./tools/atlas/bin/atlas v1 status demo-operation --strict
./tools/atlas/bin/atlas release packet demo-operation-release --json --operation demo-operation --qa-status pass
./tools/atlas/bin/atlas release verify demo-operation-release
```

## Retained Release Evidence Commands

Use these commands to inspect the currently retained public release evidence:

```bash
./tools/atlas/bin/atlas release verify docs/retention/releases/atlas-m118-reviewer-flow-polish.json --commit de90b442d43ade01d4f15754b5952d0615582cd6
./tools/atlas/bin/atlas release manifest-verify docs/retention/releases/atlas-m118-reviewer-flow-polish.manifest.json --commit de90b442d43ade01d4f15754b5952d0615582cd6
./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m118-reviewer-flow-polish.json --json
./tools/atlas/bin/atlas production status --strict --explain
```

For the supported reviewer shell path:

```bash
nix-shell --run './tools/atlas/bin/atlas production status --strict --explain'
```

## Expected Review Surface

The reviewer should see:

- metadata-only demo operation records
- evidence hash and evidence ID
- finding ID linked to the evidence ID
- validation plan ID linked to the finding and evidence
- report, handoff, closeout, audit, archive, and trust-chain outputs
- optional business-flow packet, assurance, and trust-chain outputs
- release packet verification
- release artifact manifest verification
- release replay JSON with `overall` set to `verified`
- production explain output with the full phrase
  `production-ready under the local Atlas contract` only when the local
  contract passes

## Known Limitations

- The demo is synthetic and local-only.
- The retained M118 release evidence is the public reviewer release path; the
  demo operation release packet is local unless explicitly retained.
- Release replay verifies retained release trust evidence and does not inspect
  live runtime behavior.
- Business Flow Evidence remains optional-ready and non-blocking.
- The demo does not replace manual review or independent reviewer judgment.

## Non-Guarantees

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not external SLSA certification
- not runtime safety proof
- not production deployability proof
