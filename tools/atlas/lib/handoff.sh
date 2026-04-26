#!/usr/bin/env bash

atlas_handoff_latest_report_fields() {
  local latest_report
  local report_at=""
  local report_path=""
  local report_sha=""

  latest_report="$(atlas_cycle_latest_report)"
  [ -n "$latest_report" ] || return 0

  IFS=$'\t' read -r report_at report_path <<<"$latest_report"
  if [ -n "$report_path" ] && [ -f "$report_path" ]; then
    report_sha="$(atlas_evidence_hash_path "$report_path")"
  fi

  printf '%s\t%s\t%s\n' "$report_at" "$report_path" "$report_sha"
}

atlas_handoff_latest_bundle_fields() {
  local latest_bundle
  local bundle_at=""
  local bundle_detail=""
  local part
  local bundle_slug=""
  local bundle_files=""
  local include_unredacted=""
  local bundle_dir=""
  local manifest_file=""
  local manifest_sha=""

  latest_bundle="$(atlas_readiness_latest_bundle)"
  [ -n "$latest_bundle" ] || return 0

  IFS=$'\t' read -r bundle_at bundle_detail <<<"$latest_bundle"
  for part in $bundle_detail; do
    case "$part" in
    bundle=*)
      bundle_slug="${part#bundle=}"
      ;;
    files=*)
      bundle_files="${part#files=}"
      ;;
    include_unredacted=*)
      include_unredacted="${part#include_unredacted=}"
      ;;
    esac
  done

  if [ -n "$bundle_slug" ]; then
    bundle_dir="$ATLAS_OP_DIR/evidence-bundles/$bundle_slug"
    manifest_file="$bundle_dir/manifest.ndjson"
    if [ -f "$manifest_file" ]; then
      manifest_sha="$(atlas_evidence_hash_path "$manifest_file")"
    fi
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$bundle_at" "$bundle_slug" "$bundle_dir" "$manifest_file" "$manifest_sha" "$bundle_files" "$include_unredacted"
}

atlas_handoff_findings_index_markdown() {
  local output

  output="$(
    atlas_findings_rows_for_target "$ATLAS_OP_TARGET" 1000000 |
      awk -F'\t' '{
        evidence = $6 == "" ? "-" : $6
        printf "- %s / %s / %s / %s: %s Evidence: %s.\n", $1, $3, $2, $4, $5, evidence
      }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    printf -- '- No findings recorded.\n'
  fi
}

atlas_handoff_write_packet() {
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

  atlas_readiness_collect "$ATLAS_OP_TARGET"
  latest_report="$(atlas_handoff_latest_report_fields)"
  if [ -n "$latest_report" ]; then
    IFS=$'\t' read -r report_at report_path report_sha <<<"$latest_report"
  fi
  latest_bundle="$(atlas_handoff_latest_bundle_fields)"
  if [ -n "$latest_bundle" ]; then
    IFS=$'\t' read -r bundle_at bundle_slug bundle_dir manifest_file manifest_sha bundle_files include_unredacted <<<"$latest_bundle"
  fi

  {
    printf '# Atlas Operation Handoff\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Operation Status: %s\n' "$ATLAS_OP_STATUS"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    if [ -n "${ATLAS_OP_TARGET_ADDRESS:-}" ] && [ "$ATLAS_OP_TARGET_ADDRESS" != "$ATLAS_OP_TARGET" ]; then
      printf 'Address: %s\n' "$ATLAS_OP_TARGET_ADDRESS"
    fi
    printf '\nNo raw artifact contents are included in this handoff packet.\n'
    printf '\n## Close Readiness\n\n'
    printf -- '- Close readiness: %s\n' "$ATLAS_READINESS_STATUS"
    printf -- '- Next step: %s\n' "$ATLAS_READINESS_NEXT_STEP"
    printf -- '- Evidence records: %s\n' "$ATLAS_READINESS_EVIDENCE_COUNT"
    printf -- '- Findings: %s\n' "$ATLAS_READINESS_FINDING_COUNT"
    printf -- '- Open findings: %s\n' "$ATLAS_READINESS_OPEN_FINDINGS_COUNT"
    printf -- '- Validation plans: %s\n' "$ATLAS_READINESS_VALIDATION_COUNT"
    printf -- '- Pending validation: %s\n' "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
    printf -- '- Report freshness: %s\n' "$ATLAS_READINESS_REPORT_FRESHNESS"
    if [ -n "$ATLAS_READINESS_LATEST_CHANGE" ]; then
      printf -- '- Latest state change: %s %s\n' "$ATLAS_READINESS_LATEST_CHANGE_AT" "$ATLAS_READINESS_LATEST_CHANGE_EVENT"
    else
      printf -- '- Latest state change: none\n'
    fi
    printf '\n## Primary Artifacts\n\n'
    if [ -n "$report_path" ]; then
      printf -- "- Latest report: \`%s\`" "$report_path"
      if [ -n "$report_at" ]; then
        printf ' generated=%s' "$report_at"
      fi
      if [ -n "$report_sha" ]; then
        printf ' sha256=%s' "$report_sha"
      fi
      printf '\n'
    else
      printf -- '- Latest report: none generated yet\n'
    fi
    if [ -n "$bundle_dir" ]; then
      printf -- "- Evidence bundle: \`%s\`" "$bundle_dir"
      if [ -n "$bundle_at" ]; then
        printf ' generated=%s' "$bundle_at"
      fi
      if [ -n "$bundle_files" ]; then
        printf ' files=%s' "$bundle_files"
      fi
      if [ -n "$include_unredacted" ]; then
        printf ' include_unredacted=%s' "$include_unredacted"
      fi
      printf '\n'
      printf -- "- Evidence manifest: \`%s\`" "$manifest_file"
      if [ -n "$manifest_sha" ]; then
        printf ' sha256=%s' "$manifest_sha"
      fi
      printf '\n'
    else
      printf -- '- Evidence bundle: none generated yet\n'
    fi
    printf -- "- Operation ledger: \`%s\`\n" "$(atlas_ledger_file "$ATLAS_OP_DIR")"
    printf -- "- Operation directory: \`%s\`\n" "$ATLAS_OP_DIR"
    printf '\n## Finding Index\n\n'
    atlas_handoff_findings_index_markdown
    printf '\n## Findings\n\n'
    atlas_findings_report_markdown
    printf '\n## Validation Plans\n\n'
    atlas_validation_report_markdown
    printf '\n## Handoff Notes\n\n'
    printf -- '- Validate recipient and handling requirements before sharing any bundle path.\n'
    printf -- '- Use manifest hashes to verify copied evidence bundle files.\n'
  } >"$file"
}

cmd_op_handoff() {
  local packet_name="${2:-}"
  local packet_slug
  local handoff_dir
  local packet_file

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_OP_SLUG-handoff"
  fi
  packet_slug="$(slugify "$packet_name")"
  [ -n "$packet_slug" ] || fail "handoff packet name produced an empty slug"

  handoff_dir="$ATLAS_OP_DIR/handoff"
  mkdir -p "$handoff_dir"
  chmod 700 "$handoff_dir" 2>/dev/null || true
  packet_file="$handoff_dir/$packet_slug.md"
  atlas_handoff_write_packet "$packet_file"
  chmod 600 "$packet_file" 2>/dev/null || true

  atlas_ledger_append_current "handoff.generated" "read-only" "atlas" "ok" "$packet_file"
  record_operation_history "$ATLAS_OP_DIR" "handoff" "$packet_file"

  ui_ok "handoff packet written"
  printf 'handoff: %s\n' "$packet_file"
}
