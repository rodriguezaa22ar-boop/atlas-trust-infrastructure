# Policy Plane Draft M176

## Purpose

M176 defines the first Atlas policy-plane draft. It describes how Atlas can
model capability, adapter, approval, and evidence decisions before any new
runtime policy enforcement exists.

The draft policy plane lives at `policy/policy-plane.yaml`.

## Why Atlas Needs A Policy Plane

Atlas is a metadata-first trust overlay. Capabilities name what kind of action
is being requested, adapters identify external-system metadata boundaries,
approvals record human review when needed, and evidence records what can be
checked later.

The policy plane connects those contracts so reviewers can see what decision
was modeled, what context was required, what evidence should exist, and what
remains outside Atlas. This supports clearer review, fewer ambiguous decisions,
safer future connectors, lower evidence reconstruction work,
privacy-preserving governance, stronger audit readiness, and a lower cost of
trust without lowering standards.

## Governance Contract, Not Runtime Enforcement

The policy plane is a governance contract, not runtime enforcement. M176 does
not add runtime policy enforcement.

M176 does not add a policy engine, OPA/Rego runtime execution, Cedar runtime
execution, live integrations, credentials, API calls, webhooks, network
collectors, mutation, an approval engine, a database, a server, or a web UI.

The policy plane does not grant authorization by itself. Future runtime
enforcement must be added explicitly in a later milestone and must remain
capability-named, adapter-aware, approval-aware, evidence-emitting, and
metadata-only.

Existing external systems remain the source of their own operational truth.
Atlas records proof metadata around them.

## Policy Inputs

M176 models these decision inputs:

- `actor`
- `capability`
- `adapter`
- `action`
- `resource`
- `scope`
- `risk_tier`
- `approval_state`
- `evidence_refs`
- `request_context`

These inputs are decision context. They do not make an action authorized or
executed by themselves.

## Policy Decision Vocabulary

M176 drafts this decision vocabulary:

- `allow`
- `deny`
- `approval_required`
- `evidence_required`
- `unsupported`
- `unknown_capability`
- `unknown_adapter`
- `boundary_violation`

The vocabulary is for review and future policy alignment. It does not mean a
runtime policy engine is active.

## Default-Deny Posture

The draft uses `default_decision: deny`. Unknown capabilities, unknown
adapters, unsupported requests, missing required context, and boundary
violations should fail closed in the model.

## Relationship To `capabilities.yaml`

Policy requests should reference known capability IDs from `capabilities.yaml`.
A known capability can describe class, approval posture, resources, effects,
and evidence expectations. It does not grant authorization by itself.

## Relationship To `adapters/registry.yaml`

Adapter-bound requests should reference known adapter IDs from
`adapters/registry.yaml`. Adapter registry entries identify external-system
metadata boundaries, modes, capabilities, evidence outputs, forbidden inputs,
and known limitations.

The policy plane preserves import/read/verify/export/propose separation. It
does not make adapters live.

## Relationship To Future Approval Plane

Future state-changing proposals should return `approval_required` unless
verified approval metadata exists in a later implementation.

M176 does not add approval execution. Approval metadata remains a separate
contract.

## Relationship To Future Evidence Envelope

Policy decisions should declare evidence outputs or explain missing evidence.
Evidence remains referential and hash-based. The future evidence envelope can
bind policy decisions to receipts, reviewer packages, release trust, or
evidence sufficiency reports.

## Initial Policy Bundles

M176 drafts these policy bundles:

| Bundle | Purpose |
| --- | --- |
| `atlas.default_deny` | Default deny for unknown, unsupported, missing-context, or boundary-violating requests. |
| `atlas.known_capability_required` | Require capability-bound requests to reference `capabilities.yaml`. |
| `atlas.known_adapter_required` | Require adapter-bound requests to reference `adapters/registry.yaml`. |
| `atlas.metadata_only_boundary` | Preserve forbidden raw-data boundaries. |
| `atlas.import_first_adapters` | Preserve read/import/verify/export/propose adapter separation. |
| `atlas.propose_requires_approval_path` | Require approval path before future state-changing execution. |
| `atlas.ai_agent_requester_not_authority` | Treat AI agents as requesters, not authorization authorities. |
| `atlas.release_verify_read_only` | Preserve release verification as read-only. |
| `atlas.public_export_boundary` | Preserve metadata-only and private-marker-clean public export behavior. |
| `atlas.evidence_required_for_decision` | Require evidence outputs or a missing-evidence explanation. |

## What Policy Decisions May Record

Policy decisions may record metadata such as:

- actor label
- capability ID
- adapter ID
- action label
- resource reference
- scope label
- risk tier
- approval state
- evidence references
- decision output
- known limitations

## What Policy Decisions Must Not Store

Policy decisions must not store:

- raw logs
- secrets
- private keys
- credentials
- tokens
- Authorization headers
- request bodies
- response bodies
- packet captures
- raw prompts
- raw model outputs
- customer data
- payment data
- private business records
- unredacted evidence bodies

## Metadata-Only Boundary

Policy decisions are metadata-only. They may point to references and hashes,
but they must not embed raw sensitive material.

Approval state does not override the metadata-only boundary. Evidence present
does not automatically mean evidence sufficient.

## AI-Agent Requester-Not-Authority Rule

AI-agent events can be request context or evidence sources. They are not
authorization authorities and cannot approve their own requests.

Atlas does not prove model correctness.

## Release Verification Read-Only Rule

Release verification remains read-only. Policy modeling may require release
metadata references, retained evidence, hashes, or verification results, but it
does not mutate releases or prove artifact correctness guarantees.

## Public/Private Export Boundary

Public export remains metadata-only and private-marker clean. Public proof
packages must not include private runtime state, secrets, raw evidence bodies,
or private business records.

## Reviewer/Auditor Value

The policy plane helps reviewers understand:

- which capability was requested
- whether the adapter was known
- whether approval should be required
- which evidence outputs were expected
- whether a boundary violation occurred
- what still needs human judgment

This reduces ambiguous decisions without lowering standards.

## Known Limitations

- M176 is a draft policy-plane contract for review, testing, and governance
  alignment.
- No runtime policy enforcement is implemented.
- No policy engine is implemented.
- No OPA/Rego runtime execution is added.
- No Cedar runtime execution is added.
- No live integration is added.
- No credentials, API calls, webhooks, network collectors, or mutation are
  added.
- No approval execution is added.
- No production policy enforcement is claimed.
- The policy plane does not prove compliance, certification, external audit
  completion, enterprise deployment approval, complete event coverage, runtime
  safety, model correctness, or artifact correctness.
- The policy plane does not prove that actions outside Atlas did not happen.
- Reviewer judgment remains required.

## Future Milestones

Future milestones may add:

- policy plane safety regression
- policy fixture expansion
- adapter-policy matrix
- approval-policy matrix
- evidence-policy binding
- reviewer-facing policy decision summary
- signed policy bundle contract
- runtime policy enforcement contract only after capability, adapter,
  approval, evidence, and reviewer packet contracts stabilize

## Validation

Run:

```bash
./bin/dev-policy
./bin/dev-governance
nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "M176|Policy Plane Draft"'
./bin/export-public-trust --check
nix-shell --run './bin/dev-qa'
```

Expected policy validator output:

```text
policy: ok
```
