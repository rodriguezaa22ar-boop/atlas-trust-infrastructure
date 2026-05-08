#!/usr/bin/env bash

atlas_approval_file() {
  local op_dir="$1"

  printf '%s/approvals.ndjson\n' "$op_dir"
}

atlas_approval_requires_gate() {
  case "$1" in
  safe-validation | intrusive-validation)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

atlas_approval_operator() {
  printf '%s\n' "${ATLAS_OPERATOR:-${USER:-unknown}}"
}

atlas_governance_approval_workflows_file() {
  printf '%s/approval/workflows.yaml\n' "$LAB_ROOT"
}

atlas_governance_approval_schema_file() {
  printf '%s/schemas/approval-event.v1.schema.json\n' "$LAB_ROOT"
}

atlas_approval_require_jq() {
  command -v jq >/dev/null 2>&1 || fail "approval evaluation requires jq"
}

atlas_approval_read_event() {
  local input="$1"

  if [ "$input" = "-" ]; then
    cat
    return 0
  fi

  [ -f "$input" ] || fail "missing approval event: $input"
  cat -- "$input"
}

atlas_approval_workflow_id_for_class() {
  local class="$1"
  local workflows

  workflows="$(atlas_governance_approval_workflows_file)"
  [ -f "$workflows" ] || fail "missing approval/workflows.yaml"

  jq -r --arg class "$class" '
    [
      .workflows[]
      | select(.applies_to_classes | index($class))
      | .id
    ][0] // empty
  ' "$workflows"
}

atlas_approval_validate_event_json() {
  local event_json="$1"
  local capability
  local capability_json
  local expected_class
  local actual_class
  local workflow
  local workflow_match
  local status
  local event_type

  atlas_approval_require_jq

  printf '%s\n' "$event_json" | jq -e . >/dev/null 2>&1 ||
    fail "invalid approval event JSON"

  printf '%s\n' "$event_json" | jq -e '
    . as $event |
    def nonempty($key): ($event[$key] | type == "string" and length > 0);
    ($event | type == "object") and
    $event.schema_version == "atlas.approval_event.v1" and
    $event.metadata_only == true and
    nonempty("event_id") and
    nonempty("event_type") and
    nonempty("timestamp") and
    nonempty("requester") and
    nonempty("capability") and
    nonempty("capability_class") and
    nonempty("workflow") and
    nonempty("risk") and
    ($event.scope.value | type == "string" and length > 0) and
    nonempty("approver") and
    nonempty("expiry") and
    nonempty("rationale") and
    nonempty("rollback_plan") and
    ($event.evidence_refs | type == "array" and length > 0) and
    all($event.evidence_refs[]; type == "string" and length > 0) and
    nonempty("status") and
    ($event.policy_decision.decision | type == "string" and length > 0) and
    ($event.policy_decision.policy_ref | type == "string" and length > 0) and
    ($event.policy_decision.reason | type == "string" and length > 0) and
    (["approval_requested", "approval_approved", "approval_expired"] | index($event.event_type)) and
    (["requested", "approved", "expired"] | index($event.status)) and
    (["low", "medium", "high", "critical"] | index($event.risk)) and
    (["bounded_exec", "mutate", "admin"] | index($event.capability_class)) and
    ($event | (has("raw_approval") or has("operator_notes") or has("request_body") or has("response_body") or has("secret") or has("token")) | not)
  ' >/dev/null || fail "invalid approval event fields"

  capability="$(printf '%s\n' "$event_json" | jq -r '.capability')"
  capability_json="$(atlas_policy_capability_json "$capability")"
  [ -n "$capability_json" ] || fail "unknown approval capability $capability"

  actual_class="$(printf '%s\n' "$event_json" | jq -r '.capability_class')"
  expected_class="$(printf '%s\n' "$capability_json" | jq -r '.class')"
  [ "$actual_class" = "$expected_class" ] ||
    fail "approval class mismatch $capability expected $expected_class got $actual_class"

  workflow="$(printf '%s\n' "$event_json" | jq -r '.workflow')"
  workflow_match="$(atlas_approval_workflow_id_for_class "$actual_class")"
  [ -n "$workflow_match" ] || fail "missing approval workflow for $actual_class"
  [ "$workflow" = "$workflow_match" ] ||
    fail "approval workflow mismatch $capability expected $workflow_match got $workflow"

  event_type="$(printf '%s\n' "$event_json" | jq -r '.event_type')"
  status="$(printf '%s\n' "$event_json" | jq -r '.status')"
  case "$status:$event_type" in
  requested:approval_requested)
    printf '%s\n' "$event_json" | jq -e '.policy_decision.decision == "approval_required"' >/dev/null ||
      fail "requested approval must preserve approval_required policy decision"
    ;;
  approved:approval_approved)
    printf '%s\n' "$event_json" | jq -e '.policy_decision.decision == "allow"' >/dev/null ||
      fail "approved approval must carry allow policy decision"
    ;;
  expired:approval_expired)
    printf '%s\n' "$event_json" | jq -e '
      (.original_event_id | type == "string" and length > 0) and
      (.expired_by | type == "string" and length > 0) and
      (.expire_reason | type == "string" and length > 0)
    ' >/dev/null || fail "expired approval requires original_event_id expired_by expire_reason"
    ;;
  *)
    fail "approval event status and event_type do not match"
    ;;
  esac
}

