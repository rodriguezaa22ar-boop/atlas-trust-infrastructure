# Case Study: Vendor Payment Change

## Problem

Vendor payment changes are high-trust business events. A requested bank-account
change, payment-method update, or remittance change may involve email,
accounting records, vendor-management notes, bank portal actions, document
storage, approvals, and risk review.

Each system may hold part of the story, but reviewers still need a careful
answer to a simple question:

```text
What demonstrates that this vendor payment change was reviewed under defined
controls without exposing sensitive financial or business records?
```

Atlas treats that question as a business-flow proof-chain problem. It does not
judge the payment, replace the financial systems, or store the sensitive
contents of the workflow. It records scoped metadata that points to reviewed
evidence references, approvals, controls, packets, hashes, and known
limitations.

## Current Fragmented Approach

A typical vendor payment change review may require a reviewer to inspect:

- an email request or support ticket
- vendor master record history
- accounting-system change records
- bank portal confirmation screens
- approval-tool decisions
- document-storage references
- risk-review notes
- callback or secondary-verification evidence
- exception or accepted-risk notes
- audit-log timestamps

Without a retained proof layer, those references can drift. An approval may
exist but not be tied to the vendor record that changed. A bank portal action
may be documented but not linked to the review control. A risk note may exist
but not identify which evidence references were checked.

## Atlas Proof-Layer Approach

Atlas records the vendor payment change workflow as metadata-only business-flow
evidence. The goal is to connect references across existing tools into a
scoped, retained, metadata-first proof chain.

Atlas does not replace accounting software, bank portals, approval tools,
email, document storage, GRC, fraud detection, legal review, or compliance
review. Atlas connects evidence references across those tools into a scoped,
retained, metadata-first proof chain.

The business-flow review path is:

```text
vendor payment change request
  -> scoped business-flow record
  -> system aliases
  -> data-class labels
  -> control objectives
  -> evidence references
  -> approval references
  -> risk and limitation notes
  -> flow packet
  -> verification
  -> retained proof
```

## Business-Flow Proof Chain

For a vendor payment change review, Atlas expects the reviewer to be able to
follow:

1. The flow ID and owner label.
2. The systems involved, recorded as aliases rather than raw sensitive content.
3. The data classes involved.
4. The control objectives expected for the workflow.
5. The evidence IDs and hashes that point to retained, redacted, or external
   evidence references.
6. The approval references that show review decisions were recorded.
7. The known limitations and unresolved review gaps.
8. The flow packet path and verification state.
9. The retention references that show the packet was kept for later review.
10. The responsible-use boundary for what Atlas does and does not conclude.

The result is not a claim that the payment is correct or safe. It is a retained
metadata trail showing what workflow was reviewed, what references were
connected, what controls were represented, what Atlas can verify later, and
what Atlas does not claim.

## What Atlas Stores

Atlas stores vendor-payment workflow metadata such as:

- flow ID
- flow name
- owner label
- environment label
- criticality
- system aliases
- data-class labels
- control objectives
- evidence IDs
- approval references
- finding references
- validation references
- retention packet paths
- timestamps
- SHA-256 hashes
- packet paths
- verification status
- known limitations

## What Atlas Does Not Store

Vendor-payment workflow proof must not store:

- bank account numbers
- routing numbers
- payment card data
- credentials
- tokens
- private keys
- raw invoices
- raw contracts
- raw customer data
- private business records
- unredacted emails
- full request or response bodies
- session cookies
- authorization headers
- exploit payloads
- unauthorized-access instructions

This is the same metadata-only boundary Atlas uses for security operations and
release trust. Atlas should point to evidence references and hash retained
artifacts where appropriate; it should not copy sensitive financial or business
content into public proof packets.

## Systems Involved

A vendor payment change case study may refer to systems by alias:

- `email_system`
- `vendor_management`
- `accounting_system`
- `bank_portal`
- `approval_tool`
- `document_storage`
- `risk_review`
- `audit_log`

Aliases are intentionally descriptive but not content-heavy. The goal is to
show which systems participated in the review without exposing account data,
documents, messages, credentials, or internal portal contents.

## Controls Represented

Atlas can represent expected control objectives such as:

- request source reviewed
- vendor identity checked
- secondary verification recorded
- approval threshold followed
- segregation of duties represented
- accounting change referenced
- bank portal action referenced
- risk exception recorded
- retained packet generated
- packet verification passed

These are control labels, not certifications. Atlas records that the workflow
was reviewed against declared objectives and that references exist for later
inspection.

## Verification Model

The verification model should stay referential and metadata-first:

```bash
atlas flow show vendor-payment-change
atlas flow packet vendor-payment-change vendor-payment-change-review
atlas flow verify vendor-payment-change vendor-payment-change-review
atlas flow assurance vendor-payment-change vendor-payment-change-review
atlas flow trust-chain vendor-payment-change vendor-payment-change-review
```

A reviewer can then inspect the retained packet, evidence IDs, approval
references, hashes, freshness state, known limitations, and verification
status.

## What This Demonstrates

This demonstrates that Atlas can retain and verify metadata showing that a
vendor-payment-change workflow was reviewed under defined controls.

It demonstrates:

- the workflow was named and scoped
- the participating systems were represented
- sensitive data classes were labeled but not embedded
- evidence and approval references were linked
- control objectives were declared
- a metadata-only packet was generated
- verification status and known limitations were retained

This supports business-flow proof and workflow review evidence. It does not
turn Atlas into an accounting system, bank portal, legal reviewer, or fraud
engine. It keeps the review surface focused on metadata-only operational proof.

## What This Does Not Demonstrate

This does not demonstrate:

- that fraud will be prevented
- that the payment should be approved
- that the bank's internal controls were verified
- that every human approval was legitimate
- legal compliance
- external audit completion
- certification of the workflow
- that upstream systems are correctly configured
- that the underlying business decision was correct
- that sensitive records should be copied into Atlas

Atlas can show what it connected, retained, and verified as metadata. It cannot
turn missing upstream evidence into assurance.

## Known Limitations

- Business-flow evidence is optional in Atlas.
- A flow packet is metadata-only and does not include the raw financial records.
- Control labels are not a legal or compliance conclusion.
- Atlas verification depends on the quality and availability of referenced
  evidence.
- Atlas does not validate bank systems, vendor systems, or accounting-system
  internals.
- A retained proof chain can support review, but it does not replace the
  organization's approval, legal, compliance, finance, or risk processes.

## Responsible-Use Boundary

This case study is about authorized business workflow review and
metadata-first operational proof. Do not use Atlas to collect sensitive payment
records, bypass approvals, impersonate reviewers, infer authorization, or make
claims that the retained metadata does not support.

Atlas should make business-flow claims easier to review and harder to overstate.
