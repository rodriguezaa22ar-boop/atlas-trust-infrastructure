# Atlas v0.4.0-rc1 Independent Review Packet

## Purpose

This packet gives an independent reviewer a single, executable checklist for
reviewing the Atlas v0.4.0-rc1 SLSA-verifiable release evidence.

It is metadata-only. It does not include secrets, credentials, customer data,
raw evidence bodies, packet captures, private keys, or runtime target data.

## Review Scope

Review target:

- Repository: `rodriguezaa22ar-boop/atlas-trust-infrastructure`
- Release candidate tag: `atlas-v0.4.0-rc1`
- Release artifact commit:
  `59667bf875871c1e27dbd72de20c983ac262b43b`
- Retained evidence state: `atlas-retention-m103`
- Retained evidence commit:
  `23bc8353b4e56beb30fc157f22323951e389c117`

The release artifact commit is the source commit built by GitHub Actions. The
retained evidence state is the later Atlas commit that records the verification
results. Review both.

## Evidence Inventory

Release assets:

- Release page:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/releases/tag/atlas-v0.4.0-rc1`
- Source artifact:
  `atlas-trust-infrastructure-atlas-v0.4.0-rc1-59667bf87587.tar.gz`
- Source artifact SHA-256:
  `a6fad42ced88648e49b8cbb9fcfe90533e2e389145277482f1000449108d0805`
- Checksum asset:
  `atlas-trust-infrastructure-atlas-v0.4.0-rc1-59667bf87587.tar.gz.sha256`
- Metadata asset:
  `atlas-trust-infrastructure-atlas-v0.4.0-rc1-59667bf87587.metadata.env`
- Official SLSA generic provenance:
  `atlas-trust-infrastructure-atlas-v0.4.0-rc1-59667bf87587.intoto.jsonl`
- Official SLSA generic provenance SHA-256:
  `54e0f5f070192c2716d6923868fd43b2eeab64e588caad6ec11342fdb3d046e5`

GitHub evidence:

- GitHub Artifact Attestation:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/attestations/26040322`
- `Release SLSA Provenance` workflow:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272091`
- `Official SLSA Generic Provenance` workflow:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25153272179`
- M103 QA workflow:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25156528155`
- M103 Pages workflow:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25156527582`

Retained Atlas evidence:

- SLSA reference:
  `docs/retention/releases/atlas-v0.4.0-rc1.slsa.json`
- SLSA claim:
  `docs/atlas/SLSA_CLAIM.md`
- Independent review readiness:
  `docs/atlas/INDEPENDENT_REVIEW_READINESS.md`
- Claim/evidence packet:
  `docs/retention/releases/atlas-m101-slsa-claim-evidence.md`
- M101 milestone:
  `docs/retention/milestones/MILESTONE_101.md`
- M102 milestone:
  `docs/retention/milestones/MILESTONE_102.md`
- M103 milestone:
  `docs/retention/milestones/MILESTONE_103.md`

Local release-trust baseline:

- Release packet:
  `docs/retention/releases/atlas-m93-business-flow-assurance.json`
- Release artifact manifest:
  `docs/retention/releases/atlas-m93-business-flow-assurance.manifest.json`
- Signed release provenance:
  `docs/retention/releases/atlas-m93-business-flow-assurance.provenance.json`

The M93 release-trust baseline is not the v0.4.0-rc1 source artifact. It is the
latest retained local Atlas release artifact manifest available in this repo.
Use it to verify Atlas' local release-trust machinery while using the
v0.4.0-rc1 assets to verify the GitHub/SLSA artifact chain.

## Reviewer Setup

Required tools:

- `git`
- `curl`
- `sha256sum`
- `gh`, authenticated with GitHub
- `slsa-verifier`
- `nix-shell`

Create a clean review workspace:

```bash
workdir="$(mktemp -d)"
cd "$workdir"

git clone https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure.git
cd atlas-trust-infrastructure
git fetch --tags
git checkout atlas-retention-m103
```

Download release assets:

```bash
asset_dir="$workdir/assets"
mkdir -p "$asset_dir"
cd "$asset_dir"

base="atlas-trust-infrastructure-atlas-v0.4.0-rc1-59667bf87587"
release_url="https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/releases/download/atlas-v0.4.0-rc1"

curl -fL -O "$release_url/${base}.tar.gz"
curl -fL -O "$release_url/${base}.tar.gz.sha256"
curl -fL -O "$release_url/${base}.metadata.env"
curl -fL -O "$release_url/${base}.intoto.jsonl"
```

