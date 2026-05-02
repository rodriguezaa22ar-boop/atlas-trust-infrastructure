# Atlas In One Page

## What Is Atlas?

Atlas is a shell-native, metadata-first trust control plane for authorized
security assessment workflows and optional business-flow evidence. It
coordinates scope, targets, recon, evidence, findings, validation, reports,
retention, and release trust while keeping the underlying domain tools
separate.

Atlas is the operator-facing layer. `wiremap` owns reconnaissance and packet
evidence, `vector` owns ranked action lanes and bounded validation, `intelctl`
owns direct shared-intel inspection, and `labctl` owns build and administration
workflows.

## Who Is It For?

Atlas is for operators who need a local-first assessment workflow with clear
scope, retained evidence, auditability, and release trust. It is designed for
authorized lab, internal, training, and controlled assessment work where the
operator wants a verifiable record instead of scattered terminal output.

## What Problem Does It Solve?

Atlas gives one consistent workflow for:

- registering targets and scope
- starting operations
- collecting and hashing evidence
- recording findings and accepted-risk ownership
- planning and approving validation
- generating reports and handoff packets
- closing, auditing, and archiving operations
- checking readiness and release trust
- retaining signed release provenance
- retaining SLSA-verifiable release artifact candidate metadata

The goal is not to make assessment work flashy. The goal is to make it
bounded, reviewable, and hard to misunderstand later.

The longer-term direction is trust infrastructure: evidence-backed,
metadata-only, verifiable operational proof for security operations, business
flows, releases, audits, retention, and replay.

## What Does It Not Do?

Atlas does not provide or encourage:

- autonomous exploitation
- persistence
- destructive testing
- credential spraying
- denial-of-service workflows
- stealth/evasion behavior
- out-of-scope target expansion
- malware-like behavior
- unauthorized access

Atlas does not infer authorization. Scope must be recorded accurately by the
operator.

## What Is Ready-To-Refine?

`atlas v1 status` reports internal pillar readiness. In Atlas language,
`ready` means ready for internal testing, refinement, and trust hardening. It
does not mean externally audited, enterprise-ready, deployment-certified, or
tamper-proof.

## What Is Production-Ready?

`atlas production status --strict` reports whether Atlas passes its stricter
local production contract. That contract currently requires clean and synced
repository state, v1 readiness, a verified release packet, a documented
production contract, signed release provenance, and retained dry-run evidence.

When Atlas reports `production-ready`, that means the local Atlas production
contract passes for retained release evidence. It is not an external audit,
SLSA certification, enterprise certification, runtime safety proof, or
deployment certification.

Atlas also has a SLSA-verifiable release artifact candidate path for
GitHub-built source artifacts. The retained M117 artifact has passed GitHub
artifact attestation verification, official SLSA generic provenance verification
with `slsa-verifier`, and `atlas release slsa-verify` against retained Atlas
metadata. That evidence remains a verifier path, not external SLSA
certification.

Atlas maintains v1 trust schema contracts under `docs/schemas/`. The M120
schema freeze candidate classifies each contract as stable, optional,
retained-only, experimental, or future, and requires version bumps for field
renames, removals, type changes, required-field changes, enum meaning changes,
or verification semantic changes after the freeze candidate.

## What Is The Trust Chain?

The trust chain is the proof path from scope to release:

```text
scope -> evidence -> findings -> validation -> report -> handoff -> closeout
-> audit -> archive -> operation trust-chain -> release packet -> provenance
```

Each step records metadata, paths, hashes, counts, status, verification output,
or known limitations. Trust packets are metadata-only; they do not embed raw
secrets, private keys, packet captures, tokens, credential material, or
unredacted evidence bodies.

Start with [INDEX.md](INDEX.md) for the full documentation map.
