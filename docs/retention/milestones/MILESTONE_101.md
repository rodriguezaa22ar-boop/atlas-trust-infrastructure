# Milestone 101: Official SLSA And Online Verification Path

## Commit

`cf2eefd60437353851bc7290f216137052c91e9d` Add SLSA online verification path

## Purpose

Tighten Atlas' SLSA-verifiable release path by adding an official generic
SLSA generator workflow, downloaded-artifact verification, optional online
attestation verification, and bounded claim/review documentation.

## Added

- `.github/workflows/release-slsa-generic.yml` using
  `slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0`.
- Official generic-generator release artifact subject hashes via
  `base64-subjects`.
- Release artifact publishing for tag-triggered official SLSA runs.
- `atlas release slsa-verify --artifact <path>` to compare a downloaded
  artifact SHA-256 against a retained `atlas.slsa_provenance.v1` reference.
- `atlas release slsa-verify --online` to run `gh attestation verify` when
  `gh` and a local artifact are available.
- Optional `--repo owner/repo` override for online attestation verification.
- `docs/atlas/SLSA_CLAIM.md`.
- `docs/atlas/INDEPENDENT_REVIEW_READINESS.md`.
- `docs/retention/releases/atlas-m101-slsa-claim-evidence.md`.
- Documentation updates for SLSA provenance, CI, release trust, schemas,
  roadmap, blueprint, known limitations, command reference, and README docs map.

## Verified

- `bash -n tools/atlas/lib/release.sh`
- `bash -n tools/atlas/bin/atlas`
- `git diff --check`
- focused Bats:
  `official SLSA generic workflow and claim docs define external verification path`,
  `atlas release slsa-verify checks retained SLSA provenance references`,
  `atlas release slsa-verify checks local artifacts and optional online attestations`,
  `ci workflow mirrors local Atlas QA gate`,
  `schema docs pin implemented Atlas JSON contracts`, and
  `atlas help groups target-first workflow and story commands`: 6/6
- `nix-shell --run './bin/dev-qa'`: 105/105, lint ok, stress ok

## Trust Impact

Atlas now has both:

- a GitHub Artifact Attestations path with `actions/attest@v4`
- an official SLSA generic-generator path with
  `slsa-framework/slsa-github-generator`

Atlas can also verify local artifact digests and optionally perform live GitHub
attestation verification through `gh`.

## Remaining External Work

- Publish a real release-candidate tag.
- Download the release artifact and provenance.
- Retain a matching SLSA reference JSON.
- Run `atlas release slsa-verify --artifact --online`.
- Run `slsa-verifier verify-artifact` for the official generic-generator
  `.intoto.jsonl` file.
- Have an independent reviewer inspect the retained reviewer packet.

## Limitations

- No external SLSA certification is claimed.
- No independent third-party review is claimed yet.
- Atlas does not automatically download artifacts.
- Online verification requires `gh` and network access.
- Official generic-generator verification requires the published `.intoto.jsonl`
  provenance file and `slsa-verifier`.
