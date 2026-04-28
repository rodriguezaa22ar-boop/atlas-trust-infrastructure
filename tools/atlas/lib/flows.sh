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

atlas_flow_operation_links_file() {
  local op_dir="$1"

  printf '%s/business_flows.ndjson\n' "$op_dir"
}

atlas_flow_evidence_links_file() {
  local op_dir="$1"

  printf '%s/flow_evidence.ndjson\n' "$op_dir"
}

atlas_flow_packet_dir() {
  printf '%s/flow_packets\n' "$ATLAS_OP_DIR"
}

atlas_flow_packet_slug_for() {
  local name="$1"
  local slug

  slug="$(slugify "$name")"
  [ -n "$slug" ] || fail "flow packet name produced an empty slug"
  printf '%s\n' "$slug"
}

atlas_flow_packet_path_for_name() {
  local name="$1"

  printf '%s/%s.md\n' "$(atlas_flow_packet_dir)" "$(atlas_flow_packet_slug_for "$name")"
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

  if atlas_flow_forbidden_content_present "$value"; then
    fail "business-flow metadata contains a forbidden raw-content marker"
  fi
}

atlas_flow_forbidden_content_present() {
  local value="$1"
  local lowered

  lowered="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  case "$lowered" in
  *password=* | *passwd=* | *api_key=* | *secret=* | *token=* | *authorization:* | *bearer* | *set-cookie:* | *private\ key* | *begin\ rsa* | *begin\ openssh* | *session=* | *cookie=*)
    return 0
    ;;
  esac
  return 1
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

atlas_flow_packet_csv_section() {
  local title="$1"
  local value="$2"
  local item

  printf '\n## %s\n\n' "$title"
  if [ -z "$value" ]; then
    printf -- '- none recorded\n'
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

atlas_flow_record_count() {
  local count=0
  local file

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    count=$((count + 1))
  done < <(atlas_flow_files)

  printf '%s\n' "$count"
}

atlas_flow_operation_link_count() {
  local op_dir="$1"
  local file

  file="$(atlas_flow_operation_links_file "$op_dir")"
  if [ ! -s "$file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr 'length' "$file" 2>/dev/null || printf '0\n'
}

atlas_flow_operation_packet_count() {
  local op_dir="$1"
  local packet_dir="$op_dir/flow_packets"

  if [ ! -d "$packet_dir" ]; then
    printf '0\n'
    return 0
  fi

  find "$packet_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' '
}

atlas_flow_operation_link_exists() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  [ -s "$file" ] || return 1
  jq -e \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    'select(.flow_id == $flow_id and .operation == $operation)' \
    "$file" >/dev/null
}

atlas_flow_evidence_link_count() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    '[.[] | select(.flow_id == $flow_id and .operation == $operation)] | length' \
    "$file"
}

atlas_flow_latest_evidence_linked_at() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ]; then
    return 0
  fi

  jq -sr \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    '[.[] | select(.flow_id == $flow_id and .operation == $operation) | .linked_at // empty] | max // ""' \
    "$file"
}

