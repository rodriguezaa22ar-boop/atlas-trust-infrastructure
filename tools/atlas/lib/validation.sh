#!/usr/bin/env bash

atlas_validation_index_file() {
  local op_dir="$1"

  printf '%s/validation-plans.ndjson\n' "$op_dir"
}

atlas_validation_dir() {
  local op_dir="$1"

  printf '%s/validation-plans\n' "$op_dir"
}

atlas_validation_next_id() {
  local validation_dir="$1"
  local base
  local candidate
  local index=1

  base="vp_$(date -u +%Y%m%dT%H%M%SZ)"
  candidate="$base"

  while [ -e "$validation_dir/$candidate" ]; do
    index=$((index + 1))
    candidate="$(printf '%s_%02d' "$base" "$index")"
  done

  printf '%s\n' "$candidate"
}

atlas_validation_validate_capability() {
  case "$1" in
  safe-validation)
    return 0
    ;;
  *)
    fail "validation plans currently support safe-validation only; got: $1"
    ;;
  esac
}

atlas_validation_check_capability_allowed() {
  local capability="$1"
  local target="$2"

  atlas_scope_load_snapshot
  atlas_validation_validate_capability "$capability"

  if ! atlas_scope_target_matches "$target"; then
    fail "scope refused: target '$target' is outside active operation scope '$ATLAS_SCOPE_TARGET'"
  fi
  if atlas_scope_word_contains "$ATLAS_SCOPE_BLOCKED" "$capability"; then
    fail "scope refused: capability '$capability' is blocked"
  fi
  if ! atlas_scope_word_contains "$ATLAS_SCOPE_ALLOWED" "$capability"; then
    fail "scope refused: capability '$capability' is not allowed for this operation"
  fi
}

atlas_validation_check_lane_allowed() {
  local lane="$1"

  atlas_scope_load_snapshot
  [ -z "${ATLAS_SCOPE_VALIDATION_LANES:-}" ] && return 0

  if ! atlas_scope_word_contains "$ATLAS_SCOPE_VALIDATION_LANES" "$lane"; then
    fail "validation lane '$lane' is not allowed by active scope profile '$ATLAS_SCOPE_PROFILE'"
  fi
}

atlas_validation_append_record() {
  local id="$1"
  local target="$2"
  local lane="$3"
  local capability="$4"
  local status="$5"
  local reason="$6"
  local finding_id="$7"
  local plan_path="$8"
  local created_at="$9"
  local approval_reason="${10}"
  local approved_by="${11}"
  local session_dir="${12}"
  local result_status="${13}"
  shift 13
  local evidence_ids=("$@")
  local evidence_text
  local index_file

  intel_require_jq

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  : >>"$index_file"
  chmod 600 "$index_file" 2>/dev/null || true
  evidence_text="${evidence_ids[*]}"

  jq -cn \
    --arg id "$id" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$target" \
    --arg lane "$lane" \
    --arg capability "$capability" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg finding_id "$finding_id" \
    --arg plan_path "$plan_path" \
    --arg created_at "$created_at" \
    --arg updated_at "$(timestamp)" \
    --arg approval_reason "$approval_reason" \
    --arg approved_by "$approved_by" \
    --arg session_dir "$session_dir" \
    --arg result_status "$result_status" \
    --arg evidence_text "$evidence_text" \
    '{
      id: $id,
      operation: $operation,
      target: $target,
      lane: $lane,
      capability: $capability,
      status: $status,
      reason: $reason,
      finding: (if $finding_id == "" then null else $finding_id end),
      evidence: ($evidence_text | split(" ") | map(select(length > 0))),
      plan_path: $plan_path,
      created_at: $created_at,
      updated_at: $updated_at,
      approval_reason: (if $approval_reason == "" then null else $approval_reason end),
      approved_by: (if $approved_by == "" then null else $approved_by end),
      session_dir: (if $session_dir == "" then null else $session_dir end),
      result_status: (if $result_status == "" then null else $result_status end)
    }' >>"$index_file"
}

atlas_validation_latest_record() {
  local plan_id="$1"
  local index_file

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 1

  jq -sr \
    --arg plan_id "$plan_id" '
      map(select(.id == $plan_id))
      | last // empty
    ' "$index_file"
}

