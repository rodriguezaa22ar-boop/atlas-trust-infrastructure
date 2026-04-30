# Case Study: Release Trust

## Problem

Release evidence is usually spread across several systems: CI logs, build
artifacts, checksums, provenance, tags, release notes, deployment records,
review notes, and security findings. Each system may be useful on its own, but
reviewers still need a coherent answer to a simple question:

```text
What proves this release was built, checked, retained, and reviewed under the
expected release rules?
```

Atlas treats that question as a trust-chain problem. It does not replace the
tools that build, scan, sign, publish, or review a release. Atlas connects the
metadata those tools produce into a scoped, retained, metadata-first proof
chain.

## Current Fragmented Approach

A typical release review may require a reviewer to inspect:

- CI workflow run status
- build artifact names and checksums
- signed tag state
- SLSA or Sigstore provenance
- release notes
- readiness output
- dry-run notes
- known limitations
- issue or finding closure state
- manual approval notes

Without a retained proof layer, those references can drift. A release may have
passed CI, but the artifact may not be linked to the release packet. A tag may
exist, but the reviewer may not know which readiness state it represented. A
provenance record may verify, but it may not be tied to the local production
readiness contract.

## Atlas Proof-Layer Approach

Atlas records the release proof chain as metadata. It keeps the evidence
referential: paths, hashes, timestamps, commits, tags, workflow names,
verification states, and known limitations.

Atlas does not replace CI/CD, SLSA tooling, signing tools, artifact
registries, scanners, SIEMs, or GRC tools. It connects existing evidence across
those tools into a scoped, retained, metadata-first proof chain.

The release trust flow is:

```text
source commit
  -> QA and readiness checks
  -> release packet
  -> signed provenance packet
  -> release artifact manifest
  -> dry-run or review note
  -> release verification
  -> local production-readiness status
```

## Proof Chain

For a release-trust review, Atlas expects the reviewer to be able to follow:

1. The release commit.
2. The branch and tag state.
3. The QA command and result.
4. The v1 readiness state.
5. The release packet path and hash.
6. The signed provenance packet path and hash.
7. The release artifact manifest path and hash.
8. The production dry-run or review note.
9. The known limitations.
10. The verification commands and expected result.

The result is not a claim that every system is secure. It is a retained
metadata trail showing what Atlas checked, what it retained, what it can
verify later, and what it does not claim.

## What Atlas Stores

Atlas stores release-trust metadata such as:

- repository owner and branch
- release commit
- tag name and tag target
- workflow identity
- QA command and status
- readiness JSON
- release packet path and SHA-256
- provenance packet path and SHA-256
- release artifact manifest path and SHA-256
- production dry-run note path and SHA-256
- known limitations
- verification status

## What Atlas Does Not Store

Release-trust packets must not store:

- secrets
- tokens
- credentials
- private keys
- customer data
- private business records
- target data
- packet captures
- raw request or response bodies
- exploit payloads
- raw runtime artifacts
- full CI logs
- unredacted evidence bodies

This is the core metadata-only boundary. Atlas should point to evidence and
hash it; it should not copy sensitive content into public proof packets.

## Artifacts Involved

The current Atlas release-trust chain may involve:

- `docs/retention/releases/<name>.json`
- `docs/retention/releases/<name>.provenance.json`
- `docs/retention/releases/<name>.manifest.json`
- `docs/retention/production/PRODUCTION_DRY_RUN_*.md`
- `docs/retention/milestones/MILESTONE_*.md`
- `docs/atlas/PRODUCTION_READINESS.md`
- `docs/atlas/SLSA_PROVENANCE.md`
- `docs/atlas/SLSA_CLAIM.md`
- `docs/atlas/RELEASE_ARTIFACT_MANIFEST.md`
- `docs/schemas/release-trust.v1.md`
- `docs/schemas/release-provenance.v1.md`
- `docs/schemas/release-artifact-manifest.v1.md`
- `docs/schemas/slsa-provenance.v1.md`

Each artifact has a narrow purpose. The release packet summarizes release
state. The provenance packet binds release state to a signed tag and retained
public key. The manifest indexes retained release artifacts and hashes. The
dry-run note records the local production-readiness observation before
retention. The schemas define what the packets must contain and what they must
exclude.

## Verification Commands

Typical local verification commands are:

```bash
atlas v1 status --strict
atlas release verify docs/retention/releases/<name>.json --commit <sha>
atlas release manifest-verify docs/retention/releases/<name>.manifest.json --commit <sha>
atlas production status --strict
git tag -v <tag>
```

When a release artifact and provenance have been published, reviewers can add
SLSA-oriented checks:

```bash
atlas release slsa-verify docs/retention/releases/<name>.slsa.json --commit <sha>
atlas release slsa-verify docs/retention/releases/<name>.slsa.json --commit <sha> --artifact <artifact>.tar.gz
gh attestation verify <artifact>.tar.gz --repo <owner>/<repo>
slsa-verifier verify-artifact <artifact>.tar.gz --provenance-path <artifact>.intoto.jsonl --source-uri github.com/<owner>/<repo> --source-tag <tag>
```

The exact commands depend on which artifact and provenance records exist for
the release under review.

## What This Proves

This proves that Atlas can retain and re-check a release proof chain made of:

- a named release commit
- local QA status
- v1 readiness state
- a metadata-only release packet
- signed local provenance
- a metadata-only release artifact manifest
- production dry-run or review evidence
- known limitations
- verification commands

When `atlas production status` passes, the precise wording is:

```text
production-ready under the local Atlas contract
```

That means Atlas' local retained gates pass for the release evidence. It does
not mean a broader public certification has been granted.

## What This Does Not Prove

This does not prove:

- external audit completion
- enterprise deployment approval
- legal compliance
- immutable storage
- that every runtime behavior is secure
- that every historical release has the same retained evidence
- that the release artifact is safe to deploy in every environment
- that every scanner, CI, signing, or artifact-registry control was configured
  correctly

Atlas can show what it checked and retained. It cannot turn missing upstream
evidence into proof.

## Why This Matters For SLSA-Verifiable Releases

SLSA and provenance tooling help answer where an artifact came from and how it
was built. Atlas adds the surrounding release context:

- which release commit Atlas meant to review
- which readiness state was retained
- which QA gate was recorded
- which release packet and manifest were retained
- which known limitations were attached
- which verification commands a reviewer should run

Atlas may describe SLSA-verifiable release artifacts when the artifact,
digest, source, workflow, provenance, and verification commands are explicit.
Atlas must not claim SLSA certification unless an appropriate external review
or certification process has actually granted that conclusion.

## Known Limitations

- Atlas release packets are metadata-only local records.
- Signed local provenance is not the same as an external audit.
- Release artifact manifests are local indexes, not public transparency logs.
- SLSA references are optional and only meaningful when the artifact and
  provenance exist.
- Code scanning is an additional automated signal, not proof that all runtime
  behavior is correct.
- The local Atlas production contract does not replace organization-specific
  release, deployment, legal, or compliance review.

## Responsible-Use Boundary

This case study is about authorized release review and metadata-first proof.
Do not use Atlas release trust language to imply authorization, hide missing
evidence, bypass approval gates, or claim certification that has not been
granted.

Atlas should be used to make release claims easier to verify, not easier to
overstate.
