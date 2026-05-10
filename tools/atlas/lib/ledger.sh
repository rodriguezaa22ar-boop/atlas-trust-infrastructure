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

atlas_ledger_require_hash_tool() {
  command -v sha256sum >/dev/null 2>&1 || fail "command not found: sha256sum"
}

atlas_ledger_hash_json() {
  local json="$1"

  atlas_ledger_require_hash_tool
  printf '%s\n' "$json" | jq -cS 'del(.event_hash)' | sha256sum | awk '{ print $1 }'
}

atlas_ledger_hash_file() {
  local path="$1"

  atlas_ledger_require_hash_tool
  sha256sum "$path" | awk '{ print $1 }'
}

atlas_ledger_verify_hash_json() {
  local ledger_file="$1"
  local line
  local line_no=0
  local expected_prev="GENESIS"
  local prev_hash=""
  local current_prev
  local event_hash
  local computed_hash
  local duplicate_id

  intel_require_jq
  atlas_ledger_require_hash_tool

  [ -f "$ledger_file" ] || fail "missing ledger: $ledger_file"
  [ -s "$ledger_file" ] || fail "ledger is empty: $ledger_file"

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
    [ -n "$line" ] || fail "ledger event $line_no is empty"

    printf '%s\n' "$line" | jq -e . >/dev/null 2>&1 ||
      fail "ledger event $line_no invalid JSON"

    printf '%s\n' "$line" | jq -e '
      . as $event |
      def nonempty($key): ($event[$key] | type == "string" and length > 0);
      ($event | type == "object") and
      $event.schema_version == "atlas.run_event.v1" and
      nonempty("event_id") and
      nonempty("event_type") and
      nonempty("timestamp") and
      $event.metadata_only == true and
      nonempty("actor") and
      nonempty("capability") and
      (["allow", "deny", "approval_required", "unsupported", "not_in_scope"] | index($event.decision)) and
      (["requested", "approved", "running", "pass", "fail", "not-ready", "expired", "skipped"] | index($event.status)) and
      ($event.evidence_refs | type == "array") and
      all($event.evidence_refs[]; type == "string" and length > 0) and
      nonempty("prev_hash") and
      ($event.event_hash | test("^[a-f0-9]{64}$")) and
      ([
        paths
        | .[]?
        | tostring
        | select(
            . == "raw_evidence" or
            . == "evidence_body" or
            . == "request_body" or
            . == "response_body" or
            . == "secret" or
            . == "token" or
            . == "private_key"
          )
      ] | length == 0)
    ' >/dev/null || fail "ledger event $line_no invalid fields"

    current_prev="$(printf '%s\n' "$line" | jq -r '.prev_hash')"
    if [ "$line_no" -eq 1 ]; then
      [ "$current_prev" = "GENESIS" ] || fail "ledger event $line_no prev_hash mismatch"
    else
      [ "$current_prev" = "$expected_prev" ] || fail "ledger event $line_no prev_hash mismatch"
    fi

    event_hash="$(printf '%s\n' "$line" | jq -r '.event_hash')"
    computed_hash="$(atlas_ledger_hash_json "$line")"
    [ "$event_hash" = "$computed_hash" ] || fail "ledger event $line_no event_hash mismatch"

    prev_hash="$event_hash"
    expected_prev="$event_hash"
  done <"$ledger_file"

  [ "$line_no" -gt 0 ] || fail "ledger is empty: $ledger_file"

  duplicate_id="$(
    jq -sr '
      map(.event_id)
      | group_by(.)
      | map(select(length > 1) | .[0])
      | .[0] // empty
    ' "$ledger_file"
  )"
  [ -z "$duplicate_id" ] || fail "ledger duplicate event_id $duplicate_id"

  jq -cn \
    --arg schema_version "atlas.ledger_verify.v1" \
    --arg status "ok" \
    --argjson event_count "$line_no" \
    --arg head_event_hash "$prev_hash" \
    '{
      schema_version: $schema_version,
      status: $status,
      event_count: $event_count,
      head_event_hash: $head_event_hash
    }'
}

atlas_ledger_hash_line_json() {
  local json="$1"

  atlas_ledger_require_hash_tool
  printf '%s\n' "$json" | jq -cS . | sha256sum | awk '{ print $1 }'
}

