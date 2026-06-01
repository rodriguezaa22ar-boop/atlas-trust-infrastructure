# Adoption Friction Dry-Run M167

## Purpose

Atlas supports adoption review by retaining a dry-run path that tests whether a
new reviewer or operator can follow the one-day CI release review workflow
without live help from the builder.

M167 checks friction, clarity, and usability. It asks whether a new reader can
find the starting point, run the local commands, understand receipt verify and
replay output, read the evidence sufficiency status, use the reviewer decision
packet, and explain where human judgment remains required.

This is a retained internal dry-run. It is not an external usability study and
does not prove external user success.

## Reviewer Persona

Use these personas for the dry-run:

- new engineer who can clone a repository and run shell commands;
- release reviewer who needs to understand one CI release candidate;
- security reviewer who cares about metadata-only evidence and replay;
- manager/auditor-style reader who needs a plain-English result and a bounded
  decision path.

The reviewer should not need the builder standing beside them. The repository
and docs should provide the path.

## Starting Point

Start with the public navigation and adoption workflow:

- [../INDEX.md](../INDEX.md)
- [../PUBLIC_TRUST_SURFACE.md](../PUBLIC_TRUST_SURFACE.md)
- [../workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md](../workflows/ORG_CI_RELEASE_REVIEW_WORKFLOW_M164.md)
- [REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md](REVIEWER_PLAIN_ENGLISH_OUTPUT_M166.md)
- [REVIEWER_DECISION_PACKET_M160.md](REVIEWER_DECISION_PACKET_M160.md)
- [EVIDENCE_SUFFICIENCY_REPORT_M158.md](EVIDENCE_SUFFICIENCY_REPORT_M158.md)
- [GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md)
- [../TRY_RECEIPTS.md](../TRY_RECEIPTS.md)
- [../TRY_GENERIC_EVENT_ADAPTER.md](../TRY_GENERIC_EVENT_ADAPTER.md)

The dry-run scenario is one CI release review using local GitHub Actions
run/check metadata examples. It does not use the GitHub API, a webhook, a
network collector, a database, a server, or a new adapter.

## Fresh-Clone Setup

The reviewer starts from a fresh clone:

```bash
git clone <repo> atlas-review
cd atlas-review
```

Then confirm the public proof surface can be checked locally:

```bash
nix-shell --run './bin/dev-qa'
nix-shell --run './bin/export-public-trust --check'
```

Expected output shape:

```text
qa: ok
Public Trust Export
Overall: ok
```

What the reviewer should understand:

- the repository has a local QA gate;
- the public export contract can be checked without private context;
- these checks do not make a production or compliance claim.

## Commands Run

### Receipt Quickstart

```bash
nix-shell --run './tools/atlas/bin/atlas receipt verify examples/receipt/minimal.json'
nix-shell --run './tools/atlas/bin/atlas receipt replay examples/receipt/demo-site/*.json'
```

Expected output shape:

```text
ok: receipt verified
ok: receipt chain replay verified
```

What the reviewer should understand:

- `receipt verify` checks one receipt's structure and hashes;
- `receipt replay` checks that linked receipts connect in expected order;
- the output is proof-envelope verification, not a claim that every outside
  event happened.

### Generic Adapter Quickstart

```bash
nix-shell --run './tools/atlas/bin/atlas receipt import-generic-event examples/adapters/generic-external-event/minimal-event.json --out /tmp/generic-event.atlas.json'
nix-shell --run './tools/atlas/bin/atlas receipt verify /tmp/generic-event.atlas.json'
```

Expected output shape:

```text
ok: generic event receipt written
ok: receipt verified
```

What the reviewer should understand:

- Atlas imports local files only;
- the adapter writes a metadata-only receipt;
- raw logs, secrets, tokens, prompts, request bodies, response bodies, and full
  terminal dumps remain outside the receipt.

### CI Release Review Scenario

