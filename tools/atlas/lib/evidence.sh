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

atlas_evidence_latest_record() {
  local evidence_id="$1"
  local index_file

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 1

  jq -sr \
    --arg evidence_id "$evidence_id" '
      map(select(.id == $evidence_id))
      | last // empty
    ' "$index_file"
}

atlas_evidence_append_redaction_record() {
  local id="$1"
  local target="$2"
  local kind="$3"
  local source_path="$4"
  local stored_path="$5"
  local sha256="$6"
  local classification="$7"
  local created_at="$8"
  local redacted_source_path="$9"
  local redacted_path="${10}"
  local redacted_sha256="${11}"
  local redaction_note="${12}"
  local index_file

  intel_require_jq

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
    --arg created_at "$created_at" \
    --arg updated_at "$(timestamp)" \
    --arg classification "$classification" \
    --arg redacted_source_path "$redacted_source_path" \
    --arg redacted_path "$redacted_path" \
    --arg redacted_sha256 "$redacted_sha256" \
    --arg redacted_at "$(timestamp)" \
    --arg redaction_note "$redaction_note" \
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
      updated_at: $updated_at,
      classification: $classification,
      redacted: true,
      redacted_source_path: $redacted_source_path,
      redacted_path: $redacted_path,
      redacted_sha256: $redacted_sha256,
      redacted_at: $redacted_at,
      redaction_note: $redaction_note
    }' >>"$index_file"
}

