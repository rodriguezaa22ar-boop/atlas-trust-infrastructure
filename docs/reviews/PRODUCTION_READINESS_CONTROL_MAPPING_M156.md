# Production Readiness Control Mapping M156

Atlas supports production-readiness review under the local Atlas contract by
mapping retained readiness, release, provenance, dry-run, reviewer, and public
export evidence to control objectives, verification commands, and reviewer
determinations.

## Purpose

M156 turns the production-readiness contract into a reviewer-facing control
mapping. It shows which evidence Atlas can present, which commands replay or
verify that evidence, what positive support claim follows, and which
determinations remain with reviewers, auditors, operators, or other
authorities.

This mapping is the production-readiness application of the Atlas Trust Claim
Ladder. It keeps the local contract precise while making the value of retained
evidence easier to review.

## Positive Support Claim

```text
Atlas supports production-readiness review under the local Atlas contract with retained, metadata-only, verifiable evidence for readiness, release trust, artifact manifests, signing/provenance, production dry-run evidence, reviewer package generation, and public export checks.
```

## Relationship To The Trust Claim Ladder

M156 uses [TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md) as the claim
architecture:

- Level 0 receipt integrity: Atlas verifies metadata-only proof envelopes,
  hashes, schemas, and known limitations.
- Level 1 replayable action record: Atlas verifies linked retained evidence and
  replay order where a retained proof path provides replay commands.
- Level 2 review-ready event package: Atlas packages production-readiness
  evidence so a reviewer can inspect it without private runtime context.
- Level 3 control-objective support: Atlas maps readiness, release trust,
  provenance, dry-run, reviewer package, and public export evidence to concrete
  review objectives.
- Level 4 evidence sufficiency support: Atlas can show evidence present,
  missing, stale, blocked, or unverifiable under the local contract.
- Level 5 external assurance support: Atlas can support an external assurance
  process with retained evidence while the external authority makes the final
  determination.

## Relationship To The Production Readiness Contract

The source contract is
[docs/atlas/PRODUCTION_READINESS.md](../atlas/PRODUCTION_READINESS.md). That
contract defines `atlas production status`, `--strict`, `--json`, and
`--strict --explain` behavior. It also defines the required local gates:

- v1 internal readiness
- repository clean state
- upstream sync state
- release trust packet
- release artifact manifest
- production contract
- signing and provenance
- production dry-run evidence

M156 does not change those gates. It explains how the gates support review
objectives and what evidence a reviewer should inspect.

## Production Readiness Control Mapping

| Review objective | Required evidence | Atlas verification commands | Positive support claim | What Atlas verifies | Outside-Atlas determination |
| --- | --- | --- | --- | --- | --- |
| v1 internal readiness | `docs/atlas/V1_PILLAR_READINESS.md`, current v1 status output, retained readiness references. | `./tools/atlas/bin/atlas v1 status --strict`; `./tools/atlas/bin/atlas v1 status --json`. | Atlas supports production-readiness review by showing whether current internal pillars satisfy the local readiness contract. | Required pillar state, strict-mode result, JSON shape, reasons, and known limitations. | Whether internal readiness is sufficient for a specific release, deployment, customer, or assurance process. |
| repository clean/synced state | Git checkout state, configured upstream, retained release commit. | `git status --short --branch`; `git rev-list --left-right --count HEAD...@{u}`. | Atlas supports review of release discipline by requiring a clean checkout and upstream sync for production-readiness evidence. | Dirty state, staged/untracked files, and ahead/behind drift visible to Git. | Whether ignored local runtime state, mirror policy, or organizational release controls require more evidence. |
| release trust packet verification | Latest retained packet under `docs/retention/releases/`, retained milestone references, known limitations. | `./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>`; `./tools/atlas/bin/atlas release replay <release-packet> --json`. | Atlas supports review of retained release-trust evidence with verifiable packet checks and replay output. | Packet schema, commit binding, QA metadata, readiness metadata, milestone references, known limitations, and replayable release state. | Whether release policy accepts the packet, whether deployment is approved, and whether external release review requires more evidence. |
| release artifact manifest verification | Latest retained `*.manifest.json` under `docs/retention/releases/`, packet/provenance/key/dry-run/tag artifact hashes. | `./tools/atlas/bin/atlas release manifest-verify <manifest> --commit <commit>`. | Atlas supports review of release artifact coverage by verifying a metadata-only manifest of required retained artifacts. | Required artifact classes, required paths, SHA-256 hashes, schema references, known limitations, and forbidden raw-content markers. | Whether artifact contents and distribution channels satisfy release, supply-chain, or customer controls. |
| signing/provenance verification | Retained release provenance JSON, retained public key hash, signed annotated tag metadata. | `git tag -v <tag>`; `./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>`; `./tools/atlas/bin/atlas production status --strict --explain`. | Atlas supports review of signing and provenance evidence by tying retained release artifacts to a verifiable identity and commit. | Signed tag metadata, release commit match, retained public key hash, release packet hash, and production-status references. | Whether the signer is authorized, whether external SLSA or supply-chain controls are satisfied, and whether provenance is accepted by an external authority. |
| production dry-run evidence | Retained dry-run notes under `docs/retention/production/`, QA status, readiness status, observed production status, blockers. | `./tools/atlas/bin/atlas production status --strict --explain`. | Atlas supports review of operational readiness by requiring retained dry-run or independent-review evidence before local production-readiness claims. | Dry-run note presence, required fields, commit match, QA status, readiness status, known blockers, and conservative claim language. | Whether dry runs are realistic enough, repeated enough, independently reviewed, and sufficient for a particular release decision. |
| known limitations handling | `docs/KNOWN_LIMITATIONS.md`, release packet limitations, production explain output, reviewer package limitations. | `./tools/atlas/bin/atlas production status --strict --explain`; `./tools/atlas/bin/atlas reviewer package full-capability-review`. | Atlas supports production-readiness review by keeping limitations visible in the same proof path as readiness evidence. | Limitation paths, reported gate reasons, retained known limitations, and reviewer package references. | Whether limitations are acceptable, require remediation, or block external approval. |
| explainability for external reviewers | `--strict --explain` output, reviewer package, public export manifest, docs index, retained milestones. | `./tools/atlas/bin/atlas production status --strict --explain`; `./tools/atlas/bin/atlas reviewer package full-capability-review`; `./bin/export-public-trust --check`. | Atlas supports external reviewer orientation by producing readable evidence paths, commands, gate reasons, and boundaries from the public trust surface. | Explain output shape, retained evidence references, reviewer package generation, and public export cleanliness. | Whether the reviewer accepts the scope, asks for additional evidence, or issues an assurance conclusion. |
| local production-readiness contract | `docs/atlas/PRODUCTION_READINESS.md`, production status command output, release trust evidence, artifact manifest, provenance, dry-run note. | `./tools/atlas/bin/atlas production status`; `./tools/atlas/bin/atlas production status --strict`; `./tools/atlas/bin/atlas production status --json`; `./tools/atlas/bin/atlas production status --strict --explain`. | Atlas supports production-readiness review under a local, explicit, verifiable contract instead of an implied readiness claim. | Required gate statuses, strict exit behavior, JSON schema, explainability, and local contract wording. | Whether a release, deployment, customer, regulator, or auditor accepts the local contract as sufficient. |

