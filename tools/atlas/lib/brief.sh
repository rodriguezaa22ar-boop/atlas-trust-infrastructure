#!/usr/bin/env bash

atlas_brief_observation_count() {
  local target="$1"
  local observation_type="$2"

  intel_ensure_store
  intel_require_jq
  if [ ! -s "$LAB_INTEL_OBSERVATIONS_FILE" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$target" \
    --arg observation_type "$observation_type" '
      map(select(.target == $target and .observation_type == $observation_type))
      | length
    ' "$LAB_INTEL_OBSERVATIONS_FILE"
}

atlas_brief_latest_host_state() {
  local target="$1"
  local state

  intel_ensure_store
  intel_require_jq
  if [ ! -s "$LAB_INTEL_OBSERVATIONS_FILE" ]; then
    printf 'unknown\n'
    return 0
  fi

  state="$(
    jq -r --arg target "$target" '
      select(.target == $target and .observation_type == "host_state")
      | .value.state // empty
    ' "$LAB_INTEL_OBSERVATIONS_FILE" |
      tail -n 1
  )"

  printf '%s\n' "${state:-unknown}"
}

atlas_brief_service_count() {
  local target="$1"

  intel_ensure_store
  intel_require_jq
  if [ -s "$LAB_INTEL_ENTITIES_FILE" ]; then
    jq -sr --arg target "$target" '
      map(select(.entity_type == "service" and .target == $target))
      | unique_by(.entity_id)
      | length
    ' "$LAB_INTEL_ENTITIES_FILE"
    return 0
  fi

  if [ ! -s "$LAB_INTEL_OBSERVATIONS_FILE" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr --arg target "$target" '
    map(select(.target == $target and .observation_type == "service_open"))
    | unique_by((.value.service_entity_id // "") + "|" + (.value.portproto // ""))
    | length
  ' "$LAB_INTEL_OBSERVATIONS_FILE"
}

atlas_brief_web_count() {
  local target="$1"

  intel_ensure_store
  intel_require_jq
  if [ ! -s "$LAB_INTEL_OBSERVATIONS_FILE" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr --arg target "$target" '
    map(select(.target == $target and (.observation_type == "web_surface" or .observation_type == "web_probe")))
    | unique_by((.value.endpoint // "") + "|" + (.value.portproto // ""))
    | length
  ' "$LAB_INTEL_OBSERVATIONS_FILE"
}

atlas_brief_latest_outcome() {
  local target="$1"

  intel_ensure_store
  intel_require_jq
  if [ ! -s "$LAB_INTEL_OUTCOMES_FILE" ]; then
    return 0
  fi

  jq -sr --arg target "$target" '
    map(select(.target == $target))
    | sort_by(.recorded_at)
    | last // empty
    | [
        (.source_name // "?"),
        (.status // "?"),
        (.summary // "")
      ]
    | @tsv
  ' "$LAB_INTEL_OUTCOMES_FILE"
}

atlas_brief_latest_finding() {
  local target="$1"
  local index_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr --arg target "$target" '
    reduce .[] as $record ({}; .[$record.id] = $record)
    | [.[]]
    | map(select(.target == $target))
    | sort_by(.updated_at // .created_at // "", .id)
    | last // empty
    | [
        (.id // "?"),
        (.severity // "?"),
        (.level // "?"),
        (.status // "?"),
        (.title // "?")
      ]
    | @tsv
  ' "$index_file"
}

atlas_brief_latest_validation() {
  local target="$1"
  local index_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr --arg target "$target" '
    reduce .[] as $record ({}; .[$record.id] = $record)
    | [.[]]
    | map(select(.target == $target))
    | sort_by(.updated_at, .id)
    | last // empty
    | [
        (.id // "?"),
        (.lane // "?"),
        (.status // "?"),
        (.result_status // "-")
      ]
    | @tsv
  ' "$index_file"
}

atlas_brief_validation_status_count() {
  local target="$1"
  local status="$2"
  local index_file

  [ -n "${ATLAS_OP_DIR:-}" ] || {
    printf '0\n'
    return 0
  }
  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$target" \
    --arg status "$status" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(.target == $target and .status == $status))
      | length
    ' "$index_file"
}

atlas_brief_has_active_operation_for_target() {
  local target="$1"

  has_active_operation || return 1
  load_active_operation
  operation_target_matches_identifier "$target"
}

atlas_brief_next_step() {
  local has_operation="$1"
  local service_count="$2"
  local web_count="$3"
  local finding_count="$4"
  local validation_count="$5"
  local planned_count="$6"
  local approved_count="$7"
  local executed_count="$8"

  if [ "$has_operation" != "1" ]; then
    if [ "$service_count" -gt 0 ] || [ "$web_count" -gt 0 ]; then
      printf 'Start or resume an Atlas operation before recording evidence or validation.\n'
    else
      printf 'Run scoped recon to establish host state and service evidence.\n'
    fi
    return 0
  fi

  if [ "$approved_count" -gt 0 ]; then
    printf 'Run the approved validation plan and record the resulting evidence.\n'
  elif [ "$planned_count" -gt 0 ]; then
    printf 'Approve, revise, or retire the planned validation before execution.\n'
  elif [ "$finding_count" -gt 0 ] && [ "$validation_count" -eq 0 ]; then
    printf 'Create a validation plan for the highest-value finding.\n'
  elif [ "$executed_count" -gt 0 ]; then
    printf 'Review validation output, update finding status, and refresh the report.\n'
  elif [ "$service_count" -gt 0 ] || [ "$web_count" -gt 0 ]; then
    printf 'Review candidate lanes and record findings for material issues.\n'
  else
    printf 'Run operation-aware recon to build evidence for this target.\n'
  fi
}

atlas_brief_collect() {
  local target="$1"
  local has_operation="${2:-0}"
  local host_state
  local service_count
  local web_count
  local lateral_count
  local posture_count
  local evidence_count=0
  local finding_count=0
  local validation_count=0
  local planned_count=0
  local approved_count=0
  local executed_count=0
  local latest_outcome
  local latest_finding=""
  local latest_validation=""
  local next_step

  host_state="$(atlas_brief_latest_host_state "$target")"
  service_count="$(atlas_brief_service_count "$target")"
  web_count="$(atlas_brief_web_count "$target")"
  lateral_count="$(atlas_brief_observation_count "$target" "lateral_surface")"
  posture_count="$(atlas_brief_observation_count "$target" "http_posture_finding")"
  latest_outcome="$(atlas_brief_latest_outcome "$target")"

  if [ "$has_operation" = "1" ]; then
    evidence_count="$(atlas_evidence_count_for_target "$ATLAS_OP_TARGET")"
    finding_count="$(atlas_findings_count_for_target "$ATLAS_OP_TARGET")"
    validation_count="$(atlas_validation_count_for_target "$ATLAS_OP_TARGET")"
    planned_count="$(atlas_brief_validation_status_count "$ATLAS_OP_TARGET" "planned")"
    approved_count="$(atlas_brief_validation_status_count "$ATLAS_OP_TARGET" "approved")"
    executed_count="$(atlas_brief_validation_status_count "$ATLAS_OP_TARGET" "executed")"
    latest_finding="$(atlas_brief_latest_finding "$ATLAS_OP_TARGET")"
    latest_validation="$(atlas_brief_latest_validation "$ATLAS_OP_TARGET")"
  fi

  next_step="$(atlas_brief_next_step "$has_operation" "$service_count" "$web_count" "$finding_count" "$validation_count" "$planned_count" "$approved_count" "$executed_count")"

  ATLAS_BRIEF_HOST_STATE="$host_state"
  ATLAS_BRIEF_SERVICE_COUNT="$service_count"
  ATLAS_BRIEF_WEB_COUNT="$web_count"
  ATLAS_BRIEF_LATERAL_COUNT="$lateral_count"
  ATLAS_BRIEF_POSTURE_COUNT="$posture_count"
  ATLAS_BRIEF_EVIDENCE_COUNT="$evidence_count"
  ATLAS_BRIEF_FINDING_COUNT="$finding_count"
  ATLAS_BRIEF_VALIDATION_COUNT="$validation_count"
  ATLAS_BRIEF_PLANNED_COUNT="$planned_count"
  ATLAS_BRIEF_APPROVED_COUNT="$approved_count"
  ATLAS_BRIEF_EXECUTED_COUNT="$executed_count"
  ATLAS_BRIEF_LATEST_OUTCOME="$latest_outcome"
  ATLAS_BRIEF_LATEST_FINDING="$latest_finding"
  ATLAS_BRIEF_LATEST_VALIDATION="$latest_validation"
  ATLAS_BRIEF_NEXT_STEP="$next_step"
}

atlas_brief_print_lines() {
  local has_operation="$1"
  local lane=""
  local outcome_status=""
  local outcome_summary=""
  local finding_id=""
  local severity=""
  local level=""
  local finding_status=""
  local title=""
  local validation_id=""
  local validation_lane=""
  local validation_status=""
  local validation_result=""

  ui_kv "Surface" "host=$ATLAS_BRIEF_HOST_STATE, services=$ATLAS_BRIEF_SERVICE_COUNT, web=$ATLAS_BRIEF_WEB_COUNT, lateral=$ATLAS_BRIEF_LATERAL_COUNT, posture_findings=$ATLAS_BRIEF_POSTURE_COUNT"

  if [ "$has_operation" = "1" ]; then
    ui_kv "Operation State" "evidence=$ATLAS_BRIEF_EVIDENCE_COUNT, findings=$ATLAS_BRIEF_FINDING_COUNT, validation_plans=$ATLAS_BRIEF_VALIDATION_COUNT"
    ui_kv "Validation" "planned=$ATLAS_BRIEF_PLANNED_COUNT, approved=$ATLAS_BRIEF_APPROVED_COUNT, executed=$ATLAS_BRIEF_EXECUTED_COUNT"
  else
    ui_kv "Operation State" "no active operation for this target"
  fi

  if [ -n "$ATLAS_BRIEF_LATEST_OUTCOME" ]; then
    IFS=$'\t' read -r lane outcome_status outcome_summary <<<"$ATLAS_BRIEF_LATEST_OUTCOME"
    ui_kv "Latest Outcome" "$lane $outcome_status ${outcome_summary:-}"
  fi

  if [ -n "$ATLAS_BRIEF_LATEST_FINDING" ]; then
    IFS=$'\t' read -r finding_id severity level finding_status title <<<"$ATLAS_BRIEF_LATEST_FINDING"
    ui_kv "Latest Finding" "$finding_id $severity/$level/$finding_status $title"
  fi

  if [ -n "$ATLAS_BRIEF_LATEST_VALIDATION" ]; then
    IFS=$'\t' read -r validation_id validation_lane validation_status validation_result <<<"$ATLAS_BRIEF_LATEST_VALIDATION"
    ui_kv "Latest Validation" "$validation_id $validation_lane $validation_status result=$validation_result"
  fi

  ui_kv "Next Step" "$ATLAS_BRIEF_NEXT_STEP"
}

atlas_brief_print_target() {
  local target="$1"
  local has_operation=0
  local brief_target="$target"

  if atlas_brief_has_active_operation_for_target "$target"; then
    has_operation=1
    brief_target="$ATLAS_OP_TARGET"
  fi

  atlas_brief_collect "$brief_target" "$has_operation"
  atlas_brief_print_lines "$has_operation"
}

atlas_brief_print_operation() {
  local target="$1"

  atlas_brief_collect "$target" "1"
  atlas_brief_print_lines "1"
}

atlas_brief_report_markdown() {
  local target="$1"
  local lane=""
  local outcome_status=""
  local outcome_summary=""
  local finding_id=""
  local severity=""
  local level=""
  local finding_status=""
  local title=""
  local validation_id=""
  local validation_lane=""
  local validation_status=""
  local validation_result=""

  atlas_brief_collect "$target" "1"

  printf -- '- Surface: host=%s, services=%s, web=%s, lateral=%s, posture_findings=%s.\n' \
    "$ATLAS_BRIEF_HOST_STATE" \
    "$ATLAS_BRIEF_SERVICE_COUNT" \
    "$ATLAS_BRIEF_WEB_COUNT" \
    "$ATLAS_BRIEF_LATERAL_COUNT" \
    "$ATLAS_BRIEF_POSTURE_COUNT"
  printf -- '- Operation state: evidence=%s, findings=%s, validation_plans=%s.\n' \
    "$ATLAS_BRIEF_EVIDENCE_COUNT" \
    "$ATLAS_BRIEF_FINDING_COUNT" \
    "$ATLAS_BRIEF_VALIDATION_COUNT"
  printf -- '- Validation: planned=%s, approved=%s, executed=%s.\n' \
    "$ATLAS_BRIEF_PLANNED_COUNT" \
    "$ATLAS_BRIEF_APPROVED_COUNT" \
    "$ATLAS_BRIEF_EXECUTED_COUNT"

  if [ -n "$ATLAS_BRIEF_LATEST_OUTCOME" ]; then
    IFS=$'\t' read -r lane outcome_status outcome_summary <<<"$ATLAS_BRIEF_LATEST_OUTCOME"
    printf -- '- Latest outcome: %s %s %s.\n' "$lane" "$outcome_status" "$outcome_summary"
  fi

  if [ -n "$ATLAS_BRIEF_LATEST_FINDING" ]; then
    IFS=$'\t' read -r finding_id severity level finding_status title <<<"$ATLAS_BRIEF_LATEST_FINDING"
    printf -- '- Latest finding: %s %s/%s/%s %s.\n' "$finding_id" "$severity" "$level" "$finding_status" "$title"
  fi

  if [ -n "$ATLAS_BRIEF_LATEST_VALIDATION" ]; then
    IFS=$'\t' read -r validation_id validation_lane validation_status validation_result <<<"$ATLAS_BRIEF_LATEST_VALIDATION"
    printf -- '- Latest validation: %s %s %s result=%s.\n' "$validation_id" "$validation_lane" "$validation_status" "$validation_result"
  fi

  printf -- '- Next step: %s\n' "$ATLAS_BRIEF_NEXT_STEP"
}
