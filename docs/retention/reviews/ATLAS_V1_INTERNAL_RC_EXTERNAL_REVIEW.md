# Atlas v1 Internal RC External Review Validation

## Purpose

This external review validation records a clean clone review of the retained
Atlas v1 Internal RC from a separate lab node. The goal is to confirm that a
reviewer can clone the public repository, fetch tags, run the local Atlas
verification path, inspect retained evidence, generate a reviewer package, and
see the current RC as production-ready under the local Atlas contract.
It also records the terminal-first HP-to-Surface cockpit validation boundary:
a human operator drove the review commands from an HP-controlled shell toward a
separate Surface/lab node context. Atlas records the metadata-only evidence
path; it does not operate the lab or autonomously control the dual-node setup.

This is a metadata-only review record. It is not external audit, not
certification, not legal compliance, not tamper-proof infrastructure, not
external SLSA certification, not runtime safety proof, and not production
deployability proof.

## Review Environment

- Review type: external review validation
- Review host: lab node
- Hostname: `labnode`
- Kernel observed: `Linux 6.12.82`
- Repository: `rodriguezaa22ar-boop/atlas-trust-infrastructure`
- Clean clone path observed:
  `/tmp/atlas-m122-clean-review.KzuJQi/atlas-trust-infrastructure`
- RC retention commit:
  `b44eb30890483512e1bd2bebce2b97d78ec5e140`
- RC release commit:
  `7b3f6f575f1acbdaa3729009564ad3b9824a556c`
- RC tag: `atlas-v1-internal-rc`
- Production-candidate tag: `atlas-production-candidate-m121`
- Retention tag: `atlas-retention-m121`

## M121/M122 Boundary

The retained production-candidate evidence remains M121:

- Retained RC state: `atlas-retention-m121`
- Retained RC tag: `atlas-v1-internal-rc`
- Retained production-candidate tag: `atlas-production-candidate-m121`
- Retained release commit:
  `7b3f6f575f1acbdaa3729009564ad3b9824a556c`
- Retained retention commit:
  `b44eb30890483512e1bd2bebce2b97d78ec5e140`

M122 is not a new retained production-candidate state. M122 is the active M122
branch for external review validation; it documents how a reviewer can
reproduce and inspect the retained M121 evidence. On M122, `atlas production status
--strict --explain` may correctly report `not-ready` when the active checkout
does not match the retained M121 release evidence or when generated reviewer
packages make the worktree dirty. That result is acceptable for M122 when the
explain output identifies the retained-evidence mismatch and the retained M121
release verification commands still pass.

## Dual-Node Cockpit Boundary

The cockpit validation was terminal-first and operator-driven:

- HP-controlled shell/SSH/tmux context: command and review control plane
- Surface/lab node context: clean clone and reviewer command execution context
- Atlas role: metadata-only command surface and retained evidence verifier

This validation demonstrates a reproducible external-review path across a
separate lab node. It does not claim that Atlas operates the lab, controls the
Surface node, provides runtime safety, proves production deployment readiness,
or replaces an external reviewer. If local operation state named
`atlas-dual-node-cockpit` has been generated, reviewers may inspect it with:

```bash
./tools/atlas/bin/atlas op trust-chain atlas-dual-node-cockpit --strict
```

Expected result:

```text
Trust Chain Status: current
```

That operation state is local metadata and is not the retained M121
production-candidate evidence.

## Clean Clone Commands

Use a branch checkout for full QA because the release-trust test suite expects
a branch with an upstream. Use the signed RC tag for retained evidence
identity and tag verification.

```bash
workdir="$(mktemp -d)"
cd "$workdir"

git clone https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure.git
cd atlas-trust-infrastructure
git fetch --tags --force
git switch main
git rev-parse HEAD
git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
```

Expected result:

```text
b44eb30890483512e1bd2bebce2b97d78ec5e140
origin/main
```

## Verification Commands

Run the full local QA gate:

```bash
nix-shell --run './bin/dev-qa'
```

Expected result:

```text
1..112
...
lint: ok
stress: ok
qa: ok
```

Run v1 readiness:

```bash
./tools/atlas/bin/atlas v1 status --strict
```

Expected result:

```text
Overall: ready
Blocked Pillars: 0
Warning Pillars: 0
Required Not Ready: 0
```

Verify the retained M121 release packet:

```bash
./tools/atlas/bin/atlas release verify \
  docs/retention/releases/atlas-m121-v1-internal-rc.json \
  --commit 7b3f6f575f1acbdaa3729009564ad3b9824a556c
```

Expected result:

```text
Known Limitations: ok present
ok: release trust packet verified
```

Verify the retained M121 release artifact manifest:

```bash
./tools/atlas/bin/atlas release manifest-verify \
  docs/retention/releases/atlas-m121-v1-internal-rc.manifest.json \
  --commit 7b3f6f575f1acbdaa3729009564ad3b9824a556c
```

Expected result:

```text
Signed Tag: ok verified tag=atlas-production-candidate-m121
Known Limitations: ok present
ok: release artifact manifest verified
```

Replay the retained release packet as machine-readable JSON:

