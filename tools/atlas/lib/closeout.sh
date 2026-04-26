#!/usr/bin/env bash

atlas_closeout_sha_for_file() {
  local path="$1"

  [ -n "$path" ] || return 0
  [ -f "$path" ] || return 0
  atlas_evidence_hash_path "$path"
}

atlas_closeout_ledger_event_count() {
  local ledger_file="$1"

  if [ ! -s "$ledger_file" ]; then
    printf '0\n'
    return 0
  fi

  jq -s 'length' "$ledger_file"
}

atlas_closeout_latest_handoff_fields() {
  local latest_handoff
  local handoff_at=""
  local handoff_path=""
  local handoff_sha=""

  latest_handoff="$(atlas_readiness_latest_handoff)"
  [ -n "$latest_handoff" ] || return 0

  IFS=$'\t' read -r handoff_at handoff_path <<<"$latest_handoff"
  handoff_sha="$(atlas_closeout_sha_for_file "$handoff_path")"

  printf '%s\t%s\t%s\n' "$handoff_at" "$handoff_path" "$handoff_sha"
}

atlas_closeout_print_hash_line() {
  local label="$1"
  local path="$2"
  local extra="${3:-}"
  local sha=""

  if [ -n "$path" ] && [ -f "$path" ]; then
    sha="$(atlas_closeout_sha_for_file "$path")"
    printf -- "- %s: \`%s\`" "$label" "$path"
    if [ -n "$extra" ]; then
      printf ' %s' "$extra"
    fi
    if [ -n "$sha" ]; then
      printf ' sha256=%s' "$sha"
    fi
    printf '\n'
  else
    printf -- '- %s: none\n' "$label"
  fi
}

