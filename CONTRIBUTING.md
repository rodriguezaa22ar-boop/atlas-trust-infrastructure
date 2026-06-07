# Contributing

## Project Boundary

Atlas is a local-first, shell-native trust control plane for authorized security
workflows, evidence retention, release trust, business-flow proof, and
metadata-only proof chains for critical digital actions.

This public repository is the reviewer and trust surface. The private
`atlas-lab-toolkit` repository remains the implementation and operator runtime
source. See [docs/REPOSITORY_BOUNDARY.md](docs/REPOSITORY_BOUNDARY.md) and
`exports/public-trust-manifest.json` before adding files that might cross that
boundary.

Contributions should strengthen at least one of these properties:

- scope enforcement
- operator control
- evidence integrity
- append-only auditability
- validation discipline
- report clarity
- retention freshness
- release trust
- reproducibility
- known limitations

Do not add features that encourage unauthorized access, autonomous
exploitation, persistence, destructive testing, credential spraying,
denial-of-service workflows, stealth/evasion behavior, or out-of-scope target
expansion.

## What Not to Commit

Do not commit or attach:

- credentials, tokens, passwords, private keys, or session cookies
- raw customer data, payment data, or private business records
- raw packet captures, full request bodies, or full response bodies
- private target records, runtime operation state, or local evidence bodies
- exploit payloads or instructions for unauthorized access

Use synthetic fixtures and metadata-only examples.

Atlas records and verifies metadata-only proof chains. It does not grant
permission, replace approval authorities, certify compliance, prove legal
sufficiency, guarantee action validity, prove complete event coverage, or
replace human judgment.
Atlas does not grant permission by itself.

Atlas proof records must not embed raw logs, secrets, private keys, tokens,
Authorization headers, request bodies, response bodies, packet captures, raw
prompts, raw model outputs, tool output bodies, browser/session/cookie
material, customer data, payment data, private business records, unredacted
evidence bodies, or raw artifacts.
This includes raw prompts, browser/session/cookie material, and unredacted evidence bodies.

## Development Workflow

Use the repository's Nix development environment:

```bash
nix-shell
```

Run the strongest relevant gate before opening a pull request:

```bash
nix-shell --run './bin/dev-qa'
```

For focused checks:

```bash
bash -n <changed-shell-file>
git diff --check
./bin/export-public-trust --check
./bin/dev-governance
./bin/dev-capabilities
./bin/dev-adapters
./bin/dev-policy
./bin/dev-approval
./bin/dev-evidence
./bin/dev-decisions
./bin/dev-host-check
nix-shell --run './bin/dev-lint'
nix-shell --run './bin/dev-test tests/atlas.bats'
```

Do not claim tests passed unless they were actually run.

Run helper commands only when present in the checkout. In the current public
source tree, the governance helpers validate capabilities, adapters, policy,
approval, evidence envelopes, decision vocabulary, and the combined governance
surface.

## Code and Docs Standards

Follow the root [AGENTS.md](AGENTS.md) guidance when changing Atlas code,
tests, schemas, or docs.

Keep changes small and coherent. Prefer existing shell-native patterns,
file-backed state, NDJSON records, Markdown/JSON packet parity, and
metadata-only packet contracts before introducing new structure.

When behavior changes, update the relevant docs and tests. Trust gates should
include negative paths, not only passing examples.

Governance and schema changes must include positive tests, negative tests,
metadata-only checks, no-overclaim checks, known limitations, public export
checks, and reviewer-readable docs.

Docs that touch governance must clearly distinguish:

- implemented behavior
- draft contract
- validation tooling
- future runtime
- not implemented

## Pull Requests

Pull requests should include:

- purpose of the change
- commands or docs affected
- tests run
- known limitations
- confirmation that no secrets, raw target data, or runtime evidence were added

For readiness, release trust, retention, business-flow evidence, or packet
schema changes, include the verification command output summary in the pull
request description.

Use the repository pull request template when available. It asks for scope,
validation, boundary checks, and reviewer notes so public trust changes remain
metadata-only and reviewable.

## Issues And Conduct

Use the issue templates for reproducible bugs and trust-claim or documentation
concerns. Public issues must stay metadata-only and must not include secrets,
raw target data, raw logs, raw prompts, raw model output, or private runtime
evidence.

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
