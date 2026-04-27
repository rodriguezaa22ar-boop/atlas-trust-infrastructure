#!/usr/bin/env bash

ATLAS_DEFAULT_ALLOWED_CAPABILITIES="${ATLAS_DEFAULT_ALLOWED_CAPABILITIES:-read-only passive-recon active-recon safe-validation}"
ATLAS_DEFAULT_BLOCKED_CAPABILITIES="${ATLAS_DEFAULT_BLOCKED_CAPABILITIES:-destructive persistence credential-spraying denial-of-service out-of-scope-network}"
ATLAS_SCOPE_PROFILES_DIR="${ATLAS_SCOPE_PROFILES_DIR:-$TOOL_DIR/profiles}"

atlas_scope_default_text() {
  cat <<'EOF'
Bounded authorized reconnaissance and defensive posture review for the named target.
EOF
}

atlas_scope_default_allowed_actions() {
  cat <<'EOF'
target-first recon against configured scope
service validation and non-invasive fingerprint refresh
HTTP/HTTPS probing of observed web surfaces
HTTP posture review for headers, redirects, metadata routes, and common login/admin routes
bounded API status and CORS preflight posture checks
shared-intel summarization, story views, and report generation
EOF
}

atlas_scope_default_out_of_scope() {
  cat <<'EOF'
exploitation, payload delivery, or persistence
brute forcing, password guessing, credential stuffing, or session hijacking
destructive testing, denial of service, fuzzing, or high-volume crawling
access to third-party systems beyond the configured target
data extraction beyond minimal service, route, header, API status, CORS header, and posture evidence
EOF
}

atlas_scope_profile_file() {
  local profile="$1"
  local slug

  slug="$(slugify "$profile")"
  [ -n "$slug" ] || fail "profile name produced an empty slug"
  printf '%s/%s.env\n' "$ATLAS_SCOPE_PROFILES_DIR" "$slug"
}

atlas_scope_load_profile() {
  local profile="${1:-default}"
  local file
  local PROFILE_NAME=""
  local PROFILE_SUMMARY=""
  local SCOPE_TEXT=""
  local ALLOWED_CAPABILITIES=""
  local BLOCKED_CAPABILITIES=""
  local ALLOWED_ACTIONS=""
  local OUT_OF_SCOPE_ACTIONS=""
  local RECOMMENDED_WORKFLOWS=""
  local VALIDATION_LANES=""

  if [ "$profile" != "default" ]; then
    file="$(atlas_scope_profile_file "$profile")"
    [ -f "$file" ] || fail "unknown Atlas profile: $profile"
    # shellcheck disable=SC1090
    . "$file"
  fi

  ATLAS_PROFILE_NAME="${PROFILE_NAME:-$profile}"
  ATLAS_PROFILE_SUMMARY="${PROFILE_SUMMARY:-default bounded Atlas operation profile}"
  ATLAS_PROFILE_SCOPE_TEXT="${SCOPE_TEXT:-$(atlas_scope_default_text)}"
  ATLAS_PROFILE_ALLOWED_CAPABILITIES="${ALLOWED_CAPABILITIES:-$ATLAS_DEFAULT_ALLOWED_CAPABILITIES}"
  ATLAS_PROFILE_BLOCKED_CAPABILITIES="${BLOCKED_CAPABILITIES:-$ATLAS_DEFAULT_BLOCKED_CAPABILITIES}"
  ATLAS_PROFILE_ALLOWED_ACTIONS="$ALLOWED_ACTIONS"
  ATLAS_PROFILE_OUT_OF_SCOPE_ACTIONS="$OUT_OF_SCOPE_ACTIONS"
  ATLAS_PROFILE_RECOMMENDED_WORKFLOWS="$RECOMMENDED_WORKFLOWS"
  ATLAS_PROFILE_VALIDATION_LANES="$VALIDATION_LANES"
}

atlas_scope_print_pipe_lines() {
  local value="$1"
  local item

  [ -n "$value" ] || return 1
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    printf '%s\n' "$item"
  done < <(printf '%s\n' "$value" | tr '|' '\n')
}

