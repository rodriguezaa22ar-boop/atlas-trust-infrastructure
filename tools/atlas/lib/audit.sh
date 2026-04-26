#!/usr/bin/env bash

atlas_audit_ledger_file() {
  local ledger_file

  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || fail "operation ledger is empty or missing: $ledger_file"
  printf '%s\n' "$ledger_file"
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

cmd_op_audit() {
  [ "$#" -le 1 ] || fail "op audit [name]"

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  atlas_audit_print
}