```bash
nix-shell --run './tools/atlas/bin/atlas receipt import-generic-event examples/adapters/generic-external-event/github-actions-run-event.json --out /tmp/github-actions-run.atlas.json'
nix-shell --run './tools/atlas/bin/atlas receipt verify /tmp/github-actions-run.atlas.json'
nix-shell --run 'prev_hash="$(jq -r ".event_hash" /tmp/github-actions-run.atlas.json)" && ./tools/atlas/bin/atlas receipt import-generic-event examples/adapters/generic-external-event/github-actions-check-event.json --prev-hash "$prev_hash" --out /tmp/github-actions-check.atlas.json'
nix-shell --run './tools/atlas/bin/atlas receipt verify /tmp/github-actions-check.atlas.json'
nix-shell --run './tools/atlas/bin/atlas receipt replay /tmp/github-actions-run.atlas.json /tmp/github-actions-check.atlas.json'
```

Expected output shape:

```text
ok: generic event receipt written
ok: receipt verified
ok: receipt chain replay verified
```

What the reviewer should understand:

- the run/check examples represent local GitHub Actions metadata;
- Atlas verifies the generated proof receipts and linked replay order;
- the scenario supports a bounded CI release review, not a live GitHub
  integration.

## Expected Outputs

The retained dry-run expects the reviewer to collect this plain summary:

```text
review_objective: one CI release review from local GitHub Actions metadata
first_verify: pass
first_replay: pass
github_actions_run_receipt: present
github_actions_check_receipt: present
linked_replay: present
evidence_sufficiency:
  ci_event_metadata: present
  approval_record: missing | present | stale | unverifiable
  release_notes: missing | present | stale | unverifiable
supported_decision:
  proceed with internal review when required evidence is present
unsupported_decision:
  do not treat the receipt chain as compliance, legal sufficiency, complete
  event knowledge, or business approval
human_judgment:
  reviewer still decides whether the evidence and limitations satisfy the
  release-review objective
```

## Evidence Reviewed

The dry-run reviews these existing Atlas surfaces:

- M164 organization CI release review workflow;
- M166 reviewer plain-English output;
- M160 reviewer decision packet;
- M158 evidence sufficiency report;
- M153 GitHub Actions event proof package;
- public trust surface;
- receipt and generic adapter quickstarts;
- local GitHub Actions run/check examples.

## Plain-English Summary Reviewed

The reviewer should be able to say:

```text
Atlas checked that the local metadata receipts are valid and linked. The
evidence shows a reviewable CI run/check path. Some required release evidence,
such as approvals or release notes, may still be missing, stale, or
unverifiable. A human reviewer still decides whether the release-review
objective is satisfied.
```

## Reviewer Decision Packet Reviewed

The reviewer should map the result to one of these actions:

- proceed with internal review;
- request missing evidence;
- rerun verification;
- refresh stale retained evidence;
- reject the release-readiness claim until required evidence is present;
- escalate to a reviewer, auditor, approver, or authority.

## Evidence Sufficiency Reviewed

Use the M158 status vocabulary:

| Evidence item | Dry-run status question |
| --- | --- |
| CI run metadata receipt | Is it `present`, `missing`, `stale`, or `unverifiable`? |
| CI check metadata receipt | Is it `present`, `missing`, `stale`, or `unverifiable`? |
| Linked replay | Is it `present`, `missing`, `stale`, or `unverifiable`? |
| Release notes | Are they `present`, `missing`, `stale`, or `unverifiable`? |
| Approval evidence | Is it `present`, `missing`, `stale`, or `unverifiable`? |
| Known limitations | Are they visible and current? |

## Friction Log

Record each finding with one category:

- clear;
- confusing;
- blocked;
- missing context;
- too much jargon;
- command friction;
- output friction;
- reviewer-decision friction;
- limitation clarity issue.

Initial retained dry-run log:

| Step | Category | Observation | Follow-up |
| --- | --- | --- | --- |
| Find starting point | clear | `docs/INDEX.md` exposes public trust, organization workflow, plain-English output, and quickstarts. | Keep start links near the top of the index. |
| Fresh clone setup | command friction | `nix-shell` is required for the strongest gate; reviewers without Nix need the portability docs. | Keep `nix-shell --run` examples explicit. |
| First receipt verify | clear | Minimal receipt verify is short and gives the first proof result quickly. | No change. |
| First replay | output friction | Replay output is technical unless paired with M166 plain-English wording. | Point reviewers to M166 after replay. |
| GitHub Actions import | command friction | The linked check event requires a `prev_hash` command. | Keep the copy-paste command in one block. |
| Evidence sufficiency | confusing | New reviewers may confuse `present` with sufficient. | Keep M158 language that missing, stale, or unverifiable evidence drives follow-up. |
| Reviewer decision | reviewer-decision friction | Reviewers may want a yes/no answer. | Keep M160 actions explicit and preserve outside-Atlas determination language. |
| Limitations | clear | Known limitations are visible, but readers may skip them. | Keep limitations in the dry-run scorecard and final result. |