```bash
./tools/atlas/bin/atlas release replay \
  docs/retention/releases/atlas-m121-v1-internal-rc.json \
  --json
```

Expected result:

```text
schema_version: atlas.release_replay.v1
overall: verified
checks: 4
```

Run reviewer-readable production explainability:

```bash
./tools/atlas/bin/atlas production status --strict --explain
```

Expected result:

```text
Overall: production-ready under the local Atlas contract
Release Packet: docs/retention/releases/atlas-m121-v1-internal-rc.json
Release Artifact Manifest: docs/retention/releases/atlas-m121-v1-internal-rc.manifest.json
Signed Provenance: docs/retention/releases/atlas-m121-v1-internal-rc.provenance.json
Signed Tag: atlas-production-candidate-m121
Production Dry-Run Note: docs/retention/production/PRODUCTION_DRY_RUN_2026-05-02_M121.md
```

Verify the retained SLSA-verifiable release artifact candidate metadata:

```bash
./tools/atlas/bin/atlas release slsa-verify \
  docs/retention/releases/atlas-v0.4.0-rc1.slsa.json
```

Expected result:

```text
Issuer Identity: ok https://token.actions.githubusercontent.com
Attestation Verification: ok verified
Reference Contract: ok verified
ok: SLSA provenance reference verified
```

Generate a metadata-only reviewer package:

```bash
./tools/atlas/bin/atlas reviewer package atlas-v1-internal-rc-external-review
jq -r '[.schema_version, (.metadata_only|tostring), (.raw_artifacts_embedded|tostring)] | @tsv' \
  docs/retention/reviewer-packages/atlas-v1-internal-rc-external-review/REVIEWER_PACKAGE_MANIFEST.json
```

Expected result:

```text
atlas.external_reviewer_package.v1    true    false
```

## Signed Tag Portability Note

Direct host-shell tag verification may fail on a clean reviewer host when the
Atlas release public key has not been imported into that host's GPG keyring.
The supported portable path is a temporary keyring:

```bash
tmp_gnupg="$(mktemp -d)"
chmod 700 "$tmp_gnupg"
GNUPGHOME="$tmp_gnupg" gpg --batch --no-autostart --import \
  docs/retention/releases/atlas-m67-release-signing-public-key.asc
GNUPGHOME="$tmp_gnupg" git -c gpg.program=gpg tag -v atlas-v1-internal-rc
rm -rf "$tmp_gnupg"
```

Expected result:

```text
Primary key fingerprint: 24B1 E00E EB28 6B96 6F9F CE0C 9C64 39E1 5BBF D290
object b44eb30890483512e1bd2bebce2b97d78ec5e140
tag atlas-v1-internal-rc
Atlas v1 Internal Release Candidate
```

## Observed Results

The lab node clean clone validation passed:

- `git clone`: passed
- `git fetch --tags --force`: passed
- branch/upstream context: `main` with `origin/main`
- `nix-shell --run './bin/dev-qa'`: passed with `112/112`, lint ok, stress ok
- `atlas v1 status --strict`: ready
- `atlas release verify`: passed
- `atlas release manifest-verify`: passed
- `atlas release replay --json`: `atlas.release_replay.v1`, `verified`,
  `4` checks
- `atlas production status --strict --explain`: production-ready under the
  local Atlas contract
- `atlas release slsa-verify`: passed
- `atlas reviewer package`: passed with `metadata_only=true` and
  `raw_artifacts_embedded=false`
- HP-to-Surface terminal-first cockpit validation: documented as an
  operator-driven, metadata-only dual-node review path
- temporary-keyring RC tag verification: passed with retained public key

## Known Limitations

- The full QA suite should run from a branch checkout with an upstream, such as
  `main` after a clean clone. A detached `atlas-v1-internal-rc` checkout is
  useful for inspection, but several release-trust tests intentionally expect
  branch/upstream context.
- The retained SLSA reference confirms the recorded SLSA-verifiable release
  artifact candidate metadata. It is not external SLSA certification.
- Production status remains a local Atlas contract based on retained metadata
  evidence.
- Production explainability is expected to pass only against retained release
  evidence. On active feature branches or dirty worktrees, production status
  may correctly report `not-ready` when the current checkout does not match the
  retained release evidence.
- The dual-node cockpit validation is an operator-driven terminal workflow. It
  does not mean Atlas operated the HP host, Surface host, SSH session, tmux
  session, network, or lab environment.
- The reviewer package is metadata-only and does not embed raw runtime
  evidence.
- This validation does not inspect private customer environments, live targets,
  payment systems, or sensitive business records.

## Non-Guarantees

This external review validation is:

- not external audit
- not certification
- not legal compliance
- not tamper-proof infrastructure
- not external SLSA certification
- not runtime safety proof
- not production deployability proof

## Metadata Boundary

The validation records IDs, paths, hashes, timestamps, command names, commit
IDs, tag names, workflow identities, verification states, and known
limitations. It does not include secrets, credentials, tokens, private keys,
session cookies, raw target data, raw customer data, payment data, bank
details, packet captures, full request or response bodies, raw runtime
artifacts, unredacted evidence bodies, raw invoices, raw contracts, exploit
payloads, or unauthorized-access instructions.
