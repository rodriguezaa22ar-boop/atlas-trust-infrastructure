# Organization CI Release Review Workflow M164

## Purpose

Atlas supports a one-day CI release review workflow by turning local
GitHub Actions run/check metadata into replayable metadata-only proof
receipts, then connecting those receipts to evidence sufficiency and reviewer
decision support.

This workflow is organization-facing. It shows how an engineering team can try
Atlas for one CI release review without adding a live GitHub integration,
webhook listener, GitHub API call, network collector, database, server, or new
adapter.

## Who This Is For

Use this workflow when:

- an engineering team wants a bounded first Atlas trial;
- a reviewer needs a readable CI release review path;
- the team can provide local metadata files for one workflow run and linked
  check result;
- the team wants to understand what Atlas can verify before considering any
  live integration later.

The workflow assumes a reviewer can clone the public repository and run local
commands. It does not require the Atlas builder or author standing beside the
team.

## Problem It Solves

Before Atlas, a CI release review often depends on scattered screenshots,
pipeline pages, copied log fragments, release notes, and informal approval
messages. Reviewers spend time asking where the evidence is, which commit it
belongs to, whether it changed after review, and which gaps are still open.

With Atlas, the first-day trial gives the reviewer:

- metadata-only receipts for the CI run/check event path;
- local verify and replay commands;
- an evidence sufficiency vocabulary: `present`, `missing`, `stale`, and
  `unverifiable`;
- a reviewer decision packet vocabulary for proceeding, requesting evidence,
  refreshing stale evidence, rerunning verification, or escalating the
  determination outside Atlas.

## One-Day Adoption Path

The day-one goal is not a production rollout. It is a bounded review of one CI
release candidate using existing Atlas proof surfaces.

| Timebox | Activity | Output |
| --- | --- | --- |
| 30-60 minutes | Pick one recent CI release candidate and identify the reviewed commit. | Review objective and commit. |
| 60-90 minutes | Prepare local GitHub Actions run/check metadata files or use the M151 examples for a trial. | Local metadata input files. |
| 60 minutes | Import the run/check metadata, verify receipts, and replay the linked chain. | Receipt paths and command summaries. |
| 45 minutes | Score evidence sufficiency as `present`, `missing`, `stale`, or `unverifiable`. | Evidence sufficiency notes. |
| 45 minutes | Fill the reviewer decision packet outcome. | Supported next step, requested evidence, refresh request, or escalation. |
| 30 minutes | Record blind spots and human process risks. | Known limitations and follow-up list. |

## Operator Workflow

1. Name the objective:

   ```text
   CI release review for <repo> at <commit>
   ```

2. Start with the existing GitHub Actions proof package:

   - [../reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md](../reviews/GITHUB_ACTIONS_EVENT_PROOF_PACKAGE_M153.md)
   - [../reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md](../reviews/GITHUB_ACTIONS_RUN_RECEIPT_CANDIDATE_M151.md)

3. Use local metadata files. For the public trial, use the retained examples:

   - [../../examples/adapters/generic-external-event/github-actions-run-event.json](../../examples/adapters/generic-external-event/github-actions-run-event.json)
   - [../../examples/adapters/generic-external-event/github-actions-check-event.json](../../examples/adapters/generic-external-event/github-actions-check-event.json)

4. Import the workflow run event:

   ```bash
   run_receipt=/tmp/atlas-org-ci-run.receipt.json

   ./tools/atlas/bin/atlas receipt import-generic-event \
     examples/adapters/generic-external-event/github-actions-run-event.json \
     --out "$run_receipt"
   ```

5. Verify the run receipt:

   ```bash
   ./tools/atlas/bin/atlas receipt verify "$run_receipt"
   ```

6. Import the linked check event:

   ```bash
   check_receipt=/tmp/atlas-org-ci-check.receipt.json
   prev_hash="$(jq -r '.event_hash' "$run_receipt")"

   ./tools/atlas/bin/atlas receipt import-generic-event \
     examples/adapters/generic-external-event/github-actions-check-event.json \
     --prev-hash "$prev_hash" \
     --out "$check_receipt"
   ```

7. Verify the check receipt:

   ```bash
   ./tools/atlas/bin/atlas receipt verify "$check_receipt"
   ```

