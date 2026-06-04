# Approval Plane Draft M178

## Purpose

M178 defines the first Atlas approval-plane draft. It models approval states,
reviewer roles, expiration, rejection, escalation, break-glass documentation,
and approval evidence outputs before any new approval engine or workflow
execution exists.

The draft approval-plane contract lives at `approval/approval-plane.yaml`.

## Why Atlas Needs An Approval Plane

Atlas already models capabilities, adapters, and policy decisions. The approval
plane explains how a future reviewer can see when human review was required,
who reviewed the request, what state the review reached, what evidence was
retained, and what still requires judgment outside Atlas.

This supports clearer review, fewer ambiguous approvals, safer future
workflows, lower evidence reconstruction work, privacy-preserving governance,
stronger audit readiness, and a lower cost of trust without lowering standards.

## Governance Contract, Not Workflow Execution

The approval plane is a governance contract, not workflow execution. M178 does
not add approval engine execution. M178 does not execute approval workflows.
M178 does not add automatic approval. M178 does not add break-glass execution.
M178 does not add live integrations.

Boundary summary:

- M178 does not add approval engine execution.
- M178 does not execute approval workflows.
- M178 does not add automatic approval.
- M178 does not add automatic escalation.
- M178 does not add break-glass execution.
- M178 does not add live integrations.
- M178 does not add credentials.
- M178 does not add API calls.
- M178 does not add webhooks.
- M178 does not add network collectors.
- M178 does not add mutation authority.

M178/M179 do not add approval engine execution.
M178/M179 do not execute approval workflows.
M178/M179 do not add automatic approval.
M178/M179 do not add automatic escalation.
M178/M179 do not add break-glass execution.
M178/M179 do not add credentials.
M178/M179 do not add API calls.
M178/M179 do not add webhooks.
M178/M179 do not add network collectors.
M178/M179 do not add mutation authority.

M178 does not add credentials, API calls, webhooks, network collectors, or
mutation authority. M178 does not add a database, server, web UI, policy engine
execution, adapter execution, or receipt semantic changes.

M178 is a draft approval-plane contract for review, testing, and governance
alignment. Future approval enforcement must be added explicitly. Future
approval enforcement must remain capability-named. Future approval enforcement
must remain policy-aware. Future approval enforcement must remain
evidence-emitting. Future approval enforcement must remain metadata-only.
Approval state must remain tied to capability, policy, evidence, and scope.

Future approval enforcement:

- must remain capability-named
- must remain policy-aware
- must remain evidence-emitting
- must remain metadata-only

Existing external systems remain the source of their own operational truth.
Atlas records approval proof metadata around them.

## Approval States

The draft approval vocabulary is:

- `not_required`
- `required`
- `requested`
- `approved`
- `rejected`
- `expired`
- `revoked`
- `stale`
- `escalated`
- `unsupported`
- `boundary_violation`

These states are review metadata. They do not execute actions and do not grant
authorization by themselves.

## Approval Workflow Vocabulary

Each draft workflow records:

- the capability and adapter context that may trigger review
- the review objective
- whether approval is required
- minimum reviewer count
- approver roles
- expiration expectations
- reapproval triggers
- decision outputs
- evidence references required
- metadata-only and non-execution boundaries
- known limitations

## Relationship To `capabilities.yaml`

The capability manifest names recognized actions and their classes. The
approval plane does not replace it. Approval workflows refer to capability
names so review requirements can remain capability-aware.

## Relationship To `adapters/registry.yaml`

The adapter registry describes non-live, metadata-only adapter contracts. The
approval plane refers to adapter IDs where a future approval workflow depends
on an adapter-sourced event or proposal. This does not make adapters live.

## Relationship To `policy/policy-plane.yaml`

The policy plane can model decisions such as `approval_required` and
`boundary_violation`. The approval plane describes what approval state and
evidence would support a later review. Policy decisions and approval records do
not grant authorization by themselves.

## Relationship To Future Evidence Envelope

Approval evidence should be emitted as metadata references, hashes, statuses,
reviewer labels, timestamps, and known limitations. A future evidence envelope
can bind those outputs to receipt chains and reviewer packets without embedding
raw sensitive content.

## Who Can Approve

Approvers are role labels and reviewer identities appropriate to the workflow,
such as release reviewer, security reviewer, service owner, engineering
leader, business owner, incident owner, or operator. AI agents are requesters,
not authorities.

AI agents are requesters, not authorities.

## What Approval Can Support

Approval metadata can support a reviewer decision that a named person or role
reviewed a named request within a stated scope and time window, with referenced
evidence and stated limitations.

