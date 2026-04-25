#!/usr/bin/env bash

atlas_evidence_dir() {
  local op_dir="$1"

  printf '%s/evidence\n' "$op_dir"
}

atlas_evidence_index_file() {
  local op_dir="$1"

  printf '%s/evidence.ndjson\n' "$op_dir"
}

atlas_evidence_require_hash_tool() {
  command -v sha256sum >/dev/null 2>&1 || fail "command not found: sha256sum"
}

atlas_evidence_hash_path() {
  local path="$1"

  atlas_evidence_require_hash_tool
  sha256sum "$path" | awk '{ print $1 }'
}

atlas_evidence_safe_name() {
  local path="$1"
  local base
  local safe

  base="$(basename "$path")"
  safe="$(slugify "$base")"
  if [ -z "$safe" ]; then
    safe="artifact"
  fi
  printf '%s\n' "$safe"
}

atlas_evidence_next_id() {
  local evidence_dir="$1"
  local base
  local candidate
  local index=1

  base="ev_$(date -u +%Y%m%dT%H%M%SZ)"
  candidate="$base"

  while [ -e "$evidence_dir/$candidate" ]; do
    index=$((index + 1))
    candidate="$(printf '%s_%02d' "$base" "$index")"
  done

  printf '%s\n' "$candidate"
}

atlas_evidence_validate_bool() {
  case "$1" in
  true | false)
    return 0
    ;;
  *)
    fail "expected boolean true or false, got: $1"
    ;;
  esac
}

atlas_evidence_append_record() {
  local id="$1"
  local target="$2"
  local kind="$3"
  local source_path="$4"
  local stored_path="$5"
  local sha256="$6"
  local classification="$7"
  local redacted="$8"
  local index_file

  intel_require_jq
  atlas_evidence_validate_bool "$redacted"

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  : >>"$index_file"
  chmod 600 "$index_file" 2>/dev/null || true

  jq -cn \
    --arg id "$id" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$target" \
    --arg kind "$kind" \
    --arg source_tool "atlas" \
    --arg source_path "$source_path" \
    --arg path "$stored_path" \
    --arg sha256 "$sha256" \
    --arg created_at "$(timestamp)" \
    --arg classification "$classification" \
    --argjson redacted "$redacted" \
    '{
      id: $id,
      operation: $operation,
      target: $target,
      kind: $kind,
      source_tool: $source_tool,
      source_path: $source_path,
      path: $path,
      sha256: $sha256,
      created_at: $created_at,
      classification: $classification,
      redacted: $redacted
    }' >>"$index_file"
}

cmd_evidence_hash() {
  need_args 1 "$#" "evidence hash <path>"
  local path="$1"

  [ -f "$path" ] || fail "evidence path is not a file: $path"
  printf 'sha256: %s\n' "$(atlas_evidence_hash_path "$path")"
}

