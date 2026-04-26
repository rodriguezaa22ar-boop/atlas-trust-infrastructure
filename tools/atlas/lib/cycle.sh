#!/usr/bin/env bash

atlas_cycle_findings_need_plan_count() {
  local target="$1"
  local rows

  rows="$(atlas_cycle_findings_need_plan_rows "$target" 1000000)"
  if [ -z "$rows" ]; then
    printf '0\n'
  else
    printf '%s\n' "$rows" | awk 'END { print NR + 0 }'
  fi
}

atlas_cycle_findings_need_plan_rows() {
  local target="$1"
  local limit="${2:-8}"
  local findings_file
  local validation_file="/dev/null"

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  findings_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$findings_file" ] || return 0
  if [ -s "$(atlas_validation_index_file "$ATLAS_OP_DIR")" ]; then
    validation_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  fi

  jq -sr \
    --arg target "$target" \
    --argjson limit "$limit" \
    --slurpfile validations "$validation_file" '
      ($validations
        | reduce .[] as $plan ({}; if (($plan.finding // "") != "") then .[$plan.finding] = true else . end)
      ) as $planned
      | reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(
          ($target == "" or .target == $target)
          and ((.status // "open") != "resolved")
          and ((.level // "inferred") != "validated")
          and (((.validations // []) | length) == 0)
          and (($planned[.id] // false) | not)
        ))
      | sort_by(.updated_at // .created_at // "", .id)
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.severity // "?"),
          (.level // "?"),
          (.status // "?"),
          (.title // "?")
        ]
      | @tsv
    ' "$findings_file"
}

atlas_cycle_print_findings_need_plan() {
  local target="$1"
  local output

  output="$(
    atlas_cycle_findings_need_plan_rows "$target" 8 |
      awk -F'\t' '{ printf "%-24s %-8s %-10s %-10s %s\n", $1, $2, $3, $4, $5 }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "no open findings are waiting for a validation plan"
  fi
}

atlas_cycle_validation_queue_rows() {
  local target="$1"
  local limit="${2:-8}"
  local validation_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  validation_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$validation_file" ] || return 0

  jq -sr \
    --arg target "$target" \
    --argjson limit "$limit" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(
          ($target == "" or .target == $target)
          and (((.status // "") == "planned") or ((.status // "") == "approved"))
        ))
      | sort_by(.updated_at // .created_at // "", .id)
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.lane // "?"),
          (.status // "?"),
          (.finding // "-"),
          (.reason // "")
        ]
      | @tsv
    ' "$validation_file"
}

atlas_cycle_print_validation_queue() {
  local target="$1"
  local output

  output="$(
    atlas_cycle_validation_queue_rows "$target" 8 |
      awk -F'\t' '{ printf "%-24s %-12s %-10s %-24s %s\n", $1, $2, $3, $4, $5 }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "no planned or approved validation is waiting"
  fi
}

atlas_cycle_latest_report() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "report.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_cycle_print_candidates() {
  local target="$1"
  local output

  output="$(run_vector candidates "$target" 2>/dev/null || true)"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "no candidate lanes produced from current intel"
  fi
}

atlas_cycle_print_header() {
  local target="$1"
  local has_operation="$2"
  local address=""
  local scope_status="unknown"
  local criticality="unknown"
  local owner=""
  local tags=""

  if [ "$has_operation" = "1" ]; then
    address="${ATLAS_OP_TARGET_ADDRESS:-}"
    scope_status="${ATLAS_OP_TARGET_SCOPE_STATUS:-unknown}"
    criticality="${ATLAS_OP_TARGET_CRITICALITY:-unknown}"
    owner="${ATLAS_OP_TARGET_OWNER:-}"
    tags="${ATLAS_OP_TARGET_TAGS:-}"
  else
    address="${ATLAS_TARGET_ADDRESS:-}"
    scope_status="${ATLAS_TARGET_SCOPE_STATUS:-unknown}"
    criticality="${ATLAS_TARGET_CRITICALITY:-unknown}"
    owner="${ATLAS_TARGET_OWNER:-}"
    tags="${ATLAS_TARGET_TAGS:-}"
  fi

  ui_heading "Atlas Exposure Cycle"
  ui_rule
  ui_kv "Target" "$target"
  if [ -n "$address" ] && [ "$address" != "$target" ]; then
    ui_kv "Address" "$address"
  fi
  ui_kv "Scope Status" "$scope_status"
  ui_kv "Criticality" "$criticality"
  if [ -n "$owner" ]; then
    ui_kv "Owner" "$owner"
  fi
  if [ -n "$tags" ]; then
    ui_kv "Tags" "$tags"
  fi
  if [ "$has_operation" = "1" ]; then
    ui_kv "Operation" "$ATLAS_OP_NAME"
    ui_kv "Operation Status" "$ATLAS_OP_STATUS"
  else
    ui_kv "Operation" "none active for this target"
  fi
  ui_kv "Shared Intel" "$LAB_INTEL_DIR"
}

atlas_cycle_print() {
  local target="$1"
  local has_operation="$2"
  local findings_need_plan_count="0"
  local latest_outcome_lane=""
  local latest_outcome_status=""
  local latest_outcome_summary=""
  local latest_report=""
  local latest_report_at=""
  local latest_report_path=""

  atlas_brief_collect "$target" "$has_operation"
  if [ "$has_operation" = "1" ]; then
    findings_need_plan_count="$(atlas_cycle_findings_need_plan_count "$target")"
  fi

  atlas_cycle_print_header "$target" "$has_operation"
  ui_rule

  ui_subheading "Discover"
  ui_kv "Surface" "host=$ATLAS_BRIEF_HOST_STATE, services=$ATLAS_BRIEF_SERVICE_COUNT, web=$ATLAS_BRIEF_WEB_COUNT, lateral=$ATLAS_BRIEF_LATERAL_COUNT"
  if [ -n "$ATLAS_BRIEF_LATEST_OUTCOME" ]; then
    IFS=$'\t' read -r latest_outcome_lane latest_outcome_status latest_outcome_summary <<<"$ATLAS_BRIEF_LATEST_OUTCOME"
    ui_kv "Latest Outcome" "$latest_outcome_lane $latest_outcome_status ${latest_outcome_summary:-}"
  else
    ui_kv "Latest Outcome" "none"
  fi
  ui_rule

  ui_subheading "Assess"
  ui_kv "Shared Posture Findings" "$ATLAS_BRIEF_POSTURE_COUNT"
  if [ "$has_operation" = "1" ]; then
    ui_kv "Operation Findings" "$ATLAS_BRIEF_FINDING_COUNT"
    ui_kv "Findings Needing Validation Plan" "$findings_need_plan_count"
    atlas_cycle_print_findings_need_plan "$target"
  else
    ui_kv "Operation Findings" "no active operation for this target"
    ui_note "start or resume an Atlas operation before recording findings"
  fi
  ui_rule

  ui_subheading "Validate"
  if [ "$has_operation" = "1" ]; then
    ui_kv "Validation Plans" "planned=$ATLAS_BRIEF_PLANNED_COUNT, approved=$ATLAS_BRIEF_APPROVED_COUNT, executed=$ATLAS_BRIEF_EXECUTED_COUNT"
    atlas_cycle_print_validation_queue "$target"
  else
    ui_kv "Validation Plans" "no active operation for this target"
    ui_note "validation planning stays operation-owned and approval-gated"
  fi
  ui_rule

  ui_subheading "Report"
  if [ "$has_operation" = "1" ]; then
    ui_kv "Evidence" "$ATLAS_BRIEF_EVIDENCE_COUNT"
    latest_report="$(atlas_cycle_latest_report)"
    if [ -n "$latest_report" ]; then
      IFS=$'\t' read -r latest_report_at latest_report_path <<<"$latest_report"
      ui_kv "Latest Report" "$latest_report_at $latest_report_path"
    else
      ui_kv "Latest Report" "none generated yet"
    fi
  else
    ui_kv "Evidence" "no active operation for this target"
  fi
  ui_kv "Next Safe Step" "$ATLAS_BRIEF_NEXT_STEP"
  ui_rule

  ui_subheading "Candidate Lanes"
  atlas_cycle_print_candidates "$target"
  ui_rule
  ui_note "cycle is read-only; run explicit Atlas commands for recon, validation, evidence, and reporting"
}

cmd_cycle_target() {
  need_args 1 "$#" "cycle <target>"
  local target_input="$1"
  local target
  local has_operation=0

  resolve_target_input "$target_input"
  target="$ATLAS_TARGET_RESOLVED"

  if has_active_operation; then
    load_active_operation
    if operation_target_matches_identifier "$target"; then
      has_operation=1
      target="$ATLAS_OP_TARGET"
    fi
  fi

  atlas_cycle_print "$target" "$has_operation"
}

cmd_cycle_operation() {
  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  atlas_cycle_print "$ATLAS_OP_TARGET" "1"
}

cmd_cycle() {
  if [ "$#" -gt 0 ]; then
    cmd_cycle_target "$@"
    return 0
  fi

  cmd_cycle_operation "$@"
}
