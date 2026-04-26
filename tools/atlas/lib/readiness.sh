#!/usr/bin/env bash

atlas_readiness_count_rows() {
  local output="$1"

  if [ -z "$output" ]; then
    printf '0\n'
  else
    printf '%s\n' "$output" | awk 'END { print NR + 0 }'
  fi
}

atlas_readiness_open_findings_rows() {
  local target="$1"
  local limit="${2:-8}"
  local findings_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  findings_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$findings_file" ] || return 0

  jq -sr \
    --arg target "$target" \
    --argjson limit "$limit" '
      def severity_weight:
        if . == "critical" then 5
        elif . == "high" then 4
        elif . == "medium" then 3
        elif . == "low" then 2
        elif . == "info" then 1
        else 0 end;
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(
          ($target == "" or .target == $target)
          and ((.status // "open") != "resolved")
          and ((.status // "open") != "accepted")
        ))
      | sort_by([((.severity // "info") | severity_weight), (.updated_at // .created_at // ""), .id])
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.severity // "info"),
          (.level // "inferred"),
          (.status // "open"),
          (.title // "untitled finding")
        ]
      | @tsv
    ' "$findings_file"
}

atlas_readiness_open_findings_count() {
  local target="$1"
  local rows

  rows="$(atlas_readiness_open_findings_rows "$target" 1000000)"
  atlas_readiness_count_rows "$rows"
}

atlas_readiness_print_open_findings() {
  local target="$1"
  local output

  output="$(
    atlas_readiness_open_findings_rows "$target" 8 |
      awk -F'\t' '{ printf "%-24s %-8s %-10s %-10s %s\n", $1, $2, $3, $4, $5 }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "no unresolved findings remain"
  fi
}

atlas_readiness_pending_validation_count() {
  local target="$1"
  local rows

  rows="$(atlas_cycle_validation_queue_rows "$target" 1000000)"
  atlas_readiness_count_rows "$rows"
}

atlas_readiness_latest_bundle() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "evidence.bundle.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_readiness_next_step() {
  local evidence_count="$1"
  local open_count="$2"
  local pending_count="$3"
  local latest_report="$4"
  local latest_bundle="$5"

  if [ "$pending_count" -gt 0 ]; then
    printf 'Run or retire pending validation before closure.\n'
  elif [ "$open_count" -gt 0 ]; then
    printf 'Resolve, accept, or retest unresolved findings before closure.\n'
  elif [ "$evidence_count" -eq 0 ]; then
    printf 'Add at least one evidence record before closure.\n'
  elif [ -z "$latest_report" ]; then
    printf 'Generate an operation report before closure.\n'
  elif [ -z "$latest_bundle" ]; then
    printf 'Operation is ready to close; generate an evidence bundle if handoff is required.\n'
  else
    printf 'Operation is ready to close.\n'
  fi
}

atlas_readiness_status() {
  local evidence_count="$1"
  local open_count="$2"
  local pending_count="$3"
  local latest_report="$4"

  if [ "$pending_count" -gt 0 ] || [ "$open_count" -gt 0 ] || [ "$evidence_count" -eq 0 ] || [ -z "$latest_report" ]; then
    printf 'attention-required\n'
  else
    printf 'ready\n'
  fi
}

atlas_readiness_print_pending_validation() {
  local target="$1"

  atlas_cycle_print_validation_queue "$target"
}

atlas_readiness_collect() {
  local target="${1:-$ATLAS_OP_TARGET}"
  local evidence_count
  local finding_count
  local validation_count
  local open_count
  local pending_count
  local latest_report
  local latest_report_at=""
  local latest_report_path=""
  local latest_bundle
  local latest_bundle_at=""
  local latest_bundle_detail=""
  local readiness
  local next_step

  evidence_count="$(atlas_evidence_count_for_target "$target")"
  finding_count="$(atlas_findings_count_for_target "$target")"
  validation_count="$(atlas_validation_count_for_target "$target")"
  open_count="$(atlas_readiness_open_findings_count "$target")"
  pending_count="$(atlas_readiness_pending_validation_count "$target")"
  latest_report="$(atlas_cycle_latest_report)"
  latest_bundle="$(atlas_readiness_latest_bundle)"
  readiness="$(atlas_readiness_status "$evidence_count" "$open_count" "$pending_count" "$latest_report")"
  next_step="$(atlas_readiness_next_step "$evidence_count" "$open_count" "$pending_count" "$latest_report" "$latest_bundle")"

  if [ -n "$latest_report" ]; then
    IFS=$'\t' read -r latest_report_at latest_report_path <<<"$latest_report"
  fi
  if [ -n "$latest_bundle" ]; then
    IFS=$'\t' read -r latest_bundle_at latest_bundle_detail <<<"$latest_bundle"
  fi

  ATLAS_READINESS_EVIDENCE_COUNT="$evidence_count"
  ATLAS_READINESS_FINDING_COUNT="$finding_count"
  ATLAS_READINESS_VALIDATION_COUNT="$validation_count"
  ATLAS_READINESS_OPEN_FINDINGS_COUNT="$open_count"
  ATLAS_READINESS_PENDING_VALIDATION_COUNT="$pending_count"
  ATLAS_READINESS_LATEST_REPORT="$latest_report"
  ATLAS_READINESS_LATEST_REPORT_AT="$latest_report_at"
  ATLAS_READINESS_LATEST_REPORT_PATH="$latest_report_path"
  ATLAS_READINESS_LATEST_BUNDLE="$latest_bundle"
  ATLAS_READINESS_LATEST_BUNDLE_AT="$latest_bundle_at"
  ATLAS_READINESS_LATEST_BUNDLE_DETAIL="$latest_bundle_detail"
  ATLAS_READINESS_STATUS="$readiness"
  ATLAS_READINESS_NEXT_STEP="$next_step"
}

atlas_readiness_ledger_detail() {
  local force="${1:-0}"

  printf 'readiness=%s evidence=%s open_findings=%s pending_validation=%s latest_report=%s evidence_bundle=%s force=%s' \
    "${ATLAS_READINESS_STATUS:-unknown}" \
    "${ATLAS_READINESS_EVIDENCE_COUNT:-0}" \
    "${ATLAS_READINESS_OPEN_FINDINGS_COUNT:-0}" \
    "${ATLAS_READINESS_PENDING_VALIDATION_COUNT:-0}" \
    "${ATLAS_READINESS_LATEST_REPORT_PATH:-none}" \
    "${ATLAS_READINESS_LATEST_BUNDLE_DETAIL:-none}" \
    "$force"
}

atlas_readiness_print() {
  local target="$ATLAS_OP_TARGET"

  atlas_readiness_collect "$target"

  ui_heading "Operation Readiness"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Operation Status" "$ATLAS_OP_STATUS"
  ui_kv "Target" "$target"
  ui_kv "Evidence Records" "$ATLAS_READINESS_EVIDENCE_COUNT"
  ui_kv "Findings" "$ATLAS_READINESS_FINDING_COUNT"
  ui_kv "Open Findings" "$ATLAS_READINESS_OPEN_FINDINGS_COUNT"
  ui_kv "Validation Plans" "$ATLAS_READINESS_VALIDATION_COUNT"
  ui_kv "Pending Validation" "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
  if [ -n "$ATLAS_READINESS_LATEST_REPORT" ]; then
    ui_kv "Latest Report" "$ATLAS_READINESS_LATEST_REPORT_AT $ATLAS_READINESS_LATEST_REPORT_PATH"
  else
    ui_kv "Latest Report" "none generated yet"
  fi
  if [ -n "$ATLAS_READINESS_LATEST_BUNDLE" ]; then
    ui_kv "Evidence Bundle" "$ATLAS_READINESS_LATEST_BUNDLE_AT $ATLAS_READINESS_LATEST_BUNDLE_DETAIL"
  else
    ui_kv "Evidence Bundle" "none generated yet"
  fi
  ui_kv "Close Readiness" "$ATLAS_READINESS_STATUS"
  ui_kv "Next Step" "$ATLAS_READINESS_NEXT_STEP"
  ui_rule
  ui_subheading "Open Findings"
  atlas_readiness_print_open_findings "$target"
  ui_rule
  ui_subheading "Pending Validation"
  atlas_readiness_print_pending_validation "$target"
}
