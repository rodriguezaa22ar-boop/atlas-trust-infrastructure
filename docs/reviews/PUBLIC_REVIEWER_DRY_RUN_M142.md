# Atlas Public Reviewer Dry-Run M142

## Purpose

This note records a public-reviewer dry-run from a fresh clone. The goal was to
simulate a stranger landing on Atlas with no private notes and checking whether
the public materials are understandable, cloneable, tryable, verifiable, and
honest about limits.

This is a review record, not a new feature. It does not add runtime behavior,
receipt semantics, release semantics, adapter behavior, network behavior, or
agent behavior.

## Environment

- Date: 2026-05-22
- Clone path: `/tmp/atlas-public-review`
- Source: `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure.git`
- Commit reviewed: `38627006a43b3469ae6eb1b1ea01c497c6e263f2`
- Branch: `main`
- Environment type: fresh public clone on the Nix reference host
- Private notes used: none

The dry-run used the public repository, public docs, retained public release
evidence, examples, schemas, and test suite only.

## Public Entry Points Read

```bash
sed -n '1,180p' README.md
sed -n '1,240p' docs/RECEIPT_OPEN_CORE_RC.md
sed -n '1,220p' docs/TRY_RECEIPTS.md
sed -n '1,220p' docs/KNOWN_LIMITATIONS.md
```

Document sizes inspected:

```text
150 README.md
185 docs/RECEIPT_OPEN_CORE_RC.md
111 docs/TRY_RECEIPTS.md
 72 docs/KNOWN_LIMITATIONS.md
```

## Commands Run

```bash
nix-shell --run './bin/dev-qa'
nix-shell --run './tools/atlas/bin/atlas receipt verify examples/receipt/minimal.json'
nix-shell --run './tools/atlas/bin/atlas receipt replay examples/receipt/demo-site/*.json'
nix-shell --run './tools/atlas/bin/atlas reviewer package full-capability-review'
nix-shell --run './bin/export-public-trust --check'
nix-shell --run 'rg -n "PRIVATE KEY|Authorization: Bearer|session_cookie|raw_request|raw_response|packet-capture|pcap" README.md docs examples schemas tools tests || true'
```

## Results

| Check | Result |
| --- | --- |
| Fresh public clone | passed |
| `nix-shell --run './bin/dev-qa'` | passed, 133/133 Bats plus lint, portability, and stress |
| Receipt verify | passed |
| Receipt replay | passed |
| Reviewer package | passed |
| Public export check | passed |
| Secret/raw-artifact scan | no real leaks found; expected source/test references reviewed |

Receipt verification output included:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

Receipt replay output included:

```text
receipt replay: ok
receipts: 3
ledger binding: ok prev_hash -> event_hash
chain_head_event_hash: bb79b7ba13bfc8b657a532c9a07cd3eb9c27020514c903e9cda4385f6e5012eb
chain_head_receipt_hash: f0ba44315536c8397b4a42bc1a5b18bf3992b13752b83e465bed0850a1ea6c38
metadata-only boundary: ok
```

Reviewer package generation wrote:

```text
docs/retention/reviewer-packages/full-capability-review/
```

The generated package path is ignored local output, not a committed third-party
review result.

Public Trust Export reported:

```text
Manifest: ok
Allowed files: 488
Forbidden paths: 0
Private markers: 0
Overall: ok
```

## Boundary Scan Notes

The raw-artifact scan returned expected references, not retained raw artifacts:

- `tests/atlas.bats` contains an intentional unsafe receipt fixture with
  `Authorization: Bearer abc123` to prove receipt rejection.
- `tools/wiremap/bin/wiremap`, `tools/atlas/bin/atlas`, and related tests/docs
  mention `pcap` because Wiremap owns capture planning and capture inspection.
- No raw `.pcap` files were found under `README.md docs examples schemas tools tests`.
- Public export reported `Private markers: 0`.

This scan would be clearer for future reviewers if the expected fixture/tooling
matches were documented as review noise rather than interpreted as leaked raw
evidence.

## What Was Clear

- The README quickly frames Atlas as metadata-first proof infrastructure, not a
  scanner replacement.
- `docs/RECEIPT_OPEN_CORE_RC.md` gives a usable receipt/replay/reviewer package
  overview without requiring private context.
- `docs/TRY_RECEIPTS.md` provides copy-paste commands and expected receipt
  output.
- The receipt verifier and replay commands print visible non-guarantee
  language.
- M140 retained evidence lets `atlas reviewer package full-capability-review`
  pass from a fresh public clone.

## What Was Confusing

- The broad scan for `pcap` and `Authorization: Bearer` returns expected
  source/test matches. A reviewer needs the boundary note above to distinguish
  those from raw artifacts or real secrets.
- Full `dev-qa` is valuable but long for a first public read. The five-minute
  receipt quickstart remains the better first interaction.

## What Atlas Proves

For the reviewed public commit, Atlas proves:

- the public repo passes the full local QA gate;
- metadata-only receipt verification works;
- receipt replay verifies provided-order `prev_hash -> event_hash` linkage;
- reviewer package generation works against current retained release evidence;
- public export has no forbidden paths or private markers;
- non-guarantee language is visible in docs and command output.

## What Atlas Does Not Prove

This dry-run does not prove:

- external audit;
- certification;
- legal compliance;
- production deployment approval;
- tamper-proof infrastructure;
- runtime safety;
- external artifact truth;
- human intent;
- external SLSA certification.

## Recommended Doc Fixes

- Retain this M142 note as the public-reviewer dry-run record.
- Keep the receipt quickstart as the first interactive path.
- Treat the boundary scan note as the current explanation for expected
  `pcap`/test-fixture matches.
- Consider a future dedicated public leak-scan runbook if reviewers repeatedly
  confuse defensive fixture/tooling references with raw artifact leakage.
