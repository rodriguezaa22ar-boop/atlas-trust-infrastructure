# Scale and Storage Strategy M170

## Purpose

Atlas supports larger proof-review workflows by keeping receipts portable,
metadata-only, and locally verifiable while planning for indexed views,
batch verification, batch replay, archive manifests, and reviewer queries.

M170 is architecture planning, not production storage implementation. It does
not add a database, server, hosted verifier, private collector, storage engine,
receipt semantic change, adapter change, live integration, network collector,
web UI, or hidden state.

## Current State

Current Atlas remains local-first and file-backed:

- shell-native commands are the primary interface;
- receipts, examples, schemas, proof packages, and retained evidence are
  inspectable files;
- proof receipts are metadata-only records;
- retained public evidence lives under `docs/retention/`;
- public examples live under `examples/`;
- reviewer packages and proof docs remain readable without a service;
- the verifier runs locally and does not require hosted infrastructure;
- the public repository contains proof surface, docs, schemas, examples, tests,
  and metadata-only retained evidence.

Atlas should sit above existing systems instead of replacing them. CI systems,
approval systems, release systems, AI-agent systems, and business workflows can
be event sources. Atlas remains the verifier and reviewer proof layer.

## Scale Goals

Atlas should be able to support:

- thousands of metadata-only receipts;
- large replay chains and chain segments;
- multiple workflow sources;
- multiple review objectives;
- CI/release, AI-agent, approval, and business workflow events;
- reviewer-friendly query and replay paths;
- evidence sufficiency summaries for mapped objectives;
- portable receipt exports that can be reviewed outside a private collector.

The goal is not to make Atlas look more complete by hiding state in a database.
The goal is to preserve file-backed truth while making larger proof sets easier
to inspect, index, replay, and summarize.

## Receipt Volume Assumptions

### Small Project Scale

Small project scale can remain plain file-backed:

- tens to hundreds of receipts;
- one or a few chains;
- examples and reviewer packets checked into a repo;
- manual replay by path or glob;
- simple Markdown or JSON summaries.

### Team Scale

Team scale may need lightweight indexes:

- hundreds to thousands of receipts;
- multiple branches, releases, and review objectives;
- active receipt directories plus generated index files;
- batch verify summaries;
- replay checkpoints for long chains;
- reviewer queries by actor, commit, workflow, source, and time window.

### Organization Scale

Organization scale may need stronger indexing discipline:

- thousands or tens of thousands of metadata-only receipts;
- several workflow sources;
- multiple release, CI, approval, AI-agent, and business-flow objectives;
- archive rotation with manifests;
- chain-head and checkpoint indexes;
- evidence sufficiency rollups for reviewers.

### Large Enterprise Or Private Collector Scale

Large private environments may later need collector-side indexes or replicas.
Those indexes may improve query speed, but they must not replace inspectable
receipts as the source of truth. A private collector must be able to export
portable receipts and indexes that a local verifier can inspect without raw
logs, secrets, prompts, customer data, or hosted dependencies.

## Storage Principles

Atlas storage should follow these rules:

- metadata-only by default;
- raw logs, secrets, prompts, private data, and sensitive business content are
  excluded;
- receipts remain portable files;
- local verifier compatibility remains mandatory;
- indexed views may exist, but source-of-truth receipts remain inspectable;
- hidden databases must not become the only source of truth;
- file-backed truth comes before indexed replicas;
- SQLite or other indexed storage should wait until event, graph, and packet
  contracts stabilize;
- storage scale must not weaken receipt verify, replay, canonicalization,
  release trust, reviewer packages, or evidence sufficiency boundaries.

## File Layout Strategy

A future receipt storage layout can remain file-first:

```text
receipts/
  active/
  index/
  archive/
  checkpoints/
  batches/
docs/retention/
examples/
reviewer-packages/
```

Suggested meanings:

- `receipts/active/`: current receipt batches that reviewers query often.
- `receipts/index/`: generated metadata-only index files and chain-head maps.
- `receipts/archive/`: older batches retained with manifests and archive hashes.
- `receipts/checkpoints/`: replay checkpoints for long chains.
- `receipts/batches/`: batch manifests and batch verification summaries.
- `docs/retention/`: public retained milestone and release-trust evidence.
- `examples/`: public synthetic and local-file examples.
- `reviewer-packages/`: generated metadata-only reviewer bundles.

Future private collector paths should be clearly marked as future and private.
They should not be required for public verification.

## Indexing Strategy

Indexes should be generated, metadata-only views over receipt files. Useful
index keys include:

- content-addressed receipt hashes;
- `event_hash`;
- `receipt_hash`;
- `prev_hash`;
- workflow or source type;
- subject type and subject reference;
- actor;
- timestamp;
- `evidence_refs`;
- `artifact_refs`;
- `known_limitations`;
- verification status;
- chain head;
- review objective;
- sufficiency status.

Indexes should record enough information for reviewer navigation, but the
receipt file remains the proof object that local verification checks.

## Deduplication Strategy

Deduplication should reduce storage noise without erasing review context:

- dedupe identical receipt files by `receipt_hash`;
- detect duplicate `event_hash` values;
- keep duplicate references when different workflows reference the same
  receipt;
- do not collapse evidence meaning just because hashes match;
- preserve reviewer context, objective labels, source labels, and limitation
  notes.

Two workflows can point to the same receipt for different review objectives.
That should remain visible.

## Archive and Rotation Strategy

Archive strategy should keep active receipts easy to query while preserving
reviewability:

- keep active receipts in readable directories;
- move old receipt batches to archive after a checkpoint;
- retain index files and checkpoint files;
- keep replay paths clear for archived chains;
- avoid deleting required retained evidence;
- define stale and unverifiable archive states;
- detect archive/source mismatches during verification;
- keep archive manifests close to archived batches.

