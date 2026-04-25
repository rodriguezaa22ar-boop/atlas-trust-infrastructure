#!/usr/bin/env bash

set -euo pipefail

LAB_ROOT_DEFAULT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_ROOT="${LAB_ROOT:-$LAB_ROOT_DEFAULT}"
LAB_CONFIG="${LAB_CONFIG:-$LAB_ROOT/etc/lab.env}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

slugify() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

load_config() {
  if [ -f "$LAB_CONFIG" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$LAB_CONFIG"
    set +a
  fi

  LAB_ROOT="${LAB_ROOT:-$LAB_ROOT_DEFAULT}"
  LAB_BIN_DIR="${LAB_BIN_DIR:-$LAB_ROOT/bin}"
  LAB_LIB_DIR="${LAB_LIB_DIR:-$LAB_ROOT/lib}"
  LAB_PERSIST_DIR="${LAB_PERSIST_DIR:-}"
  LAB_STATE_DIR="${LAB_STATE_DIR:-$LAB_ROOT/state}"
  LAB_TARGETS_DIR="${LAB_TARGETS_DIR:-$LAB_ROOT/targets}"
  LAB_SESSIONS_DIR="${LAB_SESSIONS_DIR:-$LAB_ROOT/sessions}"
  LAB_TOOLS_DIR="${LAB_TOOLS_DIR:-$LAB_ROOT/tools}"
  LAB_REPORTS_DIR="${LAB_REPORTS_DIR:-$LAB_ROOT/reports}"
  LAB_LOGS_DIR="${LAB_LOGS_DIR:-$LAB_ROOT/logs}"
  LAB_DOCS_DIR="${LAB_DOCS_DIR:-$LAB_ROOT/docs}"
  LAB_RELEASES_DIR="${LAB_RELEASES_DIR:-$LAB_ROOT/releases}"
  LAB_INTEL_DIR="${LAB_INTEL_DIR:-$LAB_STATE_DIR/intel}"
  LAB_INTEL_OBSERVATIONS_FILE="${LAB_INTEL_OBSERVATIONS_FILE:-$LAB_INTEL_DIR/observations.jsonl}"
  LAB_INTEL_ENTITIES_FILE="${LAB_INTEL_ENTITIES_FILE:-$LAB_INTEL_DIR/entities.jsonl}"
  LAB_INTEL_OUTCOMES_FILE="${LAB_INTEL_OUTCOMES_FILE:-$LAB_INTEL_DIR/outcomes.jsonl}"
  LAB_INTEL_RELATIONSHIPS_FILE="${LAB_INTEL_RELATIONSHIPS_FILE:-$LAB_INTEL_DIR/relationships.jsonl}"
  LAB_ROLE="${LAB_ROLE:-builder}"
  LAB_RUNTIME_TARGET="${LAB_RUNTIME_TARGET:-local-usb}"

  export LAB_ROOT LAB_BIN_DIR LAB_LIB_DIR LAB_PERSIST_DIR
  export LAB_STATE_DIR LAB_TARGETS_DIR
  export LAB_SESSIONS_DIR LAB_TOOLS_DIR LAB_REPORTS_DIR LAB_LOGS_DIR
  export LAB_DOCS_DIR LAB_RELEASES_DIR LAB_INTEL_DIR
  export LAB_INTEL_OBSERVATIONS_FILE LAB_INTEL_ENTITIES_FILE
  export LAB_INTEL_OUTCOMES_FILE LAB_INTEL_RELATIONSHIPS_FILE
  export LAB_ROLE LAB_RUNTIME_TARGET
}

ensure_layout() {
  mkdir -p \
    "$LAB_BIN_DIR" \
    "$LAB_LIB_DIR" \
    "$LAB_STATE_DIR" \
    "$LAB_TARGETS_DIR" \
    "$LAB_SESSIONS_DIR" \
    "$LAB_TOOLS_DIR" \
    "$LAB_REPORTS_DIR" \
    "$LAB_LOGS_DIR" \
    "$LAB_DOCS_DIR" \
    "$LAB_RELEASES_DIR" \
    "$LAB_INTEL_DIR"
}

need_args() {
  local minimum="$1"
  local actual="$2"
  local usage="$3"

  if [ "$actual" -lt "$minimum" ]; then
    fail "$usage"
  fi
}

upsert_env() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp

  tmp="$(mktemp)"
  if [ -f "$file" ]; then
    grep -v "^${key}=" "$file" >"$tmp" || true
  fi
  printf '%s=%q\n' "$key" "$value" >>"$tmp"
  mv "$tmp" "$file"
}

read_env() {
  local file="$1"

  if [ ! -f "$file" ]; then
    fail "missing record: $file"
  fi

  (
    set -a
    # shellcheck disable=SC1090
    . "$file"
    set +a
    env
  )
}

count_entries() {
  local dir="$1"
  find "$dir" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' '
}

supports_color() {
  if [ "${LAB_FORCE_COLOR:-0}" = "1" ]; then
    return 0
  fi

  if [ -n "${NO_COLOR:-}" ]; then
    return 1
  fi

  [ -t 1 ] || return 1

  case "${TERM:-dumb}" in
  "" | dumb)
    return 1
    ;;
  *)
    return 0
    ;;
  esac
}

ui_paint() {
  local code="$1"
  shift

  if supports_color; then
    printf '\033[%sm%s\033[0m' "$code" "$*"
  else
    printf '%s' "$*"
  fi
}

ui_dim() {
  ui_paint "2" "$*"
}

ui_accent() {
  ui_paint "1;36" "$*"
}

ui_info() {
  ui_paint "1;34" "$*"
}

ui_good() {
  ui_paint "1;32" "$*"
}

ui_warn() {
  ui_paint "1;33" "$*"
}

ui_bad() {
  ui_paint "1;31" "$*"
}

ui_focus() {
  ui_paint "1;35" "$*"
}

ui_heading() {
  printf '%s\n' "$(ui_accent "$*")"
}

ui_subheading() {
  printf '%s\n' "$(ui_info "$*")"
}

ui_rule() {
  printf '%s\n' "$(ui_dim "------------------------------------------------------------")"
}

ui_kv() {
  local key="$1"
  shift
  printf '%s %s\n' "$(ui_dim "$key:")" "$*"
}

ui_note() {
  printf '%s %s\n' "$(ui_dim "note:")" "$*"
}

ui_ok() {
  printf '%s %s\n' "$(ui_good "ok:")" "$*"
}

ui_alert() {
  printf '%s %s\n' "$(ui_warn "warn:")" "$*"
}
