#!/usr/bin/env bash

intel_ensure_store() {
  local file

  mkdir -p "$LAB_INTEL_DIR"
  for file in \
    "$LAB_INTEL_OBSERVATIONS_FILE" \
    "$LAB_INTEL_ENTITIES_FILE" \
    "$LAB_INTEL_OUTCOMES_FILE" \
    "$LAB_INTEL_RELATIONSHIPS_FILE"; do
    [ -f "$file" ] || : >"$file"
  done
}

intel_require_jq() {
  command -v jq >/dev/null 2>&1 || fail "command not found: jq"
}

intel_file_for() {
  case "$1" in
  observations)
    printf '%s\n' "$LAB_INTEL_OBSERVATIONS_FILE"
    ;;
  entities)
    printf '%s\n' "$LAB_INTEL_ENTITIES_FILE"
    ;;
  outcomes)
    printf '%s\n' "$LAB_INTEL_OUTCOMES_FILE"
    ;;
  relationships)
    printf '%s\n' "$LAB_INTEL_RELATIONSHIPS_FILE"
    ;;
  *)
    fail "unknown intel stream: $1"
    ;;
  esac
}

intel_append_record() {
  local stream="$1"
  local payload="$2"
  local file

  file="$(intel_file_for "$stream")"
  intel_ensure_store
  printf '%s\n' "$payload" >>"$file"
}

intel_stream() {
  local stream="$1"
  local file

  file="$(intel_file_for "$stream")"
  intel_ensure_store
  [ -s "$file" ] || return 0
  cat "$file"
}

intel_record_count() {
  local stream="$1"
  local file

  file="$(intel_file_for "$stream")"
  intel_ensure_store
  if [ ! -s "$file" ]; then
    printf '0'
    return 0
  fi

  wc -l <"$file" | tr -d ' '
}

intel_host_entity_id() {
  printf 'host:%s' "$1"
}

intel_service_entity_id() {
  printf 'service:%s:%s' "$1" "$2"
}
