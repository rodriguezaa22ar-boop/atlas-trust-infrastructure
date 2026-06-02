# Capability Manifest Draft M172

## Purpose

M172 drafts the next Atlas capability manifest layer. It turns the proof model
into a governance model by naming the actions Atlas recognizes, the capability
class they belong to, the approval posture they require, the metadata evidence
they should emit, and the actions that must remain blocked.

This milestone is a manifest and documentation draft. It does not add runtime
enforcement, adapter execution, live integrations, a policy engine change, a
server, a database, or a new authority claim.

No runtime enforcement is added in M172.

## Relationship To Existing Governance

`capabilities.yaml` remains the machine-readable governance root. The existing
M124 capability model, M126 policy plane, M127 approval plane, M128 evidence
envelope, and M170 storage strategy remain in force.

M172 refines the vocabulary around actions that already matter to reviewers:

- receipt creation, verification, replay, and generic event import
- policy evaluation and approval request metadata
- release packet creation and release verification
- public export checks
- reviewer package generation
- evidence sufficiency review
- bounded agent tool execution as a governance contract only

## Manifest Fields

Each capability entry records:

- stable `id`
- `class`
- owning `system`
- affected `resources`
- possible `effects`
- required `approval`
- metadata `evidence.emits`

The manifest keeps `default_mode: deny`. Unknown capabilities remain
unsupported.

## Capability Classes

| Class | Meaning | Default governance posture |
| --- | --- | --- |
| `read` | Inspect local metadata or status. | No approval by default. |
| `import` | Convert local-file metadata into Atlas metadata. | No approval by default when import-only and metadata-only. |
| `verify` | Check proof envelopes, hashes, policy, or evidence status. | No approval by default. |
| `export` | Produce public or reviewer-facing metadata packages. | Constrained to declared export/reviewer boundaries. |
| `mutate` | Write Atlas metadata artifacts. | Approval metadata required by capability contract. |
| `bounded_exec` | Execute approved bounded tools. | Approval metadata required; governance contract only unless runtime exists. |
| `admin` | Change privileged Atlas or environment state. | Approval metadata required. |

## Draft Action Map

| Capability | Class | Approval | Evidence emitted |
| --- | --- | --- | --- |
| `atlas.status.read` | `read` | `none` | decision, status result |
| `atlas.policy.evaluate` | `verify` | `none` | policy decision, policy ref, approval requirement, reason |
| `atlas.approval.request` | `mutate` | policy threshold low | approval event ref, requester, approver, expiry |
| `atlas.receipt.create` | `mutate` | policy threshold low | receipt ref, event hash, receipt hash, known limitations |
| `atlas.receipt.verify` | `verify` | `none` | verification result, receipt hash, known limitations |
| `atlas.receipt.replay` | `verify` | `none` | replay result, caller-provided chain order, known limitations |
| `atlas.receipt.import_generic_event` | `import` | `none` | source ref, generated receipt ref, receipt hash, known limitations |
| `atlas.release.packet` | `mutate` | change control high | release packet ref, readiness ref, known limitations |
| `atlas.release.verify` | `verify` | `none` | manifest ref, verification result |
| `atlas.production.verify` | `verify` | `none` | verification result, not-ready reason |
| `atlas.public_export.check` | `export` | `none` | export manifest ref, boundary result |
| `atlas.reviewer.package` | `export` | `none` | package manifest ref, retained evidence refs, known limitations |
| `atlas.evidence.sufficiency.review` | `verify` | `none` | present, missing, stale, unverifiable, outside Atlas |
| `atlas.adapter.import` | `import` | `none` | source ref, artifact hash |
| `atlas.agent.tool.exec` | `bounded_exec` | policy threshold medium | tool ref, input hash, output hash |

## Approval Requirements

M172 preserves the existing rule: mutating, bounded execution, and admin
capabilities must not use `approval: none`.

The manifest can say that approval is required. It does not by itself prove
that approval was granted. Approval evidence must be represented by
metadata-only approval events and evaluated through the policy plane.

## Evidence Requirements

Every recognized action must emit metadata evidence. The evidence should answer:

- who requested the action
- what capability was requested
- what policy decision applied
- whether approval was required
- what metadata artifact was emitted
- how a reviewer can verify or replay it
- what limitations remain

Evidence remains metadata-only. It may include references, hashes, timestamps,
commit IDs, status values, and known limitations. It must not include raw logs,
secrets, private keys, tokens, packet captures, raw prompts, raw model outputs,
request bodies, response bodies, customer data, or unredacted evidence bodies.

## Blocked Actions

These actions remain outside the recognized Atlas capability set:

- autonomous exploitation
- persistence
- destructive testing
- credential spraying
- denial-of-service workflows
- stealth or evasion behavior
- out-of-scope target expansion
- malware-like behavior
- unauthorized access
- live GitHub API collection for the current receipt candidates
- webhook server collection for the current receipt candidates
- hidden database authority
- hosted verifier authority replacing local verification
- raw sensitive data storage by default

If a future milestone needs one of these areas for an authorized workflow, it
must define a separate capability, policy, approval, evidence, and safety
contract first.

## Reviewer Interpretation

Atlas supports reviewer understanding by making actions named and reviewable.
The manifest helps reviewers see what Atlas recognizes and which evidence
should exist for a given action.

The manifest does not prove that an action happened outside Atlas. It does not
prove complete event coverage, legal sufficiency, certification, external audit
completion, production deployability, runtime safety, model correctness, or
tamper-proof infrastructure.

## Future Work

Future milestones may add:

- schema expansion for explicit blocked capability lists
- adapter permission registry refinement
- policy fixture coverage for new capability classes
- approval workflow expansion for release packet and receipt creation
- receipt evidence linking for capability decisions
- reviewer-facing capability summary output
- runtime enforcement only after manifest, policy, approval, evidence, and
  reviewer packet contracts stabilize

## Validation

Run:

```bash
./bin/dev-capabilities
nix-shell --run 'bats --print-output-on-failure tests/atlas.bats --filter "M172|Capability Manifest Draft"'
./bin/export-public-trust --check
nix-shell --run './bin/dev-qa'
```

Expected capability validator output:

```text
capabilities: ok
```
