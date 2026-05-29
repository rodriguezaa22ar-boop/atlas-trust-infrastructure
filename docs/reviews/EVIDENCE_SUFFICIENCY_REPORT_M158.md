# Evidence Sufficiency Report M158

## Reviewed Commit

`23bc4e220e4b92223c93b60230bbd8515cf3561d` M157 merged checkpoint

## Purpose

Atlas supports evidence sufficiency review by showing whether the evidence for
a review objective is `present`, `missing`, `stale`, or `unverifiable`.

M158 applies Level 4 of the
[Trust Claim Ladder](../TRUST_CLAIM_LADDER.md) to the production-readiness
review path introduced in
[PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](PRODUCTION_READINESS_CONTROL_MAPPING_M156.md).
It turns a control mapping into a reviewer-facing report shape without adding a
new command, runtime behavior, adapter, live integration, database, network
collector, or hidden state.

## Positive Support Claim

```text
Atlas supports evidence sufficiency review by mapping each required evidence
item for a review objective to a bounded status, verification command, local
proof envelope, and reviewer follow-up.
```

## Relationship To The Trust Claim Ladder

M158 is the first concrete Level 4 report:

- Level 0 receipt integrity remains the proof-record floor.
- Level 1 replayable action records remain the ordering check.
- Level 2 review-ready packages remain the reviewer packaging layer.
- Level 3 control-objective support remains the mapping layer.
- Level 4 evidence sufficiency support reports evidence status as `present`,
  `missing`, `stale`, or `unverifiable`.
- Level 5 external assurance support remains an outside determination by the
  reviewer, auditor, approver, or authority.

## Status Vocabulary

| Status | Meaning | Typical Atlas signal | Reviewer follow-up |
| --- | --- | --- | --- |
| `present` | Required evidence is available and has a named local verification path. | File path exists, command is documented, verifier or replay output can be run locally. | Run or inspect the verification path and decide whether the evidence satisfies the objective. |
| `missing` | Required evidence is absent or not referenced from the proof path. | Missing file, missing retained milestone, missing release packet, missing manifest, missing dry-run note, or missing known limitations. | Treat the objective as incomplete until evidence is retained or the gap is explicitly accepted. |
| `stale` | Evidence exists but no longer represents the reviewed state. | Dirty repo, unsynced upstream, commit mismatch, stale packet, stale manifest, or newer material state after packet generation. | Regenerate or refresh the evidence before relying on the objective. |
| `unverifiable` | Evidence exists but Atlas cannot verify it locally. | Malformed JSON, hash mismatch, unavailable referenced artifact, unsupported schema, failed signature check, or command failure without a usable proof result. | Do not treat the evidence as sufficient until the verification failure is resolved or documented as residual risk. |

These statuses make gaps visible. They do not decide approval, release,
deployment, certification, audit completion, legal adequacy, or residual risk.

## Report Subject

Review objective:

```text
production-readiness review under the local Atlas contract
```

Source mapping:

- [PRODUCTION_READINESS_CONTROL_MAPPING_M156.md](PRODUCTION_READINESS_CONTROL_MAPPING_M156.md)
- [CONTROL_OBJECTIVE_MAPPING.md](CONTROL_OBJECTIVE_MAPPING.md)
- [../atlas/PRODUCTION_READINESS.md](../atlas/PRODUCTION_READINESS.md)
- [../TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md)

M157 protects the claim boundary for this objective. M158 adds the report shape
that lets a reviewer see which evidence is available, which evidence needs
refresh, and which evidence cannot yet be verified.

## Evidence Sufficiency Report

