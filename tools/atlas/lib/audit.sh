#!/usr/bin/env bash

atlas_audit_ledger_file() {
  local ledger_file

  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || fail "operation ledger is empty or missing: $ledger_file"
  printf '%s\n' "$ledger_file"
}

atlas_audit_latest_packet() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "audit.packet.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_audit_event_count() {
  local ledger_file="$1"

  jq -s 'length' "$ledger_file"
}

atlas_audit_print_event_counts() {
  local ledger_file="$1"

  jq -sr '
    group_by(.event)
    | map({ event: (.[0].event // "?"), count: length })
    | sort_by(.event)
    | .[]
    | [.event, (.count | tostring)]
    | @tsv
  ' "$ledger_file" |
    awk -F'\t' '{ printf "%-32s %s\n", $1, $2 }'
}

atlas_audit_print_timeline() {
  local ledger_file="$1"

  printf '%-20s %-28s %-12s %-16s %-10s %s\n' "TS" "EVENT" "STATUS" "CAPABILITY" "TOOL" "DETAIL"
  jq -r '
    [
      (.ts // "?"),
      (.event // "?"),
      (.status // "?"),
      (.capability // "?"),
      (.tool // "?"),
      ((.detail // "") | gsub("\t"; " ") | gsub("\n"; " "))
    ]
    | @tsv
  ' "$ledger_file" |
    awk -F'\t' '{ printf "%-20s %-28s %-12s %-16s %-10s %s\n", $1, $2, $3, $4, $5, $6 }'
}

atlas_audit_hash_anchor_problem_count() {
  local manifest_file="$1"
  local label="$2"
  local line
  local path
  local expected_sha
  local actual_sha

  line="$(atlas_closeout_manifest_anchor_line "$manifest_file" "$label")"
  if [ -z "$line" ]; then
    printf '1\n'
    return 0
  fi

  path="$(atlas_closeout_anchor_path "$line")"
  expected_sha="$(atlas_closeout_anchor_token "$line" "sha256")"
  if [ -z "$path" ] || [ -z "$expected_sha" ] || [ ! -f "$path" ]; then
    printf '1\n'
    return 0
  fi

  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_sha" = "$expected_sha" ]; then
    printf '0\n'
  else
    printf '1\n'
  fi
}

atlas_audit_ledger_anchor_problem_count() {
  local manifest_file="$1"
  local line
  local path
  local expected_events
  local actual_events
  local expected_sha
  local actual_sha

  line="$(atlas_closeout_manifest_anchor_line "$manifest_file" "Operation ledger")"
  if [ -z "$line" ]; then
    printf '1\n'
    return 0
  fi

  path="$(atlas_closeout_anchor_path "$line")"
  expected_events="$(atlas_closeout_anchor_token "$line" "events")"
  expected_sha="$(atlas_closeout_anchor_token "$line" "sha256")"
  if [ -z "$path" ] || [ -z "$expected_events" ] || [ -z "$expected_sha" ] || [ ! -f "$path" ]; then
    printf '1\n'
    return 0
  fi

  actual_events="$(atlas_closeout_ledger_event_count "$path")"
  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_events" = "$expected_events" ] && [ "$actual_sha" = "$expected_sha" ]; then
    printf '0\n'
  else
    printf '1\n'
  fi
}

atlas_audit_closeout_verification_status() {
  local latest_closeout
  local closeout_path=""
  local problems=0
  local label

  latest_closeout="$(atlas_readiness_latest_closeout)"
  if [ -z "$latest_closeout" ]; then
    printf 'missing\t-\t0\n'
    return 0
  fi

  IFS=$'\t' read -r _ closeout_path <<<"$latest_closeout"
  if [ -z "$closeout_path" ] || [ ! -f "$closeout_path" ]; then
    printf 'missing\t%s\t1\n' "${closeout_path:--}"
    return 0
  fi

  for label in "Latest report" "Evidence manifest" "Latest handoff" "Operation env" "Scope snapshot" "Evidence index" "Finding index" "Validation index"; do
    problems=$((problems + $(atlas_audit_hash_anchor_problem_count "$closeout_path" "$label")))
  done
  problems=$((problems + $(atlas_audit_ledger_anchor_problem_count "$closeout_path")))

  if [ "$problems" -eq 0 ]; then
    printf 'verified\t%s\t0\n' "$closeout_path"
  else
    printf 'attention-required\t%s\t%s\n' "$closeout_path" "$problems"
  fi
}

atlas_audit_print_denied_preflights() {
  local ledger_file="$1"

  jq -r '
    select(.event == "scope.preflight" and .status == "denied")
    | [.ts, (.detail // "")]
    | @tsv
  ' "$ledger_file" |
    awk -F'\t' '{ printf "denied preflight: %s %s\n", $1, $2 }'
}

atlas_audit_print_forced_closes() {
  local ledger_file="$1"

  jq -r '
    select(.event == "op.close.readiness" and ((.detail // "") | contains("force=1")))
    | [.ts, (.status // "?"), (.detail // "")]
    | @tsv
  ' "$ledger_file" |
    awk -F'\t' '{ printf "forced close: %s readiness=%s %s\n", $1, $2, $3 }'
}

atlas_audit_print_flags() {
  local ledger_file="$1"
  local denied
  local forced
  local verification
  local verification_status
  local verification_path
  local verification_problems
  local flag_count=0

  denied="$(atlas_audit_print_denied_preflights "$ledger_file")"
  if [ -n "$denied" ]; then
    printf '%s\n' "$denied"
    flag_count=$((flag_count + 1))
  fi

  forced="$(atlas_audit_print_forced_closes "$ledger_file")"
  if [ -n "$forced" ]; then
    printf '%s\n' "$forced"
    flag_count=$((flag_count + 1))
  fi

  atlas_readiness_collect "$ATLAS_OP_TARGET"
  if [ "$ATLAS_READINESS_REPORT_FRESHNESS" = "stale" ]; then
    printf 'stale report: %s\n' "${ATLAS_READINESS_LATEST_REPORT_PATH:-none}"
    flag_count=$((flag_count + 1))
  fi
  if [ "$ATLAS_READINESS_BUNDLE_FRESHNESS" = "stale" ]; then
    printf 'stale evidence bundle: %s\n' "${ATLAS_READINESS_LATEST_BUNDLE_DETAIL:-none}"
    flag_count=$((flag_count + 1))
  fi
  if [ "$ATLAS_READINESS_HANDOFF_FRESHNESS" = "stale" ]; then
    printf 'stale handoff: %s\n' "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none}"
    flag_count=$((flag_count + 1))
  fi
  if [ "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" = "stale" ]; then
    printf 'stale closeout: %s\n' "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none}"
    flag_count=$((flag_count + 1))
  fi
  if [ "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" = "stale" ]; then
    printf 'stale audit packet: %s\n' "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none}"
    flag_count=$((flag_count + 1))
  fi

  verification="$(atlas_audit_closeout_verification_status)"
  IFS=$'\t' read -r verification_status verification_path verification_problems <<<"$verification"
  case "$verification_status" in
  verified)
    ui_note "closeout verification: verified manifest=$verification_path"
    ;;
  *)
    printf 'closeout verification: %s manifest=%s problems=%s\n' "$verification_status" "$verification_path" "$verification_problems"
    flag_count=$((flag_count + 1))
    ;;
  esac

  if [ "$flag_count" -eq 0 ]; then
    ui_note "no audit flags detected"
  fi
}

atlas_audit_print() {
  local ledger_file

  ledger_file="$(atlas_audit_ledger_file)"

  ui_heading "Operation Audit"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Operation Status" "$ATLAS_OP_STATUS"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Ledger" "$ledger_file"
  ui_kv "Events" "$(atlas_audit_event_count "$ledger_file")"
  ui_rule
  ui_subheading "Event Counts"
  atlas_audit_print_event_counts "$ledger_file"
  ui_rule
  ui_subheading "Audit Flags"
  atlas_audit_print_flags "$ledger_file"
  ui_rule
  ui_subheading "Timeline"
  atlas_audit_print_timeline "$ledger_file"
}

atlas_audit_write_packet() {
  local file="$1"
  local ledger_file
  local ledger_sha=""
  local verification
  local verification_status
  local verification_path
  local verification_problems

  atlas_readiness_collect "$ATLAS_OP_TARGET"
  ledger_file="$(atlas_audit_ledger_file)"
  if [ -f "$ledger_file" ]; then
    ledger_sha="$(atlas_evidence_hash_path "$ledger_file")"
  fi
  verification="$(atlas_audit_closeout_verification_status)"
  IFS=$'\t' read -r verification_status verification_path verification_problems <<<"$verification"

  {
    printf '# Atlas Operation Audit Packet\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Operation Status: %s\n' "$ATLAS_OP_STATUS"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    printf '\nNo raw artifact contents are included in this audit packet.\n'

    printf '\n## Ledger\n\n'
    printf -- "- Operation ledger: \`%s\`\n" "$ledger_file"
    printf -- '- Events: %s\n' "$(atlas_audit_event_count "$ledger_file")"
    printf -- '- Ledger SHA256: %s\n' "$ledger_sha"
    printf -- '- Closeout verification: %s\n' "$verification_status"
    printf -- '- Closeout manifest: %s\n' "$verification_path"
    printf -- '- Closeout verification problems: %s\n' "$verification_problems"
    printf -- '- Audit packet freshness: %s\n' "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS"

    printf '\n## Event Counts\n\n'
    printf '```text\n'
    atlas_audit_print_event_counts "$ledger_file"
    printf '```\n'

    printf '\n## Audit Flags\n\n'
    printf '```text\n'
    atlas_audit_print_flags "$ledger_file"
    printf '```\n'

    printf '\n## Timeline\n\n'
    printf '```text\n'
    atlas_audit_print_timeline "$ledger_file"
    printf '```\n'
  } >"$file"
}

cmd_op_audit_packet() {
  local packet_name="${2:-}"
  local packet_slug
  local audit_dir
  local packet_file

  [ "$#" -le 2 ] || fail "op audit-packet [name] [packet-name]"

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_OP_SLUG-audit"
  fi
  packet_slug="$(slugify "$packet_name")"
  [ -n "$packet_slug" ] || fail "audit packet name produced an empty slug"

  audit_dir="$ATLAS_OP_DIR/audit"
  mkdir -p "$audit_dir"
  chmod 700 "$audit_dir" 2>/dev/null || true
  packet_file="$audit_dir/$packet_slug.md"

  atlas_ledger_append_current "audit.packet.generated" "read-only" "atlas" "ok" "$packet_file"
  atlas_audit_write_packet "$packet_file"
  chmod 600 "$packet_file" 2>/dev/null || true
  record_operation_history "$ATLAS_OP_DIR" "audit-packet" "$packet_file"

  ui_ok "audit packet written"
  printf 'audit_packet: %s\n' "$packet_file"
}

atlas_audit_packet_field() {
  local packet_file="$1"
  local field="$2"

  awk -F': ' -v wanted="$field" '$1 == wanted { print $2; exit }' "$packet_file"
}

atlas_audit_packet_bullet_value() {
  local packet_file="$1"
  local label="$2"

  awk -F': ' -v prefix="- $label" '$1 == prefix { print $2; exit }' "$packet_file"
}

atlas_audit_packet_anchor_line() {
  local packet_file="$1"
  local label="$2"

  awk -v prefix="- $label: " 'index($0, prefix) == 1 { print; exit }' "$packet_file"
}

atlas_audit_resolve_packet() {
  local packet_arg="$1"
  local latest_packet
  local latest_packet_path=""
  local candidate
  local packet_slug

  if [ -z "$packet_arg" ]; then
    latest_packet="$(atlas_audit_latest_packet)"
    [ -n "$latest_packet" ] || fail "no audit packet recorded for operation '$ATLAS_OP_SLUG'"
    IFS=$'\t' read -r _ latest_packet_path <<<"$latest_packet"
    [ -f "$latest_packet_path" ] || fail "recorded audit packet is missing: $latest_packet_path"
    printf '%s\n' "$latest_packet_path"
    return 0
  fi

  if [ -f "$packet_arg" ]; then
    readlink -f "$packet_arg"
    return 0
  fi

  candidate="$ATLAS_OP_DIR/audit/$packet_arg"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  packet_slug="$(slugify "${packet_arg%.md}")"
  candidate="$ATLAS_OP_DIR/audit/$packet_slug.md"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  fail "unknown audit packet for operation '$ATLAS_OP_SLUG': $packet_arg"
}

atlas_audit_verify_packet() {
  local packet_file="$1"
  local packet_operation
  local ledger_line
  local ledger_file
  local expected_events
  local actual_events=""
  local expected_sha
  local actual_sha=""
  local problems=0
  local status="verified"
  local ledger_status="verified"

  [ -f "$packet_file" ] || fail "audit packet is not a file: $packet_file"
  packet_operation="$(atlas_audit_packet_field "$packet_file" "Operation ID")"
  [ -n "$packet_operation" ] || fail "audit packet is missing Operation ID: $packet_file"
  [ "$packet_operation" = "$ATLAS_OP_SLUG" ] || fail "audit packet belongs to '$packet_operation', not '$ATLAS_OP_SLUG'"

  ledger_line="$(atlas_audit_packet_anchor_line "$packet_file" "Operation ledger")"
  ledger_file="$(atlas_closeout_anchor_path "$ledger_line")"
  expected_events="$(atlas_audit_packet_bullet_value "$packet_file" "Events")"
  expected_sha="$(atlas_audit_packet_bullet_value "$packet_file" "Ledger SHA256")"

  if [ -z "$ledger_file" ] || [ -z "$expected_events" ] || [ -z "$expected_sha" ]; then
    ledger_status="unverifiable"
    problems=$((problems + 1))
  elif [ ! -f "$ledger_file" ]; then
    ledger_status="missing"
    problems=$((problems + 1))
  else
    actual_events="$(atlas_audit_event_count "$ledger_file")"
    actual_sha="$(atlas_evidence_hash_path "$ledger_file")"
    if [ "$actual_events" != "$expected_events" ] || [ "$actual_sha" != "$expected_sha" ]; then
      ledger_status="changed"
      problems=$((problems + 1))
    fi
  fi

  if [ "$problems" -gt 0 ]; then
    status="attention-required"
  fi

  ui_heading "Audit Packet Verification"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Packet" "$packet_file"
  ui_rule
  printf '%-20s %-14s %s\n' "ARTIFACT" "STATUS" "DETAIL"
  printf '%-20s %-14s expected_events=%s actual_events=%s expected_sha=%s actual_sha=%s ledger=%s\n' \
    "Operation Ledger" \
    "$ledger_status" \
    "${expected_events:-unknown}" \
    "${actual_events:-unknown}" \
    "${expected_sha:-unknown}" \
    "${actual_sha:-unknown}" \
    "${ledger_file:-unknown}"
  ui_rule
  ui_kv "Verification Status" "$status"
  ui_kv "Verification Problems" "$problems"

  [ "$problems" -eq 0 ] || return 1
}

cmd_op_audit_verify() {
  local operation_name=""
  local packet_arg=""
  local packet_file
  local slug

  [ "$#" -le 2 ] || fail "op audit-verify [name] [audit-packet]"

  if [ "$#" -eq 0 ]; then
    load_active_operation
  elif [ "$#" -eq 1 ]; then
    slug="$(session_slug_for "$1")"
    if [ -f "$(atlas_op_file_for_slug "$slug")" ]; then
      load_atlas_operation "$1"
    else
      load_active_operation
      packet_arg="$1"
    fi
  else
    operation_name="$1"
    packet_arg="$2"
    load_atlas_operation "$operation_name"
  fi

  packet_file="$(atlas_audit_resolve_packet "$packet_arg")"
  atlas_audit_verify_packet "$packet_file"
}

cmd_op_audit() {
  [ "$#" -le 1 ] || fail "op audit [name]"

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  atlas_audit_print
}
