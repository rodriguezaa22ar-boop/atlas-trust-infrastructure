# External Project Receipt Failure Review

## Purpose

M191 is a safety regression milestone for the M190 external-project receipt
pilot. It gives reviewers a small failure map for metadata-only receipt review
without changing receipt semantics, hashing, canonicalization, replay behavior,
runtime execution, UI, server state, or source-system authority.

The failure examples are synthetic. They are reviewer aids for understanding why
Atlas fails closed. They are not runtime evidence, production certification,
legal sufficiency, compliance approval, external audit completion, or proof that
an external action was correct.

## Failure Classes

| Failure class | Example condition | Expected verifier posture | Reviewer action |
| --- | --- | --- | --- |
| Metadata boundary disabled | `metadata_only=false` | Reject the event or receipt. | Request a metadata-only envelope with references and hashes only. |
| Raw artifacts declared | `raw_artifacts_embedded=true` | Reject the event or receipt. | Keep raw evidence in the source system or approved evidence store, then reference it by ID or digest. |
| Required metadata missing | required schema or identity field omitted | Reject before receipt review. | Ask for a complete event envelope before relying on the receipt. |
| Raw or sensitive marker present | raw prompt, raw log, request body, response body, token, credential, private keys, packet capture, or unredacted body marker | Reject before import or verification. | Remove raw content and replace it with a stable reference or hash. |
| Receipt hash changed | receipt fields are edited after creation | Reject verification. | Regenerate the receipt from the source event and compare the resulting hash. |
| Chain order broken | later receipt appears before its `prev_hash` parent | Reject replay. | Reorder receipts or locate the missing predecessor before review. |

## Reviewer Interpretation

A passing external-project receipt means Atlas could verify the local metadata
contract for the receipt file it was given. It can show schema shape, local
hashes, metadata-only flags, forbidden marker absence, and caller-supplied chain
order.

A passing receipt does not prove source-system truth, external artifact
availability, legal compliance, production approval, model correctness, artifact
correctness, complete event coverage, tamper-proof storage, or human judgment.

A failing receipt should be treated as a review blocker for that proof chain,
not as proof that the underlying external action did or did not happen.

## Negative Fixtures

The committed negative fixtures are intentionally synthetic and contain no raw
runtime evidence:

- `negative-metadata-only-false.json`: metadata boundary disabled.
- `negative-raw-artifacts-embedded.json`: raw artifact embedding declared.
- `negative-missing-schema-version.json`: required schema metadata omitted.

The fixture names describe unsafe states. The files do not contain secrets,
tokens, credentials, private keys, request bodies, response bodies, packet
captures, raw prompts, raw outputs, customer data, payment data, private
business records, private target records, or unredacted evidence bodies.

## Non-Changes

M191 does not change receipt creation, import, verification, replay,
canonicalization, hashing, schemas, command grammar, shell behavior, Atlas Node
UI behavior, server behavior, runtime collection, or source-system integration.
