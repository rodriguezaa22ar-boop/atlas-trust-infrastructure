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

## Near-Term Milestones

1. Trust infrastructure direction. Implemented as
   `docs/atlas/TRUST_INFRASTRUCTURE_DIRECTION.md`.
2. Trust object model and schema consolidation. Implemented as
   `docs/atlas/TRUST_OBJECT_MODEL.md`.
3. Metadata-only Business Flow Evidence packets.
4. Business Flow Evidence verification.
5. Optional Business Flow Evidence readiness integration.
6. Flow record, flow link, and flow packet schema stabilization.
7. JSON parity for archive, audit, and business-flow packets where needed.

## Later Control-Plane Work

- broader JSON packet parity
- stable schema documents for every trust packet
- signed/provenance hardening beyond local signed tags
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
