# Schema Contract: atlas.business_flow.v1

## Purpose

`atlas.business_flow.v1` describes the file-backed env record created by
`atlas flow add`. It stores metadata labels for a business-critical workflow
without storing customer data, secrets, request bodies, response bodies,
payment data, or raw evidence.

The record is global Atlas state under:

```text
state/atlas/flows/<flow-slug>.env
```

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `SCHEMA_VERSION` | string | Must be `atlas.business_flow.v1`. |
| `FLOW_ID` | string | Stable Atlas flow ID, for example `flow_customer_signup`. |
| `FLOW_SLUG` | string | Slug used for the env filename and command lookup. |
| `FLOW_NAME` | string | Operator-provided business flow name. |
| `FLOW_TYPE` | string | Flow category such as `customer_onboarding`. |
| `OWNER` | string | Business or technical owner label. |
| `CRITICALITY` | string | `low`, `medium`, `high`, or `critical`. |
| `ENVIRONMENT` | string | Environment label such as `local`, `staging`, or `production`. |
| `SCOPE_STATUS` | string | Scope label for the flow review context. |
| `DATA_CLASSES` | CSV string | Data-class labels only. |
| `SYSTEMS` | CSV string | System aliases only. |
| `CONTROL_OBJECTIVES` | CSV string | Control objective labels only. |
| `CREATED_AT` | string | Creation timestamp. |
| `UPDATED_AT` | string | Last update timestamp. |
| `SOURCE_TOOL` | string | Must identify Atlas as the source tool. |
| `MODE` | string | Must be `business_flow`. |
| `METADATA_ONLY` | boolean string | Must be `true`. |

## Allowed Values

- `CRITICALITY`: `low`, `medium`, `high`, `critical`
- `MODE`: `business_flow`
- `METADATA_ONLY`: `true`

`DATA_CLASSES`, `SYSTEMS`, and `CONTROL_OBJECTIVES` are labels. They are not
content fields and must not contain raw business data.

## Forbidden Content

Flow records must not include:

- passwords
- API keys
- tokens
- private keys
- session cookies
- authorization headers
- raw customer records
- payment card data
- request bodies
- response bodies
- raw evidence bodies
- private business documents

## Verification Rules

A verifier should fail when:

- `SCHEMA_VERSION` is not `atlas.business_flow.v1`.
- Required fields are missing.
- `MODE` is not `business_flow`.
- `METADATA_ONLY` is not `true`.
- `CRITICALITY` is not one of the allowed values.
- A forbidden raw-content marker appears in any value.
- The env file cannot be loaded by Atlas.

## Non-Goals

- This record is not a business-process transcript.
- This record is not a customer-data store.
- This record is not a payment processor record.
- This record does not prove control effectiveness by itself.