atlas_scope_profile_files() {
  local file

  for file in "$ATLAS_SCOPE_PROFILES_DIR"/*.env; do
    [ -e "$file" ] || return 0
    printf '%s\n' "$file"
  done
}

cmd_profile_list() {
  local file
  local PROFILE_NAME=""
  local PROFILE_SUMMARY=""
  local count=0

  printf '%-24s %s\n' "PROFILE" "SUMMARY"
  printf '%-24s %s\n' "default" "default bounded Atlas operation profile"
  count=$((count + 1))

  while IFS= read -r file; do
    PROFILE_NAME=""
    PROFILE_SUMMARY=""
    # shellcheck disable=SC1090
    . "$file"
    printf '%-24s %s\n' "${PROFILE_NAME:-$(basename "$file" .env)}" "${PROFILE_SUMMARY:-}"
    count=$((count + 1))
  done < <(atlas_scope_profile_files)

  if [ "$count" -eq 0 ]; then
    ui_note "no Atlas profiles found in $ATLAS_SCOPE_PROFILES_DIR"
  fi
}

cmd_profile_show() {
  need_args 1 "$#" "profile show <name>"
  local profile="$1"

  atlas_scope_load_profile "$profile"

  ui_heading "Atlas Profile"
  ui_rule
  ui_kv "Profile" "$ATLAS_PROFILE_NAME"
  ui_kv "Summary" "$ATLAS_PROFILE_SUMMARY"
  ui_kv "Allowed" "$ATLAS_PROFILE_ALLOWED_CAPABILITIES"
  ui_kv "Blocked" "$ATLAS_PROFILE_BLOCKED_CAPABILITIES"
  ui_rule
  ui_subheading "Scope"
  printf '%s\n' "$ATLAS_PROFILE_SCOPE_TEXT"
  ui_rule
  ui_subheading "Allowed Actions"
  if ! atlas_scope_print_pipe_lines "$ATLAS_PROFILE_ALLOWED_ACTIONS"; then
    atlas_scope_default_allowed_actions
  fi
  ui_rule
  ui_subheading "Explicitly Out Of Scope"
  if ! atlas_scope_print_pipe_lines "$ATLAS_PROFILE_OUT_OF_SCOPE_ACTIONS"; then
    atlas_scope_default_out_of_scope
  fi
  ui_rule
  ui_subheading "Recommended Workflow"
  if ! atlas_scope_print_pipe_lines "$ATLAS_PROFILE_RECOMMENDED_WORKFLOWS"; then
    ui_note "no profile-specific workflow configured"
  fi
}

atlas_scope_snapshot_file() {
  local op_dir="$1"

  printf '%s/scope.snapshot.env\n' "$op_dir"
}

atlas_scope_write_snapshot() {
  local op_dir="$1"
  local target="$2"
  local address="$3"
  local label="$4"
  local profile="${5:-default}"
  local target_scope_status="${6:-unknown}"
  local target_criticality="${7:-unknown}"
  local target_tags="${8:-}"
  local target_owner="${9:-}"
  local file

  atlas_scope_load_profile "$profile"

  file="$(atlas_scope_snapshot_file "$op_dir")"
  : >"$file"
  chmod 600 "$file" 2>/dev/null || true

  upsert_env "$file" SCOPE_PROFILE "$ATLAS_PROFILE_NAME"
  upsert_env "$file" SCOPE_PROFILE_SUMMARY "$ATLAS_PROFILE_SUMMARY"
  upsert_env "$file" SCOPE_TARGET "$target"
  upsert_env "$file" SCOPE_TARGET_ADDRESS "$address"
  upsert_env "$file" SCOPE_TARGET_LABEL "$label"
  upsert_env "$file" TARGET_SCOPE_STATUS "$target_scope_status"
  upsert_env "$file" TARGET_CRITICALITY "$target_criticality"
  upsert_env "$file" TARGET_TAGS "$target_tags"
  upsert_env "$file" TARGET_OWNER "$target_owner"
  upsert_env "$file" SCOPE_TEXT "$ATLAS_PROFILE_SCOPE_TEXT"
  upsert_env "$file" ALLOWED_CAPABILITIES "$ATLAS_PROFILE_ALLOWED_CAPABILITIES"
  upsert_env "$file" BLOCKED_CAPABILITIES "$ATLAS_PROFILE_BLOCKED_CAPABILITIES"
  upsert_env "$file" ALLOWED_ACTIONS "$ATLAS_PROFILE_ALLOWED_ACTIONS"
  upsert_env "$file" OUT_OF_SCOPE_ACTIONS "$ATLAS_PROFILE_OUT_OF_SCOPE_ACTIONS"
  upsert_env "$file" RECOMMENDED_WORKFLOWS "$ATLAS_PROFILE_RECOMMENDED_WORKFLOWS"
  upsert_env "$file" VALIDATION_LANES "$ATLAS_PROFILE_VALIDATION_LANES"
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
  local SCOPE_PROFILE=""
  local SCOPE_PROFILE_SUMMARY=""
  local SCOPE_TARGET=""
  local SCOPE_TARGET_ADDRESS=""
  local SCOPE_TARGET_LABEL=""
  local TARGET_SCOPE_STATUS=""
  local TARGET_CRITICALITY=""
  local TARGET_TAGS=""
  local TARGET_OWNER=""
  local SCOPE_TEXT=""
  local ALLOWED_CAPABILITIES=""
  local BLOCKED_CAPABILITIES=""
  local ALLOWED_ACTIONS=""
  local OUT_OF_SCOPE_ACTIONS=""
  local RECOMMENDED_WORKFLOWS=""
  local VALIDATION_LANES=""

  file="$(atlas_scope_snapshot_file "$ATLAS_OP_DIR")"
  if [ -f "$file" ]; then
    # shellcheck disable=SC1090
    . "$file"
  fi

  ATLAS_SCOPE_PROFILE="${SCOPE_PROFILE:-default}"
  # shellcheck disable=SC2034
  ATLAS_SCOPE_PROFILE_SUMMARY="${SCOPE_PROFILE_SUMMARY:-default bounded Atlas operation profile}"
  ATLAS_SCOPE_TARGET="${SCOPE_TARGET:-$ATLAS_OP_TARGET}"
  ATLAS_SCOPE_TARGET_ADDRESS="${SCOPE_TARGET_ADDRESS:-$ATLAS_OP_TARGET_ADDRESS}"
  ATLAS_SCOPE_TARGET_LABEL="${SCOPE_TARGET_LABEL:-$ATLAS_OP_TARGET_LABEL}"
  ATLAS_SCOPE_TARGET_SCOPE_STATUS="${TARGET_SCOPE_STATUS:-${ATLAS_OP_TARGET_SCOPE_STATUS:-unknown}}"
  ATLAS_SCOPE_TARGET_CRITICALITY="${TARGET_CRITICALITY:-${ATLAS_OP_TARGET_CRITICALITY:-unknown}}"
  ATLAS_SCOPE_TARGET_TAGS="${TARGET_TAGS:-${ATLAS_OP_TARGET_TAGS:-}}"
  ATLAS_SCOPE_TARGET_OWNER="${TARGET_OWNER:-${ATLAS_OP_TARGET_OWNER:-}}"
  # shellcheck disable=SC2034
  ATLAS_SCOPE_TEXT="${SCOPE_TEXT:-$(atlas_scope_default_text)}"
  ATLAS_SCOPE_ALLOWED="${ALLOWED_CAPABILITIES:-$ATLAS_DEFAULT_ALLOWED_CAPABILITIES}"
  ATLAS_SCOPE_BLOCKED="${BLOCKED_CAPABILITIES:-$ATLAS_DEFAULT_BLOCKED_CAPABILITIES}"
  # shellcheck disable=SC2034
  ATLAS_SCOPE_ALLOWED_ACTIONS="$ALLOWED_ACTIONS"
  # shellcheck disable=SC2034
  ATLAS_SCOPE_OUT_OF_SCOPE_ACTIONS="$OUT_OF_SCOPE_ACTIONS"
  ATLAS_SCOPE_RECOMMENDED_WORKFLOWS="$RECOMMENDED_WORKFLOWS"
  # shellcheck disable=SC2034
  ATLAS_SCOPE_VALIDATION_LANES="$VALIDATION_LANES"
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
  ui_kv "Profile" "$ATLAS_SCOPE_PROFILE"
  ui_kv "Target" "$ATLAS_SCOPE_TARGET"
  if [ -n "$ATLAS_SCOPE_TARGET_ADDRESS" ] && [ "$ATLAS_SCOPE_TARGET_ADDRESS" != "$ATLAS_SCOPE_TARGET" ]; then
    ui_kv "Address" "$ATLAS_SCOPE_TARGET_ADDRESS"
  fi
  ui_kv "Target Scope" "${ATLAS_SCOPE_TARGET_SCOPE_STATUS:-unknown}"
  ui_kv "Target Criticality" "${ATLAS_SCOPE_TARGET_CRITICALITY:-unknown}"
  if [ -n "${ATLAS_SCOPE_TARGET_OWNER:-}" ]; then
    ui_kv "Target Owner" "$ATLAS_SCOPE_TARGET_OWNER"
  fi
  if [ -n "${ATLAS_SCOPE_TARGET_TAGS:-}" ]; then
    ui_kv "Target Tags" "$ATLAS_SCOPE_TARGET_TAGS"
  fi
  ui_kv "Allowed" "$ATLAS_SCOPE_ALLOWED"
  ui_kv "Blocked" "$ATLAS_SCOPE_BLOCKED"
  ui_kv "Recommended" "${ATLAS_SCOPE_RECOMMENDED_WORKFLOWS:-none}"
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
