# Contributing

## Project Boundary

Atlas is a local-first, shell-native trust control plane for authorized security
workflows, evidence retention, release trust, and business-flow proof.

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
nix-shell --run './bin/dev-lint'
nix-shell --run './bin/dev-test tests/atlas.bats'
```

Do not claim tests passed unless they were actually run.

## Code and Docs Standards

Follow the root [AGENTS.md](AGENTS.md) guidance when changing Atlas code,
tests, schemas, or docs.

Keep changes small and coherent. Prefer existing shell-native patterns,
file-backed state, NDJSON records, Markdown/JSON packet parity, and
metadata-only packet contracts before introducing new structure.

When behavior changes, update the relevant docs and tests. Trust gates should
include negative paths, not only passing examples.

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
