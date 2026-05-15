# Demo Site Inventory

## Purpose

This inventory binds the public-facing Emergent demo site to the Atlas proof
surface without turning the site into an execution surface.

The inventory is metadata-only. It records public site identity, repository
links, deployed commit references when known, screenshots or screenshot
references, claims, non-claims, and known limitations.

## Current Inventory

| Field | Value |
| --- | --- |
| Site URL | Pending operator input |
| Hosting provider | Emergent AI |
| Source repository | Pending operator input |
| Latest deployed commit | Pending operator input |
| Public purpose | public-facing proof-of-concept surface for explaining Atlas receipts and trust-chain verification. |
| Demonstrates | Metadata-only proof receipts, verification, replay, public/private boundary, and known limitations. |
| Does not claim | External audit, certification, legal compliance, tamper-proof infrastructure, external SLSA certification, runtime safety proof, production deployability proof, or live authorized-assessment execution. |
| Screenshots | Pending metadata-only screenshot references under `docs/retention/demo/`; do not embed raw private runtime data. |
| Known limitations | Demo site identity and deployed commit are not yet verified in this repository; the site must remain explanatory until the receipt MVP has a public verifier contract. |

## Site Purpose

The demo site should explain what Atlas proves:

- who requested or performed an action
- what action was requested
- which capability and policy decision applied
- what approval status existed
- which evidence and artifact references were retained
- which commit or packet result was produced
- how a reviewer verifies and replays the proof chain

The site should use synthetic public examples only. It must not run scans,
trigger live actions, collect private targets, accept secrets, store raw
runtime artifacts, or expose private implementation state.

## Required Before Public Claiming

Before the demo site is described as bound to Atlas proof, record:

1. The canonical site URL.
2. The source repository or deployment source.
3. The latest deployed commit or immutable deployment identifier.
4. A screenshot reference that contains no private data.
5. The receipt or packet example used by the site.
6. The exact verify and replay commands a reviewer can run locally.

## Public Boundary

Allowed public material:

- site URL and hosting provider
- public source repository reference
- deployed commit or immutable deployment identifier
- sanitized screenshots
- synthetic receipt examples
- verification and replay commands
- known limitations and non-guarantees

Forbidden public material:

- credentials, tokens, private keys, cookies, or session data
- private target records or customer data
- raw packet captures
- full request or response bodies
- unredacted runtime evidence
- local runtime state from private `sessions/`, `state/`, `shared/`, `logs/`,
  `reports/`, `releases/`, or `targets/`
- private implementation context that belongs only in `atlas-lab-toolkit`

## Non-Guarantees

The demo site inventory is not external audit, not certification, not legal compliance, not tamper-proof infrastructure, not external SLSA certification, not runtime safety proof, and not production deployability proof.
