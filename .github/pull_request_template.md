# Purpose

Describe the trust, docs, schema, test, or workflow change in one or two
sentences.

## Scope

- [ ] Docs/tests only
- [ ] Runtime behavior changed
- [ ] Workflow or repository hygiene changed
- [ ] Release-trust or reviewer evidence changed

## Validation

List the commands actually run, for example:

```text
git diff --check
./bin/export-public-trust --check
nix-shell --run './bin/dev-qa'
```

## Boundary Check

- [ ] No secrets, tokens, private keys, passwords, or session cookies added
- [ ] No raw target data, customer data, packet captures, request bodies, or
      response bodies added
- [ ] No raw prompts, raw model output, raw logs, or private runtime evidence
      added
- [ ] Known limitations and non-guarantees remain visible where claims changed
- [ ] No certification, legal compliance, tamper-proof, guaranteed safety, or
      model correctness claim added

## Reviewer Notes

Call out any remaining limitations, stale evidence, intentionally unverified
source-system facts, or follow-up review needed.
