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
11. Flow retention links and flow trust-chain integration.
12. JSON parity for archive and audit packets where needed.

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
