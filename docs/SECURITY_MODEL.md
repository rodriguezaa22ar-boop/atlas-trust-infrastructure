# Atlas Security Model

## Purpose

This document describes the current Atlas security assumptions and boundaries.
It is not an external audit report or production certification.

## Authorized Use

Atlas is for authorized assessment orchestration only. Target-touching
workflows should preserve:

- scope checks
- capability classification
- operator intent
- approval gates when required
- ledger events
- evidence handling

## Capability Tiers

- Tier 0: read-only
- Tier 1: passive recon
- Tier 2: active recon
- Tier 3: safe validation, explicit approval required
- Tier 4: intrusive validation, explicit ROE required
- Tier 5: destructive, blocked by default

When unsure, classify higher and require stronger approval.

## Data Handling

Metadata-only packets may include paths, hashes, counts, statuses, timestamps,
commit IDs, branch names, readiness JSON, QA status, and known limitations.

Metadata-only packets must not include raw runtime artifacts, target secrets,
session contents, packet captures, credential material, private keys, tokens,
unredacted evidence bodies, or exploit payloads.

## Local Trust Assumptions

Atlas currently assumes:

- the local operator controls the repository and runtime root
- the local filesystem is available and inspectable
- Git history and tags are useful retention anchors
- Nix development tooling is available for repeatable QA
- external signing and provenance are future hardening layers

## Non-Goals

Atlas is not:

- an autonomous exploitation platform
- a malware, persistence, or evasion framework
- a denial-of-service runner
- a replacement for legal authorization
- a SIEM, EDR, or vulnerability scanner replacement
- production-certified security infrastructure