atlas_approval_risk_valid() {
  case "$1" in
  low | medium | high | critical)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

atlas_approval_evidence_json() {
  local ref

  for ref in "$@"; do
    printf '%s\n' "$ref"
  done | jq -R . | jq -s .
}

cmd_approval_request() {
  need_args 1 "$#" "approval request <capability> --scope scope --risk risk --requester actor --approver actor --expiry timestamp --rationale text --rollback-plan text --evidence-ref ref [--json]"
  local capability="$1"
  local scope=""
  local risk=""
  local requester="${ATLAS_OPERATOR:-${USER:-unknown}}"
  local approver=""
  local expiry=""
  local rationale=""
  local rollback_plan=""
  local json=0
  local evidence_refs=()
  local decision_json
  local decision
  local class
  local workflow
  local evidence_json
  local event_json
  local event_id
  local ts
  local policy_decision_json

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --scope)
      [ "$#" -ge 2 ] || fail "--scope requires a value"
      scope="$2"
      shift 2
      ;;
    --risk)
      [ "$#" -ge 2 ] || fail "--risk requires a value"
      risk="$2"
      shift 2
      ;;
    --requester)
      [ "$#" -ge 2 ] || fail "--requester requires a value"
      requester="$2"
      shift 2
      ;;
    --approver)
      [ "$#" -ge 2 ] || fail "--approver requires a value"
      approver="$2"
      shift 2
      ;;
    --expiry)
      [ "$#" -ge 2 ] || fail "--expiry requires a value"
      expiry="$2"
      shift 2
      ;;
    --rationale)
      [ "$#" -ge 2 ] || fail "--rationale requires a value"
      rationale="$2"
      shift 2
      ;;
    --rollback-plan)
      [ "$#" -ge 2 ] || fail "--rollback-plan requires a value"
      rollback_plan="$2"
      shift 2
      ;;
    --evidence-ref)
      [ "$#" -ge 2 ] || fail "--evidence-ref requires a value"
      evidence_refs+=("$2")
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    *)
      fail "unknown approval request option: $1"
      ;;
    esac
  done

  [ -n "$scope" ] || fail "--scope is required"
  [ -n "$risk" ] || fail "--risk is required"
  atlas_approval_risk_valid "$risk" || fail "unknown approval risk $risk"
  [ -n "$requester" ] || fail "--requester is required"
  [ -n "$approver" ] || fail "--approver is required"
  [ -n "$expiry" ] || fail "--expiry is required"
  [ -n "$rationale" ] || fail "--rationale is required"
  [ -n "$rollback_plan" ] || fail "--rollback-plan is required"
  [ "${#evidence_refs[@]}" -gt 0 ] || fail "--evidence-ref is required"

  decision_json="$(atlas_policy_decision_json "$capability" "$scope" "none" "$requester")"
  decision="$(printf '%s\n' "$decision_json" | jq -r '.decision')"
  case "$decision" in
  unsupported)
    fail "unsupported approval capability $capability"
    ;;
  not_in_scope)
    fail "approval capability out of scope $capability"
    ;;
  approval_required)
    ;;
  *)
    fail "approval not required for $capability"
    ;;
  esac

  class="$(printf '%s\n' "$decision_json" | jq -r '.class')"
  workflow="$(atlas_approval_workflow_id_for_class "$class")"
  [ -n "$workflow" ] || fail "missing approval workflow for $class"
  evidence_json="$(atlas_approval_evidence_json "${evidence_refs[@]}")"
  ts="$(timestamp)"
  event_id="approval:$(slugify "$capability"):$ts"
  policy_decision_json="$(printf '%s\n' "$decision_json" | jq -c '{decision, policy_ref, reason}')"

  event_json="$(
    jq -cn \
      --arg schema_version "atlas.approval_event.v1" \
      --arg event_id "$event_id" \
      --arg event_type "approval_requested" \
      --arg ts "$ts" \
      --arg requester "$requester" \
      --arg capability "$capability" \
      --arg class "$class" \
      --arg workflow "$workflow" \
      --arg risk "$risk" \
      --arg scope "$scope" \
      --arg approver "$approver" \
      --arg expiry "$expiry" \
      --arg rationale "$rationale" \
      --arg rollback_plan "$rollback_plan" \
      --arg status "requested" \
      --argjson evidence_refs "$evidence_json" \
      --argjson policy_decision "$policy_decision_json" \
      '{
        schema_version: $schema_version,
        event_id: $event_id,
        event_type: $event_type,
        timestamp: $ts,
        metadata_only: true,
        requester: $requester,
        capability: $capability,
        capability_class: $class,
        workflow: $workflow,
        risk: $risk,
        scope: {
          value: $scope
        },
        approver: $approver,
        expiry: $expiry,
        rationale: $rationale,
        rollback_plan: $rollback_plan,
        evidence_refs: $evidence_refs,
        status: $status,
        policy_decision: $policy_decision
      }'
  )"

  atlas_approval_validate_event_json "$event_json"

  if [ "$json" -eq 1 ]; then
    printf '%s\n' "$event_json"
    return 0
  fi

  ui_heading "Atlas Approval Request"
  ui_rule
  ui_kv "Event" "$event_id"
  ui_kv "Capability" "$capability"
  ui_kv "Workflow" "$workflow"
  ui_kv "Risk" "$risk"
  ui_kv "Status" "requested"
  ui_kv "Policy Decision" "$decision"
}

