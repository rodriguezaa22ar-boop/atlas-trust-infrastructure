# AI-Agent Event Reviewer Dry-Run M149

## Purpose

This note records a public-reviewer dry-run for the AI-agent event receipt
path. The goal was to prove a reviewer can clone Atlas and verify the
AI-agent event receipt path without private context.

This is a review record, not a new feature. It does not add runtime behavior,
receipt semantics, adapter behavior, network behavior, agent behavior, or
approval authority.

## Environment

- Date: 2026-05-28
- Clone path: `/tmp/atlas-ai-agent-review-m149.q9stBV/atlas-trust-infrastructure`
- Source: `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure.git`
- Commit reviewed: `68444ccb2892230cf67b696aa17076f1b5fcdda6`
- Branch: detached at reviewed commit
- Environment type: fresh public clone on the Nix reference host
- Private notes used: none

The dry-run used only the public repository, public docs, public examples,
schemas, retained milestone notes, and test suite.

## Public Entry Points Read

```bash
sed -n '1,180p' README.md
sed -n '1,220p' docs/TRY_AI_AGENT_EVENT_RECEIPTS.md
sed -n '1,220p' docs/adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md
sed -n '1,180p' docs/adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md
sed -n '1,120p' docs/KNOWN_LIMITATIONS.md
```

Document sizes inspected:

```text
150 README.md
191 docs/TRY_AI_AGENT_EVENT_RECEIPTS.md
178 docs/adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md
136 docs/adapters/GENERIC_EXTERNAL_EVENT_RECEIPT_ADAPTER.md
 72 docs/KNOWN_LIMITATIONS.md
727 total
```

## Commands Run

```bash
git clone https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure.git \
  /tmp/atlas-ai-agent-review-m149.q9stBV/atlas-trust-infrastructure
cd /tmp/atlas-ai-agent-review-m149.q9stBV/atlas-trust-infrastructure
git checkout 68444ccb2892230cf67b696aa17076f1b5fcdda6

nix-shell --run './bin/dev-qa'

nix-shell --run './tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-action-event.json \
  --out /tmp/m149-ai-agent-action.atlas.json'

nix-shell --run './tools/atlas/bin/atlas receipt verify \
  /tmp/m149-ai-agent-action.atlas.json'

action_event_hash="$(jq -r .event_hash /tmp/m149-ai-agent-action.atlas.json)"
export action_event_hash

nix-shell --run './tools/atlas/bin/atlas receipt import-generic-event \
  examples/adapters/generic-external-event/ai-agent-result-event.json \
  --prev-hash "$action_event_hash" \
  --out /tmp/m149-ai-agent-result.atlas.json'

nix-shell --run './tools/atlas/bin/atlas receipt verify \
  /tmp/m149-ai-agent-result.atlas.json'

nix-shell --run './tools/atlas/bin/atlas receipt replay \
  /tmp/m149-ai-agent-action.atlas.json \
  /tmp/m149-ai-agent-result.atlas.json'

nix-shell --run './tools/atlas/bin/atlas receipt replay \
  /tmp/m149-ai-agent-action.atlas.json \
  /tmp/m149-ai-agent-result.atlas.json \
  --json' | sed -n '/^{/,$ p' | jq -e \
  '.schema_version == "atlas.receipt_replay.v1" and
   .status == "ok" and
   .metadata_only == true and
   .raw_artifacts_embedded == false and
   .receipt_count == 2 and
   .ledger_binding.status == "ok"'

nix-shell --run './bin/export-public-trust --check'

rg -n 'BEGIN PRIVATE KEY|Authorization: Bearer|token=|password=|secret=|session_cookie|raw_request|raw_response|packet-capture|pcap|raw_prompt|raw_model_output|system_prompt|tool_output_body|tool_call_raw' \
  README.md docs examples schemas tools tests || true

find README.md docs examples schemas tools tests \
  \( -name '*.pcap' -o -name '*.pcapng' \) -print
```

The JSON replay check strips the `nix-shell` banner before `jq` because the
local dev shell prints an entry banner before the command output.

## Results

| Check | Result |
| --- | --- |
| Fresh public clone | passed |
| Reviewed commit checkout | passed |
| `nix-shell --run './bin/dev-qa'` | passed, 140/140 Bats plus lint, capabilities, adapters, policy, approval, evidence, portability, and stress |
| AI-agent proposed-action import | passed |
| AI-agent proposed-action receipt verify | passed |
| AI-agent result import | passed |
| AI-agent result receipt verify | passed |
| Linked AI-agent receipt replay | passed |
| Linked AI-agent replay JSON check | passed |
| Public export check | passed |
| Boundary scan | expected source/test/tooling references only |
| Raw pcap file search | no files found |

