# Atlas Responsible Use

## Purpose

Atlas coordinates authorized security assessment workflows. Use it only where
you have permission to assess the target, collect evidence, and retain
operation metadata.

## Required Operator Practices

- Define scope before target-touching work.
- Keep target records accurate.
- Use approval gates for validation.
- Preserve evidence hashes and retained artifacts.
- Redact sensitive material before summaries or external handoff.
- Record accepted risk ownership, reason, and review dates.
- Stop when scope, authorization, or safety is unclear.

## Disallowed Workflows

Do not use Atlas to support:

- unauthorized access
- autonomous exploitation
- persistence
- destructive testing
- credential spraying
- denial-of-service workflows
- stealth or evasion behavior
- out-of-scope target expansion
- malware-like behavior

## AI Advisor Boundary

The AI Advisor Interface is a state reader and drafting aid. It must not be
treated as an execution engine, authorization source, or approval bypass.

Advisor packets remain metadata-only and should not include raw secrets,
tokens, private keys, unredacted evidence bodies, or exploit payloads.
