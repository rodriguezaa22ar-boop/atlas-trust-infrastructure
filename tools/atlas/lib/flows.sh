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

atlas_flow_finding_links_file() {
  local op_dir="$1"

  printf '%s/flow_findings.ndjson\n' "$op_dir"
}

atlas_flow_validation_links_file() {
  local op_dir="$1"

  printf '%s/flow_validation.ndjson\n' "$op_dir"
}

atlas_flow_approval_links_file() {
  local op_dir="$1"

  printf '%s/flow_approvals.ndjson\n' "$op_dir"
}

atlas_flow_packet_dir() {
  printf '%s/flow_packets\n' "$ATLAS_OP_DIR"
}

atlas_flow_packet_json_dir() {
  printf '%s/flow_packets_json\n' "$ATLAS_OP_DIR"
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

atlas_flow_packet_json_path_for_name() {
  local name="$1"

  printf '%s/%s.json\n' "$(atlas_flow_packet_json_dir)" "$(atlas_flow_packet_slug_for "$name")"
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
  local packet_json_dir="$op_dir/flow_packets_json"
  local count=0

  if [ -d "$packet_dir" ]; then
    count=$((count + $(find "$packet_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')))
  fi
  if [ -d "$packet_json_dir" ]; then
    count=$((count + $(find "$packet_json_dir" -maxdepth 1 -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ')))
  fi

  printf '%s\n' "$count"
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

atlas_flow_finding_link_count() {
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

atlas_flow_validation_link_count() {
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

atlas_flow_approval_link_count() {
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

atlas_flow_latest_finding_linked_at() {
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

atlas_flow_latest_validation_linked_at() {
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

atlas_flow_latest_approval_linked_at() {
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

  if [ ! -s "$file" ] ||
    ! jq -e --arg flow_id "$flow_id" --arg operation "$operation" 'select(.flow_id == $flow_id and .operation == $operation)' "$file" >/dev/null 2>&1; then
    printf -- '- none linked\n'
    return 0
  fi

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

atlas_flow_packet_finding_refs() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ] ||
    ! jq -e --arg flow_id "$flow_id" --arg operation "$operation" 'select(.flow_id == $flow_id and .operation == $operation)' "$file" >/dev/null 2>&1; then
    printf -- '- none linked\n'
    return 0
  fi

  jq -r \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    'select(.flow_id == $flow_id and .operation == $operation) |
      "- Finding ID: " + (.finding_id // "unknown") + "\n" +
      "  - Title: " + (.title // "unknown") + "\n" +
      "  - Level: " + (.level // "unknown") + "\n" +
      "  - Severity: " + (.severity // "unknown") + "\n" +
      "  - Confidence: " + (.confidence // "unknown") + "\n" +
      "  - Status: " + (.status // "unknown") + "\n" +
      "  - Linked At: " + (.linked_at // "unknown") + "\n" +
      "  - Metadata Only: " + ((.metadata_only // false) | tostring)' \
    "$file"
}

atlas_flow_packet_validation_refs() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ] ||
    ! jq -e --arg flow_id "$flow_id" --arg operation "$operation" 'select(.flow_id == $flow_id and .operation == $operation)' "$file" >/dev/null 2>&1; then
    printf -- '- none linked\n'
    return 0
  fi

  jq -r \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    'select(.flow_id == $flow_id and .operation == $operation) |
      "- Validation ID: " + (.validation_id // "unknown") + "\n" +
      "  - Lane: " + (.lane // "unknown") + "\n" +
      "  - Capability: " + (.capability // "unknown") + "\n" +
      "  - Status: " + (.status // "unknown") + "\n" +
      "  - Finding: " + (.finding_id // "-") + "\n" +
      "  - Result: " + (.result_status // "-") + "\n" +
      "  - Linked At: " + (.linked_at // "unknown") + "\n" +
      "  - Metadata Only: " + ((.metadata_only // false) | tostring)' \
    "$file"
}

atlas_flow_packet_approval_refs() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ] ||
    ! jq -e --arg flow_id "$flow_id" --arg operation "$operation" 'select(.flow_id == $flow_id and .operation == $operation)' "$file" >/dev/null 2>&1; then
    printf -- '- none linked\n'
    return 0
  fi

  jq -r \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    'select(.flow_id == $flow_id and .operation == $operation) |
      "- Approval Ref: " + (.approval_ref // "unknown") + "\n" +
      "  - Capability: " + (.capability // "unknown") + "\n" +
      "  - Tier: " + (.tier // "unknown") + "\n" +
      "  - Status: " + (.status // "unknown") + "\n" +
      "  - Approved By: " + (.approved_by // "unknown") + "\n" +
      "  - Approval Timestamp: " + (.approval_ts // "unknown") + "\n" +
      "  - Linked At: " + (.linked_at // "unknown") + "\n" +
      "  - Metadata Only: " + ((.metadata_only // false) | tostring)' \
    "$file"
}

atlas_flow_csv_json_array() {
  local value="$1"

  if [ -z "$value" ]; then
    printf '[]\n'
    return 0
  fi

  printf '%s\n' "$value" |
    tr ',' '\n' |
    jq -R 'select(length > 0)' |
    jq -s '.'
}

atlas_flow_evidence_refs_json() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ]; then
    printf '[]\n'
    return 0
  fi

  jq -s \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    '[.[] | select(.flow_id == $flow_id and .operation == $operation) | {
      evidence_id: (.evidence_id // ""),
      kind: (.kind // "artifact"),
      path: (.evidence_path // ""),
      sha256: (.evidence_sha256 // ""),
      classification: (.evidence_classification // "unknown"),
      redacted: (.evidence_redacted // false),
      linked_at: (.linked_at // ""),
      metadata_only: (.metadata_only // false)
    }]' \
    "$file"
}

atlas_flow_finding_refs_json() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ]; then
    printf '[]\n'
    return 0
  fi

  jq -s \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    '[.[] | select(.flow_id == $flow_id and .operation == $operation) | {
      finding_id: (.finding_id // ""),
      title: (.title // ""),
      level: (.level // "unknown"),
      severity: (.severity // "unknown"),
      confidence: (.confidence // "unknown"),
      status: (.status // "unknown"),
      linked_at: (.linked_at // ""),
      metadata_only: (.metadata_only // false)
    }]' \
    "$file"
}

atlas_flow_validation_refs_json() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ]; then
    printf '[]\n'
    return 0
  fi

  jq -s \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    '[.[] | select(.flow_id == $flow_id and .operation == $operation) | {
      validation_id: (.validation_id // ""),
      lane: (.lane // "unknown"),
      capability: (.capability // "unknown"),
      status: (.status // "unknown"),
      finding_id: (.finding_id // null),
      result_status: (.result_status // null),
      linked_at: (.linked_at // ""),
      metadata_only: (.metadata_only // false)
    }]' \
    "$file"
}

atlas_flow_approval_refs_json() {
  local file="$1"
  local flow_id="$2"
  local operation="$3"

  if [ ! -s "$file" ]; then
    printf '[]\n'
    return 0
  fi

  jq -s \
    --arg flow_id "$flow_id" \
    --arg operation "$operation" \
    '[.[] | select(.flow_id == $flow_id and .operation == $operation) | {
      approval_ref: (.approval_ref // ""),
      capability: (.capability // "unknown"),
      tier: (.tier // "unknown"),
      status: (.status // "unknown"),
      approved_by: (.approved_by // "unknown"),
      approval_ts: (.approval_ts // ""),
      linked_at: (.linked_at // ""),
      metadata_only: (.metadata_only // false)
    }]' \
    "$file"
}

atlas_flow_validate_packet_file() {
  local packet_file="$1"

  if atlas_flow_packet_forbidden_content_present "$packet_file"; then
    return 1
  fi

  return 0
}

atlas_flow_validate_json_packet_file() {
  local packet_file="$1"

  if atlas_flow_json_packet_forbidden_content_present "$packet_file"; then
    return 1
  fi

  return 0
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

atlas_flow_json_packet_forbidden_content_present() {
  local packet_file="$1"
  local value

  while IFS= read -r value; do
    if atlas_flow_forbidden_content_present "$value"; then
      return 0
    fi
  done < <(jq -r '.. | scalars? // empty' "$packet_file")
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

atlas_flow_append_finding_link() {
  local file="$1"
  local finding_record="$2"
  local finding_id="$3"
  local linked_at="$4"
  local title
  local level
  local severity
  local confidence
  local status
  local created_at
  local updated_at

  intel_require_jq

  title="$(printf '%s\n' "$finding_record" | jq -r '.title // ""')"
  level="$(printf '%s\n' "$finding_record" | jq -r '.level // "unknown"')"
  severity="$(printf '%s\n' "$finding_record" | jq -r '.severity // "unknown"')"
  confidence="$(printf '%s\n' "$finding_record" | jq -r '.confidence // "unknown"')"
  status="$(printf '%s\n' "$finding_record" | jq -r '.status // "unknown"')"
  created_at="$(printf '%s\n' "$finding_record" | jq -r '.created_at // ""')"
  updated_at="$(printf '%s\n' "$finding_record" | jq -r '.updated_at // .created_at // ""')"

  [ -n "$title" ] || fail "finding record missing title: $finding_id"
  atlas_flow_validate_metadata_value "finding title" "$title"
  atlas_flow_validate_metadata_value "finding level" "$level"
  atlas_flow_validate_metadata_value "finding severity" "$severity"
  atlas_flow_validate_metadata_value "finding confidence" "$confidence"
  atlas_flow_validate_metadata_value "finding status" "$status"

  : >>"$file"
  chmod 600 "$file" 2>/dev/null || true

  jq -cn \
    --arg schema_version "atlas.flow_finding_link.v1" \
    --arg flow_id "$ATLAS_FLOW_ID" \
    --arg flow_slug "$ATLAS_FLOW_SLUG" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg finding_id "$finding_id" \
    --arg title "$title" \
    --arg level "$level" \
    --arg severity "$severity" \
    --arg confidence "$confidence" \
    --arg status "$status" \
    --arg finding_created_at "$created_at" \
    --arg finding_updated_at "$updated_at" \
    --arg linked_at "$linked_at" \
    --arg linked_by "atlas" \
    --arg notes "Metadata-only reference. Finding impact and recommendation bodies are not embedded." \
    '{
      schema_version: $schema_version,
      flow_id: $flow_id,
      flow_slug: $flow_slug,
      operation: $operation,
      target: $target,
      finding_id: $finding_id,
      title: $title,
      level: $level,
      severity: $severity,
      confidence: $confidence,
      status: $status,
      finding_created_at: $finding_created_at,
      finding_updated_at: $finding_updated_at,
      linked_at: $linked_at,
      linked_by: $linked_by,
      notes: $notes,
      metadata_only: true
    }' >>"$file"
}

atlas_flow_append_validation_link() {
  local file="$1"
  local validation_record="$2"
  local validation_id="$3"
  local linked_at="$4"
  local lane
  local capability
  local status
  local finding_id
  local result_status
  local created_at
  local updated_at

  intel_require_jq

  lane="$(printf '%s\n' "$validation_record" | jq -r '.lane // "unknown"')"
  capability="$(printf '%s\n' "$validation_record" | jq -r '.capability // "unknown"')"
  status="$(printf '%s\n' "$validation_record" | jq -r '.status // "unknown"')"
  finding_id="$(printf '%s\n' "$validation_record" | jq -r '.finding // ""')"
  result_status="$(printf '%s\n' "$validation_record" | jq -r '.result_status // ""')"
  created_at="$(printf '%s\n' "$validation_record" | jq -r '.created_at // ""')"
  updated_at="$(printf '%s\n' "$validation_record" | jq -r '.updated_at // .created_at // ""')"

  atlas_flow_validate_metadata_value "validation lane" "$lane"
  atlas_flow_validate_metadata_value "validation capability" "$capability"
  atlas_flow_validate_metadata_value "validation status" "$status"
  if [ -n "$finding_id" ]; then
    atlas_flow_validate_metadata_value "validation finding id" "$finding_id"
  fi
  if [ -n "$result_status" ]; then
    atlas_flow_validate_metadata_value "validation result status" "$result_status"
  fi

  : >>"$file"
  chmod 600 "$file" 2>/dev/null || true

  jq -cn \
    --arg schema_version "atlas.flow_validation_link.v1" \
    --arg flow_id "$ATLAS_FLOW_ID" \
    --arg flow_slug "$ATLAS_FLOW_SLUG" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg validation_id "$validation_id" \
    --arg lane "$lane" \
    --arg capability "$capability" \
    --arg status "$status" \
    --arg finding_id "$finding_id" \
    --arg result_status "$result_status" \
    --arg validation_created_at "$created_at" \
    --arg validation_updated_at "$updated_at" \
    --arg linked_at "$linked_at" \
    --arg linked_by "atlas" \
    --arg notes "Metadata-only reference. Validation reason, plan body, and session contents are not embedded." \
    '{
      schema_version: $schema_version,
      flow_id: $flow_id,
      flow_slug: $flow_slug,
      operation: $operation,
      target: $target,
      validation_id: $validation_id,
      lane: $lane,
      capability: $capability,
      status: $status,
      finding_id: (if $finding_id == "" then null else $finding_id end),
      result_status: (if $result_status == "" then null else $result_status end),
      validation_created_at: $validation_created_at,
      validation_updated_at: $validation_updated_at,
      linked_at: $linked_at,
      linked_by: $linked_by,
      notes: $notes,
      metadata_only: true
    }' >>"$file"
}

atlas_flow_latest_approval_record() {
  local capability="$1"
  local file

  file="$(atlas_approval_file "$ATLAS_OP_DIR")"
  [ -s "$file" ] || return 0

  jq -cs \
    --arg capability "$capability" \
    --arg target "$ATLAS_OP_TARGET" '
      [.[] | select(
        .capability == $capability
        and .target == $target
        and .status == "approved"
      )]
      | sort_by(.ts // "")
      | last // empty
    ' "$file"
}

atlas_flow_approval_record_exists() {
  local capability="$1"
  local approval_ts="$2"
  local file

  file="$(atlas_approval_file "$ATLAS_OP_DIR")"
  [ -s "$file" ] || return 1

  jq -e \
    --arg capability "$capability" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg approval_ts "$approval_ts" '
      select(
        .capability == $capability
        and .target == $target
        and .ts == $approval_ts
        and .status == "approved"
      )
    ' "$file" >/dev/null
}

atlas_flow_approval_record_for_link() {
  local capability="$1"
  local approval_ts="$2"
  local file

  file="$(atlas_approval_file "$ATLAS_OP_DIR")"
  [ -s "$file" ] || return 0

  jq -c \
    --arg capability "$capability" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg approval_ts "$approval_ts" '
      select(
        .capability == $capability
        and .target == $target
        and .ts == $approval_ts
        and .status == "approved"
      )
    ' "$file" | head -n 1
}

atlas_flow_append_approval_link() {
  local file="$1"
  local approval_record="$2"
  local capability="$3"
  local linked_at="$4"
  local approval_ts
  local tier
  local status
  local approved_by
  local approval_ref

  intel_require_jq

  approval_ts="$(printf '%s\n' "$approval_record" | jq -r '.ts // ""')"
  tier="$(printf '%s\n' "$approval_record" | jq -r '.tier // "unknown"')"
  status="$(printf '%s\n' "$approval_record" | jq -r '.status // "unknown"')"
  approved_by="$(printf '%s\n' "$approval_record" | jq -r '.approved_by // "unknown"')"
  approval_ref="approval:${capability}:${approval_ts}"

  [ -n "$approval_ts" ] || fail "approval record missing timestamp: $capability"
  atlas_flow_validate_metadata_value "approval capability" "$capability"
  atlas_flow_validate_metadata_value "approval tier" "$tier"
  atlas_flow_validate_metadata_value "approval status" "$status"
  atlas_flow_validate_metadata_value "approved by" "$approved_by"
  atlas_flow_validate_metadata_value "approval ref" "$approval_ref"

  : >>"$file"
  chmod 600 "$file" 2>/dev/null || true

  jq -cn \
    --arg schema_version "atlas.flow_approval_link.v1" \
    --arg flow_id "$ATLAS_FLOW_ID" \
    --arg flow_slug "$ATLAS_FLOW_SLUG" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg approval_ref "$approval_ref" \
    --arg capability "$capability" \
    --arg tier "$tier" \
    --arg status "$status" \
    --arg approved_by "$approved_by" \
    --arg approval_ts "$approval_ts" \
    --arg linked_at "$linked_at" \
    --arg linked_by "atlas" \
    --arg notes "Metadata-only reference. Approval reason and operator notes are not embedded." \
    '{
      schema_version: $schema_version,
      flow_id: $flow_id,
      flow_slug: $flow_slug,
      operation: $operation,
      target: $target,
      approval_ref: $approval_ref,
      capability: $capability,
      tier: $tier,
      status: $status,
      approved_by: $approved_by,
      approval_ts: $approval_ts,
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

cmd_flow_link_finding() {
  need_args 2 "$#" "flow link-finding <flow> <finding-id>"
  local flow="$1"
  local finding_id="$2"
  local finding_record
  local linked_at
  local flow_links_file
  local finding_links_file
  local finding_title
  local finding_status
  local finding_severity

  atlas_flow_load "$flow"
  load_active_operation

  finding_record="$(atlas_findings_latest_record "$finding_id" || true)"
  [ -n "$finding_record" ] || fail "unknown finding id in active operation: $finding_id"

  linked_at="$(timestamp)"
  flow_links_file="$(atlas_flow_operation_links_file "$ATLAS_OP_DIR")"
  finding_links_file="$(atlas_flow_finding_links_file "$ATLAS_OP_DIR")"

  atlas_flow_append_operation_link "$flow_links_file" "$linked_at"
  atlas_flow_append_finding_link "$finding_links_file" "$finding_record" "$finding_id" "$linked_at"

  finding_title="$(printf '%s\n' "$finding_record" | jq -r '.title // ""')"
  finding_status="$(printf '%s\n' "$finding_record" | jq -r '.status // "unknown"')"
  finding_severity="$(printf '%s\n' "$finding_record" | jq -r '.severity // "unknown"')"

  atlas_ledger_append_current "flow.finding_linked" "read-only" "atlas" "ok" "flow_id=$ATLAS_FLOW_ID finding=$finding_id severity=$finding_severity status=$finding_status"

  ui_ok "business flow finding linked"
  printf 'flow_id: %s\n' "$ATLAS_FLOW_ID"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'finding_id: %s\n' "$finding_id"
  printf 'finding_title: %s\n' "$finding_title"
  printf 'link_path: %s\n' "$finding_links_file"
}

cmd_flow_link_validation() {
  need_args 2 "$#" "flow link-validation <flow> <validation-id>"
  local flow="$1"
  local validation_id="$2"
  local validation_record
  local linked_at
  local flow_links_file
  local validation_links_file
  local lane
  local status
  local finding_id

  atlas_flow_load "$flow"
  load_active_operation

  validation_record="$(atlas_validation_latest_record "$validation_id" || true)"
  [ -n "$validation_record" ] || fail "unknown validation id in active operation: $validation_id"

  linked_at="$(timestamp)"
  flow_links_file="$(atlas_flow_operation_links_file "$ATLAS_OP_DIR")"
  validation_links_file="$(atlas_flow_validation_links_file "$ATLAS_OP_DIR")"

  atlas_flow_append_operation_link "$flow_links_file" "$linked_at"
  atlas_flow_append_validation_link "$validation_links_file" "$validation_record" "$validation_id" "$linked_at"

  lane="$(printf '%s\n' "$validation_record" | jq -r '.lane // "unknown"')"
  status="$(printf '%s\n' "$validation_record" | jq -r '.status // "unknown"')"
  finding_id="$(printf '%s\n' "$validation_record" | jq -r '.finding // ""')"

  atlas_ledger_append_current "flow.validation_linked" "read-only" "atlas" "ok" "flow_id=$ATLAS_FLOW_ID validation=$validation_id lane=$lane status=$status finding=$finding_id"

  ui_ok "business flow validation linked"
  printf 'flow_id: %s\n' "$ATLAS_FLOW_ID"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'validation_id: %s\n' "$validation_id"
  printf 'lane: %s\n' "$lane"
  printf 'link_path: %s\n' "$validation_links_file"
}

cmd_flow_link_approval() {
  need_args 2 "$#" "flow link-approval <flow> <capability>"
  local flow="$1"
  local capability="$2"
  local approval_record
  local linked_at
  local flow_links_file
  local approval_links_file
  local approval_ts
  local tier
  local approved_by

  atlas_flow_load "$flow"
  load_active_operation
  atlas_flow_validate_metadata_value "approval capability" "$capability"

  approval_record="$(atlas_flow_latest_approval_record "$capability" || true)"
  [ -n "$approval_record" ] || fail "unknown approved capability in active operation: $capability"

  linked_at="$(timestamp)"
  flow_links_file="$(atlas_flow_operation_links_file "$ATLAS_OP_DIR")"
  approval_links_file="$(atlas_flow_approval_links_file "$ATLAS_OP_DIR")"

  atlas_flow_append_operation_link "$flow_links_file" "$linked_at"
  atlas_flow_append_approval_link "$approval_links_file" "$approval_record" "$capability" "$linked_at"

  approval_ts="$(printf '%s\n' "$approval_record" | jq -r '.ts // ""')"
  tier="$(printf '%s\n' "$approval_record" | jq -r '.tier // "unknown"')"
  approved_by="$(printf '%s\n' "$approval_record" | jq -r '.approved_by // "unknown"')"

  atlas_ledger_append_current "flow.approval_linked" "read-only" "atlas" "ok" "flow_id=$ATLAS_FLOW_ID capability=$capability tier=$tier approval_ts=$approval_ts"

  ui_ok "business flow approval linked"
  printf 'flow_id: %s\n' "$ATLAS_FLOW_ID"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'capability: %s\n' "$capability"
  printf 'tier: %s\n' "$tier"
  printf 'approval_ts: %s\n' "$approval_ts"
  printf 'approved_by: %s\n' "$approved_by"
  printf 'link_path: %s\n' "$approval_links_file"
}

atlas_flow_write_json_packet() {
  local packet_file="$1"
  local packet_name="$2"
  local generated_at="$3"
  local flow_file="$4"
  local flow_sha="$5"
  local evidence_links_file="$6"
  local evidence_link_count="$7"
  local latest_evidence_link="$8"
  local finding_links_file="$9"
  local finding_link_count="${10}"
  local latest_finding_link="${11}"
  local validation_links_file="${12}"
  local validation_link_count="${13}"
  local latest_validation_link="${14}"
  local approval_links_file="${15}"
  local approval_link_count="${16}"
  local latest_approval_link="${17}"
  local packet_slug
  local systems_json
  local data_classes_json
  local controls_json
  local evidence_refs_json
  local finding_refs_json
  local validation_refs_json
  local approval_refs_json

  packet_slug="$(atlas_flow_packet_slug_for "$packet_name")"
  systems_json="$(atlas_flow_csv_json_array "$ATLAS_FLOW_SYSTEMS")"
  data_classes_json="$(atlas_flow_csv_json_array "$ATLAS_FLOW_DATA_CLASSES")"
  controls_json="$(atlas_flow_csv_json_array "$ATLAS_FLOW_CONTROL_OBJECTIVES")"
  evidence_refs_json="$(atlas_flow_evidence_refs_json "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  finding_refs_json="$(atlas_flow_finding_refs_json "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  validation_refs_json="$(atlas_flow_validation_refs_json "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  approval_refs_json="$(atlas_flow_approval_refs_json "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"

  jq -n \
    --arg schema_version "atlas.business_flow_packet.v1" \
    --arg packet_id "$packet_slug" \
    --arg packet_name "$packet_slug" \
    --arg generated_at "$generated_at" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg flow_schema_version "$ATLAS_FLOW_SCHEMA_VERSION" \
    --arg flow_id "$ATLAS_FLOW_ID" \
    --arg flow_slug "$ATLAS_FLOW_SLUG" \
    --arg flow_name "$ATLAS_FLOW_NAME" \
    --arg flow_type "$ATLAS_FLOW_TYPE" \
    --arg owner "$ATLAS_FLOW_OWNER" \
    --arg criticality "$ATLAS_FLOW_CRITICALITY" \
    --arg environment "$ATLAS_FLOW_ENVIRONMENT" \
    --arg scope_status "$ATLAS_FLOW_SCOPE_STATUS" \
    --arg flow_record "$flow_file" \
    --arg flow_record_sha256 "$flow_sha" \
    --arg flow_created_at "$ATLAS_FLOW_CREATED_AT" \
    --arg flow_updated_at "$ATLAS_FLOW_UPDATED_AT" \
    --arg latest_evidence_link "${latest_evidence_link:-}" \
    --arg latest_finding_link "${latest_finding_link:-}" \
    --arg latest_validation_link "${latest_validation_link:-}" \
    --arg latest_approval_link "${latest_approval_link:-}" \
    --argjson evidence_link_count "$evidence_link_count" \
    --argjson finding_link_count "$finding_link_count" \
    --argjson validation_link_count "$validation_link_count" \
    --argjson approval_link_count "$approval_link_count" \
    --argjson systems "$systems_json" \
    --argjson data_classes "$data_classes_json" \
    --argjson control_objectives "$controls_json" \
    --argjson evidence_refs "$evidence_refs_json" \
    --argjson findings_refs "$finding_refs_json" \
    --argjson validation_refs "$validation_refs_json" \
    --argjson approval_refs "$approval_refs_json" \
    '{
      schema_version: $schema_version,
      packet_id: $packet_id,
      packet_name: $packet_name,
      generated_at: $generated_at,
      operation: $operation,
      target: $target,
      metadata_only: true,
      raw_evidence_embedded: false,
      metadata_boundary: {
        stores: [
          "flow labels",
          "operation labels",
          "evidence IDs",
          "hashes",
          "retained paths",
          "classifications",
          "approval metadata",
          "timestamps",
          "known limitations"
        ],
        excludes: [
          "raw evidence bodies",
          "customer records",
          "request bodies",
          "response bodies",
          "payment data",
          "credentials",
          "token-bearing values",
          "key material",
          "authorization headers"
        ]
      },
      flow: {
        schema_version: $flow_schema_version,
        flow_id: $flow_id,
        flow_slug: $flow_slug,
        flow_name: $flow_name,
        flow_type: $flow_type,
        owner: $owner,
        criticality: $criticality,
        environment: $environment,
        scope_status: $scope_status,
        record_path: $flow_record,
        record_sha256: $flow_record_sha256,
        created_at: $flow_created_at,
        updated_at: $flow_updated_at
      },
      systems: $systems,
      data_classes: $data_classes,
      control_objectives: $control_objectives,
      evidence_refs: $evidence_refs,
      findings_refs: $findings_refs,
      validation_refs: $validation_refs,
      approval_refs: $approval_refs,
      retention_refs: {},
      freshness: {
        status: "current",
        packet_generated_at: $generated_at,
        latest_evidence_link: (if $latest_evidence_link == "" then null else $latest_evidence_link end),
        latest_finding_link: (if $latest_finding_link == "" then null else $latest_finding_link end),
        latest_validation_link: (if $latest_validation_link == "" then null else $latest_validation_link end),
        latest_approval_link: (if $latest_approval_link == "" then null else $latest_approval_link end),
        evidence_link_count: $evidence_link_count,
        finding_link_count: $finding_link_count,
        validation_link_count: $validation_link_count,
        approval_link_count: $approval_link_count
      },
      known_limitations: [
        "This packet is metadata-only and does not embed raw evidence content.",
        "Flow verification checks packet metadata, evidence, finding, validation, and approval links, hashes, freshness, and forbidden-content guardrails.",
        "Approval reasons and operator notes are intentionally excluded from flow packets.",
        "Retention links are not included in this packet slice.",
        "This packet is not production certification, payment verification, legal compliance evidence, or a third-party audit."
      ]
    }' >"$packet_file"
}

cmd_flow_packet_markdown() {
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
  local finding_links_file
  local validation_links_file
  local approval_links_file
  local evidence_link_count
  local finding_link_count
  local validation_link_count
  local approval_link_count
  local latest_evidence_link
  local latest_finding_link
  local latest_validation_link
  local latest_approval_link

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
  finding_links_file="$(atlas_flow_finding_links_file "$ATLAS_OP_DIR")"
  validation_links_file="$(atlas_flow_validation_links_file "$ATLAS_OP_DIR")"
  approval_links_file="$(atlas_flow_approval_links_file "$ATLAS_OP_DIR")"

  if ! atlas_flow_operation_link_exists "$flow_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"; then
    fail "business flow has no links in active operation; run 'atlas flow link-evidence' first"
  fi

  evidence_link_count="$(atlas_flow_evidence_link_count "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  finding_link_count="$(atlas_flow_finding_link_count "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  validation_link_count="$(atlas_flow_validation_link_count "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  approval_link_count="$(atlas_flow_approval_link_count "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  [ "$evidence_link_count" -gt 0 ] || fail "business flow has no evidence links in active operation"

  generated_at="$(timestamp)"
  packet_dir="$(atlas_flow_packet_dir)"
  packet_file="$(atlas_flow_packet_path_for_name "$packet_name")"
  latest_evidence_link="$(atlas_flow_latest_evidence_linked_at "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  latest_finding_link="$(atlas_flow_latest_finding_linked_at "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  latest_validation_link="$(atlas_flow_latest_validation_linked_at "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  latest_approval_link="$(atlas_flow_latest_approval_linked_at "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"

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
    printf -- '- Stores flow labels, operation labels, evidence IDs, hashes, retained paths, classifications, approval metadata, timestamps, and known limitations.\n'
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
    atlas_flow_packet_finding_refs "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"
    printf '\n## Validation\n\n'
    atlas_flow_packet_validation_refs "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"
    printf '\n## Approvals\n\n'
    atlas_flow_packet_approval_refs "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"
    printf '\n## Freshness\n\n'
    printf -- '- Status: current\n'
    printf -- '- Packet Generated At: %s\n' "$generated_at"
    if [ -n "$latest_evidence_link" ]; then
      printf -- '- Latest Evidence Link: %s\n' "$latest_evidence_link"
    else
      printf -- '- Latest Evidence Link: none recorded\n'
    fi
    if [ -n "$latest_finding_link" ]; then
      printf -- '- Latest Finding Link: %s\n' "$latest_finding_link"
    else
      printf -- '- Latest Finding Link: none recorded\n'
    fi
    if [ -n "$latest_validation_link" ]; then
      printf -- '- Latest Validation Link: %s\n' "$latest_validation_link"
    else
      printf -- '- Latest Validation Link: none recorded\n'
    fi
    if [ -n "$latest_approval_link" ]; then
      printf -- '- Latest Approval Link: %s\n' "$latest_approval_link"
    else
      printf -- '- Latest Approval Link: none recorded\n'
    fi
    printf -- '- Evidence Link Count: %s\n' "$evidence_link_count"
    printf -- '- Finding Link Count: %s\n' "$finding_link_count"
    printf -- '- Validation Link Count: %s\n' "$validation_link_count"
    printf -- '- Approval Link Count: %s\n' "$approval_link_count"
    printf '\n## Known Limitations\n\n'
    printf -- '- This packet is metadata-only and does not embed raw evidence content.\n'
    printf -- '- Flow verification checks packet metadata, evidence, finding, validation, and approval links, hashes, freshness, and forbidden-content guardrails.\n'
    printf -- '- Approval reasons and operator notes are intentionally excluded from flow packets.\n'
    printf -- '- Retention links are not included in this packet slice.\n'
    printf -- '- This packet is not production certification, payment verification, legal compliance evidence, or a third-party audit.\n'
  } >"$packet_file"

  chmod 600 "$packet_file" 2>/dev/null || true
  if ! atlas_flow_validate_packet_file "$packet_file"; then
    rm -f "$packet_file"
    fail "business-flow packet failed metadata-only validation"
  fi

  atlas_ledger_append_current "flow.packet.generated" "read-only" "atlas" "ok" "flow_id=$ATLAS_FLOW_ID packet=$packet_file evidence_links=$evidence_link_count finding_links=$finding_link_count validation_links=$validation_link_count approval_links=$approval_link_count"

  ui_ok "business flow packet written"
  printf 'flow_id: %s\n' "$ATLAS_FLOW_ID"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'packet: %s\n' "$packet_file"
}

cmd_flow_packet_json() {
  need_args 1 "$#" "flow packet --json <flow> [packet-name]"
  [ "$#" -le 2 ] || fail "flow packet --json <flow> [packet-name]"

  local flow="$1"
  local packet_name="${2:-}"
  local generated_at
  local packet_file
  local packet_dir
  local flow_file
  local flow_sha
  local flow_links_file
  local evidence_links_file
  local finding_links_file
  local validation_links_file
  local approval_links_file
  local evidence_link_count
  local finding_link_count
  local validation_link_count
  local approval_link_count
  local latest_evidence_link
  local latest_finding_link
  local latest_validation_link
  local latest_approval_link

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
  finding_links_file="$(atlas_flow_finding_links_file "$ATLAS_OP_DIR")"
  validation_links_file="$(atlas_flow_validation_links_file "$ATLAS_OP_DIR")"
  approval_links_file="$(atlas_flow_approval_links_file "$ATLAS_OP_DIR")"

  if ! atlas_flow_operation_link_exists "$flow_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"; then
    fail "business flow has no links in active operation; run 'atlas flow link-evidence' first"
  fi

  evidence_link_count="$(atlas_flow_evidence_link_count "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  finding_link_count="$(atlas_flow_finding_link_count "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  validation_link_count="$(atlas_flow_validation_link_count "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  approval_link_count="$(atlas_flow_approval_link_count "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  [ "$evidence_link_count" -gt 0 ] || fail "business flow has no evidence links in active operation"

  generated_at="$(timestamp)"
  packet_dir="$(atlas_flow_packet_json_dir)"
  packet_file="$(atlas_flow_packet_json_path_for_name "$packet_name")"
  latest_evidence_link="$(atlas_flow_latest_evidence_linked_at "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  latest_finding_link="$(atlas_flow_latest_finding_linked_at "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  latest_validation_link="$(atlas_flow_latest_validation_linked_at "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  latest_approval_link="$(atlas_flow_latest_approval_linked_at "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"

  mkdir -p "$packet_dir"
  chmod 700 "$packet_dir" 2>/dev/null || true
  atlas_flow_write_json_packet "$packet_file" "$packet_name" "$generated_at" "$flow_file" "$flow_sha" "$evidence_links_file" "$evidence_link_count" "$latest_evidence_link" "$finding_links_file" "$finding_link_count" "$latest_finding_link" "$validation_links_file" "$validation_link_count" "$latest_validation_link" "$approval_links_file" "$approval_link_count" "$latest_approval_link"

  chmod 600 "$packet_file" 2>/dev/null || true
  if ! atlas_flow_validate_json_packet_file "$packet_file"; then
    rm -f "$packet_file"
    fail "business-flow JSON packet failed metadata-only validation"
  fi

  atlas_ledger_append_current "flow.packet.generated" "read-only" "atlas" "ok" "flow_id=$ATLAS_FLOW_ID packet=$packet_file format=json evidence_links=$evidence_link_count finding_links=$finding_link_count validation_links=$validation_link_count approval_links=$approval_link_count"

  ui_ok "business flow JSON packet written"
  printf 'flow_id: %s\n' "$ATLAS_FLOW_ID"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'packet_json: %s\n' "$packet_file"
}

cmd_flow_packet() {
  local json=0
  local flow=""
  local packet_name=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail "unknown flow packet option: $1"
      ;;
    *)
      if [ -z "$flow" ]; then
        flow="$1"
      elif [ -z "$packet_name" ]; then
        packet_name="$1"
      else
        fail "flow packet [--json] <flow> [packet-name]"
      fi
      shift
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "flow packet [--json] <flow> [packet-name]"
  [ -n "$flow" ] || fail "flow packet [--json] <flow> [packet-name]"

  if [ "$json" -eq 1 ]; then
    cmd_flow_packet_json "$flow" "$packet_name"
  else
    cmd_flow_packet_markdown "$flow" "$packet_name"
  fi
}

cmd_flow_verify_markdown() {
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
  local finding_links_file
  local validation_links_file
  local approval_links_file
  local expected_count
  local packet_count
  local evidence_count_stale=0
  local expected_finding_count
  local packet_finding_count
  local finding_count_stale=0
  local expected_validation_count
  local packet_validation_count
  local validation_count_stale=0
  local expected_approval_count
  local packet_approval_count
  local approval_count_stale=0
  local generated_at
  local latest_evidence_link
  local latest_finding_link
  local latest_validation_link
  local latest_approval_link
  local link_json
  local evidence_id
  local finding_id
  local validation_id
  local approval_ref
  local link_path
  local link_sha
  local link_classification
  local link_redacted
  local link_linked_at
  local link_title
  local link_level
  local link_severity
  local link_confidence
  local link_status
  local link_lane
  local link_capability
  local link_finding_id
  local link_result_status
  local link_tier
  local link_approved_by
  local link_approval_ts
  local record
  local record_path
  local record_sha
  local record_classification
  local record_redacted
  local record_title
  local record_level
  local record_severity
  local record_confidence
  local record_status
  local record_lane
  local record_capability
  local record_finding_id
  local record_result_status
  local record_tier
  local record_approved_by
  local record_approval_ts
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
  finding_links_file="$(atlas_flow_finding_links_file "$ATLAS_OP_DIR")"
  validation_links_file="$(atlas_flow_validation_links_file "$ATLAS_OP_DIR")"
  approval_links_file="$(atlas_flow_approval_links_file "$ATLAS_OP_DIR")"

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

  expected_finding_count="$(atlas_flow_finding_link_count "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_finding_count="$(atlas_flow_packet_field "$packet_file" "Finding Link Count")"
  if [ -z "$packet_finding_count" ] && [ "$expected_finding_count" = "0" ]; then
    packet_finding_count="0"
  fi
  if [ "$packet_finding_count" = "$expected_finding_count" ]; then
    atlas_flow_verify_row "Finding Count" "ok" "$packet_finding_count"
  else
    finding_count_stale=1
    atlas_flow_verify_row "Finding Count" "stale" "expected=$expected_finding_count actual=${packet_finding_count:-missing}"
  fi

  latest_finding_link="$(atlas_flow_latest_finding_linked_at "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_finding_link" "$generated_at"; then
    atlas_flow_verify_row "Finding Freshness" "stale" "latest_finding_link=$latest_finding_link packet_generated=$generated_at"
  else
    atlas_flow_verify_row "Finding Freshness" "ok" "latest_finding_link=${latest_finding_link:-none} packet_generated=${generated_at:-missing}"
  fi

  expected_validation_count="$(atlas_flow_validation_link_count "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_validation_count="$(atlas_flow_packet_field "$packet_file" "Validation Link Count")"
  if [ -z "$packet_validation_count" ] && [ "$expected_validation_count" = "0" ]; then
    packet_validation_count="0"
  fi
  if [ "$packet_validation_count" = "$expected_validation_count" ]; then
    atlas_flow_verify_row "Validation Count" "ok" "$packet_validation_count"
  else
    validation_count_stale=1
    atlas_flow_verify_row "Validation Count" "stale" "expected=$expected_validation_count actual=${packet_validation_count:-missing}"
  fi

  latest_validation_link="$(atlas_flow_latest_validation_linked_at "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_validation_link" "$generated_at"; then
    atlas_flow_verify_row "Validation Freshness" "stale" "latest_validation_link=$latest_validation_link packet_generated=$generated_at"
  else
    atlas_flow_verify_row "Validation Freshness" "ok" "latest_validation_link=${latest_validation_link:-none} packet_generated=${generated_at:-missing}"
  fi

  expected_approval_count="$(atlas_flow_approval_link_count "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_approval_count="$(atlas_flow_packet_field "$packet_file" "Approval Link Count")"
  if [ -z "$packet_approval_count" ] && [ "$expected_approval_count" = "0" ]; then
    packet_approval_count="0"
  fi
  if [ "$packet_approval_count" = "$expected_approval_count" ]; then
    atlas_flow_verify_row "Approval Count" "ok" "$packet_approval_count"
  else
    approval_count_stale=1
    atlas_flow_verify_row "Approval Count" "stale" "expected=$expected_approval_count actual=${packet_approval_count:-missing}"
  fi

  latest_approval_link="$(atlas_flow_latest_approval_linked_at "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_approval_link" "$generated_at"; then
    atlas_flow_verify_row "Approval Freshness" "stale" "latest_approval_link=$latest_approval_link packet_generated=$generated_at"
  else
    atlas_flow_verify_row "Approval Freshness" "ok" "latest_approval_link=${latest_approval_link:-none} packet_generated=${generated_at:-missing}"
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

  while IFS= read -r link_json; do
    [ -n "$link_json" ] || continue
    finding_id="$(printf '%s\n' "$link_json" | jq -r '.finding_id // ""')"
    link_title="$(printf '%s\n' "$link_json" | jq -r '.title // ""')"
    link_level="$(printf '%s\n' "$link_json" | jq -r '.level // ""')"
    link_severity="$(printf '%s\n' "$link_json" | jq -r '.severity // ""')"
    link_confidence="$(printf '%s\n' "$link_json" | jq -r '.confidence // ""')"
    link_status="$(printf '%s\n' "$link_json" | jq -r '.status // ""')"
    link_linked_at="$(printf '%s\n' "$link_json" | jq -r '.linked_at // ""')"

    if [ -z "$finding_id" ]; then
      atlas_flow_verify_row "Finding Record" "blocked" "link missing finding id"
      continue
    fi

    if atlas_flow_packet_contains_value "$packet_file" "Finding ID" "$finding_id"; then
      atlas_flow_verify_row "Finding $finding_id" "ok" "packet reference present"
    elif [ "$finding_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_row "Finding $finding_id" "stale" "link newer than packet or count mismatch"
    else
      atlas_flow_verify_row "Finding $finding_id" "blocked" "packet reference missing"
    fi

    record="$(atlas_findings_latest_record "$finding_id" || true)"
    if [ -z "$record" ]; then
      atlas_flow_verify_row "Finding Record" "blocked" "missing current record for $finding_id"
      continue
    fi

    record_title="$(printf '%s\n' "$record" | jq -r '.title // ""')"
    record_level="$(printf '%s\n' "$record" | jq -r '.level // ""')"
    record_severity="$(printf '%s\n' "$record" | jq -r '.severity // ""')"
    record_confidence="$(printf '%s\n' "$record" | jq -r '.confidence // ""')"
    record_status="$(printf '%s\n' "$record" | jq -r '.status // ""')"

    if [ "$record_title" = "$link_title" ] &&
      [ "$record_level" = "$link_level" ] &&
      [ "$record_severity" = "$link_severity" ] &&
      [ "$record_confidence" = "$link_confidence" ] &&
      [ "$record_status" = "$link_status" ]; then
      atlas_flow_verify_row "Finding Metadata" "ok" "$finding_id status=$record_status severity=$record_severity"
    else
      atlas_flow_verify_row "Finding Metadata" "stale" "finding=$finding_id current metadata differs from linked snapshot"
    fi
  done < <(
    if [ -s "$finding_links_file" ]; then
      jq -c \
        --arg flow_id "$ATLAS_FLOW_ID" \
        --arg operation "$ATLAS_OP_SLUG" \
        'select(.flow_id == $flow_id and .operation == $operation)' \
        "$finding_links_file"
    fi
  )

  while IFS= read -r link_json; do
    [ -n "$link_json" ] || continue
    validation_id="$(printf '%s\n' "$link_json" | jq -r '.validation_id // ""')"
    link_lane="$(printf '%s\n' "$link_json" | jq -r '.lane // ""')"
    link_capability="$(printf '%s\n' "$link_json" | jq -r '.capability // ""')"
    link_status="$(printf '%s\n' "$link_json" | jq -r '.status // ""')"
    link_finding_id="$(printf '%s\n' "$link_json" | jq -r '.finding_id // ""')"
    link_result_status="$(printf '%s\n' "$link_json" | jq -r '.result_status // ""')"
    link_linked_at="$(printf '%s\n' "$link_json" | jq -r '.linked_at // ""')"

    if [ -z "$validation_id" ]; then
      atlas_flow_verify_row "Validation Record" "blocked" "link missing validation id"
      continue
    fi

    if atlas_flow_packet_contains_value "$packet_file" "Validation ID" "$validation_id"; then
      atlas_flow_verify_row "Validation $validation_id" "ok" "packet reference present"
    elif [ "$validation_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_row "Validation $validation_id" "stale" "link newer than packet or count mismatch"
    else
      atlas_flow_verify_row "Validation $validation_id" "blocked" "packet reference missing"
    fi

    record="$(atlas_validation_latest_record "$validation_id" || true)"
    if [ -z "$record" ]; then
      atlas_flow_verify_row "Validation Record" "blocked" "missing current record for $validation_id"
      continue
    fi

    record_lane="$(printf '%s\n' "$record" | jq -r '.lane // ""')"
    record_capability="$(printf '%s\n' "$record" | jq -r '.capability // ""')"
    record_status="$(printf '%s\n' "$record" | jq -r '.status // ""')"
    record_finding_id="$(printf '%s\n' "$record" | jq -r '.finding // ""')"
    record_result_status="$(printf '%s\n' "$record" | jq -r '.result_status // ""')"

    if [ "$record_lane" = "$link_lane" ] &&
      [ "$record_capability" = "$link_capability" ] &&
      [ "$record_status" = "$link_status" ] &&
      [ "$record_finding_id" = "$link_finding_id" ] &&
      [ "$record_result_status" = "$link_result_status" ]; then
      atlas_flow_verify_row "Validation Metadata" "ok" "$validation_id status=$record_status lane=$record_lane"
    else
      atlas_flow_verify_row "Validation Metadata" "stale" "validation=$validation_id current metadata differs from linked snapshot"
    fi
  done < <(
    if [ -s "$validation_links_file" ]; then
      jq -c \
        --arg flow_id "$ATLAS_FLOW_ID" \
        --arg operation "$ATLAS_OP_SLUG" \
        'select(.flow_id == $flow_id and .operation == $operation)' \
        "$validation_links_file"
    fi
  )

  while IFS= read -r link_json; do
    [ -n "$link_json" ] || continue
    approval_ref="$(printf '%s\n' "$link_json" | jq -r '.approval_ref // ""')"
    link_capability="$(printf '%s\n' "$link_json" | jq -r '.capability // ""')"
    link_tier="$(printf '%s\n' "$link_json" | jq -r '.tier // ""')"
    link_status="$(printf '%s\n' "$link_json" | jq -r '.status // ""')"
    link_approved_by="$(printf '%s\n' "$link_json" | jq -r '.approved_by // ""')"
    link_approval_ts="$(printf '%s\n' "$link_json" | jq -r '.approval_ts // ""')"
    link_linked_at="$(printf '%s\n' "$link_json" | jq -r '.linked_at // ""')"

    if [ -z "$approval_ref" ]; then
      atlas_flow_verify_row "Approval Record" "blocked" "link missing approval ref"
      continue
    fi

    if atlas_flow_packet_contains_value "$packet_file" "Approval Ref" "$approval_ref"; then
      atlas_flow_verify_row "Approval $link_capability" "ok" "packet reference present"
    elif [ "$approval_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_row "Approval $link_capability" "stale" "link newer than packet or count mismatch"
    else
      atlas_flow_verify_row "Approval $link_capability" "blocked" "packet reference missing"
    fi

    if ! atlas_flow_approval_record_exists "$link_capability" "$link_approval_ts"; then
      atlas_flow_verify_row "Approval Record" "blocked" "missing current approved record for $link_capability at $link_approval_ts"
      continue
    fi

    record="$(atlas_flow_approval_record_for_link "$link_capability" "$link_approval_ts" || true)"
    record_tier="$(printf '%s\n' "$record" | jq -r '.tier // ""')"
    record_status="$(printf '%s\n' "$record" | jq -r '.status // ""')"
    record_approved_by="$(printf '%s\n' "$record" | jq -r '.approved_by // ""')"
    record_approval_ts="$(printf '%s\n' "$record" | jq -r '.ts // ""')"

    if atlas_flow_packet_contains_value "$packet_file" "Capability" "$link_capability" &&
      atlas_flow_packet_contains_value "$packet_file" "Tier" "$link_tier" &&
      atlas_flow_packet_contains_value "$packet_file" "Status" "$link_status" &&
      atlas_flow_packet_contains_value "$packet_file" "Approved By" "$link_approved_by" &&
      atlas_flow_packet_contains_value "$packet_file" "Approval Timestamp" "$link_approval_ts"; then
      atlas_flow_verify_row "Packet Approval" "ok" "$link_capability metadata matches"
    elif [ "$approval_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_row "Packet Approval" "stale" "$link_capability link newer than packet or count mismatch"
    else
      atlas_flow_verify_row "Packet Approval" "blocked" "$link_capability metadata missing or mismatched"
    fi

    if [ "$record_tier" = "$link_tier" ] &&
      [ "$record_status" = "$link_status" ] &&
      [ "$record_approved_by" = "$link_approved_by" ] &&
      [ "$record_approval_ts" = "$link_approval_ts" ]; then
      atlas_flow_verify_row "Approval Metadata" "ok" "$link_capability status=$record_status tier=$record_tier"
    else
      atlas_flow_verify_row "Approval Metadata" "stale" "approval=$link_capability current metadata differs from linked snapshot"
    fi
  done < <(
    if [ -s "$approval_links_file" ]; then
      jq -c \
        --arg flow_id "$ATLAS_FLOW_ID" \
        --arg operation "$ATLAS_OP_SLUG" \
        'select(.flow_id == $flow_id and .operation == $operation)' \
        "$approval_links_file"
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

atlas_flow_verify_json_row() {
  local rows_file="$1"
  local check="$2"
  local status="$3"
  local detail="$4"

  printf '%s\t%s\t%s\n' "$check" "$status" "$detail" >>"$rows_file"
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

atlas_flow_verify_json_print() {
  local rows_file="$1"
  local packet_file="$2"

  jq -Rn \
    --arg schema_version "atlas.business_flow_verify.v1" \
    --arg flow_id "$ATLAS_FLOW_ID" \
    --arg flow_slug "$ATLAS_FLOW_SLUG" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg packet "$packet_file" \
    --arg packet_format "json" \
    --arg overall "$ATLAS_FLOW_VERIFY_OVERALL" \
    --argjson failures "$ATLAS_FLOW_VERIFY_FAILURES" '
      [inputs | split("\t")] as $rows
      | {
          schema_version: $schema_version,
          flow_id: $flow_id,
          flow_slug: $flow_slug,
          operation: $operation,
          target: $target,
          packet: $packet,
          packet_format: $packet_format,
          overall: $overall,
          failures: $failures,
          checks: (
            $rows
            | map({
                check: .[0],
                status: .[1],
                detail: .[2]
              })
          )
        }
    ' <"$rows_file"
}

cmd_flow_verify_json() {
  need_args 1 "$#" "flow verify --json <flow> [packet-name]"
  [ "$#" -le 2 ] || fail "flow verify --json <flow> [packet-name]"

  local flow="$1"
  local packet_name="${2:-}"
  local packet_file
  local flow_file
  local flow_sha
  local packet_flow_sha
  local packet_flow_id
  local packet_operation
  local packet_target
  local flow_links_file
  local evidence_links_file
  local finding_links_file
  local validation_links_file
  local approval_links_file
  local expected_count
  local packet_count
  local evidence_count_stale=0
  local expected_finding_count
  local packet_finding_count
  local finding_count_stale=0
  local expected_validation_count
  local packet_validation_count
  local validation_count_stale=0
  local expected_approval_count
  local packet_approval_count
  local approval_count_stale=0
  local generated_at
  local latest_evidence_link
  local latest_finding_link
  local latest_validation_link
  local latest_approval_link
  local link_json
  local evidence_id
  local finding_id
  local validation_id
  local approval_ref
  local link_path
  local link_sha
  local link_classification
  local link_redacted
  local link_linked_at
  local link_title
  local link_level
  local link_severity
  local link_confidence
  local link_status
  local link_lane
  local link_capability
  local link_finding_id
  local link_result_status
  local link_tier
  local link_approved_by
  local link_approval_ts
  local packet_ref
  local packet_ref_path
  local packet_ref_sha
  local packet_ref_classification
  local packet_ref_redacted
  local packet_ref_title
  local packet_ref_level
  local packet_ref_severity
  local packet_ref_confidence
  local packet_ref_status
  local packet_ref_lane
  local packet_ref_capability
  local packet_ref_finding_id
  local packet_ref_result_status
  local packet_ref_tier
  local packet_ref_approved_by
  local packet_ref_approval_ts
  local record
  local record_path
  local record_sha
  local record_classification
  local record_redacted
  local record_title
  local record_level
  local record_severity
  local record_confidence
  local record_status
  local record_lane
  local record_capability
  local record_finding_id
  local record_result_status
  local record_tier
  local record_approved_by
  local record_approval_ts
  local evidence_file
  local actual_sha
  local rows_file
  local exit_status=0

  atlas_flow_load "$flow"
  load_active_operation
  intel_require_jq

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_FLOW_SLUG-flow-packet"
  fi

  packet_file="$(atlas_flow_packet_json_path_for_name "$packet_name")"
  flow_file="$(atlas_flow_file_for_slug "$ATLAS_FLOW_SLUG")"
  flow_sha="$(atlas_evidence_hash_path "$flow_file")"
  flow_links_file="$(atlas_flow_operation_links_file "$ATLAS_OP_DIR")"
  evidence_links_file="$(atlas_flow_evidence_links_file "$ATLAS_OP_DIR")"
  finding_links_file="$(atlas_flow_finding_links_file "$ATLAS_OP_DIR")"
  validation_links_file="$(atlas_flow_validation_links_file "$ATLAS_OP_DIR")"
  approval_links_file="$(atlas_flow_approval_links_file "$ATLAS_OP_DIR")"
  rows_file="$(mktemp)"

  atlas_flow_verify_reset

  if [ -f "$packet_file" ]; then
    atlas_flow_verify_json_row "$rows_file" "Packet" "ok" "$packet_file"
  else
    atlas_flow_verify_json_row "$rows_file" "Packet" "blocked" "missing"
    atlas_flow_verify_json_print "$rows_file" "$packet_file"
    rm -f "$rows_file"
    return 1
  fi

  if jq -e 'type == "object"' "$packet_file" >/dev/null 2>&1; then
    atlas_flow_verify_json_row "$rows_file" "JSON" "ok" "object"
  else
    atlas_flow_verify_json_row "$rows_file" "JSON" "blocked" "invalid or non-object"
    atlas_flow_verify_json_print "$rows_file" "$packet_file"
    rm -f "$rows_file"
    return 1
  fi

  if atlas_flow_json_packet_forbidden_content_present "$packet_file"; then
    atlas_flow_verify_json_row "$rows_file" "Forbidden Content" "blocked" "forbidden raw-content marker detected"
  else
    atlas_flow_verify_json_row "$rows_file" "Forbidden Content" "ok" "absent"
  fi

  if jq -e '.schema_version == "atlas.business_flow_packet.v1"' "$packet_file" >/dev/null 2>&1; then
    atlas_flow_verify_json_row "$rows_file" "Schema" "ok" "atlas.business_flow_packet.v1"
  else
    atlas_flow_verify_json_row "$rows_file" "Schema" "blocked" "missing or mismatched"
  fi

  if jq -e '.metadata_only == true' "$packet_file" >/dev/null 2>&1; then
    atlas_flow_verify_json_row "$rows_file" "Metadata Only" "ok" "true"
  else
    atlas_flow_verify_json_row "$rows_file" "Metadata Only" "blocked" "expected=true"
  fi

  if jq -e '.raw_evidence_embedded == false' "$packet_file" >/dev/null 2>&1; then
    atlas_flow_verify_json_row "$rows_file" "Raw Evidence Embedded" "ok" "false"
  else
    atlas_flow_verify_json_row "$rows_file" "Raw Evidence Embedded" "blocked" "expected=false"
  fi

  packet_operation="$(jq -r '.operation // ""' "$packet_file" 2>/dev/null || true)"
  if [ "$packet_operation" = "$ATLAS_OP_SLUG" ]; then
    atlas_flow_verify_json_row "$rows_file" "Operation" "ok" "$packet_operation"
  else
    atlas_flow_verify_json_row "$rows_file" "Operation" "blocked" "expected=$ATLAS_OP_SLUG actual=${packet_operation:-missing}"
  fi

  packet_target="$(jq -r '.target // ""' "$packet_file" 2>/dev/null || true)"
  if [ "$packet_target" = "$ATLAS_OP_TARGET" ]; then
    atlas_flow_verify_json_row "$rows_file" "Target" "ok" "$packet_target"
  else
    atlas_flow_verify_json_row "$rows_file" "Target" "blocked" "expected=$ATLAS_OP_TARGET actual=${packet_target:-missing}"
  fi

  packet_flow_id="$(jq -r '.flow.flow_id // ""' "$packet_file" 2>/dev/null || true)"
  if [ "$packet_flow_id" = "$ATLAS_FLOW_ID" ]; then
    atlas_flow_verify_json_row "$rows_file" "Flow ID" "ok" "$packet_flow_id"
  else
    atlas_flow_verify_json_row "$rows_file" "Flow ID" "blocked" "expected=$ATLAS_FLOW_ID actual=${packet_flow_id:-missing}"
  fi

  packet_flow_sha="$(jq -r '.flow.record_sha256 // ""' "$packet_file" 2>/dev/null || true)"
  if [ "$packet_flow_sha" = "$flow_sha" ]; then
    atlas_flow_verify_json_row "$rows_file" "Flow Record Hash" "ok" "$flow_sha"
  else
    atlas_flow_verify_json_row "$rows_file" "Flow Record Hash" "stale" "expected=$flow_sha actual=${packet_flow_sha:-missing}"
  fi

  generated_at="$(jq -r '.freshness.packet_generated_at // .generated_at // ""' "$packet_file" 2>/dev/null || true)"
  if [ -n "$generated_at" ]; then
    atlas_flow_verify_json_row "$rows_file" "Generated At" "ok" "$generated_at"
  else
    atlas_flow_verify_json_row "$rows_file" "Generated At" "blocked" "missing"
  fi

  if atlas_flow_operation_link_exists "$flow_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG"; then
    atlas_flow_verify_json_row "$rows_file" "Operation Link" "ok" "$flow_links_file"
  else
    atlas_flow_verify_json_row "$rows_file" "Operation Link" "blocked" "missing flow link in active operation"
  fi

  expected_count="$(atlas_flow_evidence_link_count "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_count="$(jq -r '.freshness.evidence_link_count // ""' "$packet_file" 2>/dev/null || true)"
  if [ "$expected_count" -gt 0 ]; then
    atlas_flow_verify_json_row "$rows_file" "Evidence Links" "ok" "$expected_count"
  else
    atlas_flow_verify_json_row "$rows_file" "Evidence Links" "blocked" "none linked"
  fi

  if [ "$packet_count" = "$expected_count" ]; then
    atlas_flow_verify_json_row "$rows_file" "Evidence Count" "ok" "$packet_count"
  else
    evidence_count_stale=1
    atlas_flow_verify_json_row "$rows_file" "Evidence Count" "stale" "expected=$expected_count actual=${packet_count:-missing}"
  fi

  latest_evidence_link="$(atlas_flow_latest_evidence_linked_at "$evidence_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_evidence_link" "$generated_at"; then
    atlas_flow_verify_json_row "$rows_file" "Freshness" "stale" "latest_evidence_link=$latest_evidence_link packet_generated=$generated_at"
  else
    atlas_flow_verify_json_row "$rows_file" "Freshness" "ok" "latest_evidence_link=${latest_evidence_link:-none} packet_generated=${generated_at:-missing}"
  fi

  expected_finding_count="$(atlas_flow_finding_link_count "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_finding_count="$(jq -r '.freshness.finding_link_count // ""' "$packet_file" 2>/dev/null || true)"
  if [ -z "$packet_finding_count" ] && [ "$expected_finding_count" = "0" ]; then
    packet_finding_count="0"
  fi
  if [ "$packet_finding_count" = "$expected_finding_count" ]; then
    atlas_flow_verify_json_row "$rows_file" "Finding Count" "ok" "$packet_finding_count"
  else
    finding_count_stale=1
    atlas_flow_verify_json_row "$rows_file" "Finding Count" "stale" "expected=$expected_finding_count actual=${packet_finding_count:-missing}"
  fi

  latest_finding_link="$(atlas_flow_latest_finding_linked_at "$finding_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_finding_link" "$generated_at"; then
    atlas_flow_verify_json_row "$rows_file" "Finding Freshness" "stale" "latest_finding_link=$latest_finding_link packet_generated=$generated_at"
  else
    atlas_flow_verify_json_row "$rows_file" "Finding Freshness" "ok" "latest_finding_link=${latest_finding_link:-none} packet_generated=${generated_at:-missing}"
  fi

  expected_validation_count="$(atlas_flow_validation_link_count "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_validation_count="$(jq -r '.freshness.validation_link_count // ""' "$packet_file" 2>/dev/null || true)"
  if [ -z "$packet_validation_count" ] && [ "$expected_validation_count" = "0" ]; then
    packet_validation_count="0"
  fi
  if [ "$packet_validation_count" = "$expected_validation_count" ]; then
    atlas_flow_verify_json_row "$rows_file" "Validation Count" "ok" "$packet_validation_count"
  else
    validation_count_stale=1
    atlas_flow_verify_json_row "$rows_file" "Validation Count" "stale" "expected=$expected_validation_count actual=${packet_validation_count:-missing}"
  fi

  latest_validation_link="$(atlas_flow_latest_validation_linked_at "$validation_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_validation_link" "$generated_at"; then
    atlas_flow_verify_json_row "$rows_file" "Validation Freshness" "stale" "latest_validation_link=$latest_validation_link packet_generated=$generated_at"
  else
    atlas_flow_verify_json_row "$rows_file" "Validation Freshness" "ok" "latest_validation_link=${latest_validation_link:-none} packet_generated=${generated_at:-missing}"
  fi

  expected_approval_count="$(atlas_flow_approval_link_count "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  packet_approval_count="$(jq -r '.freshness.approval_link_count // ""' "$packet_file" 2>/dev/null || true)"
  if [ -z "$packet_approval_count" ] && [ "$expected_approval_count" = "0" ]; then
    packet_approval_count="0"
  fi
  if [ "$packet_approval_count" = "$expected_approval_count" ]; then
    atlas_flow_verify_json_row "$rows_file" "Approval Count" "ok" "$packet_approval_count"
  else
    approval_count_stale=1
    atlas_flow_verify_json_row "$rows_file" "Approval Count" "stale" "expected=$expected_approval_count actual=${packet_approval_count:-missing}"
  fi

  latest_approval_link="$(atlas_flow_latest_approval_linked_at "$approval_links_file" "$ATLAS_FLOW_ID" "$ATLAS_OP_SLUG")"
  if atlas_flow_timestamp_after "$latest_approval_link" "$generated_at"; then
    atlas_flow_verify_json_row "$rows_file" "Approval Freshness" "stale" "latest_approval_link=$latest_approval_link packet_generated=$generated_at"
  else
    atlas_flow_verify_json_row "$rows_file" "Approval Freshness" "ok" "latest_approval_link=${latest_approval_link:-none} packet_generated=${generated_at:-missing}"
  fi

  if atlas_flow_timestamp_after "$ATLAS_FLOW_UPDATED_AT" "$generated_at"; then
    atlas_flow_verify_json_row "$rows_file" "Flow Freshness" "stale" "flow_updated=$ATLAS_FLOW_UPDATED_AT packet_generated=$generated_at"
  else
    atlas_flow_verify_json_row "$rows_file" "Flow Freshness" "ok" "flow_updated=${ATLAS_FLOW_UPDATED_AT:-unknown}"
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
      atlas_flow_verify_json_row "$rows_file" "Evidence Record" "blocked" "link missing evidence id"
      continue
    fi

    packet_ref="$(jq -c --arg evidence_id "$evidence_id" '[.evidence_refs[]? | select(.evidence_id == $evidence_id)] | first // empty' "$packet_file" 2>/dev/null || true)"
    if [ -n "$packet_ref" ]; then
      atlas_flow_verify_json_row "$rows_file" "Evidence $evidence_id" "ok" "packet reference present"
      packet_ref_path="$(printf '%s\n' "$packet_ref" | jq -r '.path // ""')"
      packet_ref_sha="$(printf '%s\n' "$packet_ref" | jq -r '.sha256 // ""')"
      packet_ref_classification="$(printf '%s\n' "$packet_ref" | jq -r '.classification // ""')"
      packet_ref_redacted="$(printf '%s\n' "$packet_ref" | jq -r '(.redacted // false) | tostring')"
    elif [ "$evidence_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Evidence $evidence_id" "stale" "link newer than packet or count mismatch"
      packet_ref_path=""
      packet_ref_sha=""
      packet_ref_classification=""
      packet_ref_redacted=""
    else
      atlas_flow_verify_json_row "$rows_file" "Evidence $evidence_id" "blocked" "packet reference missing"
      packet_ref_path=""
      packet_ref_sha=""
      packet_ref_classification=""
      packet_ref_redacted=""
    fi

    record="$(atlas_evidence_latest_record "$evidence_id" || true)"
    if [ -z "$record" ]; then
      atlas_flow_verify_json_row "$rows_file" "Evidence Record" "blocked" "missing current record for $evidence_id"
      continue
    fi

    record_path="$(printf '%s\n' "$record" | jq -r '.path // ""')"
    record_sha="$(printf '%s\n' "$record" | jq -r '.sha256 // ""')"
    record_classification="$(printf '%s\n' "$record" | jq -r '.classification // ""')"
    record_redacted="$(printf '%s\n' "$record" | jq -r '(.redacted // false) | tostring')"

    if [ "$record_path" = "$link_path" ]; then
      atlas_flow_verify_json_row "$rows_file" "Evidence Path" "ok" "$evidence_id $record_path"
    else
      atlas_flow_verify_json_row "$rows_file" "Evidence Path" "blocked" "evidence=$evidence_id expected=$record_path actual=${link_path:-missing}"
    fi

    if [ "$record_sha" = "$link_sha" ] && [ -n "$record_sha" ]; then
      atlas_flow_verify_json_row "$rows_file" "Evidence Hash" "ok" "$evidence_id $record_sha"
    else
      atlas_flow_verify_json_row "$rows_file" "Evidence Hash" "blocked" "evidence=$evidence_id expected=$record_sha actual=${link_sha:-missing}"
    fi

    if [ "$packet_ref_path" = "$link_path" ] &&
      [ "$packet_ref_sha" = "$link_sha" ] &&
      [ "$packet_ref_classification" = "$link_classification" ] &&
      [ "$packet_ref_redacted" = "$link_redacted" ]; then
      atlas_flow_verify_json_row "$rows_file" "Packet Evidence" "ok" "$evidence_id metadata matches"
    elif [ "$evidence_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Packet Evidence" "stale" "$evidence_id link newer than packet or count mismatch"
    else
      atlas_flow_verify_json_row "$rows_file" "Packet Evidence" "blocked" "$evidence_id metadata missing or mismatched"
    fi

    if [ "$record_classification" != "$link_classification" ] || [ "$record_redacted" != "$link_redacted" ]; then
      atlas_flow_verify_json_row "$rows_file" "Evidence Metadata" "blocked" "evidence=$evidence_id classification/redaction mismatch"
    else
      atlas_flow_verify_json_row "$rows_file" "Evidence Metadata" "ok" "$evidence_id classification=$record_classification redacted=$record_redacted"
    fi

    evidence_file="$ATLAS_OP_DIR/$record_path"
    if [ -f "$evidence_file" ]; then
      actual_sha="$(atlas_evidence_hash_path "$evidence_file")"
      if [ "$actual_sha" = "$record_sha" ]; then
        atlas_flow_verify_json_row "$rows_file" "Evidence File" "ok" "$evidence_id actual hash matches"
      else
        atlas_flow_verify_json_row "$rows_file" "Evidence File" "blocked" "evidence=$evidence_id actual hash mismatch expected=$record_sha actual=$actual_sha"
      fi
    else
      atlas_flow_verify_json_row "$rows_file" "Evidence File" "blocked" "missing retained file for $evidence_id: $record_path"
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

  while IFS= read -r link_json; do
    [ -n "$link_json" ] || continue
    finding_id="$(printf '%s\n' "$link_json" | jq -r '.finding_id // ""')"
    link_title="$(printf '%s\n' "$link_json" | jq -r '.title // ""')"
    link_level="$(printf '%s\n' "$link_json" | jq -r '.level // ""')"
    link_severity="$(printf '%s\n' "$link_json" | jq -r '.severity // ""')"
    link_confidence="$(printf '%s\n' "$link_json" | jq -r '.confidence // ""')"
    link_status="$(printf '%s\n' "$link_json" | jq -r '.status // ""')"
    link_linked_at="$(printf '%s\n' "$link_json" | jq -r '.linked_at // ""')"

    if [ -z "$finding_id" ]; then
      atlas_flow_verify_json_row "$rows_file" "Finding Record" "blocked" "link missing finding id"
      continue
    fi

    packet_ref="$(jq -c --arg finding_id "$finding_id" '[.findings_refs[]? | select(.finding_id == $finding_id)] | first // empty' "$packet_file" 2>/dev/null || true)"
    if [ -n "$packet_ref" ]; then
      atlas_flow_verify_json_row "$rows_file" "Finding $finding_id" "ok" "packet reference present"
      packet_ref_title="$(printf '%s\n' "$packet_ref" | jq -r '.title // ""')"
      packet_ref_level="$(printf '%s\n' "$packet_ref" | jq -r '.level // ""')"
      packet_ref_severity="$(printf '%s\n' "$packet_ref" | jq -r '.severity // ""')"
      packet_ref_confidence="$(printf '%s\n' "$packet_ref" | jq -r '.confidence // ""')"
      packet_ref_status="$(printf '%s\n' "$packet_ref" | jq -r '.status // ""')"
    elif [ "$finding_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Finding $finding_id" "stale" "link newer than packet or count mismatch"
      packet_ref_title=""
      packet_ref_level=""
      packet_ref_severity=""
      packet_ref_confidence=""
      packet_ref_status=""
    else
      atlas_flow_verify_json_row "$rows_file" "Finding $finding_id" "blocked" "packet reference missing"
      packet_ref_title=""
      packet_ref_level=""
      packet_ref_severity=""
      packet_ref_confidence=""
      packet_ref_status=""
    fi

    record="$(atlas_findings_latest_record "$finding_id" || true)"
    if [ -z "$record" ]; then
      atlas_flow_verify_json_row "$rows_file" "Finding Record" "blocked" "missing current record for $finding_id"
      continue
    fi

    record_title="$(printf '%s\n' "$record" | jq -r '.title // ""')"
    record_level="$(printf '%s\n' "$record" | jq -r '.level // ""')"
    record_severity="$(printf '%s\n' "$record" | jq -r '.severity // ""')"
    record_confidence="$(printf '%s\n' "$record" | jq -r '.confidence // ""')"
    record_status="$(printf '%s\n' "$record" | jq -r '.status // ""')"

    if [ "$packet_ref_title" = "$link_title" ] &&
      [ "$packet_ref_level" = "$link_level" ] &&
      [ "$packet_ref_severity" = "$link_severity" ] &&
      [ "$packet_ref_confidence" = "$link_confidence" ] &&
      [ "$packet_ref_status" = "$link_status" ]; then
      atlas_flow_verify_json_row "$rows_file" "Packet Finding" "ok" "$finding_id metadata matches"
    elif [ "$finding_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Packet Finding" "stale" "$finding_id link newer than packet or count mismatch"
    else
      atlas_flow_verify_json_row "$rows_file" "Packet Finding" "blocked" "$finding_id metadata missing or mismatched"
    fi

    if [ "$record_title" = "$link_title" ] &&
      [ "$record_level" = "$link_level" ] &&
      [ "$record_severity" = "$link_severity" ] &&
      [ "$record_confidence" = "$link_confidence" ] &&
      [ "$record_status" = "$link_status" ]; then
      atlas_flow_verify_json_row "$rows_file" "Finding Metadata" "ok" "$finding_id status=$record_status severity=$record_severity"
    else
      atlas_flow_verify_json_row "$rows_file" "Finding Metadata" "stale" "finding=$finding_id current metadata differs from linked snapshot"
    fi
  done < <(
    if [ -s "$finding_links_file" ]; then
      jq -c \
        --arg flow_id "$ATLAS_FLOW_ID" \
        --arg operation "$ATLAS_OP_SLUG" \
        'select(.flow_id == $flow_id and .operation == $operation)' \
        "$finding_links_file"
    fi
  )

  while IFS= read -r link_json; do
    [ -n "$link_json" ] || continue
    validation_id="$(printf '%s\n' "$link_json" | jq -r '.validation_id // ""')"
    link_lane="$(printf '%s\n' "$link_json" | jq -r '.lane // ""')"
    link_capability="$(printf '%s\n' "$link_json" | jq -r '.capability // ""')"
    link_status="$(printf '%s\n' "$link_json" | jq -r '.status // ""')"
    link_finding_id="$(printf '%s\n' "$link_json" | jq -r '.finding_id // ""')"
    link_result_status="$(printf '%s\n' "$link_json" | jq -r '.result_status // ""')"
    link_linked_at="$(printf '%s\n' "$link_json" | jq -r '.linked_at // ""')"

    if [ -z "$validation_id" ]; then
      atlas_flow_verify_json_row "$rows_file" "Validation Record" "blocked" "link missing validation id"
      continue
    fi

    packet_ref="$(jq -c --arg validation_id "$validation_id" '[.validation_refs[]? | select(.validation_id == $validation_id)] | first // empty' "$packet_file" 2>/dev/null || true)"
    if [ -n "$packet_ref" ]; then
      atlas_flow_verify_json_row "$rows_file" "Validation $validation_id" "ok" "packet reference present"
      packet_ref_lane="$(printf '%s\n' "$packet_ref" | jq -r '.lane // ""')"
      packet_ref_capability="$(printf '%s\n' "$packet_ref" | jq -r '.capability // ""')"
      packet_ref_status="$(printf '%s\n' "$packet_ref" | jq -r '.status // ""')"
      packet_ref_finding_id="$(printf '%s\n' "$packet_ref" | jq -r '.finding_id // ""')"
      packet_ref_result_status="$(printf '%s\n' "$packet_ref" | jq -r '.result_status // ""')"
    elif [ "$validation_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Validation $validation_id" "stale" "link newer than packet or count mismatch"
      packet_ref_lane=""
      packet_ref_capability=""
      packet_ref_status=""
      packet_ref_finding_id=""
      packet_ref_result_status=""
    else
      atlas_flow_verify_json_row "$rows_file" "Validation $validation_id" "blocked" "packet reference missing"
      packet_ref_lane=""
      packet_ref_capability=""
      packet_ref_status=""
      packet_ref_finding_id=""
      packet_ref_result_status=""
    fi

    record="$(atlas_validation_latest_record "$validation_id" || true)"
    if [ -z "$record" ]; then
      atlas_flow_verify_json_row "$rows_file" "Validation Record" "blocked" "missing current record for $validation_id"
      continue
    fi

    record_lane="$(printf '%s\n' "$record" | jq -r '.lane // ""')"
    record_capability="$(printf '%s\n' "$record" | jq -r '.capability // ""')"
    record_status="$(printf '%s\n' "$record" | jq -r '.status // ""')"
    record_finding_id="$(printf '%s\n' "$record" | jq -r '.finding // ""')"
    record_result_status="$(printf '%s\n' "$record" | jq -r '.result_status // ""')"

    if [ "$packet_ref_lane" = "$link_lane" ] &&
      [ "$packet_ref_capability" = "$link_capability" ] &&
      [ "$packet_ref_status" = "$link_status" ] &&
      [ "$packet_ref_finding_id" = "$link_finding_id" ] &&
      [ "$packet_ref_result_status" = "$link_result_status" ]; then
      atlas_flow_verify_json_row "$rows_file" "Packet Validation" "ok" "$validation_id metadata matches"
    elif [ "$validation_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Packet Validation" "stale" "$validation_id link newer than packet or count mismatch"
    else
      atlas_flow_verify_json_row "$rows_file" "Packet Validation" "blocked" "$validation_id metadata missing or mismatched"
    fi

    if [ "$record_lane" = "$link_lane" ] &&
      [ "$record_capability" = "$link_capability" ] &&
      [ "$record_status" = "$link_status" ] &&
      [ "$record_finding_id" = "$link_finding_id" ] &&
      [ "$record_result_status" = "$link_result_status" ]; then
      atlas_flow_verify_json_row "$rows_file" "Validation Metadata" "ok" "$validation_id status=$record_status lane=$record_lane"
    else
      atlas_flow_verify_json_row "$rows_file" "Validation Metadata" "stale" "validation=$validation_id current metadata differs from linked snapshot"
    fi
  done < <(
    if [ -s "$validation_links_file" ]; then
      jq -c \
        --arg flow_id "$ATLAS_FLOW_ID" \
        --arg operation "$ATLAS_OP_SLUG" \
        'select(.flow_id == $flow_id and .operation == $operation)' \
        "$validation_links_file"
    fi
  )

  while IFS= read -r link_json; do
    [ -n "$link_json" ] || continue
    approval_ref="$(printf '%s\n' "$link_json" | jq -r '.approval_ref // ""')"
    link_capability="$(printf '%s\n' "$link_json" | jq -r '.capability // ""')"
    link_tier="$(printf '%s\n' "$link_json" | jq -r '.tier // ""')"
    link_status="$(printf '%s\n' "$link_json" | jq -r '.status // ""')"
    link_approved_by="$(printf '%s\n' "$link_json" | jq -r '.approved_by // ""')"
    link_approval_ts="$(printf '%s\n' "$link_json" | jq -r '.approval_ts // ""')"
    link_linked_at="$(printf '%s\n' "$link_json" | jq -r '.linked_at // ""')"

    if [ -z "$approval_ref" ]; then
      atlas_flow_verify_json_row "$rows_file" "Approval Record" "blocked" "link missing approval ref"
      continue
    fi

    packet_ref="$(jq -c --arg approval_ref "$approval_ref" '[.approval_refs[]? | select(.approval_ref == $approval_ref)] | first // empty' "$packet_file" 2>/dev/null || true)"
    if [ -n "$packet_ref" ]; then
      atlas_flow_verify_json_row "$rows_file" "Approval $link_capability" "ok" "packet reference present"
      packet_ref_capability="$(printf '%s\n' "$packet_ref" | jq -r '.capability // ""')"
      packet_ref_tier="$(printf '%s\n' "$packet_ref" | jq -r '.tier // ""')"
      packet_ref_status="$(printf '%s\n' "$packet_ref" | jq -r '.status // ""')"
      packet_ref_approved_by="$(printf '%s\n' "$packet_ref" | jq -r '.approved_by // ""')"
      packet_ref_approval_ts="$(printf '%s\n' "$packet_ref" | jq -r '.approval_ts // ""')"
    elif [ "$approval_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Approval $link_capability" "stale" "link newer than packet or count mismatch"
      packet_ref_capability=""
      packet_ref_tier=""
      packet_ref_status=""
      packet_ref_approved_by=""
      packet_ref_approval_ts=""
    else
      atlas_flow_verify_json_row "$rows_file" "Approval $link_capability" "blocked" "packet reference missing"
      packet_ref_capability=""
      packet_ref_tier=""
      packet_ref_status=""
      packet_ref_approved_by=""
      packet_ref_approval_ts=""
    fi

    record="$(atlas_flow_approval_record_for_link "$link_capability" "$link_approval_ts" || true)"
    if [ -z "$record" ]; then
      atlas_flow_verify_json_row "$rows_file" "Approval Record" "blocked" "missing current approved record for $link_capability at $link_approval_ts"
      continue
    fi

    record_tier="$(printf '%s\n' "$record" | jq -r '.tier // ""')"
    record_status="$(printf '%s\n' "$record" | jq -r '.status // ""')"
    record_approved_by="$(printf '%s\n' "$record" | jq -r '.approved_by // ""')"
    record_approval_ts="$(printf '%s\n' "$record" | jq -r '.ts // ""')"

    if [ "$packet_ref_capability" = "$link_capability" ] &&
      [ "$packet_ref_tier" = "$link_tier" ] &&
      [ "$packet_ref_status" = "$link_status" ] &&
      [ "$packet_ref_approved_by" = "$link_approved_by" ] &&
      [ "$packet_ref_approval_ts" = "$link_approval_ts" ]; then
      atlas_flow_verify_json_row "$rows_file" "Packet Approval" "ok" "$link_capability metadata matches"
    elif [ "$approval_count_stale" -eq 1 ] || atlas_flow_timestamp_after "$link_linked_at" "$generated_at"; then
      atlas_flow_verify_json_row "$rows_file" "Packet Approval" "stale" "$link_capability link newer than packet or count mismatch"
    else
      atlas_flow_verify_json_row "$rows_file" "Packet Approval" "blocked" "$link_capability metadata missing or mismatched"
    fi

    if [ "$record_tier" = "$link_tier" ] &&
      [ "$record_status" = "$link_status" ] &&
      [ "$record_approved_by" = "$link_approved_by" ] &&
      [ "$record_approval_ts" = "$link_approval_ts" ]; then
      atlas_flow_verify_json_row "$rows_file" "Approval Metadata" "ok" "$link_capability status=$record_status tier=$record_tier"
    else
      atlas_flow_verify_json_row "$rows_file" "Approval Metadata" "stale" "approval=$link_capability current metadata differs from linked snapshot"
    fi
  done < <(
    if [ -s "$approval_links_file" ]; then
      jq -c \
        --arg flow_id "$ATLAS_FLOW_ID" \
        --arg operation "$ATLAS_OP_SLUG" \
        'select(.flow_id == $flow_id and .operation == $operation)' \
        "$approval_links_file"
    fi
  )

  atlas_flow_verify_json_print "$rows_file" "$packet_file"
  if [ "$ATLAS_FLOW_VERIFY_FAILURES" -ne 0 ]; then
    exit_status=1
  fi
  rm -f "$rows_file"
  return "$exit_status"
}

cmd_flow_verify() {
  local json=0
  local flow=""
  local packet_name=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail "unknown flow verify option: $1"
      ;;
    *)
      if [ -z "$flow" ]; then
        flow="$1"
      elif [ -z "$packet_name" ]; then
        packet_name="$1"
      else
        fail "flow verify [--json] <flow> [packet-name]"
      fi
      shift
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "flow verify [--json] <flow> [packet-name]"
  [ -n "$flow" ] || fail "flow verify [--json] <flow> [packet-name]"

  if [ "$json" -eq 1 ]; then
    cmd_flow_verify_json "$flow" "$packet_name"
  else
    cmd_flow_verify_markdown "$flow" "$packet_name"
  fi
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
  link-finding)
    shift
    cmd_flow_link_finding "$@"
    ;;
  link-validation)
    shift
    cmd_flow_link_validation "$@"
    ;;
  link-approval)
    shift
    cmd_flow_link_approval "$@"
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