atlas_closeout_write_manifest() {
  local file="$1"
  local latest_report
  local report_at=""
  local report_path=""
  local report_sha=""
  local latest_bundle
  local bundle_at=""
  local bundle_slug=""
  local bundle_dir=""
  local manifest_file=""
  local manifest_sha=""
  local bundle_files=""
  local include_unredacted=""
  local latest_handoff
  local handoff_at=""
  local handoff_path=""
  local handoff_sha=""
  local ledger_file
  local ledger_sha=""
  local ledger_events="0"
  local scope_file
  local evidence_index
  local findings_index
  local validation_index

  atlas_scope_load_snapshot
  atlas_readiness_collect "$ATLAS_OP_TARGET"

  latest_report="$(atlas_handoff_latest_report_fields)"
  if [ -n "$latest_report" ]; then
    IFS=$'\t' read -r report_at report_path report_sha <<<"$latest_report"
  fi

  latest_bundle="$(atlas_handoff_latest_bundle_fields)"
  if [ -n "$latest_bundle" ]; then
    IFS=$'\t' read -r bundle_at bundle_slug bundle_dir manifest_file manifest_sha bundle_files include_unredacted <<<"$latest_bundle"
  fi

  latest_handoff="$(atlas_closeout_latest_handoff_fields)"
  if [ -n "$latest_handoff" ]; then
    IFS=$'\t' read -r handoff_at handoff_path handoff_sha <<<"$latest_handoff"
  fi

  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  if [ -f "$ledger_file" ]; then
    ledger_sha="$(atlas_closeout_sha_for_file "$ledger_file")"
    ledger_events="$(atlas_closeout_ledger_event_count "$ledger_file")"
  fi
  scope_file="$(atlas_scope_snapshot_file "$ATLAS_OP_DIR")"
  evidence_index="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  findings_index="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  validation_index="$(atlas_validation_index_file "$ATLAS_OP_DIR")"

  {
    printf '# Atlas Closeout Manifest\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Operation Status: %s\n' "$ATLAS_OP_STATUS"
    if [ -n "$ATLAS_OP_CLOSED_AT" ]; then
      printf 'Closed At: %s\n' "$ATLAS_OP_CLOSED_AT"
    else
      printf 'Closed At: not closed\n'
    fi
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    if [ -n "${ATLAS_OP_TARGET_ADDRESS:-}" ] && [ "$ATLAS_OP_TARGET_ADDRESS" != "$ATLAS_OP_TARGET" ]; then
      printf 'Address: %s\n' "$ATLAS_OP_TARGET_ADDRESS"
    fi
    printf 'Profile: %s\n' "$ATLAS_SCOPE_PROFILE"
    printf '\nNo raw artifact contents are included in this closeout manifest.\n'

    printf '\n## Readiness Snapshot\n\n'
    printf -- '- Close readiness: %s\n' "$ATLAS_READINESS_STATUS"
    printf -- '- Next step: %s\n' "$ATLAS_READINESS_NEXT_STEP"
    printf -- '- Evidence records: %s\n' "$ATLAS_READINESS_EVIDENCE_COUNT"
    printf -- '- Findings: %s\n' "$ATLAS_READINESS_FINDING_COUNT"
    printf -- '- Open findings: %s\n' "$ATLAS_READINESS_OPEN_FINDINGS_COUNT"
    printf -- '- Validation plans: %s\n' "$ATLAS_READINESS_VALIDATION_COUNT"
    printf -- '- Pending validation: %s\n' "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
    printf -- '- Report freshness: %s\n' "$ATLAS_READINESS_REPORT_FRESHNESS"
    printf -- '- Bundle freshness: %s\n' "$ATLAS_READINESS_BUNDLE_FRESHNESS"
    printf -- '- Handoff freshness: %s\n' "$ATLAS_READINESS_HANDOFF_FRESHNESS"

    printf '\n## Primary Artifacts\n\n'
    if [ -n "$report_path" ]; then
      printf -- "- Latest report: \`%s\` generated=%s sha256=%s\n" "$report_path" "$report_at" "$report_sha"
    else
      printf -- '- Latest report: none generated yet\n'
    fi
    if [ -n "$bundle_dir" ]; then
      printf -- "- Evidence bundle: \`%s\` slug=%s generated=%s files=%s include_unredacted=%s\n" "$bundle_dir" "$bundle_slug" "$bundle_at" "$bundle_files" "$include_unredacted"
      printf -- "- Evidence manifest: \`%s\` sha256=%s\n" "$manifest_file" "$manifest_sha"
    else
      printf -- '- Evidence bundle: none generated yet\n'
      printf -- '- Evidence manifest: none\n'
    fi
    if [ -n "$handoff_path" ]; then
      printf -- "- Latest handoff: \`%s\` generated=%s sha256=%s\n" "$handoff_path" "$handoff_at" "$handoff_sha"
    else
      printf -- '- Latest handoff: none generated yet\n'
    fi

    printf '\n## Integrity Anchors\n\n'
    printf -- "- Operation ledger: \`%s\` events=%s sha256=%s\n" "$ledger_file" "$ledger_events" "$ledger_sha"
    atlas_closeout_print_hash_line "Operation env" "$ATLAS_OP_FILE"
    atlas_closeout_print_hash_line "Scope snapshot" "$scope_file"
    atlas_closeout_print_hash_line "Evidence index" "$evidence_index"
    atlas_closeout_print_hash_line "Finding index" "$findings_index"
    atlas_closeout_print_hash_line "Validation index" "$validation_index"

    printf '\n## Closeout Notes\n\n'
    printf -- '- Verify copied report, handoff, and evidence bundle files against the hashes above.\n'
    printf -- '- Treat paths as local references; validate recipient and handling requirements before sharing artifacts.\n'
  } >"$file"
}

cmd_op_closeout() {
  local manifest_name="${2:-}"
  local manifest_slug
  local closeout_dir
  local manifest_file

  [ "$#" -le 2 ] || fail "op closeout [name] [manifest-name]"

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  if [ -z "$manifest_name" ]; then
    manifest_name="$ATLAS_OP_SLUG-closeout"
  fi
  manifest_slug="$(slugify "$manifest_name")"
  [ -n "$manifest_slug" ] || fail "closeout manifest name produced an empty slug"

  closeout_dir="$ATLAS_OP_DIR/closeout"
  mkdir -p "$closeout_dir"
  chmod 700 "$closeout_dir" 2>/dev/null || true
  manifest_file="$closeout_dir/$manifest_slug.md"

  atlas_ledger_append_current "closeout.manifest.generated" "read-only" "atlas" "ok" "$manifest_file"
  atlas_closeout_write_manifest "$manifest_file"
  chmod 600 "$manifest_file" 2>/dev/null || true
  record_operation_history "$ATLAS_OP_DIR" "closeout" "$manifest_file"

  ui_ok "closeout manifest written"
  printf 'closeout: %s\n' "$manifest_file"
}
