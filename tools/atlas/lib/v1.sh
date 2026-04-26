#!/usr/bin/env bash

atlas_v1_failures=0

atlas_v1_row() {
  local label="$1"
  local status="$2"
  local detail="$3"

  printf '%-24s %-10s %s\n' "$label" "$status" "$detail"
}

atlas_v1_ready() {
  atlas_v1_row "$1" "ready" "$2"
}

atlas_v1_missing() {
  atlas_v1_failures=$((atlas_v1_failures + 1))
  atlas_v1_row "$1" "missing" "$2"
}

atlas_v1_check_dir() {
  local label="$1"
  local dir="$2"
  local detail="$3"

  if [ -d "$dir" ] && [ -w "$dir" ]; then
    atlas_v1_ready "$label" "$detail"
  elif [ -d "$dir" ]; then
    atlas_v1_missing "$label" "not writable: $dir"
  else
    atlas_v1_missing "$label" "missing: $dir"
  fi
}

atlas_v1_check_executable() {
  local label="$1"
  local path="$2"
  local detail="$3"

  if [ -x "$path" ]; then
    atlas_v1_ready "$label" "$detail"
  else
    atlas_v1_missing "$label" "missing executable: $path"
  fi
}

atlas_v1_check_command() {
  local label="$1"
  local command_name="$2"
  local detail="$3"
  local resolved

  resolved="$(command -v "$command_name" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    atlas_v1_ready "$label" "$detail"
  else
    atlas_v1_missing "$label" "command not found: $command_name"
  fi
}

atlas_v1_count_targets() {
  [ -d "$LAB_TARGETS_DIR" ] || {
    printf '0\n'
    return 0
  }
  find "$LAB_TARGETS_DIR" -maxdepth 1 -type f -name '*.env' 2>/dev/null | wc -l | tr -d ' '
}

atlas_v1_count_operations() {
  [ -d "$LAB_SESSIONS_DIR" ] || {
    printf '0\n'
    return 0
  }
  find "$LAB_SESSIONS_DIR" -mindepth 2 -maxdepth 2 -type f -name 'session.env' 2>/dev/null | wc -l | tr -d ' '
}

cmd_v1_status() {
  local active_slug="none"

  [ "$#" -eq 0 ] || fail "v1 status"

  atlas_v1_failures=0

  if has_active_operation; then
    active_slug="$(active_operation_slug)"
  fi

  ui_heading "Atlas V1 Status"
  ui_rule
  ui_kv "Root" "$LAB_ROOT"
  ui_kv "Runtime Target" "$LAB_RUNTIME_TARGET"
  ui_kv "Active Operation" "$active_slug"
  ui_kv "Target Records" "$(atlas_v1_count_targets)"
  ui_kv "Operations" "$(atlas_v1_count_operations)"
  ui_rule

  ui_subheading "V1 Pillars"
  atlas_v1_check_executable "Core CLI" "$TOOL_DIR/bin/atlas" "shell-native atlas entrypoint"
  atlas_v1_check_dir "Target Registry" "$LAB_TARGETS_DIR" "target env records with scope metadata"
  atlas_v1_check_dir "Operation Ledger" "$LAB_SESSIONS_DIR" "operation directories with append-only ledgers"
  atlas_v1_check_dir "ScopeGuard" "$ATLAS_STATE_DIR" "profiles, approvals, and preflight state"
  atlas_v1_check_executable "Recon Orchestrator" "$WIREMAP_BIN" "operation-aware wiremap workflows"
  atlas_v1_check_executable "Action Planner" "$VECTOR_BIN" "ranked vector lanes and outcomes"
  atlas_v1_check_executable "Intel Graph" "$INTELCTL_BIN" "entity, relationship, graph, and path views"
  atlas_v1_check_command "Evidence Vault" "sha256sum" "artifact hashes, redaction metadata, and bundles"
  atlas_v1_check_dir "Findings" "$LAB_SESSIONS_DIR" "observed, inferred, validated, and lifecycle records"
  atlas_v1_check_dir "Validation" "$LAB_SESSIONS_DIR" "approval-gated runs and retest loops"
  atlas_v1_check_dir "Reports" "$LAB_REPORTS_DIR" "operation reports and summaries"
  atlas_v1_check_dir "Retention" "$LAB_SESSIONS_DIR" "handoff, closeout, audit, and archive packets"
  atlas_v1_check_dir "AI Advisor" "$LAB_SESSIONS_DIR" "metadata-only advisor briefs and prompt packets"
  ui_rule

  if [ "$atlas_v1_failures" -gt 0 ]; then
    ui_kv "Overall" "attention required"
    ui_kv "Missing Pillars" "$atlas_v1_failures"
    return 1
  fi

  ui_kv "Overall" "ready"
}
