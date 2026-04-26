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

atlas_readiness_latest_handoff() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "handoff.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_readiness_latest_closeout() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "closeout.manifest.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_readiness_latest_audit_packet() {
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

atlas_readiness_latest_ledger_event() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '[.ts, .event, .detail] | @tsv' "$ledger_file" | tail -n 1
}

atlas_readiness_latest_audit_packet_change() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select((.event // "") != "archive.packet.generated")
    | [.ts, .event, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_readiness_latest_material_change() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    . as $record
    | select(
      [
        "tool.completed",
        "artifact.created",
        "artifact.redacted",
        "finding.recorded",
        "finding.updated",
        "approval.granted",
        "validation.planned",
        "validation.approved",
        "validation.executed",
        "validation.retested"
      ] | index($record.event)
    )
    | [.ts, .event, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_readiness_latest_evidence_change() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    . as $record
    | select(["artifact.created", "artifact.redacted"] | index($record.event))
    | [.ts, .event, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_readiness_report_freshness() {
  local latest_report_at="$1"
  local latest_change_at="$2"

  if [ -z "$latest_report_at" ]; then
    printf 'missing\n'
  elif [ -n "$latest_change_at" ] && [[ "$latest_change_at" > "$latest_report_at" ]]; then
    printf 'stale\n'
  else
    printf 'current\n'
  fi
}

atlas_readiness_bundle_freshness() {
  local latest_bundle_at="$1"
  local latest_evidence_change_at="$2"

  if [ -z "$latest_bundle_at" ]; then
    printf 'missing\n'
  elif [ -n "$latest_evidence_change_at" ] && [[ "$latest_evidence_change_at" > "$latest_bundle_at" ]]; then
    printf 'stale\n'
  else
    printf 'current\n'
  fi
}

atlas_readiness_handoff_freshness() {
  local latest_handoff_at="$1"
  local latest_change_at="$2"
  local latest_report_at="$3"
  local latest_bundle_at="$4"

  if [ -z "$latest_handoff_at" ]; then
    printf 'missing\n'
  elif [ -n "$latest_change_at" ] && [[ "$latest_change_at" > "$latest_handoff_at" ]]; then
    printf 'stale\n'
  elif [ -n "$latest_report_at" ] && [[ "$latest_report_at" > "$latest_handoff_at" ]]; then
    printf 'stale\n'
  elif [ -n "$latest_bundle_at" ] && [[ "$latest_bundle_at" > "$latest_handoff_at" ]]; then
    printf 'stale\n'
  else
    printf 'current\n'
  fi
}

atlas_readiness_closeout_freshness() {
  local latest_closeout_at="$1"
  local latest_change_at="$2"
  local latest_report_at="$3"
  local latest_bundle_at="$4"
  local latest_handoff_at="$5"

  if [ -z "$latest_closeout_at" ]; then
    printf 'missing\n'
  elif [ -n "$latest_change_at" ] && [[ "$latest_change_at" > "$latest_closeout_at" ]]; then
    printf 'stale\n'
  elif [ -n "$latest_report_at" ] && [[ "$latest_report_at" > "$latest_closeout_at" ]]; then
    printf 'stale\n'
  elif [ -n "$latest_bundle_at" ] && [[ "$latest_bundle_at" > "$latest_closeout_at" ]]; then
    printf 'stale\n'
  elif [ -n "$latest_handoff_at" ] && [[ "$latest_handoff_at" > "$latest_closeout_at" ]]; then
    printf 'stale\n'
  else
    printf 'current\n'
  fi
}

atlas_readiness_audit_packet_freshness() {
  local latest_audit_packet_at="$1"
  local latest_ledger_at="$2"

  if [ -z "$latest_audit_packet_at" ]; then
    printf 'missing\n'
  elif [ -n "$latest_ledger_at" ] && [[ "$latest_ledger_at" > "$latest_audit_packet_at" ]]; then
    printf 'stale\n'
  else
    printf 'current\n'
  fi
}

atlas_readiness_next_step() {
  local evidence_count="$1"
  local open_count="$2"
  local pending_count="$3"
  local latest_report="$4"
  local latest_bundle="$5"
  local report_freshness="$6"
  local bundle_freshness="$7"
  local latest_handoff="$8"
  local handoff_freshness="$9"
  local latest_closeout="${10}"
  local closeout_freshness="${11}"
  local latest_audit_packet="${12}"
  local audit_packet_freshness="${13}"

  if [ "$pending_count" -gt 0 ]; then
    printf 'Run or retire pending validation before closure.\n'
  elif [ "$open_count" -gt 0 ]; then
    printf 'Resolve, accept, or retest unresolved findings before closure.\n'
  elif [ "$evidence_count" -eq 0 ]; then
    printf 'Add at least one evidence record before closure.\n'
  elif [ -z "$latest_report" ]; then
    printf 'Generate an operation report before closure.\n'
  elif [ "$report_freshness" = "stale" ]; then
    printf 'Refresh the operation report before closure.\n'
  elif [ -z "$latest_bundle" ]; then
    printf 'Operation is ready to close; generate an evidence bundle if handoff is required.\n'
  elif [ "$bundle_freshness" = "stale" ]; then
    printf 'Operation is ready to close; regenerate the evidence bundle if handoff is required.\n'
  elif [ -z "$latest_handoff" ]; then
    printf 'Operation is ready to close; generate a handoff packet if handoff is required.\n'
  elif [ "$handoff_freshness" = "stale" ]; then
    printf 'Operation is ready to close; regenerate the handoff packet if handoff is required.\n'
  elif [ -z "$latest_closeout" ]; then
    printf 'Operation is ready to close; generate a closeout manifest after closure if final audit is required.\n'
  elif [ "$closeout_freshness" = "stale" ]; then
    printf 'Operation is ready to close; regenerate the closeout manifest if final audit is required.\n'
  elif [ -z "$latest_audit_packet" ]; then
    printf 'Operation is ready to close; generate an audit packet if final audit is required.\n'
  elif [ "$audit_packet_freshness" = "stale" ]; then
    printf 'Operation is ready to close; regenerate the audit packet if final audit is required.\n'
  else
    printf 'Operation is ready to close.\n'
  fi
}

atlas_readiness_status() {
  local evidence_count="$1"
  local open_count="$2"
  local pending_count="$3"
  local latest_report="$4"
  local report_freshness="$5"

  if [ "$pending_count" -gt 0 ] || [ "$open_count" -gt 0 ] || [ "$evidence_count" -eq 0 ] || [ -z "$latest_report" ] || [ "$report_freshness" = "stale" ]; then
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
  local latest_handoff
  local latest_handoff_at=""
  local latest_handoff_path=""
  local latest_closeout
  local latest_closeout_at=""
  local latest_closeout_path=""
  local latest_audit_packet
  local latest_audit_packet_at=""
  local latest_audit_packet_path=""
  local latest_ledger_event
  local latest_ledger_at=""
  local latest_ledger_event_name=""
  local latest_audit_packet_change
  local latest_audit_packet_change_at=""
  local latest_change
  local latest_change_at=""
  local latest_change_event=""
  local latest_evidence_change
  local latest_evidence_change_at=""
  local latest_evidence_change_event=""
  local report_freshness
  local bundle_freshness
  local handoff_freshness
  local closeout_freshness
  local audit_packet_freshness
  local readiness
  local next_step

  evidence_count="$(atlas_evidence_count_for_target "$target")"
  finding_count="$(atlas_findings_count_for_target "$target")"
  validation_count="$(atlas_validation_count_for_target "$target")"
  open_count="$(atlas_readiness_open_findings_count "$target")"
  pending_count="$(atlas_readiness_pending_validation_count "$target")"
  latest_report="$(atlas_cycle_latest_report)"
  latest_bundle="$(atlas_readiness_latest_bundle)"
  latest_handoff="$(atlas_readiness_latest_handoff)"
  latest_closeout="$(atlas_readiness_latest_closeout)"
  latest_audit_packet="$(atlas_readiness_latest_audit_packet)"
  latest_ledger_event="$(atlas_readiness_latest_ledger_event)"
  latest_audit_packet_change="$(atlas_readiness_latest_audit_packet_change)"
  latest_change="$(atlas_readiness_latest_material_change)"
  latest_evidence_change="$(atlas_readiness_latest_evidence_change)"

  if [ -n "$latest_report" ]; then
    IFS=$'\t' read -r latest_report_at latest_report_path <<<"$latest_report"
  fi
  if [ -n "$latest_bundle" ]; then
    IFS=$'\t' read -r latest_bundle_at latest_bundle_detail <<<"$latest_bundle"
  fi
  if [ -n "$latest_handoff" ]; then
    IFS=$'\t' read -r latest_handoff_at latest_handoff_path <<<"$latest_handoff"
  fi
  if [ -n "$latest_closeout" ]; then
    IFS=$'\t' read -r latest_closeout_at latest_closeout_path <<<"$latest_closeout"
  fi
  if [ -n "$latest_audit_packet" ]; then
    IFS=$'\t' read -r latest_audit_packet_at latest_audit_packet_path <<<"$latest_audit_packet"
  fi
  if [ -n "$latest_ledger_event" ]; then
    IFS=$'\t' read -r latest_ledger_at latest_ledger_event_name _ <<<"$latest_ledger_event"
  fi
  if [ -n "$latest_audit_packet_change" ]; then
    IFS=$'\t' read -r latest_audit_packet_change_at _ _ <<<"$latest_audit_packet_change"
  fi
  if [ -n "$latest_change" ]; then
    IFS=$'\t' read -r latest_change_at latest_change_event _ <<<"$latest_change"
  fi
  if [ -n "$latest_evidence_change" ]; then
    IFS=$'\t' read -r latest_evidence_change_at latest_evidence_change_event _ <<<"$latest_evidence_change"
  fi

  report_freshness="$(atlas_readiness_report_freshness "$latest_report_at" "$latest_change_at")"
  bundle_freshness="$(atlas_readiness_bundle_freshness "$latest_bundle_at" "$latest_evidence_change_at")"
  handoff_freshness="$(atlas_readiness_handoff_freshness "$latest_handoff_at" "$latest_change_at" "$latest_report_at" "$latest_bundle_at")"
  closeout_freshness="$(atlas_readiness_closeout_freshness "$latest_closeout_at" "$latest_change_at" "$latest_report_at" "$latest_bundle_at" "$latest_handoff_at")"
  audit_packet_freshness="$(atlas_readiness_audit_packet_freshness "$latest_audit_packet_at" "$latest_audit_packet_change_at")"
  readiness="$(atlas_readiness_status "$evidence_count" "$open_count" "$pending_count" "$latest_report" "$report_freshness")"
  next_step="$(atlas_readiness_next_step "$evidence_count" "$open_count" "$pending_count" "$latest_report" "$latest_bundle" "$report_freshness" "$bundle_freshness" "$latest_handoff" "$handoff_freshness" "$latest_closeout" "$closeout_freshness" "$latest_audit_packet" "$audit_packet_freshness")"

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
  ATLAS_READINESS_LATEST_HANDOFF="$latest_handoff"
  ATLAS_READINESS_LATEST_HANDOFF_AT="$latest_handoff_at"
  ATLAS_READINESS_LATEST_HANDOFF_PATH="$latest_handoff_path"
  ATLAS_READINESS_LATEST_CLOSEOUT="$latest_closeout"
  ATLAS_READINESS_LATEST_CLOSEOUT_AT="$latest_closeout_at"
  ATLAS_READINESS_LATEST_CLOSEOUT_PATH="$latest_closeout_path"
  ATLAS_READINESS_LATEST_AUDIT_PACKET="$latest_audit_packet"
  ATLAS_READINESS_LATEST_AUDIT_PACKET_AT="$latest_audit_packet_at"
  ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH="$latest_audit_packet_path"
  ATLAS_READINESS_LATEST_LEDGER_EVENT="$latest_ledger_event"
  ATLAS_READINESS_LATEST_LEDGER_AT="$latest_ledger_at"
  ATLAS_READINESS_LATEST_LEDGER_EVENT_NAME="$latest_ledger_event_name"
  ATLAS_READINESS_LATEST_CHANGE="$latest_change"
  ATLAS_READINESS_LATEST_CHANGE_AT="$latest_change_at"
  ATLAS_READINESS_LATEST_CHANGE_EVENT="$latest_change_event"
  ATLAS_READINESS_LATEST_EVIDENCE_CHANGE="$latest_evidence_change"
  ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_AT="$latest_evidence_change_at"
  ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_EVENT="$latest_evidence_change_event"
  ATLAS_READINESS_REPORT_FRESHNESS="$report_freshness"
  ATLAS_READINESS_BUNDLE_FRESHNESS="$bundle_freshness"
  ATLAS_READINESS_HANDOFF_FRESHNESS="$handoff_freshness"
  ATLAS_READINESS_CLOSEOUT_FRESHNESS="$closeout_freshness"
  ATLAS_READINESS_AUDIT_PACKET_FRESHNESS="$audit_packet_freshness"
  ATLAS_READINESS_STATUS="$readiness"
  ATLAS_READINESS_NEXT_STEP="$next_step"
}

atlas_readiness_ledger_detail() {
  local force="${1:-0}"

  printf 'readiness=%s evidence=%s open_findings=%s pending_validation=%s report_freshness=%s bundle_freshness=%s handoff_freshness=%s closeout_freshness=%s audit_packet_freshness=%s latest_report=%s latest_change=%s evidence_bundle=%s handoff=%s closeout=%s audit_packet=%s force=%s' \
    "${ATLAS_READINESS_STATUS:-unknown}" \
    "${ATLAS_READINESS_EVIDENCE_COUNT:-0}" \
    "${ATLAS_READINESS_OPEN_FINDINGS_COUNT:-0}" \
    "${ATLAS_READINESS_PENDING_VALIDATION_COUNT:-0}" \
    "${ATLAS_READINESS_REPORT_FRESHNESS:-unknown}" \
    "${ATLAS_READINESS_BUNDLE_FRESHNESS:-unknown}" \
    "${ATLAS_READINESS_HANDOFF_FRESHNESS:-unknown}" \
    "${ATLAS_READINESS_CLOSEOUT_FRESHNESS:-unknown}" \
    "${ATLAS_READINESS_AUDIT_PACKET_FRESHNESS:-unknown}" \
    "${ATLAS_READINESS_LATEST_REPORT_PATH:-none}" \
    "${ATLAS_READINESS_LATEST_CHANGE_EVENT:-none}" \
    "${ATLAS_READINESS_LATEST_BUNDLE_DETAIL:-none}" \
    "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none}" \
    "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none}" \
    "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none}" \
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
  ui_kv "Report Freshness" "$ATLAS_READINESS_REPORT_FRESHNESS"
  if [ -n "$ATLAS_READINESS_LATEST_CHANGE" ]; then
    ui_kv "Latest State Change" "$ATLAS_READINESS_LATEST_CHANGE_AT $ATLAS_READINESS_LATEST_CHANGE_EVENT"
  else
    ui_kv "Latest State Change" "none"
  fi
  if [ -n "$ATLAS_READINESS_LATEST_BUNDLE" ]; then
    ui_kv "Evidence Bundle" "$ATLAS_READINESS_LATEST_BUNDLE_AT $ATLAS_READINESS_LATEST_BUNDLE_DETAIL"
  else
    ui_kv "Evidence Bundle" "none generated yet"
  fi
  ui_kv "Bundle Freshness" "$ATLAS_READINESS_BUNDLE_FRESHNESS"
  if [ -n "$ATLAS_READINESS_LATEST_EVIDENCE_CHANGE" ]; then
    ui_kv "Latest Evidence Change" "$ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_AT $ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_EVENT"
  else
    ui_kv "Latest Evidence Change" "none"
  fi
  if [ -n "$ATLAS_READINESS_LATEST_HANDOFF" ]; then
    ui_kv "Latest Handoff" "$ATLAS_READINESS_LATEST_HANDOFF_AT $ATLAS_READINESS_LATEST_HANDOFF_PATH"
  else
    ui_kv "Latest Handoff" "none generated yet"
  fi
  ui_kv "Handoff Freshness" "$ATLAS_READINESS_HANDOFF_FRESHNESS"
  if [ -n "$ATLAS_READINESS_LATEST_CLOSEOUT" ]; then
    ui_kv "Latest Closeout" "$ATLAS_READINESS_LATEST_CLOSEOUT_AT $ATLAS_READINESS_LATEST_CLOSEOUT_PATH"
  else
    ui_kv "Latest Closeout" "none generated yet"
  fi
  ui_kv "Closeout Freshness" "$ATLAS_READINESS_CLOSEOUT_FRESHNESS"
  if [ -n "$ATLAS_READINESS_LATEST_AUDIT_PACKET" ]; then
    ui_kv "Latest Audit Packet" "$ATLAS_READINESS_LATEST_AUDIT_PACKET_AT $ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH"
  else
    ui_kv "Latest Audit Packet" "none generated yet"
  fi
  ui_kv "Audit Packet Freshness" "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS"
  if [ -n "$ATLAS_READINESS_LATEST_LEDGER_EVENT" ]; then
    ui_kv "Latest Ledger Event" "$ATLAS_READINESS_LATEST_LEDGER_AT $ATLAS_READINESS_LATEST_LEDGER_EVENT_NAME"
  else
    ui_kv "Latest Ledger Event" "none"
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