cmd_approval_verify() {
  need_args 1 "$#" "approval verify <event-file|-> [--json]"
  local input="$1"
  local json=0
  local event_json
  local event_id
  local status

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    *)
      fail "unknown approval verify option: $1"
      ;;
    esac
  done

  event_json="$(atlas_approval_read_event "$input")"
  atlas_approval_validate_event_json "$event_json"

  if [ "$json" -eq 1 ]; then
    event_id="$(printf '%s\n' "$event_json" | jq -r '.event_id')"
    status="$(printf '%s\n' "$event_json" | jq -r '.status')"
    jq -cn \
      --arg schema_version "atlas.approval_verify.v1" \
      --arg event_id "$event_id" \
      --arg status "$status" \
      '{schema_version: $schema_version, status: "ok", event_id: $event_id, approval_status: $status}'
    return 0
  fi

  printf 'approval: ok\n'
}

cmd_approval_expire() {
  need_args 1 "$#" "approval expire <event-file|-> --reason text [--actor actor] [--json]"
  local input="$1"
  local reason=""
  local actor="${ATLAS_OPERATOR:-${USER:-unknown}}"
  local json=0
  local event_json
  local status
  local capability
  local scope
  local decision_json
  local policy_decision_json
  local ts
  local event_id
  local expired_json

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --reason)
      [ "$#" -ge 2 ] || fail "--reason requires a value"
      reason="$2"
      shift 2
      ;;
    --actor)
      [ "$#" -ge 2 ] || fail "--actor requires a value"
      actor="$2"
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    *)
      fail "unknown approval expire option: $1"
      ;;
    esac
  done

  [ -n "$reason" ] || fail "--reason is required"
  [ -n "$actor" ] || fail "--actor is required"

  event_json="$(atlas_approval_read_event "$input")"
  atlas_approval_validate_event_json "$event_json"
  status="$(printf '%s\n' "$event_json" | jq -r '.status')"
  [ "$status" != "expired" ] || fail "approval already expired"

  capability="$(printf '%s\n' "$event_json" | jq -r '.capability')"
  scope="$(printf '%s\n' "$event_json" | jq -r '.scope.value')"
  decision_json="$(atlas_policy_decision_json "$capability" "$scope" "none" "$actor")"
  policy_decision_json="$(printf '%s\n' "$decision_json" | jq -c '{decision, policy_ref, reason}')"
  ts="$(timestamp)"
  event_id="approval-expired:$(slugify "$capability"):$ts"

  expired_json="$(
    printf '%s\n' "$event_json" | jq -c \
      --arg event_id "$event_id" \
      --arg event_type "approval_expired" \
      --arg ts "$ts" \
      --arg status "expired" \
      --arg expired_by "$actor" \
      --arg expire_reason "$reason" \
      --argjson policy_decision "$policy_decision_json" \
      '. + {
        event_id: $event_id,
        event_type: $event_type,
        timestamp: $ts,
        status: $status,
        original_event_id: .event_id,
        expired_by: $expired_by,
        expire_reason: $expire_reason,
        policy_decision: $policy_decision
      }'
  )"

  atlas_approval_validate_event_json "$expired_json"

  if [ "$json" -eq 1 ]; then
    printf '%s\n' "$expired_json"
    return 0
  fi

  ui_heading "Atlas Approval Expired"
  ui_rule
  ui_kv "Event" "$event_id"
  ui_kv "Capability" "$capability"
  ui_kv "Expired By" "$actor"
  ui_kv "Status" "expired"
}

