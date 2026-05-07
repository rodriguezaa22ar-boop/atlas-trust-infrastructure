# Atlas Container Verifier

This directory documents the container path for reviewer-style Atlas checks.

The container path is a portability aid, not a hidden source of truth. File-backed
repository material, release packets, reviewer packages, commits, and tags remain
the trust boundary.

Build a verifier image from the repository root with a compatible container
runtime:

```bash
docker build -f containers/Containerfile.verify -t atlas-verify .
```

Run read-only checks:

```bash
docker run --rm atlas-verify ./bin/dev-host-check
docker run --rm atlas-verify ./tools/atlas/bin/atlas doctor
docker run --rm atlas-verify ./tools/atlas/bin/atlas production status
```