Action import wrote:

```text
receipt: /tmp/m149-ai-agent-action.atlas.json
```

Action verification output included:

```text
receipt: ok
This receipt validates as a metadata-only proof record.
It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.
```

The action receipt event hash was:

```text
396b7440e4786a90758be59e28203b235c3514182fb797d905e41cbedd262f8b
```

Result import wrote:

```text
receipt: /tmp/m149-ai-agent-result.atlas.json
```

Linked replay output included:

```text
receipt replay: ok
receipts: 2
ledger binding: ok prev_hash -> event_hash
chain_head_event_hash: fbdbc3d57d09c5041274b7c037da3b64403e1fbe3795cda7daad4713e7fb51f0
chain_head_receipt_hash: d02dcbcdf2e22a156b0ff6d52f77bf658b07fc042391d4541e5bc4993f835018
metadata-only boundary: ok
```

The JSON replay check returned:

```text
true
```

Public Trust Export reported:

```text
Manifest: ok
Allowed files: 506
Forbidden paths: 0
Private markers: 0
Mode: check
Overall: ok
```

## Boundary Scan Notes

The broad marker scan returned expected source, test, documentation, and
guardrail references, not retained raw artifacts:

- `tests/atlas.bats` contains intentional unsafe AI-agent and generic-event
  fixtures that prove fail-closed behavior for `raw_prompt`,
  `raw_model_output`, `raw_response`, `system_prompt`, `tool_output_body`,
  `tool_call_raw`, `Authorization: Bearer`, `token=`, `password=`,
  `secret=`, and private-key markers.
- `tools/atlas/lib/receipt.sh` contains forbidden marker checks by design.
- `tools/wiremap/*`, `tools/atlas/bin/atlas`, and related tests mention
  `pcap` because Wiremap owns capture planning and capture inspection.
- `docs/reviews/PUBLIC_REVIEWER_DRY_RUN_M142.md` and retained milestone notes
  mention boundary markers to document prior fail-closed coverage.
- No raw `.pcap` or `.pcapng` files were found under `README.md docs examples
  schemas tools tests`.
- Public export reported `Private markers: 0`.

## What Was Clear

- The README points reviewers to the AI-agent event receipt quickstart.
- `docs/TRY_AI_AGENT_EVENT_RECEIPTS.md` gives copy-paste import, verify, and
  replay commands.
- `docs/adapters/AI_AGENT_EVENT_RECEIPT_PROFILE.md` keeps the boundary clear:
  AI agent = event source, Atlas = verifier, human/policy = authority.
- The existing generic adapter is enough for the AI-agent path; no second
  adapter is required.
- Receipt verify and replay output display metadata-only and non-guarantee
  language.
- M148 regression coverage makes unsafe AI-agent inputs fail closed before this
  public reviewer path is promoted.

## What Was Confusing

- `nix-shell --run` prints a dev-shell banner before JSON output, so shell
  pipelines that parse JSON need to strip that banner or run inside an
  interactive `nix-shell`.
- Broad marker scans return many expected fail-closed fixtures and guardrail
  references. A reviewer needs the boundary scan note above to distinguish
  those from real leaked secrets or raw artifacts.

## What Atlas Proves

For the reviewed public commit, Atlas proves:

- the public repository passes the full local QA gate;
- the AI-agent event receipt quickstart is cloneable and runnable without
  private context;
- AI-agent proposed-action and result events import through the existing
  generic adapter;
- generated AI-agent receipts verify as metadata-only proof records;
- linked AI-agent receipts replay with valid `prev_hash -> event_hash`
  binding;
- generated receipts preserve `metadata_only=true` and
  `raw_artifacts_embedded=false`;
- public export has no forbidden paths or private markers;
- non-guarantee language is visible in docs and command output.

## What Atlas Does Not Prove

This dry-run does not prove:

- model correctness;
- source-runtime truth;
- agent authorization;
- approval by Atlas;
- tool execution safety;
- external artifact truth;
- legal compliance;
- production deployment approval;
- external audit;
- certification;
- tamper-proof infrastructure.

## Boundary

- No runtime behavior added.
- No receipt semantics changed.
- No new adapter added.
- No agent runtime added.
- No tool execution added.
- No network collector added.
- No database, server, or web UI added.
- No approval authority added.
- No production claim added.
- AI agents remain event sources only.
- Atlas remains verifier, not authority.
- Human and policy remain authority.