Approval records support review, not replace reviewer judgment.

## What Approval Does Not Prove

Approval records do not grant authorization by themselves. Approval records do
not prove the action was valid. Approval records do not prove legal compliance.
Approval records do not prove legal sufficiency. Approval records do not prove
production deployability. Approval records do not prove enterprise deployment
approval. Approval records do not prove complete event coverage. Approval
records do not prove actions outside Atlas did not happen.

Approval records do not prove:

- Approval records do not prove the action was valid.
- Approval records do not prove legal compliance.
- Approval records do not prove legal sufficiency.
- Approval records do not prove production deployability.
- Approval records do not prove enterprise deployment approval.
- Approval records do not prove complete event coverage.
- Approval records do not prove actions outside Atlas did not happen.

Approval records do not prove runtime safety, model correctness, artifact
correctness, certification, external audit completion, or enterprise
deployment approval.

## Expiration And Stale Approval Handling

Approval workflows include expiration expectations. Expired approval means the
review window closed. Stale approval means relevant context changed after the
review, such as a changed commit, changed ticket state, changed cloud resource,
changed risk tier, changed business-flow owner, changed evidence status, or
changed public/private boundary result.

Approval can expire. Approval can be revoked. Changed scope, changed evidence,
or changed action may require reapproval.

Expired approval means the review window closed.
Stale approval means relevant context changed.
Reapproval is required when the reviewed context changes.
Changed scope, changed evidence, or changed action may require reapproval.

## Reapproval Triggers

Reapproval is required when the reviewed context changes in a way that could
alter the decision. Examples include changed scope, changed risk tier, changed
resource reference, changed release trust packet, changed evidence status,
changed reviewer objective, changed proposal rationale, or an expired review
window.

## Rejection Handling

Rejected approval is a decision state that should retain the reviewer identity
reference, decision status, reason reference, evidence references, and known
limitations. Rejection does not execute rollback and does not mutate external
systems.

## Escalation Handling

Escalation records that the reviewer path needs a higher role, more reviewers,
or more evidence. Escalation is metadata-only. It does not page, ticket, notify,
or execute any live workflow in M178. Escalation is not automatic approval.

## Break-Glass Boundary

The M178 break-glass workflow is documentation and review only, not execution.
M178 does not add break-glass execution. Break-glass records can describe the
event, owner, reviewers, evidence references, decision status, and known
limitations, but they do not authorize or perform emergency access.

Break-glass workflow is documentation/review only. Break-glass workflow does
not execute recovery or emergency actions. Break-glass workflow requires
retained evidence or explanation. Break-glass does not bypass future evidence
requirements. Break-glass does not prove legal or production sufficiency.

Break-glass workflow does not execute recovery or emergency actions.
Break-glass workflow requires retained evidence or explanation.
Break-glass does not bypass future evidence requirements.
Break-glass does not prove legal or production sufficiency.

## Metadata-Only Approval Evidence

Approval evidence may store:

- reviewer identity references
- approver role labels
- timestamps
- scope references
- capability and adapter IDs
- decision statuses
- reason references
- evidence references
- hashes
- known limitations

Approval evidence must not store raw logs, secrets, private keys, tokens,
Authorization headers, request bodies, response bodies, packet captures, raw
prompts, raw model outputs, customer data, payment data, private business
records, or unredacted evidence bodies.

## Reviewer/Auditor Value

M178 gives reviewers a single vocabulary for approval status and evidence
expectations. It makes future approval workflows easier to inspect without
making Atlas an approval engine. The value is clearer review, fewer ambiguous
approvals, safer future workflows, lower evidence reconstruction work,
privacy-preserving governance, stronger audit readiness, and lower cost of
trust without lowering standards.

## Known Limitations

- M178 does not add an approval engine.
- M178 does not execute approval workflows.
- M178 does not add automatic approval.
- M178 does not add break-glass execution.
- M178 does not add live integrations.
- M178 does not add credentials, API calls, webhooks, network collectors, or
  mutation.
- M178 does not add policy engine execution or adapter execution.
- M178 does not make approval records legal, production, compliance, or
  certification evidence by themselves.
- M178 does not prove complete event coverage or external truth.

## Future Milestones

- Approval Plane Safety Regression.
- Approval evidence envelope draft.
- Approval request/review packet draft.
- Approval expiration and stale-review report.
- Approval replay summary.
- Approval integration contract, still non-live until explicitly implemented.
- Approval engine contract, only after governance and evidence contracts
  stabilize.