## Required Review Commands

Verify artifact checksum:

```bash
cd "$asset_dir"
sha256sum -c "${base}.tar.gz.sha256"
test "$(sha256sum "${base}.tar.gz" | awk '{ print $1 }')" = "a6fad42ced88648e49b8cbb9fcfe90533e2e389145277482f1000449108d0805"
```

Verify GitHub Artifact Attestation:

```bash
gh attestation verify "${base}.tar.gz" \
  --repo rodriguezaa22ar-boop/atlas-trust-infrastructure
```

Verify official SLSA generic provenance:

```bash
slsa-verifier verify-artifact "${base}.tar.gz" \
  --provenance-path "${base}.intoto.jsonl" \
  --source-uri github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure \
  --source-tag atlas-v0.4.0-rc1
```

Verify retained Atlas SLSA reference:

```bash
cd "$workdir/atlas-trust-infrastructure"

nix-shell -p gh --run "./tools/atlas/bin/atlas release slsa-verify docs/retention/releases/atlas-v0.4.0-rc1.slsa.json --commit 59667bf875871c1e27dbd72de20c983ac262b43b --artifact '$asset_dir/${base}.tar.gz' --online"
```

Verify Atlas QA on retained evidence state:

```bash
nix-shell --run './bin/dev-qa'
```

Verify retained release-trust baseline:

```bash
./tools/atlas/bin/atlas release verify \
  docs/retention/releases/atlas-m93-business-flow-assurance.json \
  --commit 36e0c7c9b7ce50eaff84100815b927744f937333

./tools/atlas/bin/atlas release manifest-verify \
  docs/retention/releases/atlas-m93-business-flow-assurance.manifest.json \
  --commit 36e0c7c9b7ce50eaff84100815b927744f937333
```

## Checklist

The review passes only if all checks are true:

- The release artifact SHA-256 equals
  `a6fad42ced88648e49b8cbb9fcfe90533e2e389145277482f1000449108d0805`.
- `gh attestation verify` passes for
  `rodriguezaa22ar-boop/atlas-trust-infrastructure`.
- `slsa-verifier verify-artifact` passes for `atlas-v0.4.0-rc1`.
- The SLSA builder is
  `slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@refs/tags/v2.1.0`.
- `atlas release slsa-verify --artifact --online` passes.
- `nix-shell --run './bin/dev-qa'` passes.
- `atlas release verify` passes for the retained M93 release packet.
- `atlas release manifest-verify` passes for the retained M93 release artifact
  manifest.
- No reviewed retained packet embeds secrets, credentials, raw evidence bodies,
  customer data, packet captures, private keys, or tokens.
- The public claim remains bounded to SLSA-verifiable release evidence and does
  not claim external SLSA certification.

## Expected Reviewer Output

```text
Reviewer:
Organization:
Review date:
Review target tag: atlas-v0.4.0-rc1
Release artifact commit: 59667bf875871c1e27dbd72de20c983ac262b43b
Retained evidence commit: 23bc8353b4e56beb30fc157f22323951e389c117
Artifact SHA-256: a6fad42ced88648e49b8cbb9fcfe90533e2e389145277482f1000449108d0805

Commands run:
- sha256sum -c: pass/fail
- gh attestation verify: pass/fail
- slsa-verifier verify-artifact: pass/fail
- atlas release slsa-verify --artifact --online: pass/fail
- nix-shell --run './bin/dev-qa': pass/fail
- atlas release verify: pass/fail
- atlas release manifest-verify: pass/fail

Findings:
- none / list findings

Limitations:
- review is limited to the release-trust and SLSA-verifiable evidence listed
  in this packet
- review does not grant external SLSA certification unless the reviewer
  explicitly states that in a separate certification process

Conclusion:
- pass / pass with notes / fail

May Atlas describe atlas-v0.4.0-rc1 as independently reviewed for this bounded
release-trust scope?
- yes / no / yes with wording restrictions
```

## Non-Claims

This packet does not claim:

- external SLSA certification
- full security audit
- enterprise certification
- deployment certification
- legal compliance
- tamper-proof infrastructure
- review of private customer data or target evidence

It makes the retained release-trust and SLSA-verifiable evidence ready for an
independent reviewer to inspect.
