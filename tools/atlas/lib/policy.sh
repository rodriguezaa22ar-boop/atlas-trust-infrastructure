#!/usr/bin/env bash

atlas_policy_file() {
  printf '%s/policy/atlas.authz.rego\n' "$LAB_ROOT"
}

atlas_policy_cases_file() {
  printf '%s/policy/tests/decisions.v1.json\n' "$LAB_ROOT"
}

atlas_policy_require_jq() {
  command -v jq >/dev/null 2>&1 || fail "policy evaluation requires jq"
}

atlas_policy_capability_json() {
  local capability="$1"
  local manifest="$LAB_ROOT/capabilities.yaml"

  [ -f "$manifest" ] || fail "missing capabilities.yaml"

  jq -c --arg id "$capability" '
    .capabilities[]
    | select(.id == $id)
  ' "$manifest" | head -n 1
}

atlas_policy_reason() {
  local decision="$1"
  local capability="$2"
  local class="$3"

  case "$decision" in
  allow)
    case "$class" in
    bounded_exec | mutate | admin)
      printf 'approved %s capability is allowed by policy\n' "$class"
      ;;
    export)
      printf 'export capability is constrained to public trust checks\n'
      ;;
    *)
      printf '%s capability is allowed by policy\n' "$class"
      ;;
    esac
    ;;
  deny)
    printf 'capability %s is denied by policy constraints\n' "$capability"
    ;;
  approval_required)
    printf '%s capability requires approval before policy allows it\n' "$class"
    ;;
  not_in_scope)
    printf 'capability %s is outside the requested scope\n' "$capability"
    ;;
  unsupported)
    printf 'capability %s is not registered in capabilities.yaml\n' "$capability"
    ;;
  *)
    printf 'policy returned %s\n' "$decision"
    ;;
  esac
}

atlas_policy_decision_json() {
  local capability="$1"
  local scope="${2:-in_scope}"
  local approval="${3:-none}"
  local actor="${4:-${ATLAS_OPERATOR:-${USER:-unknown}}}"
  local resource="${5:-}"
  local policy_engine="shell-jq"
  local policy_evaluator_ref="tools/atlas/lib/policy.sh"
  local policy_contract_ref="policy/atlas.authz.rego"
  local policy_ref="$policy_evaluator_ref"
  local capability_json
  local class="unknown"
  local decision="unsupported"
  local reason
  local evidence_json="[]"
  local approval_required="false"

  atlas_policy_require_jq

  capability_json="$(atlas_policy_capability_json "$capability")"
  if [ -n "$capability_json" ]; then
    class="$(printf '%s\n' "$capability_json" | jq -r '.class // "unknown"')"
    evidence_json="$(printf '%s\n' "$capability_json" | jq -c '.evidence.emits // []')"

    if [ "$scope" = "out_of_scope" ]; then
      decision="not_in_scope"
    else
      case "$class" in
      read | import | verify)
        decision="allow"
        ;;
      export)
        if [ "$capability" = "atlas.public_export.check" ] || [ "$scope" = "public_trust" ]; then
          decision="allow"
        else
          decision="deny"
        fi
        ;;
      bounded_exec | mutate | admin)
        if [ "$approval" = "approved" ]; then
          decision="allow"
        else
          decision="approval_required"
          approval_required="true"
        fi
        ;;
      *)
        decision="unsupported"
        ;;
      esac
    fi
  fi

  reason="$(atlas_policy_reason "$decision" "$capability" "$class")"

  jq -cn \
    --arg schema_version "atlas.policy_decision.v1" \
    --arg capability "$capability" \
    --arg class "$class" \
    --arg decision "$decision" \
    --arg actor "$actor" \
    --arg scope "$scope" \
    --arg approval "$approval" \
    --arg resource "$resource" \
    --arg policy_engine "$policy_engine" \
    --arg policy_evaluator_ref "$policy_evaluator_ref" \
    --arg policy_contract_ref "$policy_contract_ref" \
    --arg policy_ref "$policy_ref" \
    --arg reason "$reason" \
    --argjson approval_required "$approval_required" \
    --argjson evidence_emits "$evidence_json" \
    '{
      schema_version: $schema_version,
      capability: $capability,
      class: $class,
      decision: $decision,
      approval_required: $approval_required,
      actor: $actor,
      scope: $scope,
      approval: $approval,
      resource: $resource,
      policy_engine: $policy_engine,
      policy_evaluator_ref: $policy_evaluator_ref,
      policy_contract_ref: $policy_contract_ref,
      policy_ref: $policy_ref,
      reason: $reason,
      evidence: {
        emits: $evidence_emits
      }
    }'
}

