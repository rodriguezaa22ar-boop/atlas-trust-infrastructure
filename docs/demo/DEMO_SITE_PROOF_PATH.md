# Demo Site Proof Path

## Purpose

This proof path defines how the Emergent demo site should connect to Atlas
without weakening the public/private repository boundary.

The first public site milestone is explanatory proof. It should help a reviewer
understand receipts, verification, replay, and known limitations. It must not become a live operation runner or agent execution surface.

## Public Proof Story

The site should tell one clean trust story:

```text
synthetic action request
  -> capability and policy decision
  -> approval status
  -> metadata-only evidence and artifact references
  -> receipt hash and previous hash
  -> local verify
  -> local replay
```

The site may show a synthetic receipt and the matching local commands:

```bash
atlas receipt create --input examples/receipt/minimal.json --output receipt.atlas.json
atlas receipt verify receipt.atlas.json
atlas receipt replay receipt.atlas.json
```

Until the receipt MVP exists, use the existing demo operation, release packet,
and replay commands as the proof backbone:

```bash
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas release replay docs/retention/releases/atlas-m121-v1-internal-rc.json --json
./tools/atlas/bin/atlas production status --strict --explain
./bin/export-public-trust --check
```

## Receipt MVP Boundary

A public receipt example must be metadata-only and include:

- actor
- action
- capability
- policy decision
- approval status
- evidence refs
- artifact refs
- commit refs
- event hash
- previous hash
- `metadata_only: true`

It must not include private runtime evidence, raw request or response bodies,
credentials, tokens, session cookies, packet captures, private targets, or
customer data.

## Site Sections

The demo site may include:

- What Atlas proves
- Create a synthetic receipt
- Verify a receipt
- Replay a proof chain
- Public/private boundary
- Known limitations
- Download example packet

It must not include:

- live scanning
- exploit execution
- target submission for real systems
- credential collection
- private adapter controls
- agent execution controls
- claims that Atlas is externally audited, certified, legally compliant,
  tamper-proof, externally SLSA certified, runtime safe, or production
  deployable

## Repository Binding

The public proof path belongs in `atlas-trust-infrastructure`.

Implementation details, private runtime history, live adapter internals, raw
evidence, private targets, sessions, logs, reports, and local runtime state
belong in `atlas-lab-toolkit` or private operator storage.

The binding check remains:

```bash
./bin/export-public-trust --check
```

## Retention

Demo-site retention records live under:

```text
docs/retention/demo/
```

They may retain metadata-only site inventory snapshots, sanitized screenshot
references, commit references, and local verification outputs. They must not
retain raw private runtime artifacts.

## Non-Guarantees

The demo site proof path is not external audit, not certification, not legal compliance, not tamper-proof infrastructure, not external SLSA certification, not runtime safety proof, and not production deployability proof.
