# Atlas Known Limitations

Known limitations are precision boundaries for Atlas' public trust surface.
They help reviewers understand which evidence Atlas can verify locally and
which determinations remain with reviewers, auditors, approvers, or
authorities.

## Current Maturity

Atlas is in an internal engineering and refinement phase. Current readiness
means ready-to-refine, not production-certified.

## Trust Precision Boundaries

Atlas supports audit-ready evidence, release governance, CI integrity review,
AI-agent action review, approval integrity, evidence sufficiency review, and
reviewer decision support through replayable metadata-only proof receipts. The
boundaries below keep those support claims tied to evidence.

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, or
replace human judgment.
Atlas does not grant permission by itself.

Atlas proof records must not embed raw logs, secrets, private keys, tokens,
Authorization headers, request bodies, response bodies, packet captures, raw
prompts, raw model outputs, tool output bodies, browser/session/cookie
material, customer data, payment data, private business records, unredacted
evidence bodies, or raw artifacts.
This includes raw prompts, browser/session/cookie material, and unredacted evidence bodies.

- Release trust packets are hash-bound by release provenance; packet files are
  not individually signed.
- Release provenance currently uses local signed Git tags for Atlas production
  status; GitHub/Sigstore SLSA provenance is prepared and smoke-verified for
  release artifacts, and release artifact manifests can record verified SLSA
  references when provided. `atlas release slsa-verify` checks retained SLSA
  reference metadata locally and can verify a downloaded artifact hash. With
  `--online`, it can run `gh attestation verify`, but Atlas still does not
  download artifacts automatically.
- Atlas is not externally SLSA-certified.
- Atlas has an Official SLSA Generic Provenance workflow and a retained
  `atlas-v0.4.0-rc1` release-candidate SLSA reference. Authenticated
  `gh attestation verify` has passed through Atlas for the release candidate,
  and an independent review packet is retained, but independent review is not
  complete.
- Atlas has a retained M117 SLSA-verifiable release artifact candidate.
  `gh attestation verify`, `slsa-verifier verify-artifact`, and
  `atlas release slsa-verify` have passed for that artifact/provenance path.
  This is not external SLSA certification, legal compliance, runtime safety
  proof, or production deployability proof.
- Signed-tag verification is supported through the project `nix-shell`.
  Direct host-shell GPG behavior can vary when temporary keyring imports depend
  on local agent configuration.
- Production dry-run evidence is retained locally; it is not an independent
  external validation.
- Replay verification is local-first and repository-backed.
- Metadata-only packets point to artifacts; they do not preserve raw evidence.
- Tamper evidence depends on Git history, hashes, and retained local files.
- The M120 schema freeze candidate is an internal v1 review boundary, not an
  external certification. Schema contracts are human-readable operational
  contracts under `docs/schemas/`, not generated JSON Schema artifacts.
- The Atlas v1 Internal Release Candidate is an internal review boundary. It
  does not create external audit, certification, legal compliance, runtime
  safety proof, production deployability proof, or enterprise deployment
  approval.
- Backward-compatible optional schema additions may still occur after the
  freeze candidate when documented; field renames, removals, type changes,
  required-field changes, enum meaning changes, or verification semantic
  changes require a version bump.

## Governance Stack Limitations

- Governance contracts are not runtime engines.
- The Capability Manifest names and classifies actions; it does not grant
  permission by itself.
- The Adapter Registry documents source/system boundaries; it does not create
  live integrations, API calls, webhooks, network collectors, or adapter
  execution.
- The Policy Plane models decisions; policy decisions do not prove legal or
  compliance approval and do not create runtime policy enforcement.
- The current policy runtime evaluator is shell/JQ in
  `tools/atlas/lib/policy.sh`. `policy/atlas.authz.rego` is validated by OPA as
  a policy contract/reference, but Rego is not the runtime evaluator in M193.
- The Approval Plane models approval state; approval records do not prove
  action validity, production approval, legal sufficiency, or execution.
- The Evidence Envelope is a draft schema contract unless runtime evidence
  emission is explicitly implemented later.
- evidence emission is explicitly implemented later only in a future runtime
  milestone, not by the current schema contract.
- The Governance Decision Vocabulary standardizes words; decision vocabulary
  terms do not grant authorization by themselves.
- decision vocabulary terms do not grant authorization by themselves.
- Replay does not prove complete event coverage.
- Atlas does not prove actions outside Atlas did not happen.
- Atlas does not replace human judgment.
- Atlas does not prove model correctness or artifact correctness.

## Runtime Limitations

- Atlas is shell-native and local-first.
- The current state model is file-backed.
- SQLite, server state, fleet state, and web UI layers are future work.
- Atlas OS, ISI, and kernel-level work are future research tracks.

## Workflow Limitations

- Operator judgment is still required.
- Authorization is not inferred by Atlas.
- Scope must be maintained by accurate target records and operation context.
- Validation must remain approval-gated.
- Production readiness is limited to the local contract reported by
  `atlas production status`.

## Language Boundary

Avoid describing Atlas as autonomous, unbreakable, fully secure,
organization-scale approved, externally reviewed as complete, or certified for
deployment unless future evidence actually supports those claims. If
`atlas production status` reports readiness under the local Atlas contract,
describe that as the local Atlas production contract passing for retained
release evidence.