atlas_approval_has_current() {
  local capability="$1"
  local target="$2"
  local file

  file="$(atlas_approval_file "$ATLAS_OP_DIR")"
  [ -s "$file" ] || return 1

  jq -e \
    --arg capability "$capability" \
    --arg target "$target" '
      select(
        .capability == $capability
        and .target == $target
        and .status == "approved"
      )
    ' "$file" >/dev/null
}

atlas_approval_append_current() {
  local capability="$1"
  local reason="$2"
  local file

  intel_require_jq

  file="$(atlas_approval_file "$ATLAS_OP_DIR")"
  : >>"$file"
  chmod 600 "$file" 2>/dev/null || true

  jq -cn \
    --arg ts "$(timestamp)" \
    --arg op "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg capability "$capability" \
    --arg tier "$(atlas_scope_capability_tier "$capability")" \
    --arg approved_by "$(atlas_approval_operator)" \
    --arg reason "$reason" \
    '{
      ts: $ts,
      op: $op,
      target: $target,
      capability: $capability,
      tier: $tier,
      approved_by: $approved_by,
      reason: $reason,
      status: "approved"
    }' >>"$file"
}

cmd_approval_grant() {
  need_args 2 "$#" "approval grant <capability> <reason...>"
  local capability="$1"
  local reason

  shift
  reason="$*"
  [ -n "$reason" ] || fail "approval reason is required"

  load_active_operation
  atlas_scope_load_snapshot
  if ! atlas_scope_target_matches "$ATLAS_OP_TARGET"; then
    fail "approval refused: active target is outside active operation scope"
  fi
  if ! atlas_scope_word_contains "$ATLAS_SCOPE_ALLOWED" "$capability"; then
    fail "approval refused: capability '$capability' is not allowed for this operation"
  fi
  if atlas_scope_word_contains "$ATLAS_SCOPE_BLOCKED" "$capability"; then
    fail "approval refused: capability '$capability' is blocked"
  fi

  atlas_approval_append_current "$capability" "$reason"
  atlas_ledger_append_current "approval.granted" "$capability" "atlas" "approved" "$reason"

  ui_ok "approval recorded"
  printf 'capability: %s\n' "$capability"
  printf 'tier: %s\n' "$(atlas_scope_capability_tier "$capability")"
  printf 'target: %s\n' "$ATLAS_OP_TARGET"
  printf 'approved_by: %s\n' "$(atlas_approval_operator)"
}

cmd_approval_list() {
  local file

  load_active_operation
  file="$(atlas_approval_file "$ATLAS_OP_DIR")"

  ui_heading "Approvals"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Store" "$file"
  ui_rule

  if [ ! -s "$file" ]; then
    ui_note "no approvals recorded yet"
    return 0
  fi

  jq -r '
    [
      (.ts // "?"),
      (.capability // "?"),
      (.tier // "?"),
      (.status // "?"),
      (.approved_by // "?"),
      (.reason // "")
    ]
    | @tsv
  ' "$file" |
    awk -F'\t' '{ printf "%-20s %-18s %-4s %-10s %-12s %s\n", $1, $2, $3, $4, $5, $6 }'
}