atlas_ledger_verify_operation_json() {
  local ledger_file="$1"
  local line
  local line_no=0
  local head_event_hash=""

  intel_require_jq
  atlas_ledger_require_hash_tool

  [ -f "$ledger_file" ] || fail "missing ledger: $ledger_file"
  [ -s "$ledger_file" ] || fail "ledger is empty: $ledger_file"

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
    [ -n "$line" ] || fail "operation ledger event $line_no is empty"

    printf '%s\n' "$line" | jq -e . >/dev/null 2>&1 ||
      fail "operation ledger event $line_no invalid JSON"

    printf '%s\n' "$line" | jq -e '
      . as $event |
      def nonempty($key): ($event[$key] | type == "string" and length > 0);
      def bad_value: test("password=|passwd=|api_key=|secret=|token=|authorization:|bearer[[:space:]]|set-cookie:|BEGIN RSA|BEGIN OPENSSH|session=|cookie="; "i");
      ($event | type == "object") and
      nonempty("ts") and
      nonempty("event") and
      nonempty("op") and
      nonempty("target") and
      nonempty("capability") and
      nonempty("tool") and
      nonempty("status") and
      ($event.detail | type == "string") and
      ([
        paths
        | .[]?
        | tostring
        | select(
            . == "raw_evidence" or
            . == "evidence_body" or
            . == "request_body" or
            . == "response_body" or
            . == "secret" or
            . == "token" or
            . == "private_key"
          )
      ] | length == 0) and
      ([
        paths(scalars) as $p
        | select(((getpath($p) | type) == "string") and (getpath($p) | bad_value))
      ] | length == 0)
    ' >/dev/null || fail "operation ledger event $line_no invalid fields"

    head_event_hash="$(atlas_ledger_hash_line_json "$line")"
  done <"$ledger_file"

  [ "$line_no" -gt 0 ] || fail "ledger is empty: $ledger_file"

  jq -cn \
    --arg schema_version "atlas.ledger_verify.v1" \
    --arg status "ok" \
    --arg ledger_type "atlas.operation_ledger.v1" \
    --argjson event_count "$line_no" \
    --arg head_event_hash "$head_event_hash" \
    '{
      schema_version: $schema_version,
      status: $status,
      ledger_type: $ledger_type,
      event_count: $event_count,
      head_event_hash: $head_event_hash
    }'
}

atlas_ledger_verify_json() {
  local ledger_file="$1"
  local first_line
  local schema_version

  [ -f "$ledger_file" ] || fail "missing ledger: $ledger_file"
  [ -s "$ledger_file" ] || fail "ledger is empty: $ledger_file"

  first_line="$(sed -n '1p' "$ledger_file")"
  printf '%s\n' "$first_line" | jq -e . >/dev/null 2>&1 ||
    fail "ledger event 1 invalid JSON"
  schema_version="$(printf '%s\n' "$first_line" | jq -r '.schema_version // ""')"

  if [ "$schema_version" = "atlas.run_event.v1" ]; then
    atlas_ledger_verify_hash_json "$ledger_file"
  else
    atlas_ledger_verify_operation_json "$ledger_file"
  fi
}

atlas_ledger_command_input_file() {
  local input="$1"
  local temp_file=""

  if [ "$input" = "-" ]; then
    temp_file="$(mktemp)"
    cat >"$temp_file"
    printf '%s\n' "$temp_file"
    return 0
  fi

  [ -f "$input" ] || fail "missing ledger: $input"
  printf '%s\n' "$input"
}

cmd_ledger_verify() {
  need_args 1 "$#" "ledger verify <ledger-file|-> [--json]"
  local input="$1"
  local json=0
  local ledger_file
  local verify_json

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    *)
      fail "unknown ledger verify option: $1"
      ;;
    esac
  done

  ledger_file="$(atlas_ledger_command_input_file "$input")"
  verify_json="$(atlas_ledger_verify_json "$ledger_file")"

  if [ "$json" -eq 1 ]; then
    printf '%s\n' "$verify_json"
  else
    printf 'ledger: ok\n'
  fi

  if [ "$input" = "-" ]; then
    rm -f "$ledger_file"
  fi
}

cmd_ledger_checkpoint() {
  need_args 1 "$#" "ledger checkpoint <ledger-file|-> [--json]"
  local input="$1"
  local json=0
  local ledger_file
  local verify_json
  local event_count
  local head_event_hash
  local ledger_hash
  local checkpoint_json

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    *)
      fail "unknown ledger checkpoint option: $1"
      ;;
    esac
  done

  ledger_file="$(atlas_ledger_command_input_file "$input")"
  verify_json="$(atlas_ledger_verify_json "$ledger_file")"
  event_count="$(printf '%s\n' "$verify_json" | jq -r '.event_count')"
  head_event_hash="$(printf '%s\n' "$verify_json" | jq -r '.head_event_hash')"
  ledger_hash="$(atlas_ledger_hash_file "$ledger_file")"

  checkpoint_json="$(
    jq -cn \
      --arg schema_version "atlas.checkpoint.v1" \
      --arg checkpoint_id "checkpoint_${ledger_hash:0:12}" \
      --arg timestamp "$(timestamp)" \
      --arg ledger_ref "$input" \
      --argjson event_count "$event_count" \
      --arg head_event_hash "$head_event_hash" \
      --arg ledger_hash "$ledger_hash" \
      '{
        schema_version: $schema_version,
        checkpoint_id: $checkpoint_id,
        timestamp: $timestamp,
        metadata_only: true,
        ledger_ref: $ledger_ref,
        event_count: $event_count,
        head_event_hash: $head_event_hash,
        ledger_hash: $ledger_hash
      }'
  )"

  if [ "$json" -eq 1 ]; then
    printf '%s\n' "$checkpoint_json"
  else
    printf 'ledger checkpoint: ok\n'
    printf 'events: %s\n' "$event_count"
    printf 'head_event_hash: %s\n' "$head_event_hash"
    printf 'ledger_hash: %s\n' "$ledger_hash"
  fi

  if [ "$input" = "-" ]; then
    rm -f "$ledger_file"
  fi
}
