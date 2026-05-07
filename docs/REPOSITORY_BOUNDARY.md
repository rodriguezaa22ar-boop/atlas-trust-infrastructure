# Atlas Repository Boundary

## Purpose

Atlas uses a split repository model so implementation work, runtime state, and
public proof material do not blur together.

```text
atlas-lab-toolkit = private implementation and operator runtime source
atlas-trust-infrastructure = public trust and reviewer surface
```

The public repository explains the trust model, release proof, reviewer
contracts, schemas, public examples, and portable verification commands. It must
not become a dump of private runtime state or operator evidence bodies.

## Boundary Rules

Public material may include:

- trust model documentation
- safety and responsible-use policy
- schema contracts
- capability manifests
- command references
- tests and validation scripts
- metadata-only case studies
- retained public release and reviewer proof
- sanitized lab validation summaries

Public material must not include:

- credentials, tokens, private keys, cookies, or session data
- private target records or customer data
- raw packet captures, full request bodies, or full response bodies
- local runtime state from `sessions/`, `state/`, `shared/`, `logs/`,
  `reports/`, `releases/`, or `targets/`
- private implementation context that belongs only in `atlas-lab-toolkit`
- host-specific lab identifiers beyond sanitized role labels

## Export Contract

`exports/public-trust-manifest.json` is the tracked public export contract. It
declares the public repository identity, the private implementation identity,
allowed public paths, forbidden runtime paths, and private markers that must not
cross into public proof.

`bin/export-public-trust --check` validates the current public tree against that
manifest. `bin/export-public-trust --out <dir>` copies only allowed public files
to a reviewer export directory.

The manifest is deterministic. It does not contain timestamps, local hostnames,
usernames, private paths, or machine-local build state.

## Review Questions

A reviewer should be able to answer:

- Which repository contains private implementation source?
- Which repository is the public proof and reviewer surface?
- Which paths are allowed to cross the public boundary?
- Which paths and data classes must never cross?
- Which command validates the public export contract?

If those answers are unclear, the repository boundary has regressed.
