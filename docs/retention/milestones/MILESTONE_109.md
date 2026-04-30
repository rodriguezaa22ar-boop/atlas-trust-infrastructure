# Milestone 109: CodeQL Workflow Scope Correction

## Commit

`f0adc191215c3c900c13843ff1c3cc553c2b90ac` Restrict CodeQL gate to workflow analysis

## Purpose

Correct the initial M108 CodeQL matrix after GitHub proved that the
GitHub Actions workflow analysis succeeded but the JavaScript/TypeScript
analysis failed because the public repository has no tracked JavaScript or
TypeScript source for CodeQL to analyze.

## Added

- CodeQL workflow now analyzes only the current public source surface:
  GitHub Actions workflow YAML.
- CI documentation now states JavaScript/TypeScript CodeQL analysis should be
  added only when tracked JavaScript or TypeScript source exists.
- Regression coverage now rejects `javascript-typescript` in the CodeQL
  workflow until that source surface exists.
- Retained evidence for the passing public CodeQL run:
  `https://github.com/rodriguezaa22ar-boop/atlas-trust-infrastructure/actions/runs/25183639002`

## Verified

- Focused Bats:
  `ci workflow mirrors local Atlas QA gate`: 1/1.
- Public GitHub CodeQL:
  `25183639002` `Analyze GitHub Actions workflows`: success.
- `git diff --check`: passed.
- `nix-shell --run './bin/dev-qa'`: 107/107, lint ok, stress ok.
- `atlas release verify docs/retention/releases/atlas-m109-codeql-workflow-scope.json --commit f0adc191215c3c900c13843ff1c3cc553c2b90ac`:
  verified.
- `atlas release manifest-verify docs/retention/releases/atlas-m109-codeql-workflow-scope.manifest.json --commit f0adc191215c3c900c13843ff1c3cc553c2b90ac`:
  verified.

## Trust Impact

Atlas now has a passing public CodeQL gate over the repository surface CodeQL
can currently analyze. This avoids a false CI signal and preserves claim
discipline: CodeQL is a useful public scanning signal, not proof that every
Atlas runtime path has been statically analyzed.

## Boundaries

- This milestone corrects CI scope; it does not add target-touching behavior.
- CodeQL coverage is currently limited to GitHub Actions workflow YAML.
- CodeQL does not replace manual review, external audit, runtime testing,
  shell linting, Bats coverage, or Atlas retained trust-packet verification.