cmd_policy_evaluate() {
  need_args 1 "$#" "policy evaluate <capability> [--json] [--scope scope] [--approval status] [--approval-event event-file]"
  local capability="$1"
  local json=0
  local scope="in_scope"
  local approval="none"
  local approval_event=""
  local approval_event_json
  local approval_event_capability
  local approval_event_scope
  local approval_event_status
  local actor="${ATLAS_OPERATOR:-${USER:-unknown}}"
  local resource=""
  local decision_json

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    --scope)
      [ "$#" -ge 2 ] || fail "--scope requires a value"
      scope="$2"
      shift 2
      ;;
    --approval)
      [ "$#" -ge 2 ] || fail "--approval requires a value"
      approval="$2"
      shift 2
      ;;
    --approval-event)
      [ "$#" -ge 2 ] || fail "--approval-event requires a value"
      approval_event="$2"
      shift 2
      ;;
    --actor)
      [ "$#" -ge 2 ] || fail "--actor requires a value"
      actor="$2"
      shift 2
      ;;
    --resource)
      [ "$#" -ge 2 ] || fail "--resource requires a value"
      resource="$2"
      shift 2
      ;;
    *)
      fail "unknown policy evaluate option: $1"
      ;;
    esac
  done

  if [ -n "$approval_event" ]; then
    approval_event_json="$(atlas_approval_read_event "$approval_event")"
    atlas_approval_validate_event_json "$approval_event_json"
    approval_event_capability="$(printf '%s\n' "$approval_event_json" | jq -r '.capability')"
    approval_event_scope="$(printf '%s\n' "$approval_event_json" | jq -r '.scope.value')"
    approval_event_status="$(printf '%s\n' "$approval_event_json" | jq -r '.status')"
    [ "$approval_event_capability" = "$capability" ] ||
      fail "approval event capability mismatch: expected $capability got $approval_event_capability"
    [ "$approval_event_scope" = "$scope" ] ||
      fail "approval event scope mismatch: expected $scope got $approval_event_scope"
    [ "$approval_event_status" = "approved" ] ||
      fail "approval event must be approved"
    approval="approved"
  elif [ "$approval" = "approved" ]; then
    fail "approved policy evaluation requires --approval-event"
  fi

  decision_json="$(atlas_policy_decision_json "$capability" "$scope" "$approval" "$actor" "$resource")"

  if [ "$json" -eq 1 ]; then
    printf '%s\n' "$decision_json"
    return 0
  fi

  ui_heading "Atlas Policy Decision"
  ui_rule
  ui_kv "Capability" "$capability"
  ui_kv "Class" "$(printf '%s\n' "$decision_json" | jq -r '.class')"
  ui_kv "Decision" "$(printf '%s\n' "$decision_json" | jq -r '.decision')"
  ui_kv "Approval Required" "$(printf '%s\n' "$decision_json" | jq -r '.approval_required')"
  ui_kv "Policy" "$(printf '%s\n' "$decision_json" | jq -r '.policy_ref')"
  ui_kv "Reason" "$(printf '%s\n' "$decision_json" | jq -r '.reason')"
}

cmd_policy_test() {
  local cases="${1:-$(atlas_policy_cases_file)}"
  local name
  local capability
  local scope
  local approval
  local expected
  local actual
  local decision_json

  atlas_policy_require_jq
  [ -f "$(atlas_policy_file)" ] || fail "missing policy/atlas.authz.rego"
  [ -f "$cases" ] || fail "missing policy test cases: $cases"

  while IFS=$'\t' read -r name capability scope approval expected; do
    decision_json="$(atlas_policy_decision_json "$capability" "$scope" "$approval")"
    actual="$(printf '%s\n' "$decision_json" | jq -r '.decision')"
    if [ "$actual" != "$expected" ]; then
      fail "policy case '$name' expected $expected got $actual"
    fi
  done < <(
    jq -r '
      .cases[]
      | [
          .name,
          .capability,
          (.scope // "in_scope"),
          (.approval // "none"),
          .expect
        ]
      | @tsv
    ' "$cases"
  )

  printf 'policy: ok\n'
}
