#!/usr/bin/env bash

ATLAS_DEFAULT_ALLOWED_CAPABILITIES="${ATLAS_DEFAULT_ALLOWED_CAPABILITIES:-read-only passive-recon active-recon safe-validation}"
ATLAS_DEFAULT_BLOCKED_CAPABILITIES="${ATLAS_DEFAULT_BLOCKED_CAPABILITIES:-destructive persistence credential-spraying denial-of-service out-of-scope-network}"

atlas_scope_snapshot_file() {
  local op_dir="$1"

  printf '%s/scope.snapshot.env\n' "$op_dir"
}

atlas_scope_write_snapshot() {
  local op_dir="$1"
  local target="$2"
  local address="$3"
  local label="$4"
  local file

  file="$(atlas_scope_snapshot_file "$op_dir")"
  : >"$file"
  chmod 600 "$file" 2>/dev/null || true

  upsert_env "$file" SCOPE_TARGET "$target"
  upsert_env "$file" SCOPE_TARGET_ADDRESS "$address"
  upsert_env "$file" SCOPE_TARGET_LABEL "$label"
  upsert_env "$file" ALLOWED_CAPABILITIES "$ATLAS_DEFAULT_ALLOWED_CAPABILITIES"
  upsert_env "$file" BLOCKED_CAPABILITIES "$ATLAS_DEFAULT_BLOCKED_CAPABILITIES"
  upsert_env "$file" SNAPSHOT_AT "$(timestamp)"
}

atlas_scope_word_contains() {
  local list="$1"
  local wanted="$2"
  local item

  for item in $list; do
    [ "$item" = "$wanted" ] && return 0
  done
  return 1
}

atlas_scope_capability_tier() {
  case "$1" in
  read-only) printf '0' ;;
  passive-recon) printf '1' ;;
  active-recon) printf '2' ;;
  safe-validation) printf '3' ;;
  intrusive-validation) printf '4' ;;
  destructive) printf '5' ;;
  *) printf '?' ;;
  esac
}

atlas_scope_load_snapshot() {
  local file
  local SCOPE_TARGET=""
  local SCOPE_TARGET_ADDRESS=""
  local SCOPE_TARGET_LABEL=""
  local ALLOWED_CAPABILITIES=""
  local BLOCKED_CAPABILITIES=""

  file="$(atlas_scope_snapshot_file "$ATLAS_OP_DIR")"
  if [ -f "$file" ]; then
    # shellcheck disable=SC1090
    . "$file"
  fi

  ATLAS_SCOPE_TARGET="${SCOPE_TARGET:-$ATLAS_OP_TARGET}"
  ATLAS_SCOPE_TARGET_ADDRESS="${SCOPE_TARGET_ADDRESS:-$ATLAS_OP_TARGET_ADDRESS}"
  ATLAS_SCOPE_TARGET_LABEL="${SCOPE_TARGET_LABEL:-$ATLAS_OP_TARGET_LABEL}"
  ATLAS_SCOPE_ALLOWED="${ALLOWED_CAPABILITIES:-$ATLAS_DEFAULT_ALLOWED_CAPABILITIES}"
  ATLAS_SCOPE_BLOCKED="${BLOCKED_CAPABILITIES:-$ATLAS_DEFAULT_BLOCKED_CAPABILITIES}"
}

atlas_scope_target_matches() {
  local target="$1"

  [ "$target" = "$ATLAS_SCOPE_TARGET" ] && return 0
  [ -n "$ATLAS_SCOPE_TARGET_ADDRESS" ] && [ "$target" = "$ATLAS_SCOPE_TARGET_ADDRESS" ] && return 0
  [ -n "$ATLAS_SCOPE_TARGET_LABEL" ] && [ "$target" = "$ATLAS_SCOPE_TARGET_LABEL" ] && return 0
  return 1
}

atlas_scope_preflight() {
  local capability="$1"
  local tool="$2"
  local target="$3"
  local reason="$4"
  local detail

  atlas_scope_load_snapshot
  detail="reason=$reason"

  if ! atlas_scope_target_matches "$target"; then
    atlas_ledger_append_current "scope.preflight" "$capability" "$tool" "denied" "$detail target=$target"
    fail "scope refused: target '$target' is outside active operation scope '$ATLAS_SCOPE_TARGET'"
  fi

  if atlas_scope_word_contains "$ATLAS_SCOPE_BLOCKED" "$capability"; then
    atlas_ledger_append_current "scope.preflight" "$capability" "$tool" "denied" "$detail blocked-capability=$capability"
    fail "scope refused: capability '$capability' is blocked"
  fi

  if ! atlas_scope_word_contains "$ATLAS_SCOPE_ALLOWED" "$capability"; then
    atlas_ledger_append_current "scope.preflight" "$capability" "$tool" "denied" "$detail unsupported-capability=$capability"
    fail "scope refused: capability '$capability' is not allowed for this operation"
  fi

  if atlas_approval_requires_gate "$capability" && ! atlas_approval_has_current "$capability" "$ATLAS_SCOPE_TARGET"; then
    atlas_ledger_append_current "scope.preflight" "$capability" "$tool" "denied" "$detail approval-required=$capability"
    fail "approval required: capability '$capability' needs 'atlas approval grant $capability <reason...>'"
  fi

  atlas_ledger_append_current "scope.preflight" "$capability" "$tool" "allowed" "$detail target=$target"
}

cmd_scope_status() {
  load_active_operation
  atlas_scope_load_snapshot

  ui_heading "ScopeGuard"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Target" "$ATLAS_SCOPE_TARGET"
  if [ -n "$ATLAS_SCOPE_TARGET_ADDRESS" ] && [ "$ATLAS_SCOPE_TARGET_ADDRESS" != "$ATLAS_SCOPE_TARGET" ]; then
    ui_kv "Address" "$ATLAS_SCOPE_TARGET_ADDRESS"
  fi
  ui_kv "Allowed" "$ATLAS_SCOPE_ALLOWED"
  ui_kv "Blocked" "$ATLAS_SCOPE_BLOCKED"
  ui_kv "Snapshot" "$(atlas_scope_snapshot_file "$ATLAS_OP_DIR")"
}

cmd_scope_check() {
  need_args 2 "$#" "scope check <capability> <target>"
  local capability="$1"
  local target="$2"

  load_active_operation
  atlas_scope_preflight "$capability" "atlas" "$target" "manual scope check"
  ui_ok "scope allowed"
  printf 'capability: %s\n' "$capability"
  printf 'tier: %s\n' "$(atlas_scope_capability_tier "$capability")"
  printf 'target: %s\n' "$target"
}
