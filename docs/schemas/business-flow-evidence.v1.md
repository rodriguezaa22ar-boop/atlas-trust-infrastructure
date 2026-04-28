# Schema Contract: atlas.business_flow_evidence.v1

## Purpose

`atlas.business_flow_evidence.v1` describes a metadata-only business-flow
evidence object. It links a business-critical process to Atlas artifacts without
embedding raw business data, secrets, customer records, request bodies, response
bodies, or credential material.

This is a design contract for the optional Business Flow Evidence aggregate
object. It is not yet emitted by a stable Atlas command. The implemented
file-backed surfaces are documented separately:

- `atlas.business_flow.v1`
- `atlas.business_flow_link.v1`
- `atlas.flow_evidence_link.v1`
- `atlas.flow_finding_link.v1`
- `atlas.flow_validation_link.v1`
- `atlas.business_flow_packet.v1`
- `atlas.business_flow_verify.v1`

## Required Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `schema_version` | string | Must be `atlas.business_flow_evidence.v1`. |
| `flow_id` | string | Stable flow identifier, for example `flow_customer_signup`. |
| `flow_name` | string | Human-readable flow name. |
| `flow_type` | string | Flow category, for example `customer_onboarding` or `payment_checkout`. |
| `owner` | string | Team or operator accountable for the flow. |
| `criticality` | string | `low`, `medium`, `high`, or `critical`. |
| `environment` | string | Environment label such as `local`, `staging`, or `production`. |
| `scope_status` | string | Scope status for the review context. |
| `data_classes` | array of strings | Labels for data classes involved in the flow. |
| `systems` | array of strings | System names or aliases involved in the flow. |
| `control_objectives` | array of strings | Control objectives reviewed for the flow. |
| `evidence_refs` | array of objects | Metadata references to Atlas evidence. |
| `findings_refs` | array of objects | Linked Atlas finding IDs and metadata snapshots. |
| `validation_refs` | array of objects | Linked Atlas validation IDs and metadata snapshots. |
| `approval_refs` | array of strings | Linked approval IDs or approval record references. |
| `freshness` | object | Packet or evidence freshness state. |
| `known_limitations` | array of strings | Explicit limitations of the flow evidence. |
| `created_at` | string | UTC timestamp. |

## Evidence Reference Fields

Each `evidence_refs` item should contain:

| Field | Type | Meaning |
| --- | --- | --- |
| `evidence_id` | string | Atlas evidence ID. |
| `kind` | string | Evidence kind, for example `redacted_report` or `validation_headers`. |
| `sha256` | string | SHA-256 of the retained artifact. |
| `path` | string | Path to retained metadata or redacted artifact. |

Evidence references must not embed the artifact body.

## Freshness Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `status` | string | `missing`, `current`, `stale`, or `blocked`. |
| `last_material_event` | string | Latest linked material event timestamp. |
| `last_packet` | string | Latest packet generation timestamp. |

## Example

```json
{
  "schema_version": "atlas.business_flow_evidence.v1",
  "flow_id": "flow_payment_checkout",
  "flow_name": "Payment Checkout",
  "flow_type": "payment_checkout",
  "owner": "product",
  "criticality": "high",
  "environment": "production",
  "scope_status": "in-scope",
  "data_classes": [
    "email",
    "billing_status_reference",
    "subscription_status_reference"
  ],
  "systems": [
    "web_app",
    "auth_service",
    "billing_service",
    "payment_processor"
  ],
  "control_objectives": [
    "authentication_required",
    "trusted_redirect",
    "webhook_event_handling",
    "audit_logging",
    "pii_minimization"
  ],
  "evidence_refs": [
    {
      "evidence_id": "ev_20260427_001",
      "kind": "redacted_report",
      "sha256": "abc123",
      "path": "sessions/payment-checkout/evidence/ev_20260427_001"
    }
  ],
  "findings_refs": [
    {
      "finding_id": "finding_20260427_001",
      "severity": "medium",
      "status": "open"
    }
  ],
  "validation_refs": [
    {
      "validation_id": "vp_20260427_001",
      "lane": "validate",
      "status": "planned"
    }
  ],
  "approval_refs": [
    "approval_20260427_001"
  ],
  "freshness": {
    "status": "current",
    "last_material_event": "2026-04-27T12:00:00Z",
    "last_packet": "2026-04-27T12:05:00Z"
  },
  "known_limitations": [
    "Raw customer data is not retained in Atlas.",
    "Evidence references are metadata-only."
  ],
  "created_at": "2026-04-27T12:10:00Z"
}
```

## Forbidden Content

This schema must never include:

- passwords
- API keys
- tokens
- private keys
- raw packet captures
- raw database rows
- raw customer records
- full request bodies
- full response bodies
- credit card data
- SSNs
- session cookies
- authorization headers
- private business documents
- credential material

Allowed values are labels, references, hashes, timestamps, owners, status values,
and known limitations.

## Verification Rules

A verifier should fail when:

- `schema_version` is not `atlas.business_flow_evidence.v1`.
- Required fields are missing.
- Linked evidence IDs are missing from the active operation.
- Referenced artifact hashes do not match.
- Linked findings or validations are missing.
- Freshness is stale when strict verification requires current state.
- Any forbidden raw-content marker appears in the object or packet.

## Non-Goals

- This schema is not a PCI evidence store.
- This schema is not a customer-data retention format.
- This schema is not a payment processor settlement record.
- This schema is not a full JSON Schema document yet.
