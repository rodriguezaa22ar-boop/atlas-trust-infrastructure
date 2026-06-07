# Atlas In One Page

## What Is Atlas?

Atlas is metadata-first proof infrastructure for critical digital actions. It
sits above existing systems such as GitHub, Nix, SSH, tmux, scanners, approval
tools, and business systems, and records reviewer-readable proof chains around
what those systems did.

Atlas does not replace those systems. It records who requested an action, what
capability and policy applied, whether approval was required, what evidence and
artifact references were emitted, which commit or packet contains the result,
and how another reviewer can verify or replay the proof.

## Current Governance Stack

The current public governance stack is:

```text
capability -> adapter -> policy -> approval -> evidence -> decision vocabulary
```

These layers are governance contracts, draft schemas, examples, and validation
surfaces unless future runtime implementation is explicitly added later.

## What Atlas Helps With

Atlas helps reviewers and operators:

- create, verify, and replay metadata-only proof receipts and proof chains;
- lower evidence reconstruction work without lowering standards;
- preserve privacy by avoiding raw sensitive data in public proof records;
- make decisions and limitations visible to reviewers;
- keep existing tools as their own operational source of truth.

The bounded value is clearer review, fewer ambiguous records, stronger audit
readiness, privacy-preserving proof, lower cost of trust without lowering
standards, and proof without exposure.

## What Does It Not Do?

Atlas does not provide autonomous exploitation, persistence, destructive
testing, credential spraying, denial-of-service workflows, stealth/evasion,
out-of-scope expansion, malware-like behavior, or authorization inference.

## What Is Ready-To-Refine?

`atlas v1 status` reports internal readiness for testing, refinement, and trust
hardening. Ready-to-refine does not mean external audit completion,
certification, legal sufficiency, deployment approval, or runtime safety proof.

## What Is The Trust Chain?

The trust chain is the metadata-only proof path from scope to evidence,
findings, validation, report, handoff, closeout, audit, archive, release
packet, provenance, receipt verification, and replay. The longer-term
direction is trust infrastructure for verifiable, replayable proof without
exposure.

The M120 schema freeze candidate classifies each contract and remains an
internal v1 review boundary for trust contracts. Atlas also has a
SLSA-verifiable release artifact candidate path for retained GitHub-built
artifacts. The retained M117 artifact has passed GitHub artifact attestation verification and official SLSA generic provenance verification with `atlas release slsa-verify`. These are verifier paths, not external certification or compliance claims.
This is not external SLSA certification.

## What Atlas Does Not Prove

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, or
replace human judgment.
Atlas does not grant permission by itself.

Atlas does not prove actions outside Atlas did not happen. It does not prove
runtime safety, model correctness, artifact correctness, external audit
completion, tamper-proof infrastructure, immutable storage, or deployment
approval.

Atlas does not replace human judgment.

## Metadata-Only Boundary

Atlas proof records must not embed raw logs, secrets, private keys, tokens,
Authorization headers, request bodies, response bodies, packet captures, raw
prompts, raw model outputs, tool output bodies, browser/session/cookie
material, customer data, payment data, private business records, unredacted
evidence bodies, or raw artifacts.
This includes raw prompts, browser/session/cookie material, and unredacted evidence bodies.

Start with [INDEX.md](INDEX.md) for the full documentation map.