atlas_validation_load_plan() {
  local plan_id="$1"
  local record
  local output

  record="$(atlas_validation_latest_record "$plan_id" || true)"
  [ -n "$record" ] || fail "unknown validation plan: $plan_id"

  output="$(
    printf '%s\n' "$record" |
      jq -r '
        [
          (.id // ""),
          (.operation // ""),
          (.target // ""),
          (.lane // ""),
          (.capability // ""),
          (.status // ""),
          (.reason // ""),
          (.finding // ""),
          ((.evidence // []) | join(" ")),
          (.plan_path // ""),
          (.created_at // ""),
          (.updated_at // ""),
          (.approval_reason // ""),
          (.approved_by // ""),
          (.session_dir // ""),
          (.result_status // "")
        ]
        | @tsv
      '
  )"

  IFS=$'\t' read -r \
    ATLAS_VALIDATION_ID \
    ATLAS_VALIDATION_OPERATION \
    ATLAS_VALIDATION_TARGET \
    ATLAS_VALIDATION_LANE \
    ATLAS_VALIDATION_CAPABILITY \
    ATLAS_VALIDATION_STATUS \
    ATLAS_VALIDATION_REASON \
    ATLAS_VALIDATION_FINDING \
    ATLAS_VALIDATION_EVIDENCE \
    ATLAS_VALIDATION_PLAN_PATH \
    ATLAS_VALIDATION_CREATED_AT \
    ATLAS_VALIDATION_UPDATED_AT \
    ATLAS_VALIDATION_APPROVAL_REASON \
    ATLAS_VALIDATION_APPROVED_BY \
    ATLAS_VALIDATION_SESSION_DIR \
    ATLAS_VALIDATION_RESULT_STATUS <<<"$output"
}

atlas_validation_evidence_args() {
  local evidence_text="$1"
  local evidence_id

  for evidence_id in $evidence_text; do
    [ -n "$evidence_id" ] || continue
    printf '%s\n' "$evidence_id"
  done
}

atlas_validation_finding_exists() {
  local finding_id="$1"
  local index_file

  [ -n "$finding_id" ] || return 0
  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 1

  jq -e \
    --arg finding_id "$finding_id" \
    'select(.id == $finding_id)' \
    "$index_file" >/dev/null
}

cmd_validation_plan() {
  need_args 1 "$#" "validation plan <lane> [--finding id] [--evidence id] [--reason text]"
  local lane="$1"
  local capability="safe-validation"
  local reason=""
  local finding_id=""
  local evidence_ids=()
  local validation_root
  local plan_id
  local plan_dir
  local relative_plan_path
  local plan_file
  local plan_output
  local created_at

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --finding)
      need_args 2 "$#" "validation plan <lane> --finding <id>"
      finding_id="$2"
      shift 2
      ;;
    --evidence)
      need_args 2 "$#" "validation plan <lane> --evidence <id>"
      evidence_ids+=("$2")
      shift 2
      ;;
    --reason)
      need_args 2 "$#" "validation plan <lane> --reason <text>"
      reason="$2"
      shift 2
      ;;
    --capability)
      need_args 2 "$#" "validation plan <lane> --capability <capability>"
      capability="$2"
      shift 2
      ;;
    *)
      fail "unknown validation plan option: $1"
      ;;
    esac
  done

  load_active_operation
  atlas_scope_preflight "read-only" "atlas" "$ATLAS_OP_TARGET" "plan validation lane $lane"
  atlas_validation_check_capability_allowed "$capability" "$ATLAS_OP_TARGET"
  atlas_validation_check_lane_allowed "$lane"
  atlas_findings_validate_evidence_ids "${evidence_ids[@]}"
  if [ -n "$finding_id" ] && ! atlas_validation_finding_exists "$finding_id"; then
    fail "unknown finding id for active operation: $finding_id"
  fi

  plan_output="$(run_vector plan "$lane" "$ATLAS_OP_TARGET")"

  validation_root="$(atlas_validation_dir "$ATLAS_OP_DIR")"
  mkdir -p "$validation_root"
  chmod 700 "$validation_root" 2>/dev/null || true

  plan_id="$(atlas_validation_next_id "$validation_root")"
  plan_dir="$validation_root/$plan_id"
  mkdir -p "$plan_dir"
  chmod 700 "$plan_dir" 2>/dev/null || true
  relative_plan_path="validation-plans/$plan_id/vector-plan.txt"
  plan_file="$ATLAS_OP_DIR/$relative_plan_path"
  printf '%s\n' "$plan_output" >"$plan_file"
  chmod 600 "$plan_file" 2>/dev/null || true

  created_at="$(timestamp)"
  atlas_validation_append_record "$plan_id" "$ATLAS_OP_TARGET" "$lane" "$capability" "planned" "$reason" "$finding_id" "$relative_plan_path" "$created_at" "" "" "" "" "${evidence_ids[@]}"
  atlas_ledger_append_current "validation.planned" "$capability" "atlas" "planned" "validation_plan=$plan_id lane=$lane finding=$finding_id"
  record_operation_history "$ATLAS_OP_DIR" "validation-plan:$lane" "$plan_id"

  ui_ok "validation plan recorded"
  printf 'id: %s\n' "$plan_id"
  printf 'status: planned\n'
  printf 'lane: %s\n' "$lane"
  printf 'capability: %s\n' "$capability"
  printf 'target: %s\n' "$ATLAS_OP_TARGET"
  printf 'plan: %s\n' "$plan_file"
  if [ -n "$finding_id" ]; then
    printf 'finding: %s\n' "$finding_id"
  fi
  if [ "${#evidence_ids[@]}" -gt 0 ]; then
    printf 'evidence: %s\n' "${evidence_ids[*]}"
  fi
  printf '\n%s\n' "$plan_output"
}

cmd_validation_list() {
  local index_file

  load_active_operation
  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"

  ui_heading "Validation Plans"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Store" "$index_file"
  ui_rule

  if [ ! -s "$index_file" ]; then
    ui_note "no validation plans recorded yet"
    return 0
  fi

  jq -sr '
    reduce .[] as $record ({}; .[$record.id] = $record)
    | [.[]]
    | sort_by(.created_at, .id)
    | .[]
    | [
        (.id // "?"),
        (.lane // "?"),
        (.capability // "?"),
        (.status // "?"),
        (.finding // "-"),
        ((.evidence // []) | join(","))
      ]
    | @tsv
  ' "$index_file" |
    awk -F'\t' '{
      evidence = $6 == "" ? "-" : $6
      printf "%-24s %-12s %-16s %-10s %-24s %s\n", $1, $2, $3, $4, $5, evidence
    }'
}

cmd_validation_show() {
  need_args 1 "$#" "validation show <id>"
  local plan_id="$1"

  load_active_operation
  atlas_validation_load_plan "$plan_id"

  ui_heading "Validation Plan"
  ui_rule
  ui_kv "ID" "$ATLAS_VALIDATION_ID"
  ui_kv "Operation" "$ATLAS_VALIDATION_OPERATION"
  ui_kv "Target" "$ATLAS_VALIDATION_TARGET"
  ui_kv "Lane" "$ATLAS_VALIDATION_LANE"
  ui_kv "Capability" "$ATLAS_VALIDATION_CAPABILITY"
  ui_kv "Status" "$ATLAS_VALIDATION_STATUS"
  if [ -n "$ATLAS_VALIDATION_REASON" ]; then
    ui_kv "Reason" "$ATLAS_VALIDATION_REASON"
  fi
  if [ -n "$ATLAS_VALIDATION_FINDING" ]; then
    ui_kv "Finding" "$ATLAS_VALIDATION_FINDING"
  fi
  if [ -n "$ATLAS_VALIDATION_EVIDENCE" ]; then
    ui_kv "Evidence" "$ATLAS_VALIDATION_EVIDENCE"
  fi
  ui_kv "Plan" "$ATLAS_OP_DIR/$ATLAS_VALIDATION_PLAN_PATH"
  ui_kv "Created" "$ATLAS_VALIDATION_CREATED_AT"
  ui_kv "Updated" "$ATLAS_VALIDATION_UPDATED_AT"
  if [ -n "$ATLAS_VALIDATION_APPROVED_BY" ]; then
    ui_kv "Approved By" "$ATLAS_VALIDATION_APPROVED_BY"
  fi
  if [ -n "$ATLAS_VALIDATION_APPROVAL_REASON" ]; then
    ui_kv "Approval Reason" "$ATLAS_VALIDATION_APPROVAL_REASON"
  fi
  if [ -n "$ATLAS_VALIDATION_SESSION_DIR" ]; then
    ui_kv "Session Dir" "$ATLAS_VALIDATION_SESSION_DIR"
  fi
  if [ -n "$ATLAS_VALIDATION_RESULT_STATUS" ]; then
    ui_kv "Result" "$ATLAS_VALIDATION_RESULT_STATUS"
  fi
}

cmd_validation_approve() {
  need_args 2 "$#" "validation approve <id> <reason...>"
  local plan_id="$1"
  local reason
  local evidence_ids=()
  local evidence_id

  shift
  reason="$*"
  [ -n "$reason" ] || fail "approval reason is required"

  load_active_operation
  atlas_validation_load_plan "$plan_id"
  [ "$ATLAS_VALIDATION_STATUS" = "planned" ] || fail "validation plan '$plan_id' is not pending approval; status: $ATLAS_VALIDATION_STATUS"
  atlas_validation_check_capability_allowed "$ATLAS_VALIDATION_CAPABILITY" "$ATLAS_VALIDATION_TARGET"
  atlas_validation_check_lane_allowed "$ATLAS_VALIDATION_LANE"

  while IFS= read -r evidence_id; do
    evidence_ids+=("$evidence_id")
  done < <(atlas_validation_evidence_args "$ATLAS_VALIDATION_EVIDENCE")

  atlas_approval_append_current "$ATLAS_VALIDATION_CAPABILITY" "validation_plan=$plan_id $reason"
  atlas_validation_append_record "$plan_id" "$ATLAS_VALIDATION_TARGET" "$ATLAS_VALIDATION_LANE" "$ATLAS_VALIDATION_CAPABILITY" "approved" "$ATLAS_VALIDATION_REASON" "$ATLAS_VALIDATION_FINDING" "$ATLAS_VALIDATION_PLAN_PATH" "$ATLAS_VALIDATION_CREATED_AT" "$reason" "$(atlas_approval_operator)" "" "" "${evidence_ids[@]}"
  atlas_ledger_append_current "approval.granted" "$ATLAS_VALIDATION_CAPABILITY" "atlas" "approved" "validation_plan=$plan_id $reason"
  atlas_ledger_append_current "validation.approved" "$ATLAS_VALIDATION_CAPABILITY" "atlas" "approved" "validation_plan=$plan_id lane=$ATLAS_VALIDATION_LANE"

  ui_ok "validation plan approved"
  printf 'id: %s\n' "$plan_id"
  printf 'status: approved\n'
  printf 'lane: %s\n' "$ATLAS_VALIDATION_LANE"
  printf 'capability: %s\n' "$ATLAS_VALIDATION_CAPABILITY"
  printf 'target: %s\n' "$ATLAS_VALIDATION_TARGET"
  printf 'approved_by: %s\n' "$(atlas_approval_operator)"
}

cmd_validation_run() {
  need_args 1 "$#" "validation run <id> [session-name]"
  local plan_id="$1"
  local session_name="${2:-}"
  local output
  local session_dir
  local result_status
  local link
  local evidence_ids=()
  local evidence_id

  load_active_operation
  atlas_validation_load_plan "$plan_id"
  [ "$ATLAS_VALIDATION_STATUS" = "approved" ] || fail "validation plan '$plan_id' requires approval before run; status: $ATLAS_VALIDATION_STATUS"
  atlas_validation_check_capability_allowed "$ATLAS_VALIDATION_CAPABILITY" "$ATLAS_VALIDATION_TARGET"
  atlas_validation_check_lane_allowed "$ATLAS_VALIDATION_LANE"
  atlas_scope_preflight "$ATLAS_VALIDATION_CAPABILITY" "vector" "$ATLAS_VALIDATION_TARGET" "run validation plan $plan_id lane $ATLAS_VALIDATION_LANE"

  if [ -z "$session_name" ]; then
    session_name="$ATLAS_OP_NAME validation $ATLAS_VALIDATION_LANE $plan_id"
  fi

  output="$(run_vector run "$ATLAS_VALIDATION_LANE" "$ATLAS_VALIDATION_TARGET" "$session_name")"
  printf '%s\n' "$output"

  session_dir="$(printf '%s\n' "$output" | capture_field "Session Dir")"
  [ -n "$session_dir" ] || fail "unable to determine vector session directory"
  result_status="$(printf '%s\n' "$output" | capture_field "Status")"
  link="$(track_operation_action_session "$ATLAS_OP_DIR" "$ATLAS_OP_FILE" "$session_dir")"

  while IFS= read -r evidence_id; do
    evidence_ids+=("$evidence_id")
  done < <(atlas_validation_evidence_args "$ATLAS_VALIDATION_EVIDENCE")

  atlas_validation_append_record "$plan_id" "$ATLAS_VALIDATION_TARGET" "$ATLAS_VALIDATION_LANE" "$ATLAS_VALIDATION_CAPABILITY" "executed" "$ATLAS_VALIDATION_REASON" "$ATLAS_VALIDATION_FINDING" "$ATLAS_VALIDATION_PLAN_PATH" "$ATLAS_VALIDATION_CREATED_AT" "$ATLAS_VALIDATION_APPROVAL_REASON" "$ATLAS_VALIDATION_APPROVED_BY" "$session_dir" "$result_status" "${evidence_ids[@]}"
  atlas_ledger_append_current "validation.executed" "$ATLAS_VALIDATION_CAPABILITY" "vector" "${result_status:-ok}" "validation_plan=$plan_id lane=$ATLAS_VALIDATION_LANE session_dir=$session_dir"
  atlas_ledger_append_current "tool.completed" "$ATLAS_VALIDATION_CAPABILITY" "vector" "${result_status:-ok}" "validation_plan=$plan_id lane=$ATLAS_VALIDATION_LANE session_dir=$session_dir"
  record_operation_history "$ATLAS_OP_DIR" "validation-run:$ATLAS_VALIDATION_LANE" "$plan_id"

  printf 'validation_plan: %s\n' "$plan_id"
  printf 'validation_status: executed\n'
  printf 'operation_action_session: %s\n' "$session_dir"
  printf 'operation_action_link: %s\n' "$link"
}

atlas_validation_count_for_target() {
  local target="${1:-}"
  local index_file

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$target" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select($target == "" or .target == $target))
      | length
    ' "$index_file"
}

atlas_validation_rows_for_target() {
  local target="${1:-}"
  local limit="${2:-8}"
  local index_file

  intel_require_jq

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg target "$target" \
    --argjson limit "$limit" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select($target == "" or .target == $target))
      | sort_by(.created_at, .id)
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.lane // "?"),
          (.capability // "?"),
          (.status // "?"),
          (.finding // "-"),
          (.result_status // "-")
        ]
      | @tsv
    ' "$index_file"
}

atlas_validation_print_table_for_target() {
  local target="${1:-}"
  local limit="${2:-8}"
  local empty_note="${3:-no validation plans recorded yet}"
  local output

  output="$(
    atlas_validation_rows_for_target "$target" "$limit" |
      awk -F'\t' '{ printf "%-24s %-12s %-16s %-10s %-24s %s\n", $1, $2, $3, $4, $5, $6 }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "$empty_note"
  fi
}

atlas_validation_report_markdown() {
  local index_file

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf -- '- No validation plans recorded yet.\n'
    return 0
  fi

  jq -sr '
    reduce .[] as $record ({}; .[$record.id] = $record)
    | [.[]]
    | sort_by(.created_at, .id)
    | .[]
    | "- " + (.id // "?") +
      " / " + (.lane // "?") +
      " / " + (.capability // "?") +
      " / " + (.status // "?") +
      (if (.finding // "") != "" then " Finding: " + .finding + "." else "" end) +
      (if ((.evidence // []) | length) > 0 then " Evidence: " + ((.evidence // []) | join(", ")) + "." else "" end) +
      (if (.result_status // "") != "" then " Result: " + .result_status + "." else "" end)
  ' "$index_file"
}
