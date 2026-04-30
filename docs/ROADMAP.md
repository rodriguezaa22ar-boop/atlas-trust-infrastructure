# Atlas Roadmap

## Current Phase

Atlas is in the trust infrastructure lane:

- agent governance
- milestone retention
- release replay guidance
- operation trust-chain JSON
- packet format parity
- schema contracts
- operator walkthroughs
- external legibility
- signed release provenance
- metadata-only business-flow records
- metadata-only business-flow evidence links
- metadata-only business-flow packets
- metadata-only business-flow packet verification
- optional Business Flow Evidence readiness integration
- Business Flow Evidence schema stabilization
- Business Flow Evidence JSON packet parity
- Business Flow Evidence finding and validation links
- Business Flow Evidence approval links
- Business Flow Evidence operation trust-chain visibility
- Business Flow Evidence retention links
- Business Flow Evidence flow-specific trust-chain visibility
- Business Flow Evidence assurance view
- archive packet JSON parity
- audit packet JSON parity
- closeout manifest JSON parity
- handoff packet JSON parity
- accepted-risk review packet JSON parity
- advisor prompt packet JSON parity
- release artifact manifest hardening
- SLSA-verifiable release artifact workflow
- retained SLSA reference verification
- official SLSA generic-generator alignment
- optional online SLSA attestation verification
- retained release-candidate SLSA evidence
- authenticated online SLSA attestation verification

## Near-Term Milestones

1. Trust infrastructure direction. Implemented as
   `docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md`.
2. Trust object model and schema consolidation. Implemented as
   `docs/atlas/TRUST_OBJECT_MODEL.md`.
3. Release replay command. Implemented as `atlas release replay`.
4. Metadata-only Business Flow Evidence packets. Implemented as
   `atlas flow packet`.
5. Business Flow Evidence verification. Implemented as `atlas flow verify`.
6. Optional Business Flow Evidence readiness integration. Implemented in
   `atlas v1 status` and `atlas production status` as non-blocking.
7. Flow record, flow link, and flow packet schema stabilization. Implemented as
   `atlas.business_flow.v1`, `atlas.business_flow_link.v1`,
   `atlas.flow_evidence_link.v1`, and `atlas.business_flow_packet.v1`
   contracts.
8. Business Flow Evidence JSON packet parity. Implemented as
   `atlas flow packet --json` and `atlas flow verify --json`.
9. Flow finding and validation links. Implemented as
   `atlas flow link-finding` and `atlas flow link-validation`.
10. Flow approval links. Implemented as `atlas flow link-approval`, with
    `atlas.flow_approval_link.v1` records and Markdown/JSON packet verification.
11. Flow operation trust-chain visibility. Implemented in
    `atlas op trust-chain` and `atlas op trust-chain --json` as non-blocking
    Business Flow Evidence link and packet counts.
12. Flow retention links. Implemented as `atlas flow link-retention`, with
    `atlas.flow_retention_link.v1` records and Markdown/JSON packet
    verification.
13. Flow-specific trust-chain command. Implemented as
    `atlas flow trust-chain` and `atlas flow trust-chain --json` with
    `atlas.business_flow_trust_chain.v1`.
14. Flow assurance view. Implemented as `atlas flow assurance` and
    `atlas flow assurance --json` with `atlas.business_flow_assurance.v1`,
    summarizing open linked findings, validation gaps, retention coverage, and
    packet verification state without making Business Flow Evidence required.
15. Archive packet JSON parity. Implemented as
    `atlas op archive-packet --json`, with `atlas.archive_packet.v1` and
    `atlas op archive-verify` support for Markdown or JSON packets.
16. Audit packet JSON parity. Implemented as
    `atlas op audit-packet --json`, with `atlas.audit_packet.v1` and
    `atlas op audit-verify` support for Markdown or JSON packets.
17. Closeout manifest JSON parity. Implemented as
    `atlas op closeout --json`, with `atlas.closeout_manifest.v1` and
    `atlas op verify` support for Markdown or JSON closeout manifests.
18. Handoff packet JSON parity. Implemented as
    `atlas op handoff --json`, with `atlas.handoff_packet.v1`.
19. Accepted-risk review packet JSON parity. Implemented as
    `atlas finding review-packet --json`, with
    `atlas.accepted_risk_review_packet.v1` and `atlas finding review-verify`
    support for Markdown or JSON packets.
20. Advisor prompt packet JSON parity. Implemented as
    `atlas advisor prompt --json`, with `atlas.advisor_prompt_packet.v1`.
21. Release artifact manifest hardening. Implemented as
    `atlas release manifest` and `atlas release manifest-verify`, with
    `atlas.release_artifact_manifest.v1`.
22. Production manifest gate. Implemented by requiring the latest verified
    release artifact manifest inside `atlas production status`.
23. Release artifact manifest completeness. Harden
    `atlas release manifest-verify` with generated commit/tag checks, required
    artifact classes, required paths, schema references, known limitations, and
    forbidden raw-content marker detection.
24. SLSA-verifiable release artifacts. Implemented as
    `.github/workflows/release-slsa.yml`, `docs/atlas/SLSA_PROVENANCE.md`, and
    `atlas.slsa_provenance.v1`. This prepares GitHub/Sigstore provenance for
    release artifacts without claiming external SLSA certification. A
    tag-triggered smoke run has verified artifact upload and attestation.
25. SLSA references in release manifests. Implemented as optional
    `atlas release manifest --slsa <reference>` support and manifest
    verification for retained `atlas.slsa_provenance.v1` references.
26. SLSA reference verification. Implemented as `atlas release slsa-verify`,
    a read-only local verifier for retained metadata-only SLSA references,
    expected source commits, artifact digests, workflow metadata, recorded
    attestation verification status, and no-certification-overclaim flags.
27. Official SLSA and online verification path. Implemented as
    `.github/workflows/release-slsa-generic.yml`, `docs/atlas/SLSA_CLAIM.md`,
    `docs/atlas/INDEPENDENT_REVIEW_READINESS.md`, and
    `atlas release slsa-verify --artifact --online`. This tightens the
    official builder path and makes the external verification/review steps
    explicit without claiming certification.
28. Retained release-candidate SLSA evidence. Implemented as
    `atlas-v0.4.0-rc1`,
    `docs/retention/releases/atlas-v0.4.0-rc1.slsa.json`, and retained
    `slsa-verifier verify-artifact` evidence for the official generic
    generator provenance.
29. Authenticated online SLSA attestation verification. Implemented by running
    `atlas release slsa-verify --artifact --online` after GitHub CLI
    authentication and retaining the successful online attestation result in
    `docs/retention/releases/atlas-v0.4.0-rc1.slsa.json`.

## Later Control-Plane Work

- get an independent release-trust review
- read-only dashboard planning
- node runtime planning
- reproducible runtime profile

## Future Research Tracks

- Atlas OS
- node enrollment and trust
- policy synchronization
- evidence synchronization
- Intentional Security Intelligence research
- user-space ISI runtime prototypes
- kernel-level research much later

## Rule

Atlas earns deeper layers by proving the current layer. Do not jump to Atlas
OS, ISI, kernel, fleet, SQL migration, autonomous features, or web execution
surfaces before the metadata-first trust infrastructure is stable and
verifiable.
