# Atlas Repository Boundary

## Purpose

Atlas uses a split repository model so public contracts and implementation do
not blur into private operator state or runtime artifacts.

```text
current public repository = trust contracts + public shell implementation + verification
private operator context  = private runtime artifacts + configuration + history
```

The earlier project shorthand was:

```text
atlas-lab-toolkit = private implementation and operator runtime source
atlas-trust-infrastructure = public trust and reviewer surface
```

That shorthand is no longer a complete description and must not be read to
mean that all implementation is private. `atlas-trust-infrastructure` already
contains substantial public shell-native implementation in `tools/`, `bin/`,
and `lib/`, together with public tests, schemas, examples, and verification
workflows. `atlas-lab-toolkit` remains the private operator/runtime context and
may retain private implementation history that is not part of the public
export contract.

The public repository may define and implement inspectable trust behavior. It
must not become a dump of private runtime state, model input/output, operator
history, or raw evidence bodies.

## Boundary Rules

Public material may include:

- trust model documentation
- safety and responsible-use policy
- schema contracts
- language specifications, grammars, and synthetic fixtures
- capability manifests
- adapter registry contracts
- policy contracts and policy test fixtures
- approval workflow contracts and approval event schemas
- command references
- tests and validation scripts
- public shell-native implementation and portable verification commands
- metadata-only case studies
- retained public release and reviewer proof
- sanitized lab validation summaries

Public material must not include:

- credentials, tokens, private keys, cookies, approval credentials, or session
  data
- private target records or customer data
- raw model inputs, raw prompts, raw model outputs, or private artifacts
- environment-resolved endpoints and host-specific configuration
- raw packet captures, full request bodies, or full response bodies
- local runtime state from `sessions/`, `state/`, `shared/`, `logs/`,
  `reports/`, `releases/`, or `targets/`
- private implementation or operator history retained only in
  `atlas-lab-toolkit`
- host-specific lab identifiers beyond sanitized role labels

## Export Contract

`exports/public-trust-manifest.json` is the tracked public export contract. It
declares the public repository identity, the private operator-context identity,
allowed public paths, forbidden runtime paths, and private markers that must
not cross into public proof.

`bin/export-public-trust --check` validates the current public tree against that
manifest. `bin/export-public-trust --out <dir>` copies only allowed public files
to a reviewer export directory.

The manifest is deterministic. It does not contain timestamps, local hostnames,
usernames, private paths, or machine-local build state.

## Review Questions

A reviewer should be able to answer:

- Which implementation and verification surfaces are intentionally public?
- Which private operator/runtime context remains outside the public export?
- Which paths are allowed to cross the public boundary?
- Which paths and data classes must never cross?
- Which command validates the public export contract?

If those answers are unclear, the repository boundary has regressed.
