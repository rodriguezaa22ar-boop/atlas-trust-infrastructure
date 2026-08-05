# Atlas Language Security Model

## Authority Boundary

Source requests authority but never grants it. The external
[`capabilities.yaml`](../../capabilities.yaml) manifest remains authoritative
for recognized capability meaning and posture. Source cannot define a
capability, approve itself, alter policy, register an adapter, widen scope, or
declare an action authorized.

Agents are requesters, not authorities. A model cannot approve its own step,
change an immutable plan, select undeclared capabilities, or bypass a denial.

## Current Policy Baseline

The implemented Atlas runtime evaluator is the Shell/JQ logic in
[`tools/atlas/lib/policy.sh`](../../tools/atlas/lib/policy.sh).
[`policy/atlas.authz.rego`](../../policy/atlas.authz.rego) is currently a
validated policy contract/reference, not the runtime authority. Making a Rego
bundle authoritative is a future target state that requires an explicit
migration milestone, parity tests, and a single source-of-truth decision.

AL-001 changes no policy behavior.

## Fail-Closed Source Rules

- Unknown language versions, fields, capabilities, policies, providers,
  adapters, and schemas are rejected.
- Source contains no arbitrary shell command, executable path, `eval`, command
  substitution, environment expansion, or dynamic code loading.
- Paths are workspace-relative and must not traverse or escape through
  symlinks.
- Credentials and secret values are forbidden. A later language may use
  opaque secret references only.
- Raw goals, prompts, model output, customer data, and private artifacts are
  not embedded in public plans or receipts.
- A registered adapter is bound to explicit capabilities, filesystem scope,
  network scope, limits, and a known implementation identity.
- Unknown output fields and unsupported contract versions fail closed.

## Required Later Controls

Any future execution path must independently verify plan and input identity,
policy decision, approval binding and expiry, adapter registration, workspace
paths, egress restrictions, time/attempt/token limits, and cancellation. It
must treat model output as untrusted data, validate structured output before
downstream use, hash artifacts promptly, append events safely, and write
records atomically.

Approvals must later bind the precise plan, step, inputs, target, policy
decision, approver, and expiry. A changed or expired binding must be rejected.

## Proof Boundary

Atlas may later verify schema validity, referenced contract identity, hash
linkage, approval metadata, adapter identity, artifact references, and event
continuity. It does not thereby prove factual correctness, legal authority,
complete event coverage, model correctness, external-system truth, compliance,
or tamper-proof storage.

## AL-001 Security Posture

AL-001 is non-executing. It introduces no parser, compiler, adapter, network
request, credential handling, model invocation, approval engine, or runtime
state. The synthetic fixture is not an authorization and cannot be executed.