cmd_evidence_add() {
  need_args 1 "$#" "evidence add <path> [--kind kind] [--target target] [--classification label] [--redacted true|false]"
  local source_path="$1"
  local kind="artifact"
  local target=""
  local classification="internal"
  local redacted="false"
  local evidence_root
  local evidence_id
  local evidence_dir
  local file_name
  local relative_path
  local destination
  local sha256
  local copied_sha256

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --kind)
      need_args 2 "$#" "evidence add <path> --kind <kind>"
      kind="$2"
      shift 2
      ;;
    --target)
      need_args 2 "$#" "evidence add <path> --target <target>"
      target="$2"
      shift 2
      ;;
    --classification)
      need_args 2 "$#" "evidence add <path> --classification <label>"
      classification="$2"
      shift 2
      ;;
    --redacted)
      need_args 2 "$#" "evidence add <path> --redacted <true|false>"
      redacted="$2"
      shift 2
      ;;
    *)
      fail "unknown evidence add option: $1"
      ;;
    esac
  done

  [ -f "$source_path" ] || fail "evidence path is not a file: $source_path"
  atlas_evidence_validate_bool "$redacted"

  load_active_operation
  if [ -z "$target" ]; then
    target="$ATLAS_OP_TARGET"
  fi
  atlas_scope_preflight "read-only" "atlas" "$target" "add evidence artifact"

  evidence_root="$(atlas_evidence_dir "$ATLAS_OP_DIR")"
  mkdir -p "$evidence_root"
  chmod 700 "$evidence_root" 2>/dev/null || true

  evidence_id="$(atlas_evidence_next_id "$evidence_root")"
  evidence_dir="$evidence_root/$evidence_id"
  mkdir -p "$evidence_dir"
  chmod 700 "$evidence_dir" 2>/dev/null || true

  file_name="$(atlas_evidence_safe_name "$source_path")"
  relative_path="evidence/$evidence_id/$file_name"
  destination="$ATLAS_OP_DIR/$relative_path"

  sha256="$(atlas_evidence_hash_path "$source_path")"
  cp -- "$source_path" "$destination"
  chmod 600 "$destination" 2>/dev/null || true
  copied_sha256="$(atlas_evidence_hash_path "$destination")"
  [ "$sha256" = "$copied_sha256" ] || fail "evidence copy integrity check failed"

  atlas_evidence_append_record "$evidence_id" "$target" "$kind" "$source_path" "$relative_path" "$sha256" "$classification" "$redacted"
  atlas_ledger_append_current "artifact.created" "read-only" "atlas" "ok" "evidence=$evidence_id kind=$kind sha256=$sha256 path=$relative_path"

  ui_ok "evidence added"
  printf 'id: %s\n' "$evidence_id"
  printf 'kind: %s\n' "$kind"
  printf 'target: %s\n' "$target"
  printf 'sha256: %s\n' "$sha256"
  printf 'path: %s\n' "$destination"
}

cmd_evidence_list() {
  local index_file

  load_active_operation
  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"

  ui_heading "Evidence"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Store" "$index_file"
  ui_rule

  if [ ! -s "$index_file" ]; then
    ui_note "no evidence recorded yet"
    return 0
  fi

  jq -r '
    [
      (.id // "?"),
      (.created_at // "?"),
      (.kind // "?"),
      (.target // "?"),
      (.sha256 // "?"),
      (.path // "?")
    ]
    | @tsv
  ' "$index_file" |
    awk -F'\t' '{ printf "%-22s %-20s %-16s %-16s %-64s %s\n", $1, $2, $3, $4, $5, $6 }'
}

cmd_evidence_show() {
  need_args 1 "$#" "evidence show <id>"
  local evidence_id="$1"
  local index_file
  local output

  load_active_operation
  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || fail "unknown evidence: $evidence_id"

  output="$(
    jq -r \
      --arg evidence_id "$evidence_id" '
        select(.id == $evidence_id)
        | [
          (.id // "?"),
          (.operation // "?"),
          (.target // "?"),
          (.kind // "?"),
          (.classification // "?"),
          ((.redacted // false) | tostring),
          (.sha256 // "?"),
          (.path // "?"),
          (.created_at // "?")
        ]
        | @tsv
      ' "$index_file" |
      head -n 1
  )"
  [ -n "$output" ] || fail "unknown evidence: $evidence_id"

  IFS=$'\t' read -r evidence_id operation target kind classification redacted sha256 path created_at <<<"$output"

  ui_heading "Evidence Record"
  ui_rule
  ui_kv "ID" "$evidence_id"
  ui_kv "Operation" "$operation"
  ui_kv "Target" "$target"
  ui_kv "Kind" "$kind"
  ui_kv "Classification" "$classification"
  ui_kv "Redacted" "$redacted"
  ui_kv "SHA256" "$sha256"
  ui_kv "Path" "$ATLAS_OP_DIR/$path"
  ui_kv "Created" "$created_at"
}