Archived does not mean unimportant. It means the batch is less active and must
remain traceable through manifest, hash, checkpoint, and replay metadata.

## Compression Strategy

Compression should be conservative:

- compress archived batches only;
- keep active examples readable;
- never compress in a way that prevents local verification;
- record archive hash;
- record a manifest and checkpoint for compressed archives;
- keep enough metadata outside the compressed archive for reviewer discovery;
- report compression or decompression failure as unverifiable.

Compression is a storage optimization, not a trust guarantee.

## Batch Verification

Batch verification should verify many receipts without loading raw artifacts.
A batch verify report should:

- verify receipt structure and hashes;
- summarize pass, fail, stale, and unverifiable counts;
- preserve metadata-only boundaries;
- emit reviewer summaries;
- keep failure detail traceable to receipt path and hash;
- avoid embedding raw logs or sensitive artifacts;
- preserve non-guarantee language.

Batch verification should make large receipt sets easier to review without
turning presence into sufficiency.

## Batch Replay

Batch replay should support:

- replay chains by provided order;
- replay chain segments;
- replay from checkpoint;
- detecting missing `prev_hash` links;
- detecting duplicate heads;
- detecting ambiguous ordering;
- preserving metadata-only replay output.

Replay verifies local receipt hashes and caller-provided chain order, not
external truth. It does not prove complete event coverage or prove that no
action happened outside Atlas.

## Evidence Sufficiency At Scale

Evidence sufficiency should remain explicit at larger scale:

- present;
- missing;
- stale;
- unverifiable;
- outside Atlas.

Atlas can support objective-level summaries that show which evidence exists,
which evidence needs attention, and which determinations remain outside Atlas.
Evidence present does not automatically mean evidence sufficient.

## Reviewer Query Needs

Reviewers will need queries by:

- actor;
- workflow or source;
- subject or subject reference;
- commit;
- review objective;
- evidence status;
- chain head;
- time window;
- limitation;
- unsupported decision.

These queries can be backed by generated index files first. A future private
collector may accelerate the same queries, but the query result should point
back to portable receipt files, manifests, checkpoints, and reviewer packages.

## Public/Private Boundary

The public repository may contain:

- metadata-only examples;
- docs;
- schemas;
- retained public evidence;
- public proof packages;
- synthetic or redacted fixtures.

The public repository must not contain raw sensitive data. Private or on-prem
collectors may later store private receipt metadata, but they must preserve the
metadata-only boundary by default and avoid raw logs, secrets, prompts, private
business records, customer data, and unredacted evidence bodies.

## Future Private Collector Boundary

A future private collector may index receipts. It must not become:

- an action authority;
- an approval authority;
- an execution engine;
- a secret store;
- the only source of proof truth.

A private collector should:

- emit exportable portable receipts;
- preserve local verifier compatibility;
- store metadata-only records by default;
- keep private source-system credentials out of receipt exports;
- make index/source mismatches visible;
- support reviewer package generation without raw sensitive content.

## Future Hosted Verifier Boundary

A hosted verifier may provide convenience later. It must not be required to
verify receipts. The local verifier remains open and authoritative for receipt
verification.

A hosted verifier must not require raw sensitive data. It should accept
metadata-only receipt exports and return bounded verification summaries that
can be reproduced locally.

## Failure Modes

Atlas storage and replay at scale must handle:

- missing receipt;
- stale receipt;
- duplicate receipt;
- unverifiable receipt;
- malformed receipt;
- missing `prev_hash`;
- chain ordering ambiguity;
- duplicate chain heads;
- archive corruption;
- missing archive manifest;
- stale index;
- index/source mismatch;
- compression failure;
- private/public boundary violation;
- evidence present but not sufficient;
- reviewer misinterprets status.

Each failure mode should produce a traceable status, not a vague pass.

## What Atlas Must Not Store

Atlas public proof packages and metadata-only receipts must not store:

- raw logs;
- secrets;
- raw prompts;
- raw model outputs;
- private keys;
- credentials;
- Authorization headers;
- request bodies;
- response bodies;
- packet captures;
- customer data;
- payment data;
- private business records;
- unredacted evidence bodies.

Private collectors should follow the same default. If a future private
deployment stores sensitive source-system material outside Atlas receipts, that
material remains outside the public proof boundary and outside default receipt
exports.

## Architecture Layers

Atlas should keep storage and review concerns separated:

- adapter layer: import local metadata-only events into receipt-compatible
  records;
- control layer: keep policy, approval, release trust, and production status
  gates explicit;
- workflow layer: map receipts to CI, release, AI-agent, approval, and
  business workflows;
- evidence layer: track references, hashes, manifests, checkpoints, and
  sufficiency states;
- review layer: produce reviewer packages, decision packets, plain-English
  summaries, and public proof surfaces.

This keeps Atlas above existing systems instead of replacing them.

## Future Milestones

Likely follow-up milestones:

- receipt index manifest;
- batch verify report;
- batch replay report;
- archive manifest;
- checkpoint strategy;
- private collector contract;
- hosted verifier contract;
- scale simulation dry-run;
- storage safety regression.

## Boundaries

M170 does not implement production storage. It does not implement an enterprise
collector, hosted verifier, database, server, network collector, web UI, live
integration, or new adapter.

Future indexing must not replace inspectable receipts as the source of truth.
Future private collectors or hosted verifiers must preserve metadata-only
boundaries. Storage scale must not weaken receipt verify, replay,
canonicalization, release trust, reviewer packages, public export, or evidence
sufficiency boundaries.

Known limitations remain visible: Atlas verifies the proof envelope it can
inspect locally; reviewers, auditors, approvers, and authorities still make
final determinations.
