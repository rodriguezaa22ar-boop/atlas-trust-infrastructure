#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'atlas github repo trust surface: fail %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command $1"
}

usage() {
  cat <<'USAGE'
usage: import-github-actions-events.sh <run-event.json> <check-event.json> <out-dir>

Requires ATLAS_ROOT to point at an atlas-trust-infrastructure checkout.
Writes metadata-only linked receipts into <out-dir>.
USAGE
}

[ "$#" -eq 3 ] || {
  usage >&2
  exit 2
}

run_event="$1"
check_event="$2"
out_dir="$3"
atlas_root="${ATLAS_ROOT:-}"

[ -n "$atlas_root" ] || fail "ATLAS_ROOT is required"
[ -x "$atlas_root/tools/atlas/bin/atlas" ] || fail "missing atlas binary under ATLAS_ROOT"
[ -f "$run_event" ] || fail "missing run event $run_event"
[ -f "$check_event" ] || fail "missing check event $check_event"

require_command jq
require_command sha256sum

mkdir -p "$out_dir"
chmod 700 "$out_dir" 2>/dev/null || true

run_receipt="$out_dir/github-actions-run.receipt.json"
check_receipt="$out_dir/github-actions-check.receipt.json"
replay_summary="$out_dir/github-actions-replay.summary.json"

"$atlas_root/tools/atlas/bin/atlas" receipt import-generic-event \
  "$run_event" \
  --out "$run_receipt" >/dev/null

"$atlas_root/tools/atlas/bin/atlas" receipt verify "$run_receipt" >/dev/null

prev_hash="$(jq -r '.event_hash' "$run_receipt")"

"$atlas_root/tools/atlas/bin/atlas" receipt import-generic-event \
  "$check_event" \
  --prev-hash "$prev_hash" \
  --out "$check_receipt" >/dev/null

"$atlas_root/tools/atlas/bin/atlas" receipt verify "$check_receipt" >/dev/null
"$atlas_root/tools/atlas/bin/atlas" receipt replay \
  "$run_receipt" \
  "$check_receipt" >"$replay_summary"

printf 'atlas github repo trust surface: ok\n'
printf 'receipts: %s\n' "$out_dir"
