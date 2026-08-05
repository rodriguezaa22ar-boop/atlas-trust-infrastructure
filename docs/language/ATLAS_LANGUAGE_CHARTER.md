# Atlas Language Charter

## Status

This document defines the AL-001 charter for a candidate Atlas Language. AL-001
adds public documentation, a candidate execution-plan contract, and synthetic
fixtures only. It does not add a parser, compiler, runtime, adapter, policy
behavior, approval enforcement, model invocation, or execution command.

## Mission

Atlas Language is a declarative language for describing governed digital
workflows that compile into inspectable execution plans and, in later
milestones, produce metadata-only proof receipts.

The language describes intent. Atlas evaluates whether that intent may run and
records the proof boundary around any later execution.

## North Star

```text
source intent
  -> deterministic execution plan
  -> external capability and policy evaluation
  -> independent approval when required
  -> registered bounded adapter
  -> private runtime artifacts
  -> metadata-only events and receipt
  -> independent verification and replay
```

## Architectural Invariants

- Default deny: unknown fields, versions, capabilities, policies, adapters, and
  actions fail closed.
- Source requests authority; it never grants authority.
- Agents are requesters, not approvers or policy authorities.
- Parsing, checking, compiling, explaining, and verifying do not execute a
  workflow.
- Compiling does not grant permission, and a plan does not grant permission.
- Execution is explicit and is not implemented by AL-001.
- Adapters must be registered and capability-bound; source cannot name an
  arbitrary executable or shell command.
- External side effects must later emit events and contribute to a receipt.
- Plans and receipts exclude secrets and raw private artifacts.
- Unknown contract versions fail closed.
- Inspectable contracts remain authoritative; derived indexes and interfaces do
  not become hidden sources of truth.
- Verification makes bounded claims about structure, linkage, and evidence. It
  does not certify correctness, legality, compliance, or authorization.

## Non-Goals

Atlas Language is not a general-purpose programming language, shell
replacement, operating system, free-form agent framework, hidden automation
engine, autonomous security-testing system, or compliance certification
system. Version 0.1 does not include arbitrary commands, dynamic loading,
recursion, unbounded loops, packages, parallel execution, or self-modifying
workflows.

## Maturity

The AL-001 artifacts are design contracts for review. The example plan is a
candidate structural fixture, not compiler output and not evidence of portable
canonicalization or cross-platform determinism. An authoritative `plan_hash`
is deferred until a later milestone freezes the canonical byte contract and
publishes golden vectors.

The public/private source and runtime boundary is owned by
[../REPOSITORY_BOUNDARY.md](../REPOSITORY_BOUNDARY.md). This charter does not
create a separate repository-boundary contract.