atlas_evidence_bundle_rows() {
  local include_unredacted="$1"
  local index_file

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" \
    --argjson include_unredacted "$include_unredacted" '
      def bundle_source:
        if ((.redacted // false) == true and (.redacted_path // "") != "") then
          ["redacted", (.redacted_path // ""), (.redacted_sha256 // "")]
        elif ((.redacted // false) == true) then
          ["redacted", (.path // ""), (.sha256 // "")]
        elif (.classification // "internal") == "public" then
          ["public", (.path // ""), (.sha256 // "")]
        elif $include_unredacted == 1 then
          ["unredacted", (.path // ""), (.sha256 // "")]
        else
          empty
        end;
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(.target == $target))
      | sort_by(.created_at, .id)
      | .[]
      | bundle_source as $source
      | [
          (.id // "?"),
          (.kind // "?"),
          (.classification // "internal"),
          ((.redacted // false) | tostring),
          (.path // ""),
          (.sha256 // ""),
          $source[0],
          $source[1],
          $source[2]
        ]
      | @tsv
    ' "$index_file"
}

atlas_evidence_bundle_blocked_count() {
  local index_file

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(
          .target == $target
          and (.redacted // false) == false
          and (.classification // "internal") != "public"
        ))
      | length
    ' "$index_file"
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

cmd_evidence_redact() {
  need_args 2 "$#" "evidence redact <id> <redacted-path> [--classification label] [--note text]"
  local evidence_id="$1"
  local redacted_source_path="$2"
  local classification=""
  local note=""
  local record
  local output
  local operation
  local target
  local kind
  local source_path
  local stored_path
  local sha256
  local classification_from_record
  local created_at
  local redacted_root
  local file_name
  local relative_path
  local destination
  local redacted_sha256
  local copied_sha256

  shift 2
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --classification)
      need_args 2 "$#" "evidence redact <id> <redacted-path> --classification <label>"
      classification="$2"
      shift 2
      ;;
    --note)
      need_args 2 "$#" "evidence redact <id> <redacted-path> --note <text>"
      note="$2"
      shift 2
      ;;
    *)
      fail "unknown evidence redact option: $1"
      ;;
    esac
  done

  [ -f "$redacted_source_path" ] || fail "redacted evidence path is not a file: $redacted_source_path"

  load_active_operation
  record="$(atlas_evidence_latest_record "$evidence_id" || true)"
  [ -n "$record" ] || fail "unknown evidence: $evidence_id"

  output="$(
    printf '%s\n' "$record" |
      jq -r '
        [
          (.operation // ""),
          (.target // ""),
          (.kind // ""),
          (.source_path // ""),
          (.path // ""),
          (.sha256 // ""),
          (.classification // "internal"),
          (.created_at // "")
        ]
        | @tsv
      '
  )"
  IFS=$'\t' read -r operation target kind source_path stored_path sha256 classification_from_record created_at <<<"$output"

  if [ "$operation" != "$ATLAS_OP_SLUG" ]; then
    fail "evidence '$evidence_id' does not belong to active operation '$ATLAS_OP_SLUG'"
  fi
  [ -n "$classification" ] || classification="$classification_from_record"
  atlas_scope_preflight "read-only" "atlas" "$target" "attach redacted evidence artifact"

  redacted_root="$ATLAS_OP_DIR/evidence/$evidence_id/redacted"
  mkdir -p "$redacted_root"
  chmod 700 "$redacted_root" 2>/dev/null || true

  file_name="$(atlas_evidence_safe_name "$redacted_source_path")"
  if [ -e "$redacted_root/$file_name" ]; then
    file_name="$(date -u +%Y%m%dT%H%M%SZ)-$file_name"
  fi
  relative_path="evidence/$evidence_id/redacted/$file_name"
  destination="$ATLAS_OP_DIR/$relative_path"

  redacted_sha256="$(atlas_evidence_hash_path "$redacted_source_path")"
  cp -- "$redacted_source_path" "$destination"
  chmod 600 "$destination" 2>/dev/null || true
  copied_sha256="$(atlas_evidence_hash_path "$destination")"
  [ "$redacted_sha256" = "$copied_sha256" ] || fail "redacted evidence copy integrity check failed"

  atlas_evidence_append_redaction_record "$evidence_id" "$target" "$kind" "$source_path" "$stored_path" "$sha256" "$classification" "$created_at" "$redacted_source_path" "$relative_path" "$redacted_sha256" "$note"
  atlas_ledger_append_current "artifact.redacted" "read-only" "atlas" "ok" "evidence=$evidence_id redacted_sha256=$redacted_sha256 path=$relative_path"

  ui_ok "evidence redacted"
  printf 'id: %s\n' "$evidence_id"
  printf 'target: %s\n' "$target"
  printf 'classification: %s\n' "$classification"
  printf 'redacted_sha256: %s\n' "$redacted_sha256"
  printf 'redacted_path: %s\n' "$destination"
}

cmd_evidence_bundle() {
  local bundle_name=""
  local include_unredacted=0
  local index_file
  local blocked_count
  local bundle_slug
  local bundle_root
  local bundle_dir
  local files_dir
  local manifest_file
  local readme_file
  local evidence_id
  local kind
  local classification
  local redacted
  local original_path
  local original_sha256
  local included_as
  local source_path
  local source_sha256
  local source_abs
  local file_name
  local bundle_rel_path
  local bundle_abs_path
  local bundled_sha256
  local count=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --include-unredacted)
      include_unredacted=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail "unknown evidence bundle option: $1"
      ;;
    *)
      if [ -n "$bundle_name" ]; then
        fail "unexpected evidence bundle argument: $1"
      fi
      bundle_name="$1"
      shift
      ;;
    esac
  done

  if [ "$#" -gt 0 ]; then
    if [ -n "$bundle_name" ]; then
      fail "unexpected evidence bundle argument: $1"
    fi
    bundle_name="$1"
    shift
  fi
  [ "$#" -eq 0 ] || fail "unexpected evidence bundle argument: $1"

  load_active_operation
  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || fail "no evidence recorded yet"

  blocked_count="$(atlas_evidence_bundle_blocked_count)"
  if [ "$include_unredacted" -ne 1 ] && [ "$blocked_count" -gt 0 ]; then
    fail "redaction required before bundling: $blocked_count non-public evidence record(s) are unredacted"
  fi

  if [ -z "$bundle_name" ]; then
    bundle_name="$ATLAS_OP_SLUG-evidence-bundle"
  fi
  bundle_slug="$(slugify "$bundle_name")"
  [ -n "$bundle_slug" ] || fail "evidence bundle name produced an empty slug"

  bundle_root="$ATLAS_OP_DIR/evidence-bundles"
  bundle_dir="$bundle_root/$bundle_slug"
  files_dir="$bundle_dir/files"
  manifest_file="$bundle_dir/manifest.ndjson"
  readme_file="$bundle_dir/README.md"

  [ ! -e "$bundle_dir" ] || fail "evidence bundle already exists: $bundle_slug"
  mkdir -p "$files_dir"
  chmod 700 "$bundle_root" "$bundle_dir" "$files_dir" 2>/dev/null || true
  : >"$manifest_file"
  chmod 600 "$manifest_file" 2>/dev/null || true

  while IFS=$'\t' read -r evidence_id kind classification redacted original_path original_sha256 included_as source_path source_sha256; do
    [ -n "$evidence_id" ] || continue
    [ -n "$source_path" ] || fail "evidence '$evidence_id' has no bundle source path"
    source_abs="$ATLAS_OP_DIR/$source_path"
    [ -f "$source_abs" ] || fail "missing bundle source for evidence '$evidence_id': $source_abs"

    file_name="$(atlas_evidence_safe_name "$source_path")"
    bundle_rel_path="files/$evidence_id-$included_as-$file_name"
    bundle_abs_path="$bundle_dir/$bundle_rel_path"

    cp -- "$source_abs" "$bundle_abs_path"
    chmod 600 "$bundle_abs_path" 2>/dev/null || true
    bundled_sha256="$(atlas_evidence_hash_path "$bundle_abs_path")"
    if [ -n "$source_sha256" ]; then
      [ "$bundled_sha256" = "$source_sha256" ] || fail "bundle copy integrity check failed for evidence '$evidence_id'"
    fi

    jq -cn \
      --arg id "$evidence_id" \
      --arg operation "$ATLAS_OP_SLUG" \
      --arg target "$ATLAS_OP_TARGET" \
      --arg kind "$kind" \
      --arg classification "$classification" \
      --arg redacted "$redacted" \
      --arg original_path "$original_path" \
      --arg original_sha256 "$original_sha256" \
      --arg included_as "$included_as" \
      --arg source_path "$source_path" \
      --arg source_sha256 "$source_sha256" \
      --arg bundle_path "$bundle_rel_path" \
      --arg bundled_sha256 "$bundled_sha256" \
      --arg bundled_at "$(timestamp)" \
      '{
        id: $id,
        operation: $operation,
        target: $target,
        kind: $kind,
        classification: $classification,
        redacted: ($redacted == "true"),
        original_path: $original_path,
        original_sha256: $original_sha256,
        included_as: $included_as,
        source_path: $source_path,
        source_sha256: $source_sha256,
        bundle_path: $bundle_path,
        bundled_sha256: $bundled_sha256,
        bundled_at: $bundled_at
      }' >>"$manifest_file"
    count=$((count + 1))
  done < <(atlas_evidence_bundle_rows "$include_unredacted")

  [ "$count" -gt 0 ] || fail "no bundle-eligible evidence records found"

  {
    printf '# Atlas Evidence Bundle\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    printf 'Include unredacted: %s\n' "$include_unredacted"
    printf 'Files: %s\n' "$count"
    printf '\n## Files\n\n'
    jq -r '
      "- " + (.id // "?") +
      " / " + (.included_as // "?") +
      " / " + (.classification // "?") +
      " / sha256=" + (.bundled_sha256 // "?") +
      " / `" + (.bundle_path // "?") + "`"
    ' "$manifest_file"
  } >"$readme_file"
  chmod 600 "$readme_file" 2>/dev/null || true

  atlas_ledger_append_current "evidence.bundle.generated" "read-only" "atlas" "ok" "bundle=$bundle_slug files=$count include_unredacted=$include_unredacted"

  ui_ok "evidence bundle written"
  printf 'bundle: %s\n' "$bundle_dir"
  printf 'manifest: %s\n' "$manifest_file"
  printf 'files: %s\n' "$count"
  printf 'include_unredacted: %s\n' "$include_unredacted"
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

  jq -sr '
    reduce .[] as $record ({}; .[$record.id] = $record)
    | [.[]]
    | sort_by(.created_at, .id)
    | reverse
    | .[]
    |
    [
      (.id // "?"),
      (.created_at // "?"),
      (.kind // "?"),
      (.target // "?"),
      (.classification // "?"),
      ((.redacted // false) | tostring),
      (.sha256 // "?"),
      (.path // "?")
    ]
    | @tsv
  ' "$index_file" |
    awk -F'\t' '{ printf "%-22s %-20s %-16s %-16s %-14s %-8s %-64s %s\n", $1, $2, $3, $4, $5, $6, $7, $8 }'
}

cmd_evidence_show() {
  need_args 1 "$#" "evidence show <id>"
  local evidence_id="$1"
  local index_file
  local record
  local output
  local operation
  local target
  local kind
  local classification
  local redacted
  local sha256
  local path
  local created_at
  local redacted_path
  local redacted_sha256
  local redacted_at
  local redaction_note

  load_active_operation
  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || fail "unknown evidence: $evidence_id"
  record="$(atlas_evidence_latest_record "$evidence_id" || true)"
  [ -n "$record" ] || fail "unknown evidence: $evidence_id"

  output="$(
    printf '%s\n' "$record" |
      jq -r '
        [
          (.id // "?"),
          (.operation // "?"),
          (.target // "?"),
          (.kind // "?"),
          (.classification // "?"),
          ((.redacted // false) | tostring),
          (.sha256 // "?"),
          (.path // "?"),
          (.created_at // "?"),
          (.redacted_path // ""),
          (.redacted_sha256 // ""),
          (.redacted_at // ""),
          (.redaction_note // "")
        ]
        | @tsv
      '
  )"
  [ -n "$output" ] || fail "unknown evidence: $evidence_id"

  IFS=$'\t' read -r evidence_id operation target kind classification redacted sha256 path created_at redacted_path redacted_sha256 redacted_at redaction_note <<<"$output"

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
  if [ -n "$redacted_path" ]; then
    ui_kv "Redacted Path" "$ATLAS_OP_DIR/$redacted_path"
  fi
  if [ -n "$redacted_sha256" ]; then
    ui_kv "Redacted SHA256" "$redacted_sha256"
  fi
  if [ -n "$redacted_at" ]; then
    ui_kv "Redacted At" "$redacted_at"
  fi
  if [ -n "$redaction_note" ]; then
    ui_kv "Redaction Note" "$redaction_note"
  fi
}

atlas_evidence_count_for_target() {
  local target="${1:-}"
  local index_file

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$target" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select($target == "" or .target == $target))
      | length
    ' "$index_file"
}

atlas_evidence_rows_for_target() {
  local target="${1:-}"
  local limit="${2:-8}"
  local index_file

  intel_require_jq

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg target "$target" \
    --argjson limit "$limit" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select($target == "" or .target == $target))
      | sort_by(.created_at, .id)
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.kind // "?"),
          (.classification // "?"),
          ((.redacted // false) | tostring),
          (.sha256 // "?"),
          (.path // "?")
        ]
      | @tsv
    ' "$index_file"
}

atlas_evidence_print_table_for_target() {
  local target="${1:-}"
  local limit="${2:-8}"
  local empty_note="${3:-no evidence recorded yet}"
  local output

  output="$(
    atlas_evidence_rows_for_target "$target" "$limit" |
      awk -F'\t' '{ printf "%-22s %-16s %-14s %-8s %-20s %s\n", $1, $2, $3, $4, substr($5, 1, 20), $6 }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "$empty_note"
  fi
}