## Confusing Points Found

- `receipt verify` and `receipt replay` need plain-English translation for
  non-technical readers.
- `present` evidence is not automatically enough for a decision.
- The GitHub Actions linked replay example is clearer when the `prev_hash`
  command is included as a copy-paste block.
- A reviewer may assume a clean proof chain means all source-system events were
  captured unless the limitation is stated nearby.

## Fixes Or Follow-Up Recommendations

- Keep `docs/INDEX.md` role-based starting points current.
- Keep M166 linked beside M164 and M160 wherever the organization workflow is
  listed.
- Add future command output examples if reviewer testing shows output jargon is
  still slowing adoption.
- Consider a future generated reader-mode artifact after the docs-only format
  proves useful.

## Time-To-First-Result Target

The retained target is:

- time to first successful verify: 10 minutes or less after dependencies are
  available;
- time to first replay: 20 minutes or less;
- time to understand what Atlas verifies: 30 minutes or less;
- time to understand what Atlas does not verify: 45 minutes or less;
- time to identify a supported decision: 60 minutes or less;
- time to identify an unsupported decision: 60 minutes or less.

These are adoption targets for internal dry-run review. They are not external
success metrics.

## Adoption Scorecard

| Score item | Target | Retained dry-run result |
| --- | --- | --- |
| Time to first successful verify | `<= 10 minutes` | pass target when Nix is available |
| Time to first replay | `<= 20 minutes` | pass target with quickstart commands |
| Time to understand what Atlas verifies | `<= 30 minutes` | pass target when M166 is read |
| Time to understand what Atlas does not verify | `<= 45 minutes` | warning: limitations must stay near the result |
| Time to identify supported decision | `<= 60 minutes` | pass target with M160 decision actions |
| Time to identify unsupported decision | `<= 60 minutes` | warning: must repeat no-compliance/no-coverage boundary |
| Overall adoption result | `pass / warning / blocked` | warning: usable path, with command and output friction to reduce |

## Known Limitations Reviewed

- This dry-run does not prove market adoption.
- This dry-run does not prove external user success.
- This dry-run does not prove compliance, certification, legal sufficiency,
  complete event coverage, or production deployability.
- This dry-run does not prove the reviewer saw every relevant external event.
- This dry-run does not detect every missing event.
- This dry-run does not prove no action happened outside Atlas.
- This dry-run does not replace reviewer, auditor, approver, or authority
  judgment.
- This dry-run helps identify adoption friction and reviewer clarity issues.

## Unsupported Decisions

The retained dry-run does not support decisions that say:

- the organization is certified or legally compliant;
- the workflow is guaranteed safe;
- the infrastructure cannot be altered;
- an external audit is complete;
- external SLSA certification exists;
- deployment is approved outside the local Atlas contract;
- all events were captured;
- all missing events were detected;
- model correctness or runtime safety is established;
- artifact correctness is established.

## Final Adoption Result

Overall result: `warning`.

The path is usable from a fresh clone and preserves adoption value. A reviewer
can reach a first receipt verify, replay a receipt chain, import GitHub Actions
metadata examples, read evidence sufficiency status, and choose a reviewer
decision action. The remaining friction is mostly command shape, output jargon,
and the need to keep limitations close to supported decisions.

## Remaining Adoption Risks

- Reviewers without Nix may need help reaching the reference environment.
- Reviewers may skip limitation sections if they are not placed near the
  decision.
- Reviewers may mistake metadata-only proof for source-system truth.
- Reviewers may treat a present receipt as sufficient even when approval,
  release notes, or business context remain missing.
- Future external reviewer dry-runs should record real timing and confusion
  points separately from this internal retained dry-run.
