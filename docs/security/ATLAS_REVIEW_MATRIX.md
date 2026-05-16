# Atlas Review Matrix

## Purpose

This matrix turns external security-reference material, including The Book of
Secret Knowledge, into an Atlas review checklist. It is not an execution
playbook.

Atlas uses this matrix to ask whether the public trust surface preserves:

- metadata-only proof records
- read-only verification behavior
- no hidden runtime state
- no unnecessary network exposure
- no untrusted shell execution
- bounded public claims

Run commands only against owned Atlas systems and retained public repository
content. Do not use this matrix to justify exploitation, credential attacks,
fuzzing, denial-of-service testing, payload delivery, stealth, persistence, or
out-of-scope scanning.

## Metadata Boundary

Review question:

```text
Can receipts, replay output, packets, schemas, examples, or demo docs leak raw
sensitive artifacts?
```

Expected Atlas answer:

```text
No. Atlas public trust artifacts should contain metadata references, hashes,
known limitations, replay instructions, and reviewer-safe summaries only.
```

Checks:

- secret markers are rejected
- raw request and response bodies are rejected
- embedded raw artifacts are rejected
- `metadata_only` is required where the contract defines it
- `raw_artifacts_embedded=false` is required where the contract defines it
- `known_limitations` are required for receipt and packet interpretation

Review commands:

```bash
rg -n "password|token|secret|PRIVATE KEY|Authorization:|cookie|session_cookie|raw_request|raw_response|pcap" \
  docs examples schemas tools tests

nix-shell --run 'bats --filter "receipt" tests/atlas.bats'
```

Current coverage:

- `M134 receipt verifier rejects unsafe content and hash tampering`
- `M134 receipt replay rejects chain tampering and remains read-only`
- receipt and replay schema checks in `tests/atlas.bats`

## Read-Only Boundary

Review question:

```text
Can documented read-only Atlas commands mutate runtime layout or operation
state?
```

Expected Atlas answer:

```text
No. Receipt verification, receipt replay, status, and verifier commands must
not create logs, state, sessions, targets, reports, or release directories.
```

Checks:

- `atlas receipt verify` does not mutate runtime layout
- `atlas receipt replay` does not mutate runtime layout
- `atlas v1 status --json` does not mutate runtime layout
- verifier commands do not append operation ledger events

Review commands:

```bash
before="$(find . -maxdepth 2 -type d | sort)"
./tools/atlas/bin/atlas receipt verify examples/receipt/minimal.json
./tools/atlas/bin/atlas receipt replay \
  examples/receipt/minimal.json \
  examples/receipt/software-action.json \
  examples/receipt/approval-workflow.json \
  examples/receipt/agent-action.json
./tools/atlas/bin/atlas v1 status --json
after="$(find . -maxdepth 2 -type d | sort)"
diff <(printf '%s\n' "$before") <(printf '%s\n' "$after")
```

Expected result:

```text
No new logs/
No new releases/
No new reports/
No new sessions/
No new state/
No new targets/
```

Current coverage:

- `atlas v1 status and release verify do not initialize runtime layout`
- `atlas receipt replay validates chain failures and stays read-only`
- M134 read-only receipt verify and replay regression checks

## Network Boundary

Review question:

```text
Is Atlas exposing any network service it does not need?
```

Expected Atlas answer:

```text
No. Atlas CLI, receipt, and replay surfaces should not open ports.
```

Checks:

- Atlas public trust repository adds no server or listener
- builder SSH is key-only when used for operator workflow
- Tailscale path is known and documented
- LAN exposure is intentional or blocked
- unexpected listeners are attributed to host services, not Atlas CLI

Review commands for owned Atlas devices:

```bash
nmap -sV -Pn atlas-builder
nmap -sV -Pn 100.66.164.109
ssh-audit 100.66.164.109
ssh builder 'ss -tulpen 2>/dev/null || ss -tuln'
```

Current baseline:

```text
/home/ao/workspace/projects/labs/parrot-to-nix-security-current/parrot-to-nix-security-test-report.txt
```

Baseline hash:

```text
7a674864bca5ae9ff574268867c1e25502960d166b31115f592d2247775d003c
```

Observed baseline notes:

- builder SSH was reachable on Tailscale and LAN
- SSH was key-only by probe and readable config
- `tailscaled.service` exposed a Tailscale-owned HTTP listener
- Atlas CLI, receipt, and replay added no network service

## Host Hardening

Review question:

```text
Are Parrot and builder hardened enough for the operator workflow?
```

Expected Atlas answer:

```text
The operator workflow should rely on key-only SSH, least exposed network paths,
encrypted bootstrap material, and explicit compartment boundaries.
```

Checks:

- SSH key-only authentication
- no root SSH
- firewall posture reviewed
- Tailscale-only where practical
- Bluetooth off when unused
- UPnP disabled on the router
- recovery and encrypted secret USB roles preserved
- unknown downloads flow through quarantine

Review commands for owned hosts:

```bash
sudo systemctl status auditd
sudo aa-status
sudo lynis audit system
```

Notes:

- Host hardening tools are outside Atlas receipt/replay semantics.
- Host audit output should stay in private builder workspaces unless redacted.
- Do not commit host-specific secrets, raw evidence, or full audit logs to this
  public trust repository.

## Shell Safety

Review question:

```text
Can untrusted receipt fields become shell execution?
```

Expected Atlas answer:

```text
No. Receipt data should be parsed and verified, never executed.
```

Checks:

- no `eval` in receipt paths
- no unsafe `curl | sh` patterns
- no untrusted `bash -c` or `sh -c` execution
- temp files use `mktemp`
- cleanup uses `trap` where temporary state persists
- shell variables are quoted
- receipt JSON is handled through `jq`

Review commands:

```bash
rg -n "eval|curl .*\\| sh|bash -c|sh -c|mktemp|trap|chmod 777|sudo " tools bin lib tests
shellcheck tools/atlas/lib/*.sh tools/atlas/bin/atlas bin/*
```

Current receipt/replay expectation:

- receipt fields are validated with `jq`
- receipt hashes are canonicalized before comparison
- replay links `prev_hash` to prior `event_hash`
- no receipt field is executed as a shell command

## Demo Boundary

Review question:

```text
Does the demo claim only what Atlas actually proves?
```

Expected Atlas answer:

```text
Yes. Public demos should remain synthetic, metadata-only, and explicit that
Atlas is not an agent runtime, scanner, SIEM, GRC replacement, or external
certification.
```

Checks:

- synthetic only
- metadata-only
- not an agent runtime
- not a scanner
- not a SIEM/GRC replacement
- no external certification claim
- no production readiness overclaim

Review commands for public demo material:

```bash
rg -n "metadata-only|synthetic|not an agent runtime|not a scanner|not a SIEM|not a GRC|certification|production" \
  README.md docs examples
```

For an owned demo site:

```bash
curl -I https://your-demo-site
curl -s https://your-demo-site | rg -n "metadata_only|raw_artifacts_embedded|not an agent runtime|not a scanner"
```

## Regression Backlog

Turn this matrix into focused Bats checks over time:

- metadata boundary leak checks for every packet family
- read-only mutation checks for every verifier
- shell-safety checks for receipt and replay paths
- public-demo overclaim checks
- host-baseline report hash retention checks

Each regression should preserve Atlas boundaries: local-first, metadata-only,
operator-controlled, no hidden state, and no execution engine.