atlas_flow_packet_evidence_refs() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  jq -r \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    'select(.flow_id == $flow_id and .operation == $operation) |
      "- Evidence ID: " + (.evidence_id // "unknown") + "\n" +
      "  - Kind: " + (.kind // "artifact") + "\n" +
      "  - Retained Path: " + (.evidence_path // "unknown") + "\n" +
      "  - SHA-256: " + (.evidence_sha256 // "unknown") + "\n" +
      "  - Classification: " + (.evidence_classification // "unknown") + "\n" +
      "  - Redacted: " + ((.evidence_redacted // false) | tostring) + "\n" +
      "  - Linked At: " + (.linked_at // "unknown") + "\n" +
      "  - Metadata Only: " + ((.metadata_only // false) | tostring)' \
    "$file"
}

atlas_flow_validate_packet_file() {
  local packet_file="$1"

  if atlas_flow_packet_forbidden_content_present "$packet_file"; then
    fail "business-flow metadata contains a forbidden raw-content marker"
  fi
}

atlas_flow_packet_forbidden_content_present() {
  local packet_file="$1"
  local line

  while IFS= read -r line; do
    if atlas_flow_forbidden_content_present "$line"; then
      return 0
    fi
  done <"$packet_file"
  return 1
}

atlas_flow_packet_field() {
  local packet_file="$1"
  local label="$2"

  awk -F': ' -v wanted="- $label" '$1 == wanted { print substr($0, length(wanted) + 3); exit }' "$packet_file"
}

atlas_flow_packet_contains_value() {
  local packet_file="$1"
  local label="$2"
  local value="$3"

  grep -Fq -- "- $label: $value" "$packet_file"
}

atlas_flow_timestamp_after() {
  local left="$1"
  local right="$2"

  [ -n "$left" ] && [ -n "$right" ] && [[ "$left" > "$right" ]]
}

atlas_flow_verify_reset() {
  ATLAS_FLOW_VERIFY_FAILURES=0
  ATLAS_FLOW_VERIFY_OVERALL="current"
}

atlas_flow_verify_row() {
  local check="$1"
  local status="$2"
  local detail="$3"

  printf '%-28s %-10s %s\n' "$check" "$status" "$detail"
  case "$status" in
  ok)
    ;;
  stale)
    ATLAS_FLOW_VERIFY_FAILURES=$((ATLAS_FLOW_VERIFY_FAILURES + 1))
    if [ "$ATLAS_FLOW_VERIFY_OVERALL" != "blocked" ]; then
      ATLAS_FLOW_VERIFY_OVERALL="stale"
    fi
    ;;
  *)
    ATLAS_FLOW_VERIFY_FAILURES=$((ATLAS_FLOW_VERIFY_FAILURES + 1))
    ATLAS_FLOW_VERIFY_OVERALL="blocked"
    ;;
  esac
}

atlas_flow_verify_packet_field_equals() {
  local packet_file="$1"
  local label="$2"
  local expected="$3"
  local actual

  actual="$(atlas_flow_packet_field "$packet_file" "$label")"
  if [ "$actual" = "$expected" ]; then
    atlas_flow_verify_row "$label" "ok" "$actual"
  else
    atlas_flow_verify_row "$label" "blocked" "expected=${expected:-missing} actual=${actual:-missing}"
  fi
}

atlas_flow_append_operation_link() {
  local file="$1"
  local linked_at="$2"

  intel_require_jq
  : >>"$file"
  chmod 600 "$file" 2>/dev/null || true

  if atlas_flow_operation_link_exists "$file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"; then
    return 0
  fi

  jq -cn \
    --arg schema_version "atlas.business_flow_link.v1" \
    --arg flow_id "$ATLAS_FLOW_ID" \
    --arg flow_slug "$ATLAS_FLOW_SLUG" \
    --arg flow_name "$ATLAS_FLOW_NAME" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg linked_at "$linked_at" \
    --arg linked_by "atlas" \
    '{
      schema_version: $schema_version,
      flow_id: $flow_id,
      flow_slug: $flow_slug,
      flow_name: $flow_name,
      operation: $operation,
      target: $target,
      linked_at: $linked_at,
      linked_by: $linked_by,
      metadata_only: true
    }' >>"$file"
}

atlas_flow_append_evidence_link() {
  local file="$1"
  local evidence_record="$2"
  local evidence_id="$3"
  local linked_at="$4"
  local evidence_kind
  local evidence_path
  local evidence_sha256
  local evidence_classification
  local evidence_redacted

  intel_require_jq

  evidence_kind="$(printf '%s\n' "$evidence_record" | jq -r '.kind // "artifact"')"
  evidence_path="$(printf '%s\n' "$evidence_record" | jq -r '.path // ""')"
  evidence_sha256="$(printf '%s\n' "$evidence_record" | jq -r '.sha256 // ""')"
  evidence_classification="$(printf '%s\n' "$evidence_record" | jq -r '.classification // "internal"')"
  evidence_redacted="$(printf '%s\n' "$evidence_record" | jq -r '(.redacted // false) | tostring')"

  [ -n "$evidence_path" ] || fail "evidence record missing retained path: $evidence_id"
  [ -n "$evidence_sha256" ] || fail "evidence record missing sha256: $evidence_id"

  : >>"$file"
  chmod 600 "$file" 2>/dev/null || true

  jq -cn \
    --arg schema_version "atlas.flow_evidence_link.v1" \
    --arg flow_id "$ATLAS_FLOW_ID" \
    --arg flow_slug "$ATLAS_FLOW_SLUG" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg evidence_id "$evidence_id" \
    --arg kind "$evidence_kind" \
    --arg evidence_path "$evidence_path" \
    --arg evidence_sha256 "$evidence_sha256" \
    --arg evidence_classification "$evidence_classification" \
    --argjson evidence_redacted "$evidence_redacted" \
    --arg linked_at "$linked_at" \
    --arg linked_by "atlas" \
    --arg notes "Metadata-only reference. Raw evidence not embedded." \
    '{
      schema_version: $schema_version,
      flow_id: $flow_id,
      flow_slug: $flow_slug,
      operation: $operation,
      target: $target,
      evidence_id: $evidence_id,
      kind: $kind,
      evidence_path: $evidence_path,
      evidence_sha256: $evidence_sha256,
      evidence_classification: $evidence_classification,
      evidence_redacted: $evidence_redacted,
      linked_at: $linked_at,
      linked_by: $linked_by,
      notes: $notes,
      metadata_only: true
    }' >>"$file"
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

cmd_flow_link_evidence() {
  need_args 2 "$#" "flow link-evidence <flow> <evidence-id>"
  local flow="$1"
  local evidence_id="$2"
  local evidence_record
  local linked_at
  local flow_links_file
  local evidence_links_file
  local evidence_kind
  local evidence_path
  local evidence_sha256

  atlas_flow_load "$flow"
  load_active_operation

  evidence_record="$(atlas_evidence_latest_record "$evidence_id" || true)"
  [ -n "$evidence_record" ] || fail "unknown evidence id in active operation: $evidence_id"

  linked_at="$(timestamp)"
  flow_links_file="$(atlas_flow_operation_links_file "$ATLAS_OP_DIR")"
  evidence_links_file="$(atlas_flow_evidence_links_file "$ATLAS_OP_DIR")"

  atlas_flow_append_operation_link "$flow_links_file" "$linked_at"
  atlas_flow_append_evidence_link "$evidence_links_file" "$evidence_record" "$evidence_id" "$linked_at"

  evidence_kind="$(printf '%s\n' "$evidence_record" | jq -r '.kind // "artifact"')"
  evidence_path="$(printf '%s\n' "$evidence_record" | jq -r '.path // ""')"
  evidence_sha256="$(printf '%s\n' "$evidence_record" | jq -r '.sha256 // ""')"

  atlas_ledger_append_current "flow.evidence_linked" "read-only" "atlas" "ok" "flow_id=$ATLAS_FLOW_ID evidence=$evidence_id kind=$evidence_kind sha256=$evidence_sha256 path=$evidence_path"

  ui_ok "business flow evidence linked"
  printf 'flow_id: %s\n' "$ATLAS_FLOW_ID"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'evidence_id: %s\n' "$evidence_id"
  printf 'link_path: %s\n' "$evidence_links_file"
}

cmd_flow_packet() {
  need_args 1 "$#" "flow packet <flow> [packet-name]"
  [ "$#" -le 2 ] || fail "flow packet <flow> [packet-name]"

  local flow="$1"
  local packet_name="${2:-}"
  local generated_at
  local packet_file
  local packet_dir
  local flow_file
  local flow_sha
  local flow_links_file
  local evidence_links_file
  local evidence_link_count
  local latest_evidence_link

  atlas_flow_load "$flow"
  load_active_operation
  intel_require_jq

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_FLOW_SLUG-flow-packet"
  fi

  flow_file="$(atlas_flow_file_for_slug "$ATLAS_FLOW_SLUG")"
  flow_sha="$(atlas_evidence_hash_path "$flow_file")"
  flow_links_file="$(atlas_flow_operation_links_file "$ATLAS_OP_DIR")"
  evidence_links_file="$(atlas_flow_evidence_links_file "$ATLAS_OP_DIR")"

  if ! atlas_flow_operation_link_exists "$flow_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"; then
    fail "business flow has no links in active operation; run 'atlas flow link-evidence' first"
  fi

  evidence_link_count="$(atlas_flow_evidence_link_count "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  [ "$evidence_link_count" -gt 0 ] || fail "business flow has no evidence links in active operation"

  generated_at="$(timestamp)"
  packet_dir="$(atlas_flow_packet_dir)"
  packet_file="$(atlas_flow_packet_path_for_name "$packet_name")"
  latest_evidence_link="$(atlas_flow_latest_evidence_linked_at "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"

  mkdir -p "$packet_dir"
  chmod 700 "$packet_dir" 2>/dev/null || true

  {
    printf '# Atlas Business Flow Evidence Packet\n\n'
    printf '## Packet\n\n'
    printf -- '- Schema: atlas.business_flow_packet.v1\n'
    printf -- '- Packet Name: %s\n' "$(atlas_flow_packet_slug_for "$packet_name")"
    printf -- '- Generated At: %s\n' "$generated_at"
    printf -- '- Operation: %s\n' "$ATLAS_OP_SLUG"
    printf -- '- Target: %s\n' "$ATLAS_OP_TARGET"
    printf -- '- Metadata Only: true\n'
    printf -- '- Raw Evidence Embedded: false\n'
    printf '\n## Metadata Boundary\n\n'
    printf -- '- Stores flow labels, operation labels, evidence IDs, hashes, retained paths, classifications, timestamps, and known limitations.\n'
    printf -- '- Does not store raw evidence bodies, customer records, request bodies, response bodies, payment data, credentials, token-bearing values, key material, or authorization headers.\n'
    printf '\n## Flow\n\n'
    printf -- '- Flow ID: %s\n' "$ATLAS_FLOW_ID"
    printf -- '- Flow Slug: %s\n' "$ATLAS_FLOW_SLUG"
    printf -- '- Flow Name: %s\n' "$ATLAS_FLOW_NAME"
    printf -- '- Type: %s\n' "$ATLAS_FLOW_TYPE"
    printf -- '- Owner: %s\n' "$ATLAS_FLOW_OWNER"
    printf -- '- Criticality: %s\n' "$ATLAS_FLOW_CRITICALITY"
    printf -- '- Environment: %s\n' "$ATLAS_FLOW_ENVIRONMENT"
    printf -- '- Scope Status: %s\n' "$ATLAS_FLOW_SCOPE_STATUS"
    printf -- '- Flow Record: %s\n' "$flow_file"
    printf -- '- Flow Record SHA-256: %s\n' "$flow_sha"
    atlas_flow_packet_csv_section "Systems" "$ATLAS_FLOW_SYSTEMS"
    atlas_flow_packet_csv_section "Data Classes" "$ATLAS_FLOW_DATA_CLASSES"
    atlas_flow_packet_csv_section "Control Objectives" "$ATLAS_FLOW_CONTROL_OBJECTIVES"
    printf '\n## Evidence References\n\n'
    atlas_flow_packet_evidence_refs "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"
    printf '\n\n## Findings\n\n'
    printf -- '- none linked in this packet version\n'
    printf '\n## Validation\n\n'
    printf -- '- none linked in this packet version\n'
    printf '\n## Approvals\n\n'
    printf -- '- none linked in this packet version\n'
    printf '\n## Freshness\n\n'
    printf -- '- Status: current\n'
    printf -- '- Packet Generated At: %s\n' "$generated_at"
    if [ -n "$latest_evidence_link" ]; then
      printf -- '- Latest Evidence Link: %s\n' "$latest_evidence_link"
    else
      printf -- '- Latest Evidence Link: none recorded\n'
    fi
    printf -- '- Evidence Link Count: %s\n' "$evidence_link_count"
    printf '\n## Known Limitations\n\n'
    printf -- '- This packet is metadata-only and does not embed raw evidence content.\n'
    printf -- '- Flow verification checks packet metadata, evidence links, hashes, freshness, and forbidden-content guardrails.\n'
    printf -- '- Finding, validation, approval, retention, and JSON packet parity links are not included in this first packet slice.\n'
    printf -- '- This packet is not production certification, payment verification, legal compliance evidence, or a third-party audit.\n'
  } >"$packet_file"

  chmod 600 "$packet_file" 2>/dev/null || true
  if ! atlas_flow_validate_packet_file "$packet_file"; then
    rm -f "$packet_file"
    fail "business-flow packet failed metadata-only validation"
  fi

  atlas_ledger_append_current "flow.packet.generated" "read-only" "atlas" "ok" "flow_id=$ATLAS_FLOW_ID packet=$packet_file evidence_links=$evidence_link_count"

  ui_ok "business flow packet written"
  printf 'flow_id: %s\n' "$ATLAS_FLOW_ID"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'packet: %s\n' "$packet_file"
}

cmd_flow_verify() {
  need_args 1 "$#" "flow verify <flow> [packet-name]"
  [ "$#" -le 2 ] || fail "flow verify <flow> [packet-name]"

  local flow="$1"
  local packet_name="${2:-}"
  local packet_file
  local flow_file
  local flow_sha
  local packet_flow_sha
  local flow_links_file
  local evidence_links_file
  local expected_count
  local packet_count
  local evidence_count_stale=0
  local generated_at
  local latest_evidence_link
  local link_json
  local evidence_id
  local link_path
  local link_sha
  local link_classification
  local link_redacted
  local link_linked_at
  local record
  local record_path
  local record_sha
  local record_classification
  local record_redacted
  local evidence_file
  local actual_sha

  atlas_flow_load "$flow"
  load_active_operation
  intel_require_jq

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_FLOW_SLUG-flow-packet"
  fi

  packet_file="$(atlas_flow_packet_path_for_name "$packet_name")"
  flow_file="$(atlas_flow_file_for_slug "$ATLAS_FLOW_SLUG")"
  flow_sha="$(atlas_evidence_hash_path "$flow_file")"
  flow_links_file="$(atlas_flow_operation_links_file "$ATLAS_OP_DIR")"
  evidence_links_file="$(atlas_flow_evidence_links_file "$ATLAS_OP_DIR")"

  ui_heading "Atlas Business Flow Packet Verification"
  ui_rule
  ui_kv "Flow" "$ATLAS_FLOW_ID"
  ui_kv "Operation" "$ATLAS_OP_SLUG"
  ui_kv "Packet" "$packet_file"
  ui_rule
  printf '%-28s %-10s %s\n' "CHECK" "STATUS" "DETAIL"

  atlas_flow_verify_reset

  if [ -f "$packet_file" ]; then
    atlas_flow_verify_row "Packet" "ok" "$packet_file"
  else
    atlas_flow_verify_row "Packet" "blocked" "missing"
    ui_rule
    ui_kv "Overall" "$ATLAS_FLOW_VERIFY_OVERALL"
    return 1
  fi

  if atlas_flow_packet_forbidden_content_present "$packet_file"; then
    atlas_flow_verify_row "Forbidden Content" "blocked" "forbidden raw-content marker detected"
  else
    atlas_flow_verify_row "Forbidden Content" "ok" "absent"
  fi

  atlas_flow_verify_packet_field_equals "$packet_file" "Schema" "atlas.business_flow_packet.v1"
  atlas_flow_verify_packet_field_equals "$packet_file" "Metadata Only" "true"
  atlas_flow_verify_packet_field_equals "$packet_file" "Raw Evidence Embedded" "false"
  atlas_flow_verify_packet_field_equals "$packet_file" "Operation" "$ATLAS_OP_SLUG"
  atlas_flow_verify_packet_field_equals "$packet_file" "Target" "$ATLAS_OP_TARGET"
  atlas_flow_verify_packet_field_equals "$packet_file" "Flow ID" "$ATLAS_FLOW_ID"

  packet_flow_sha="$(atlas_flow_packet_field "$packet_file" "Flow Record SHA-256")"
  if [ "$packet_flow_sha" = "$flow_sha" ]; then
    atlas_flow_verify_row "Flow Record Hash" "ok" "$flow_sha"
  else
    atlas_flow_verify_row "Flow Record Hash" "stale" "expected=$flow_sha actual=${packet_flow_sha:-missing}"
  fi

  generated_at="$(atlas_flow_packet_field "$packet_file" "Packet Generated At")"
  if [ -z "$generated_at" ]; then
    generated_at="$(atlas_flow_packet_field "$packet_file" "Generated At")"
  fi
  if [ -n "$generated_at" ]; then
    atlas_flow_verify_row "Generated At" "ok" "$generated_at"
  else
    atlas_flow_verify_row "Generated At" "blocked" "missing"
  fi

  if atlas_flow_operation_link_exists "$flow_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"; then
    atlas_flow_verify_row "Operation Link" "ok" "$flow_links_file"
  else
    atlas_flow_verify_row "Operation Link" "blocked" "missing flow link in active operation"
  fi

  expected_count="$(atlas_flow_evidence_link_count "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_count="$(atlas_flow_packet_field "$packet_file" "Evidence Link Count")"
  if [ "$expected_count" -gt 0 ]; then
    atlas_flow_verify_row "Evidence Links" "ok" "$expected_count"
  else
    atlas_flow_verify_row "Evidence Links" "blocked" "none linked"
  fi

  if [ "$packet_count" = "$expected_count" ]; then
    atlas_flow_verify_row "Evidence Count" "ok" "$packet_count"
  else
    evidence_count_stale=1
    atlas_flow_verify_row "Evidence Count" "stale" "expected=$expected_count actual=${packet_count:-missing}"
  fi

  latest_evidence_link="$(atlas_flow_latest_evidence_linked_at "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_evidence_link" "$generated_at"; then
    atlas_flow_verify_row "Freshness" "stale" "latest_evidence_link=$latest_evidence_link packet_generated=$generated_at"
  else
    atlas_flow_verify_row "Freshness" "ok" "latest_evidence_link=${latest_evidence_link:-none} packet_generated=${generated_at:-missing}"
  fi

  if atlas_flow_timestamp_after "$ATLAS_FLOW_UPDATED_AT" "$generated_at"; then
    atlas_flow_verify_row "Flow Freshness" "stale" "flow_updated=$ATLAS_FLOW_UPDATED_AT packet_generated=$generated_at"
  else
    atlas_flow_verify_row "Flow Freshness" "ok" "flow_updated=${ATLAS_FLOW_UPDATED_AT:-unknown}"
  fi

  while IFS= read -r link_json; do
    [ -n "$link_json" ] || continue
    evidence_id="$(printf '%s\n' "$link_json" | jq -r '.evidence_id // ""')"
    link_path="$(printf '%s\n' "$link_json" | jq -r '.evidence_path // ""')"
    link_sha="$(printf '%s\n' "$link_json" | jq -r '.evidence_sha256 // ""')"
    link_classification="$(printf '%s\n' "$link_json" | jq -r '.evidence_classification // ""')"
    link_redacted="$(printf '%s\n' "$link_json" | jq -r '(.evidence_redacted // false) | tostring')"
    link_linked_at="$(printf '%s\n' "$link_json" | jq -r '.linked_at // ""')"

    if [ -z "$evidence_id" ]; then
      atlas_flow_verify_row "Evidence Record" "blocked" "link missing evidence id"
      continue
    fi

    if atlas_flow_packet_contains_value "$packet_file" "Evidence ID" "$evidence_id"; then
      atlas_flow_verify_row "Evidence $evidence_id" "ok" "packet reference present"
    elif [ "$evidence_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_row "Evidence $evidence_id" "stale" "link newer than packet or count mismatch"
    else
      atlas_flow_verify_row "Evidence $evidence_id" "blocked" "packet reference missing"
    fi

    record="$(atlas_evidence_latest_record "$evidence_id" || true)"
    if [ -z "$record" ]; then
      atlas_flow_verify_row "Evidence Record" "blocked" "missing current record for $evidence_id"
      continue
    fi

    record_path="$(printf '%s\n' "$record" | jq -r '.path // ""')"
    record_sha="$(printf '%s\n' "$record" | jq -r '.sha256 // ""')"
    record_classification="$(printf '%s\n' "$record" | jq -r '.classification // ""')"
    record_redacted="$(printf '%s\n' "$record" | jq -r '(.redacted // false) | tostring')"

    if [ "$record_path" = "$link_path" ]; then
      atlas_flow_verify_row "Evidence Path" "ok" "$evidence_id $record_path"
    else
      atlas_flow_verify_row "Evidence Path" "blocked" "evidence=$evidence_id expected=$record_path actual=${link_path:-missing}"
    fi

    if [ "$record_sha" = "$link_sha" ] && [ -n "$record_sha" ]; then
      atlas_flow_verify_row "Evidence Hash" "ok" "$evidence_id $record_sha"
    else
      atlas_flow_verify_row "Evidence Hash" "blocked" "evidence=$evidence_id expected=$record_sha actual=${link_sha:-missing}"
    fi

    if atlas_flow_packet_contains_value "$packet_file" "Retained Path" "$link_path" &&
      atlas_flow_packet_contains_value "$packet_file" "SHA-256" "$link_sha" &&
      atlas_flow_packet_contains_value "$packet_file" "Classification" "$link_classification" &&
      atlas_flow_packet_contains_value "$packet_file" "Redacted" "$link_redacted"; then
      atlas_flow_verify_row "Packet Evidence" "ok" "$evidence_id metadata matches"
    elif [ "$evidence_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_row "Packet Evidence" "stale" "$evidence_id link newer than packet or count mismatch"
    else
      atlas_flow_verify_row "Packet Evidence" "blocked" "$evidence_id metadata missing or mismatched"
    fi

    if [ "$record_classification" != "$link_classification" ] || [ "$record_redacted" != "$link_redacted" ]; then
      atlas_flow_verify_row "Evidence Metadata" "blocked" "evidence=$evidence_id classification/redaction mismatch"
    else
      atlas_flow_verify_row "Evidence Metadata" "ok" "$evidence_id classification=$record_classification redacted=$record_redacted"
    fi

    evidence_file="$ATLAS_OP_DIR/$record_path"
    if [ -f "$evidence_file" ]; then
      actual_sha="$(atlas_evidence_hash_path "$evidence_file")"
      if [ "$actual_sha" = "$record_sha" ]; then
        atlas_flow_verify_row "Evidence File" "ok" "$evidence_id actual hash matches"
      else
        atlas_flow_verify_row "Evidence File" "blocked" "evidence=$evidence_id actual hash mismatch expected=$record_sha actual=$actual_sha"
      fi
    else
      atlas_flow_verify_row "Evidence File" "blocked" "missing retained file for $evidence_id: $record_path"
    fi
  done < <(
    if [ -s "$evidence_links_file" ]; then
      jq -c \
        --arg flow_id "$ATLAS_FLOW_ID" \
        --arg operation "$ATLAS_OP_SLUG" \
        'select(.flow_id == $flow_id and .operation == $operation)' \
        "$evidence_links_file"
    fi
  )

  ui_rule
  ui_kv "Overall" "$ATLAS_FLOW_VERIFY_OVERALL"
  if [ "$ATLAS_FLOW_VERIFY_FAILURES" -eq 0 ]; then
    ui_ok "business flow packet verified"
    return 0
  fi

  return 1
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
  link-evidence)
    shift
    cmd_flow_link_evidence "$@"
    ;;
  packet)
    shift
    cmd_flow_packet "$@"
    ;;
  verify)
    shift
    cmd_flow_verify "$@"
    ;;
  *)
    usage
    exit 1
    ;;
  esac
}