8. Replay the linked run/check receipt chain:

   ```bash
   ./tools/atlas/bin/atlas receipt replay \
     "$run_receipt" \
     "$check_receipt"
   ```

9. Record command summaries, receipt paths, reviewed commit, and known
   limitations. Do not paste raw logs, secrets, tokens, raw request bodies, raw
   response bodies, or full terminal dumps into the review packet.

## Reviewer Workflow

The reviewer uses the local evidence and existing Atlas review docs:

- [../TRUST_CLAIM_LADDER.md](../TRUST_CLAIM_LADDER.md)
- [../reviews/CONTROL_OBJECTIVE_MAPPING.md](../reviews/CONTROL_OBJECTIVE_MAPPING.md)
- [../reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md](../reviews/EVIDENCE_SUFFICIENCY_REPORT_M158.md)
- [../reviews/REVIEWER_DECISION_PACKET_M160.md](../reviews/REVIEWER_DECISION_PACKET_M160.md)
- [../PUBLIC_TRUST_SURFACE.md](../PUBLIC_TRUST_SURFACE.md)

Reviewer steps:

1. Confirm the review objective and reviewed commit.
2. Confirm run/check metadata was imported from local files.
3. Confirm generated receipts verify.
4. Confirm the linked run/check receipt chain replays.
5. Score each required evidence item as `present`, `missing`, `stale`, or
   `unverifiable`.
6. Choose a supported reviewer action:
   - proceed with internal review;
   - request missing evidence;
   - rerun verification;
   - refresh stale retained evidence;
   - reject the release-readiness claim until required evidence is present;
   - escalate to the relevant reviewer, auditor, approver, or authority.

## Evidence Produced

The day-one workflow produces or references:

- local GitHub Actions run/check metadata files;
- one workflow run receipt;
- one linked check receipt;
- receipt verify summaries;
- receipt replay summary;
- reviewed commit and branch context;
- evidence sufficiency notes;
- reviewer decision packet outcome;
- known limitations and remaining determinations.

These are metadata-only proof records and summaries. They are meant to make the
review path inspectable without embedding raw CI logs, workflow secrets, tokens,
private keys, webhook payloads, packet captures, raw request bodies, raw
response bodies, or full terminal dumps.

## Commands To Run

Minimum local command set:

```bash
run_receipt=/tmp/atlas-org-ci-run.receipt.json
check_receipt=/tmp/atlas-org-ci-check.receipt.json

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/github-actions-run-event.json \
  --out "$run_receipt"

./tools/atlas/bin/atlas receipt verify "$run_receipt"

prev_hash="$(jq -r '.event_hash' "$run_receipt")"

./tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/github-actions-check-event.json \
  --prev-hash "$prev_hash" \
  --out "$check_receipt"

./tools/atlas/bin/atlas receipt verify "$check_receipt"

./tools/atlas/bin/atlas receipt replay "$run_receipt" "$check_receipt"
```

Optional public-surface checks:

```bash
./bin/export-public-trust --check
./tools/atlas/bin/atlas reviewer package full-capability-review
```

## Expected Reviewer Output

A concise reviewer output can look like this:

```text
review_objective: CI release review for <repo> at <commit>
event_path: GitHub Actions run/check metadata
receipts:
  run: /tmp/atlas-org-ci-run.receipt.json
  check: /tmp/atlas-org-ci-check.receipt.json
verification:
  run_receipt: present
  check_receipt: present
  linked_replay: present
evidence_sufficiency:
  ci_event_metadata: present
  raw_logs: intentionally not embedded
  approval_record: missing | present | stale | unverifiable
  release_notes: missing | present | stale | unverifiable
reviewer_decision:
  proceed with internal review | request missing evidence | rerun verification |
  refresh stale retained evidence | escalate to reviewer/auditor/authority
known_limitations:
  ...
```

The output records what the proof envelope supports and what still needs human
review.

## Evidence Sufficiency Check

Use the M158 vocabulary:

| Evidence item | Suggested status rule |
| --- | --- |
| CI run metadata receipt | `present` when import and verify succeed; `missing` when no metadata file or receipt exists; `stale` when tied to the wrong commit; `unverifiable` when verify fails. |
| CI check metadata receipt | `present` when import and verify succeed; `missing` when absent; `stale` when linked to the wrong run; `unverifiable` when verify fails. |
| Linked run/check replay | `present` when replay succeeds; `missing` when either receipt is absent; `stale` when `prev_hash` points to older evidence; `unverifiable` when replay fails. |
| Release notes or release packet | `present` when available and tied to the reviewed commit; `missing` when absent; `stale` when tied to an older release; `unverifiable` when the packet cannot be checked. |
| Approval evidence | `present` when the approval path is retained and reviewable; `missing` when absent; `stale` when no longer tied to the reviewed release; `unverifiable` when the reviewer cannot inspect it. |
| Known limitations | `present` when gaps and outside determinations are written down; `missing` when omitted; `stale` when no longer accurate; `unverifiable` when unclear. |

Missing, stale, or unverifiable evidence should drive follow-up. It should not
be treated as sufficient by default.

## Reviewer Decision Packet Outcome

Use M160 to turn the evidence status into an action:

- `proceed with internal review` when required evidence is present and the
  limitations are visible;
- `request missing evidence` when the packet lacks required release, approval,
  or CI metadata;
- `rerun verification` when receipt verify or replay output is unavailable or
  failed;
- `refresh stale retained evidence` when receipts or release evidence no
  longer match the reviewed commit;
- `reject release-readiness claim until required evidence is present` when the
  required proof envelope is incomplete;
- `escalate to external reviewer/auditor/authority` when the requested
  determination belongs outside Atlas.

## Blind Spots / Negative Proof

Atlas can show that the local proof envelope verifies. It cannot show that
every relevant external event was captured unless the organization retained
that event evidence and gave the reviewer a way to inspect it.

Key blind spots:

- a CI run/check event may be missing from the local packet;
- missed events remain a risk when the organization does not retain or provide
  the relevant metadata;
- a later rerun may have changed the external state after the receipt was
  created;
- a workflow approval may exist outside the provided metadata;
- release notes or deployment records may be absent;
- the event source may be wrong, incomplete, or stale;
- receipt replay checks provided-order linkage, not external GitHub truth.

Negative proof matters because a clean replay of incomplete evidence is still
incomplete evidence.

## Human Process Risks

Atlas reduces ambiguity, but the organization's process still matters.
Reviewers should watch for:

- rubber-stamped approvals;
- missing separation of duties;
- stale release notes copied from an older release;
- screenshots used instead of retained metadata;
- unclear ownership of the reviewed commit;
- evidence added after review without a refreshed packet;
- pressure to treat a successful receipt replay as approval.

These risks should be recorded as reviewer follow-up, accepted residual risk,
or escalation outside Atlas.

## Time / Cost Benefit

This is a rough qualitative comparison, not a hard ROI claim.

Before Atlas, the reviewer usually chases CI pages, screenshots, release notes,
approval messages, branch state, and log snippets manually. The result can be
slow to reproduce and hard for another reviewer to inspect.

With Atlas, the reviewer gets a repeatable local path:

- import local CI metadata;
- verify metadata-only receipts;
- replay the linked run/check chain;
- classify evidence as present, missing, stale, or unverifiable;
- record a reviewer decision packet outcome.

The main benefit is less ambiguity: the team can see which evidence is present
and which gaps still need review in the same day.

## Known Limitations

- M164 is docs/tests only.
- M164 does not add a live GitHub integration, GitHub API call, webhook,
  network collector, database, server, web UI, or new adapter.
- The workflow uses local metadata files and existing example events.
- Atlas verifies the proof envelope: receipt structure, hashes,
  metadata-only boundaries, and caller-provided replay order.
- Atlas does not decide source-system truth, workflow authorization, release
  approval, deployment approval, human approval quality, residual risk,
  external audit outcome, legal or compliance conclusion, model behavior, or
  runtime behavior.
- A complete organizational review still depends on retained evidence and
  reviewer judgment outside Atlas.

## What To Do Next

1. Run the workflow once with the public M151 example events.
2. Replace the examples with one organization's locally prepared CI run/check
   metadata files.
3. Record missing, stale, or unverifiable evidence explicitly.
4. Use the Reviewer Decision Packet to choose the next reviewer action.
5. Keep live integrations out of scope until the local, metadata-only review
   path is understandable and useful.
