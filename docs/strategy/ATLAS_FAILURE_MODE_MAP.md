# Atlas Failure-Mode Map

## Purpose

This map translates common startup failure lessons into Atlas-specific risks
and safeguards.

It is a strategy document, not a new runtime contract. It adds no execution
surface, scanner behavior, CI/CD integration, ticketing workflow, GRC workflow,
or agent autonomy.

Atlas should become more useful by becoming more verifiable, not by making
stronger claims than the evidence supports.

## Boundary

Atlas is a shell-native control plane for authorized security assessment
workflows. It coordinates proof metadata around scope, evidence, findings,
validation, reporting, retention, receipts, and release trust.

This document does not claim that Atlas is production-certified, externally
audited, compliance-certified, tamper-proof, autonomous, or complete. It
describes failure modes to keep visible while Atlas is still in internal
testing, refinement, and trust hardening.

## Failure-Mode Map

| Startup failure lesson | Atlas risk if unhandled | Atlas safeguard |
| --- | --- | --- |
| Tell the market what is true, not what sounds fundable. | Atlas language drifts from ready-to-refine into production-certified, audit-certified, or autonomous claims. | Use bounded language: metadata-only, verifier-backed, local-first, ready-to-refine, release-trust candidate, and known limitations. Keep non-guarantees in verifiers and docs. |
| Do not confuse a convincing demo with a durable product. | Demo operations become proof theater if they cannot be replayed, inspected, or bounded. | Keep demo records synthetic and metadata-only. Link demo walkthroughs to retained packets, receipts, release verification, and clean reviewer commands. |
| Do not let private state become the product truth. | Public reviewers cannot distinguish public proof from private operator history. | Preserve the public/private repository split. Keep raw runtime state, private targets, secrets, and host-specific details out of this repository. Enforce the public export manifest. |
| Avoid feature spread before the core contract is reliable. | Atlas becomes a loose collection of commands instead of a trust control plane. | Prefer file-backed contracts, small command grammar, schemas, receipts, release packets, replay, and focused tests before adding new surfaces. |
| Do not ship authority without accountability. | Validation or action paths could be interpreted as permission, approval, or authorization. | Keep scope records, capability tiers, policy decisions, approval gates, ledger events, and evidence handling explicit. Atlas records operator intent; it does not grant authorization. |
| Do not hide failure behind optimistic status text. | Readiness and production gates become marketing labels instead of verifiers. | `atlas v1 status` remains internal readiness. `atlas production status` remains stricter and evidence-blocked when required proof is missing. |
| Do not trust a receipt that carries the raw thing it claims to prove. | Receipts become artifact storage, leak private data, or imply artifact correctness. | Atlas Receipt v1 is metadata-only. `metadata_only` must be true, `raw_artifacts_embedded` must be false, and known limitations are required. |
| Do not make read-only review commands mutate state. | A reviewer command changes the tree it is supposed to inspect, weakening clean-clone review. | Read-only commands must avoid runtime initialization. Regression tests cover source/archive behavior for status, receipt, release, production, and export checks. |
| Do not let retained evidence silently rot. | Release trust, replay, and production readiness point to stale or mismatched artifacts. | Retain milestone notes, release packets, artifact manifests, replay results, SLSA references, and known limitations with verification commands. |
| Do not let dependency convenience become a portability claim. | Host-specific tools or Nix-only assumptions are mistaken for universal support. | Keep the Nix shell as the reference environment, document host-shell dependencies, and separate source archive checks from full clone checks. |
| Do not make AI sound like an operator. | Advisor output could be mistaken for authorization, execution, or independent judgment. | Treat AI as an Advisor Packet Interface only: summaries, prompts, and drafting support. No autonomous execution, scope expansion, or approval bypass. |
| Do not bury negative evidence. | Reviewers miss what Atlas does not prove. | Keep known limitations close to every proof surface: receipts, release packets, production status, review packets, demos, and public docs. |

## Safeguard Classes

Atlas safeguards should stay concrete and reviewable:

- **Language safeguards:** bounded claims, explicit non-guarantees, and
  documented known limitations.
- **State safeguards:** file-backed records, metadata-only packets, hashes,
  schemas, and retained milestone notes.
- **Command safeguards:** predictable grammar, read-only commands that remain
  read-only, approval-gated validation, and fail-closed verifiers.
- **Repository safeguards:** public/private boundary, export manifest checks,
  clean-clone review paths, and source archive portability checks.
- **Review safeguards:** focused Bats tests, `git diff --check`, full local QA,
  release verification, replay verification, and retained review packets.

## Design Pressure

When a new Atlas idea appears, ask these questions before implementation:

1. Does it make scope, evidence, verification, retention, or release trust
   clearer?
2. Can a reviewer replay or inspect the claim without private runtime state?
3. Is it metadata-only where the public trust repository requires
   metadata-only records?
4. Does it preserve operator control and approval boundaries?
5. Does the verifier state what it does not prove?
6. Does the feature fail closed when required proof is missing?
7. Does the documentation describe implemented behavior instead of desired
   future behavior?

If the answer is unclear, keep the idea in strategy or roadmap form until the
contract, verifier, and tests are ready.

## Non-Goals

This map is not:

- a fundraising narrative
- a market-positioning claim
- a legal compliance claim
- a production-readiness claim
- an external audit claim
- a request to add autonomous execution
- a request to add a web UI or server layer
- a replacement for `docs/KNOWN_LIMITATIONS.md`

The useful direction is narrower: make Atlas failure modes visible early, then
bind each important claim to metadata, verification, replay, and retained
limitations.
