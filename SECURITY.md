# Security Policy

## Project Status

Atlas is a metadata-first trust control plane for authorized security workflows,
evidence retention, release trust, and business-flow proof.

The repository may report local readiness states such as internal readiness,
release-trust readiness, or production-ready under the local Atlas contract.
Those states do not mean external audit, enterprise certification, deployment
certification, legal compliance, immutable storage, or tamper-proof
infrastructure.

## Reporting Vulnerabilities

Use GitHub private vulnerability reporting when available. If private reporting
is not available, open a GitHub issue with a metadata-only description and ask
for a private coordination channel before sharing sensitive detail.

Do not include any of the following in public issues, pull requests, comments,
or attachments:

- credentials, tokens, passwords, private keys, or session cookies
- customer data, payment data, or private business records
- raw packet captures, full request bodies, or full response bodies
- live target data from systems you do not own or control
- exploit payloads or instructions for unauthorized access

Safe reports should include:

- affected command, file, or document
- expected behavior
- observed behavior
- impact on scope, evidence, retention, release trust, or verification
- minimal reproduction steps using synthetic data

## Authorized-Use Boundary

Atlas is for authorized assessment orchestration only. Do not use this project
to perform unauthorized access, autonomous exploitation, persistence,
credential spraying, denial-of-service workflows, stealth/evasion behavior, or
out-of-scope target expansion.

Security reports should preserve the project boundary: metadata-only evidence,
scope enforcement, operator control, approval gates where required, append-only
ledger semantics, and verifiable retention.

## Supported Surface

The public repository supports reports against tracked source, tests,
documentation, schemas, CI, and retained metadata-only release artifacts.

Runtime state, private target data, private operation evidence, customer data,
and local operator secrets are not supported through public disclosure and
should not be committed or posted.
