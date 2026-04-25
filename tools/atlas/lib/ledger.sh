#!/usr/bin/env bash

atlas_ledger_file() {
  local op_dir="$1"

  printf '%s/ledger.ndjson\n' "$op_dir"
}

atlas_ledger_append() {
  local op_dir="$1"
  local event="$2"
  local op="$3"
  local target="$4"
  local capability="$5"
  local tool="$6"
  local status="$7"
  local detail="$8"
  local ledger

  intel_require_jq

  ledger="$(atlas_ledger_file "$op_dir")"
  mkdir -p "$op_dir"
  : >>"$ledger"
  chmod 600 "$ledger" 2>/dev/null || true

  jq -cn \
    --arg ts "$(timestamp)" \
    --arg event "$event" \
    --arg op "$op" \
    --arg target "$target" \
    --arg capability "$capability" \
    --arg tool "$tool" \
    --arg status "$status" \
    --arg detail "$detail" \
    '{
      ts: $ts,
      event: $event,
      op: $op,
      target: $target,
      capability: $capability,
      tool: $tool,
      status: $status,
      detail: $detail
    }' >>"$ledger"
}

atlas_ledger_append_current() {
  local event="$1"
  local capability="$2"
  local tool="$3"
  local status="$4"
  local detail="$5"

  atlas_ledger_append \
    "$ATLAS_OP_DIR" \
    "$event" \
    "$ATLAS_OP_SLUG" \
    "$ATLAS_OP_TARGET" \
    "$capability" \
    "$tool" \
    "$status" \
    "$detail"
}
