#!/usr/bin/env bash

atlas_flow_dir() {
  printf '%s/flows\n' "$ATLAS_STATE_DIR"
}

atlas_flow_slug_for() {
  local name="$1"
  local slug

  slug="$(slugify "$name")"
  [ -n "$slug" ] || fail "flow name produced an empty slug"
  printf '%s\n' "$slug"
}

atlas_flow_id_for_slug() {
  local slug="$1"
  local flow_key

  flow_key="$(printf '%s' "$slug" | tr '.-' '__')"
  printf 'flow_%s\n' "$flow_key"
}

atlas_flow_file_for_slug() {
  local slug="$1"

  printf '%s/%s.env\n' "$(atlas_flow_dir)" "$slug"
}

atlas_flow_slug_for_input() {
  local input="$1"
  local slug
  local stripped

  slug="$(slugify "$input")"
  if [ -f "$(atlas_flow_file_for_slug "$slug")" ]; then
    printf '%s\n' "$slug"
    return 0
  fi

  case "$input" in
  flow_*)
    stripped="${input#flow_}"
    stripped="$(printf '%s' "$stripped" | tr '_' '-')"
    slug="$(slugify "$stripped")"
    ;;
  esac

  [ -n "$slug" ] || fail "flow name produced an empty slug"
  printf '%s\n' "$slug"
}

atlas_flow_forbidden_content_check() {
  local value="$1"
  local lowered

  lowered="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  case "$lowered" in
  *password=* | *passwd=* | *api_key=* | *secret=* | *token=* | *authorization:* | *bearer* | *set-cookie:* | *private\ key* | *begin\ rsa* | *begin\ openssh* | *session=* | *cookie=*)
    fail "business-flow metadata contains a forbidden raw-content marker"
    ;;
  esac
}

atlas_flow_validate_metadata_value() {
  local label="$1"
  local value="$2"

  [ -n "$value" ] || fail "empty business-flow metadata value for $label"
  case "$value" in
  *$'\n'* | *$'\r'*)
    fail "business-flow metadata must be single-line: $label"
    ;;
  esac
  atlas_flow_forbidden_content_check "$value"
}

atlas_flow_validate_choice() {
  local label="$1"
  local value="$2"
  local allowed="$3"
  local item

  for item in $allowed; do
    [ "$value" = "$item" ] && return 0
  done
  fail "invalid $label: $value"
}

atlas_flow_join_csv() {
  local joined=""
  local item

  for item in "$@"; do
    if [ -z "$joined" ]; then
      joined="$item"
    else
      joined="$joined,$item"
    fi
  done
  printf '%s\n' "$joined"
}

atlas_flow_print_csv_list() {
  local value="$1"
  local item

  if [ -z "$value" ]; then
    ui_note "none recorded"
    return 0
  fi

  while IFS= read -r item; do
    [ -n "$item" ] || continue
    printf -- '- %s\n' "$item"
  done < <(printf '%s\n' "$value" | tr ',' '\n')
}

atlas_flow_load_file() {
  local file="$1"
  local SCHEMA_VERSION=""
  local FLOW_ID=""
  local FLOW_SLUG=""
  local FLOW_NAME=""
  local FLOW_TYPE=""
  local OWNER=""
  local CRITICALITY=""
  local ENVIRONMENT=""
  local SCOPE_STATUS=""
  local DATA_CLASSES=""
  local SYSTEMS=""
  local CONTROL_OBJECTIVES=""
  local CREATED_AT=""
  local UPDATED_AT=""
  local SOURCE_TOOL=""
  local MODE=""
  local METADATA_ONLY=""

  [ -f "$file" ] || fail "unknown business flow: $file"
  # shellcheck disable=SC1090
  . "$file"

  [ "${SOURCE_TOOL:-}" = "$TOOL_NAME" ] || fail "not an atlas business flow: $file"
  [ "${MODE:-}" = "business_flow" ] || fail "invalid business flow record: $file"
  [ "${METADATA_ONLY:-}" = "true" ] || fail "business flow record is not marked metadata-only: $file"

  ATLAS_FLOW_SCHEMA_VERSION="${SCHEMA_VERSION:-}"
  ATLAS_FLOW_ID="${FLOW_ID:-}"
  ATLAS_FLOW_SLUG="${FLOW_SLUG:-$(basename "$file" .env)}"
  ATLAS_FLOW_NAME="${FLOW_NAME:-$ATLAS_FLOW_SLUG}"
  ATLAS_FLOW_TYPE="${FLOW_TYPE:-business_process}"
  ATLAS_FLOW_OWNER="${OWNER:-unknown}"
  ATLAS_FLOW_CRITICALITY="${CRITICALITY:-medium}"
  ATLAS_FLOW_ENVIRONMENT="${ENVIRONMENT:-unknown}"
  ATLAS_FLOW_SCOPE_STATUS="${SCOPE_STATUS:-unknown}"
  ATLAS_FLOW_DATA_CLASSES="${DATA_CLASSES:-}"
  ATLAS_FLOW_SYSTEMS="${SYSTEMS:-}"
  ATLAS_FLOW_CONTROL_OBJECTIVES="${CONTROL_OBJECTIVES:-}"
  ATLAS_FLOW_CREATED_AT="${CREATED_AT:-}"
  ATLAS_FLOW_UPDATED_AT="${UPDATED_AT:-}"
}

