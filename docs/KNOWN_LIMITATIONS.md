# Atlas Known Limitations

## Current Maturity

Atlas is in an internal engineering and refinement phase. Current readiness
means ready-to-refine, not production-certified.

## Trust Limitations

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
- Production dry-run evidence is retained locally; it is not an independent
  external validation.
- Replay verification is local-first and repository-backed.
- Metadata-only packets point to artifacts; they do not preserve raw evidence.
- Tamper evidence depends on Git history, hashes, and retained local files.

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
enterprise-ready, externally audited, or deployment-certified unless future
evidence actually supports those claims. If `atlas production status` reports
`production-ready`, describe that as the local Atlas production contract
passing for retained release evidence.
