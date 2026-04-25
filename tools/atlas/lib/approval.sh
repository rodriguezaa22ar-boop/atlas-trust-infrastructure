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