atlas_flow_load() {
  local input="$1"
  local slug
  local file

  slug="$(atlas_flow_slug_for_input "$input")"
  file="$(atlas_flow_file_for_slug "$slug")"
  [ -f "$file" ] || fail "unknown business flow: $input"
  atlas_flow_load_file "$file"
}

atlas_flow_files() {
  local file

  for file in "$(atlas_flow_dir)"/*.env; do
    [ -e "$file" ] || return 0
    printf '%s\n' "$file"
  done
}

cmd_flow_add() {
  need_args 1 "$#" "flow add <flow-name> [--type type] [--owner owner] [--criticality low|medium|high|critical] [--environment label] [--scope-status status] [--data-class label] [--system alias] [--control objective]"
  local name="$1"
  local flow_type="business_process"
  local owner="unknown"
  local criticality="medium"
  local environment="unknown"
  local scope_status="unknown"
  local data_classes=()
  local systems=()
  local controls=()
  local slug
  local flow_id
  local file
  local created_at

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --type)
      need_args 2 "$#" "flow add <flow-name> --type <type>"
      flow_type="$2"
      shift 2
      ;;
    --owner)
      need_args 2 "$#" "flow add <flow-name> --owner <owner>"
      owner="$2"
      shift 2
      ;;
    --criticality)
      need_args 2 "$#" "flow add <flow-name> --criticality <low|medium|high|critical>"
      criticality="$2"
      shift 2
      ;;
    --environment)
      need_args 2 "$#" "flow add <flow-name> --environment <label>"
      environment="$2"
      shift 2
      ;;
    --scope-status)
      need_args 2 "$#" "flow add <flow-name> --scope-status <status>"
      scope_status="$2"
      shift 2
      ;;
    --data-class)
      need_args 2 "$#" "flow add <flow-name> --data-class <label>"
      data_classes+=("$2")
      shift 2
      ;;
    --system)
      need_args 2 "$#" "flow add <flow-name> --system <alias>"
      systems+=("$2")
      shift 2
      ;;
    --control)
      need_args 2 "$#" "flow add <flow-name> --control <objective>"
      controls+=("$2")
      shift 2
      ;;
    *)
      fail "unknown flow add option: $1"
      ;;
    esac
  done

  atlas_flow_validate_metadata_value "flow name" "$name"
  atlas_flow_validate_metadata_value "flow type" "$flow_type"
  atlas_flow_validate_metadata_value "owner" "$owner"
  atlas_flow_validate_metadata_value "criticality" "$criticality"
  atlas_flow_validate_metadata_value "environment" "$environment"
  atlas_flow_validate_metadata_value "scope status" "$scope_status"
  atlas_flow_validate_choice "criticality" "$criticality" "low medium high critical"
  for value in "${data_classes[@]}"; do
    atlas_flow_validate_metadata_value "data class" "$value"
  done
  for value in "${systems[@]}"; do
    atlas_flow_validate_metadata_value "system" "$value"
  done
  for value in "${controls[@]}"; do
    atlas_flow_validate_metadata_value "control" "$value"
  done

  slug="$(atlas_flow_slug_for "$name")"
  flow_id="$(atlas_flow_id_for_slug "$slug")"
  file="$(atlas_flow_file_for_slug "$slug")"
  [ ! -e "$file" ] || fail "business flow already exists: $slug"

  mkdir -p "$(atlas_flow_dir)"
  chmod 700 "$(atlas_flow_dir)" 2>/dev/null || true
  created_at="$(timestamp)"
  : >"$file"
  chmod 600 "$file" 2>/dev/null || true

  upsert_env "$file" SCHEMA_VERSION "atlas.business_flow.v1"
  upsert_env "$file" FLOW_ID "$flow_id"
  upsert_env "$file" FLOW_SLUG "$slug"
  upsert_env "$file" FLOW_NAME "$name"
  upsert_env "$file" FLOW_TYPE "$flow_type"
  upsert_env "$file" OWNER "$owner"
  upsert_env "$file" CRITICALITY "$criticality"
  upsert_env "$file" ENVIRONMENT "$environment"
  upsert_env "$file" SCOPE_STATUS "$scope_status"
  upsert_env "$file" DATA_CLASSES "$(atlas_flow_join_csv "${data_classes[@]}")"
  upsert_env "$file" SYSTEMS "$(atlas_flow_join_csv "${systems[@]}")"
  upsert_env "$file" CONTROL_OBJECTIVES "$(atlas_flow_join_csv "${controls[@]}")"
  upsert_env "$file" CREATED_AT "$created_at"
  upsert_env "$file" UPDATED_AT "$created_at"
  upsert_env "$file" SOURCE_TOOL "$TOOL_NAME"
  upsert_env "$file" MODE "business_flow"
  upsert_env "$file" METADATA_ONLY "true"

  ui_ok "business flow added"
  printf 'flow_id: %s\n' "$flow_id"
  printf 'flow_slug: %s\n' "$slug"
  printf 'path: %s\n' "$file"
}

cmd_flow_list() {
  local file
  local count=0

  printf '%-28s %-18s %-12s %-14s %s\n' "FLOW" "OWNER" "CRITICALITY" "ENVIRONMENT" "SCOPE"

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    atlas_flow_load_file "$file"
    printf '%-28s %-18s %-12s %-14s %s\n' \
      "$ATLAS_FLOW_SLUG" \
      "$ATLAS_FLOW_OWNER" \
      "$ATLAS_FLOW_CRITICALITY" \
      "$ATLAS_FLOW_ENVIRONMENT" \
      "$ATLAS_FLOW_SCOPE_STATUS"
    count=$((count + 1))
  done < <(atlas_flow_files)

  if [ "$count" -eq 0 ]; then
    ui_note "no business flows found"
  fi
}

cmd_flow_show() {
  need_args 1 "$#" "flow show <flow>"
  local input="$1"

  atlas_flow_load "$input"

  ui_heading "Atlas Business Flow"
  ui_rule
  ui_kv "Schema Version" "$ATLAS_FLOW_SCHEMA_VERSION"
  ui_kv "Flow ID" "$ATLAS_FLOW_ID"
  ui_kv "Flow Slug" "$ATLAS_FLOW_SLUG"
  ui_kv "Flow Name" "$ATLAS_FLOW_NAME"
  ui_kv "Type" "$ATLAS_FLOW_TYPE"
  ui_kv "Owner" "$ATLAS_FLOW_OWNER"
  ui_kv "Criticality" "$ATLAS_FLOW_CRITICALITY"
  ui_kv "Environment" "$ATLAS_FLOW_ENVIRONMENT"
  ui_kv "Scope Status" "$ATLAS_FLOW_SCOPE_STATUS"
  ui_kv "Metadata Only" "true"
  ui_kv "Created" "$ATLAS_FLOW_CREATED_AT"
  ui_kv "Updated" "$ATLAS_FLOW_UPDATED_AT"
  ui_rule
  ui_subheading "Data Classes"
  atlas_flow_print_csv_list "$ATLAS_FLOW_DATA_CLASSES"
  ui_rule
  ui_subheading "Systems"
  atlas_flow_print_csv_list "$ATLAS_FLOW_SYSTEMS"
  ui_rule
  ui_subheading "Control Objectives"
  atlas_flow_print_csv_list "$ATLAS_FLOW_CONTROL_OBJECTIVES"
}

dispatch_flow_command() {
  case "${1:-}" in
  add)
    shift
    cmd_flow_add "$@"
    ;;
  list)
    shift
    cmd_flow_list "$@"
    ;;
  show)
    shift
    cmd_flow_show "$@"
    ;;
  *)
    usage
    exit 1
    ;;
  esac
}
