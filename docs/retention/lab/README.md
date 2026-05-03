# Atlas Lab Retention

## Purpose

This directory retains metadata-only lab validation records. These records
describe how Atlas evidence was reviewed across local lab nodes without
claiming that Atlas operates, orchestrates, secures, or deploys the lab.

## Retained Records

- [ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md](ATLAS_DUAL_NODE_LAB_VALIDATION_M123.md):
  M123 dual-node HP/Surface lab validation retention.

## Boundary

Lab retention records may include host roles, command names, network-control
roles, repository refs, verification outputs, and known limitations. They must
not include secrets, credentials, private keys, tokens, session cookies, raw
target data, raw customer data, packet captures, full request or response
bodies, exploit payloads, or unauthorized-access instructions.

Lab retention is infrastructure evidence. It is not external audit,
certification, legal compliance, runtime safety proof, production deployment
approval, orchestration proof, and not a claim that Atlas controls the lab.