## Evidence Paths

Production-readiness review should start with these public evidence paths:

- [docs/TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md)
- [docs/atlas/PRODUCTION_READINESS.md](../atlas/PRODUCTION_READINESS.md)
- [docs/atlas/V1_PILLAR_READINESS.md](../atlas/V1_PILLAR_READINESS.md)
- [docs/RELEASE_TRUST.md](../RELEASE_TRUST.md)
- [docs/atlas/RELEASE_ARTIFACT_MANIFEST.md](../atlas/RELEASE_ARTIFACT_MANIFEST.md)
- [docs/atlas/SLSA_PROVENANCE.md](../atlas/SLSA_PROVENANCE.md)
- [docs/atlas/SLSA_CLAIM.md](../atlas/SLSA_CLAIM.md)
- [docs/atlas/EXTERNAL_REVIEWER_PACKAGE.md](../atlas/EXTERNAL_REVIEWER_PACKAGE.md)
- [docs/KNOWN_LIMITATIONS.md](../KNOWN_LIMITATIONS.md)
- [docs/reviews/CONTROL_OBJECTIVE_MAPPING.md](CONTROL_OBJECTIVE_MAPPING.md)
- `docs/retention/releases/`
- `docs/retention/production/`
- `exports/public-trust-manifest.json`

## Verification Commands

Reviewers can use these commands to inspect the local production-readiness
evidence path:

```bash
nix-shell --run './tools/atlas/bin/atlas production status --strict --explain'
nix-shell --run './tools/atlas/bin/atlas v1 status --strict'
git status --short --branch
git rev-list --left-right --count HEAD...@{u}
./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>
./tools/atlas/bin/atlas release manifest-verify <manifest> --commit <commit>
./tools/atlas/bin/atlas release replay <release-packet> --json
git tag -v <tag>
./tools/atlas/bin/atlas reviewer package full-capability-review
./bin/export-public-trust --check
```

## Known Limitations

This support is bounded by the local Atlas contract:

- This support is not external production certification.
- This support is not external audit completion.
- This support is not legal compliance.
- This support is not tamper-proof infrastructure.
- This support is not guaranteed safety.
- This support is not external SLSA certification.
- This support is not production deployability outside the local Atlas
  contract.
- Atlas verifies retained metadata evidence and local command results; source
  system truth, signer authority, artifact correctness, deployment approval,
  and residual risk acceptance require reviewer or authority judgment.

## Reviewer Checklist

- Confirm `docs/atlas/PRODUCTION_READINESS.md` is the active local contract.
- Run `atlas production status --strict --explain` through `nix-shell`.
- Confirm v1 internal readiness status is present and strict-mode behavior is
  visible.
- Confirm repository clean/synced state is reported or the drift is explained.
- Verify the retained release trust packet.
- Verify the retained release artifact manifest.
- Check signing and provenance references, including signed tag verification.
- Confirm production dry-run or independent-review evidence is retained.
- Confirm known limitations are visible in the proof path.
- Generate or inspect the reviewer package.
- Run `./bin/export-public-trust --check`.
- Record remaining outside-Atlas determinations before making any external
  assurance, release, or deployment decision.
