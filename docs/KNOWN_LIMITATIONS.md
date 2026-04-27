# Atlas Known Limitations

## Current Maturity

Atlas is in an internal engineering and refinement phase. Current readiness
means ready-to-refine, not production-certified.

## Trust Limitations

- Release trust packets are not cryptographically signed.
- No SLSA-style provenance packet is retained yet.
- Production dry-run or external validation evidence is not retained yet.
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
- Production readiness is blocked until the production gate reports ready.

## Language Boundary

Avoid describing Atlas as production-ready, autonomous, unbreakable, fully
secure, enterprise-ready, or externally audited unless future evidence actually
supports those claims.