| Evidence area | Required evidence | Sufficiency state to report | Atlas verification commands | What Atlas verifies | Reviewer follow-up |
| --- | --- | --- | --- | --- | --- |
| v1 internal readiness | `docs/atlas/V1_PILLAR_READINESS.md` and current v1 status output. | `present` when strict v1 status passes; `missing` when the contract or status output is absent; `stale` when readiness output no longer matches current state; `unverifiable` when the command cannot produce usable output. | `./tools/atlas/bin/atlas v1 status --strict`; `./tools/atlas/bin/atlas v1 status --json`. | Required pillar state, strict result, JSON shape, reasons, and known limitations. | Decide whether internal readiness satisfies the reviewed objective. |
| repository clean/synced state | Clean worktree, configured upstream, and reviewed commit. | `present` when clean and in sync; `stale` when dirty, ahead, or behind; `unverifiable` when Git metadata is unavailable. | `git status --short --branch`; `git rev-list --left-right --count HEAD...@{u}`. | Dirty state, untracked/staged changes, and upstream drift visible to Git. | Resolve drift or record why the reviewed state remains acceptable. |
| release trust packet | Retained release packet under `docs/retention/releases/`. | `present` when the packet verifies for the reviewed commit; `missing` when absent; `stale` on commit mismatch; `unverifiable` on malformed packet or verifier failure. | `./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>`; `./tools/atlas/bin/atlas release replay <release-packet> --json`. | Packet schema, commit binding, QA metadata, readiness metadata, retained milestones, known limitations, and replay output. | Decide whether release evidence supports the objective or requires a refreshed packet. |
| release artifact manifest | Retained `*.manifest.json` covering release packet, provenance, key, dry-run, and tag metadata. | `present` when manifest verification passes; `missing` when absent; `stale` on commit or artifact drift; `unverifiable` on hash mismatch, malformed JSON, or unavailable referenced artifact. | `./tools/atlas/bin/atlas release manifest-verify <manifest> --commit <commit>`. | Required artifact classes, paths, SHA-256 hashes, schema refs, known limitations, and forbidden raw-content boundaries. | Decide whether artifact coverage is enough for the reviewed objective. |
| signing/provenance | Signed tag metadata, retained provenance JSON, and retained public key hash. | `present` when the retained signing/provenance path verifies; `missing` when no provenance path is retained; `stale` on commit mismatch; `unverifiable` on failed signature or malformed provenance. | `git tag -v <tag>`; `./tools/atlas/bin/atlas release verify <release-packet> --commit <commit>`; `./tools/atlas/bin/atlas production status --strict --explain`. | Signed tag metadata, release commit match, public key hash reference, and retained provenance linkage. | Decide whether signer authority and provenance expectations are satisfied outside Atlas. |
| production dry-run evidence | Retained production dry-run or independent-review note under `docs/retention/production/`. | `present` when retained dry-run evidence matches the reviewed release path; `missing` when absent; `stale` when tied to an older material state; `unverifiable` when required fields cannot be inspected. | `./tools/atlas/bin/atlas production status --strict --explain`. | Dry-run path, commit relation, QA status, readiness status, blockers, and known limitations. | Decide whether dry-run realism and coverage are sufficient for the objective. |
| reviewer package | Metadata-only reviewer package generated from retained public evidence. | `present` when package generation succeeds; `missing` when required retained evidence is absent; `stale` when generated from older evidence; `unverifiable` when package generation fails without a usable proof result. | `./tools/atlas/bin/atlas reviewer package full-capability-review`. | Required retained evidence references, package contents, known limitations, and metadata-only boundaries. | Decide whether the package is enough for review or needs additional evidence. |
| public export | Public export manifest and clean export check. | `present` when public export check passes; `missing` when manifest or export contract is absent; `stale` when export does not reflect current public surface; `unverifiable` when the check fails or cannot run. | `./bin/export-public-trust --check`. | Allowed public files, forbidden paths, private marker scan, and public trust manifest consistency. | Decide whether the public review surface is acceptable for the objective. |
| known limitations | `docs/KNOWN_LIMITATIONS.md`, release limitations, production explain output, and reviewer package limitations. | `present` when limitations are visible in the proof path; `missing` when omitted; `stale` when limitations no longer match current scope; `unverifiable` when limitations cannot be tied to the reviewed evidence. | `./tools/atlas/bin/atlas production status --strict --explain`; `./tools/atlas/bin/atlas reviewer package full-capability-review`. | Limitation paths, gate reasons, retained known limitations, and reviewer package references. | Decide whether limitations require remediation, acceptance, or escalation. |

## Report Output Shape

A reviewer-facing sufficiency report should preserve this shape:

```text
review_objective: production-readiness review under the local Atlas contract
reviewed_commit: <commit>
overall_evidence_state: present | missing | stale | unverifiable
evidence_items:
  - id: v1_internal_readiness
    status: present | missing | stale | unverifiable
    required_evidence: ...
    verification_commands: ...
    atlas_verifies: ...
    reviewer_follow_up: ...
known_limitations: ...
outside_atlas_determination: ...
```

This output shape is a documentation contract for M158. It is not a new CLI
schema and does not add runtime behavior.

## How To Use This Report

1. Choose the review objective from
   [CONTROL_OBJECTIVE_MAPPING.md](CONTROL_OBJECTIVE_MAPPING.md).
2. List the required evidence for that objective.
3. Assign each evidence item one status: `present`, `missing`, `stale`, or
   `unverifiable`.
4. Record the local verification command and output summary.
5. Record known limitations.
6. Record outside-Atlas determinations before making release, deployment,
   assurance, audit, or compliance decisions.

## Reviewer Checklist

- Confirm the review objective is named.
- Confirm the reviewed commit is recorded.
- Confirm every required evidence item has exactly one sufficiency status.
- Confirm verification commands are local and metadata-only.
- Confirm raw logs, raw prompts, raw model outputs, packet captures, secrets,
  tokens, private keys, request bodies, and response bodies are not embedded.
- Confirm `missing`, `stale`, and `unverifiable` evidence is not treated as
  sufficient without reviewer follow-up.
- Confirm known limitations remain visible.
- Confirm outside-Atlas determinations are explicitly recorded.

## Known Limitations

- M158 is docs/tests only.
- M158 does not add `atlas evidence sufficiency` or any new CLI behavior.
- M158 does not create a database, network collector, web UI, adapter, or live
  integration.
- M158 does not restore, mutate, generate, or refresh evidence.
- M158 reports the proof-envelope status; it does not decide source-system
  truth, signer authority, artifact correctness, approval sufficiency,
  deployment approval, audit completion, compliance conclusion, certification,
  or residual risk acceptance.
