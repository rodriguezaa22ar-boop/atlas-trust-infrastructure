#!/usr/bin/env bash

atlas_doctor_failures=0
atlas_doctor_warnings=0

atlas_doctor_row() {
  local label="$1"
  local status="$2"
  local detail="$3"

  printf '%-24s %-8s %s\n' "$label" "$status" "$detail"
}

atlas_doctor_ok() {
  atlas_doctor_row "$1" "ok" "$2"
}

atlas_doctor_warn() {
  atlas_doctor_warnings=$((atlas_doctor_warnings + 1))
  atlas_doctor_row "$1" "warn" "$2"
}

atlas_doctor_fail() {
  atlas_doctor_failures=$((atlas_doctor_failures + 1))
  atlas_doctor_row "$1" "fail" "$2"
}

atlas_doctor_check_dir() {
  local label="$1"
  local dir="$2"

  if [ -d "$dir" ] && [ -w "$dir" ]; then
    atlas_doctor_ok "$label" "$dir"
  elif [ -d "$dir" ]; then
    atlas_doctor_fail "$label" "not writable: $dir"
  else
    atlas_doctor_fail "$label" "missing: $dir"
  fi
}

atlas_doctor_check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ] && [ -w "$file" ]; then
    atlas_doctor_ok "$label" "$file"
  elif [ -f "$file" ]; then
    atlas_doctor_fail "$label" "not writable: $file"
  else
    atlas_doctor_fail "$label" "missing: $file"
  fi
}

atlas_doctor_check_executable() {
  local label="$1"
  local path="$2"

  if [ -x "$path" ]; then
    atlas_doctor_ok "$label" "$path"
  else
    atlas_doctor_fail "$label" "missing executable: $path"
  fi
}

atlas_doctor_check_command() {
  local label="$1"
  local command_name="$2"
  local required="${3:-required}"
  local resolved

  resolved="$(command -v "$command_name" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    atlas_doctor_ok "$label" "$resolved"
  elif [ "$required" = "optional" ]; then
    atlas_doctor_warn "$label" "optional command not found: $command_name"
  else
    atlas_doctor_fail "$label" "command not found: $command_name"
  fi
}

atlas_doctor_check_intel_store() {
  intel_ensure_store

  atlas_doctor_check_dir "intel dir" "$LAB_INTEL_DIR"
  atlas_doctor_check_file "observations" "$LAB_INTEL_OBSERVATIONS_FILE"
  atlas_doctor_check_file "entities" "$LAB_INTEL_ENTITIES_FILE"
  atlas_doctor_check_file "outcomes" "$LAB_INTEL_OUTCOMES_FILE"
  atlas_doctor_check_file "relationships" "$LAB_INTEL_RELATIONSHIPS_FILE"
}

cmd_doctor() {
  local active_slug="none"

  atlas_doctor_failures=0
  atlas_doctor_warnings=0

  ui_heading "Atlas Doctor"
  ui_rule
  ui_kv "Root" "$LAB_ROOT"
  ui_kv "Role" "$LAB_ROLE"
  ui_kv "Runtime Target" "$LAB_RUNTIME_TARGET"
  if has_active_operation; then
    active_slug="$(active_operation_slug)"
  fi
  ui_kv "Active Operation" "$active_slug"
  ui_rule

  ui_subheading "Core Paths"
  atlas_doctor_check_dir "state dir" "$LAB_STATE_DIR"
  atlas_doctor_check_dir "targets dir" "$LAB_TARGETS_DIR"
  atlas_doctor_check_dir "sessions dir" "$LAB_SESSIONS_DIR"
  atlas_doctor_check_dir "reports dir" "$LAB_REPORTS_DIR"
  atlas_doctor_check_dir "logs dir" "$LAB_LOGS_DIR"
  ui_rule

  ui_subheading "Shared Intel"
  atlas_doctor_check_command "jq" "jq"
  atlas_doctor_check_intel_store
  ui_rule

  ui_subheading "Evidence"
  atlas_doctor_check_command "sha256sum" "sha256sum"
  ui_rule

  ui_subheading "Atlas Adapters"
  atlas_doctor_check_executable "wiremap" "$WIREMAP_BIN"
  atlas_doctor_check_executable "vector" "$VECTOR_BIN"
  atlas_doctor_check_executable "intelctl" "$INTELCTL_BIN"
  atlas_doctor_check_executable "labctl" "$LABCTL_BIN"
  ui_rule

  ui_subheading "Optional Backends"
  atlas_doctor_check_command "nmap" "${LAB_WIREMAP_NMAP_BIN:-nmap}" optional
  atlas_doctor_check_command "tcpdump" "${LAB_WIREMAP_TCPDUMP_BIN:-tcpdump}" optional
  atlas_doctor_check_command "tshark" "${LAB_WIREMAP_TSHARK_BIN:-tshark}" optional
  atlas_doctor_check_command "curl" "${LAB_VECTOR_CURL_BIN:-curl}" optional
  atlas_doctor_check_command "msfconsole" "${LAB_VECTOR_MSFCONSOLE_BIN:-msfconsole}" optional
  ui_rule

  if [ "$atlas_doctor_failures" -gt 0 ]; then
    ui_kv "Status" "attention required"
    ui_kv "Failures" "$atlas_doctor_failures"
    ui_kv "Warnings" "$atlas_doctor_warnings"
    return 1
  fi

  ui_kv "Status" "ok"
  ui_kv "Warnings" "$atlas_doctor_warnings"
}
