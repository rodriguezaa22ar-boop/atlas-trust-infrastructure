#!/usr/bin/env bash

atlas_archive_audit_packet_verification_status() {
  local packet_path="${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-}"

  if [ -z "$packet_path" ]; then
    printf 'missing\t-\n'
    return 0
  fi

  if [ ! -f "$packet_path" ]; then
    printf 'missing\t%s\n' "$packet_path"
    return 0
  fi

  if (atlas_audit_verify_packet "$packet_path" >/dev/null 2>&1); then
    printf 'verified\t%s\n' "$packet_path"
  else
    printf 'attention-required\t%s\n' "$packet_path"
  fi
}

atlas_archive_status() {
  local closeout_verification_status="$1"
  local audit_packet_verification_status="$2"

  if [ "$ATLAS_READINESS_STATUS" != "ready" ]; then
    printf 'attention-required\n'
  elif [ "$ATLAS_READINESS_REPORT_FRESHNESS" != "current" ]; then
    printf 'attention-required\n'
  elif [ "$ATLAS_READINESS_BUNDLE_FRESHNESS" = "stale" ] ||
    [ "$ATLAS_READINESS_HANDOFF_FRESHNESS" = "stale" ] ||
    [ "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" = "stale" ] ||
    [ "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" = "stale" ]; then
    printf 'attention-required\n'
  elif [ -z "$ATLAS_READINESS_LATEST_CLOSEOUT" ] || [ -z "$ATLAS_READINESS_LATEST_AUDIT_PACKET" ]; then
    printf 'incomplete\n'
  elif [ "$closeout_verification_status" != "verified" ] ||
    [ "$audit_packet_verification_status" != "verified" ]; then
    printf 'attention-required\n'
  else
    printf 'current\n'
  fi
}

atlas_archive_next_step() {
  local closeout_verification_status="$1"
  local audit_packet_verification_status="$2"

  if [ "$ATLAS_READINESS_STATUS" != "ready" ]; then
    printf '%s\n' "$ATLAS_READINESS_NEXT_STEP"
  elif [ "$ATLAS_READINESS_REPORT_FRESHNESS" != "current" ]; then
    printf 'Refresh the operation report before archiving.\n'
  elif [ "$ATLAS_READINESS_BUNDLE_FRESHNESS" = "stale" ]; then
    printf 'Regenerate the evidence bundle if the archive includes handoff evidence.\n'
  elif [ "$ATLAS_READINESS_HANDOFF_FRESHNESS" = "stale" ]; then
    printf 'Regenerate the handoff packet if the archive includes handoff materials.\n'
  elif [ -z "$ATLAS_READINESS_LATEST_CLOSEOUT" ]; then
    printf 'Generate a closeout manifest before final archive review.\n'
  elif [ "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" = "stale" ]; then
    printf 'Regenerate the closeout manifest before final archive review.\n'
  elif [ "$closeout_verification_status" != "verified" ]; then
    printf 'Resolve closeout verification issues before final archive review.\n'
  elif [ -z "$ATLAS_READINESS_LATEST_AUDIT_PACKET" ]; then
    printf 'Generate an audit packet before final archive review.\n'
  elif [ "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" = "stale" ]; then
    printf 'Regenerate the audit packet before final archive review.\n'
  elif [ "$audit_packet_verification_status" != "verified" ]; then
    printf 'Resolve audit packet verification issues before final archive review.\n'
  else
    printf 'Archive snapshot is current.\n'
  fi
}

atlas_archive_collect() {
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
  local closeout_verification
  local closeout_verification_status
  local closeout_verification_path
  local closeout_verification_problems
  local audit_packet_verification
  local audit_packet_verification_status
  local audit_packet_verification_path
  local archive_status
  local archive_next_step
  local ledger_file
  local ledger_events="0"
  local ledger_sha=""

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

  closeout_verification="$(atlas_audit_closeout_verification_status)"
  IFS=$'\t' read -r closeout_verification_status closeout_verification_path closeout_verification_problems <<<"$closeout_verification"

  audit_packet_verification="$(atlas_archive_audit_packet_verification_status)"
  IFS=$'\t' read -r audit_packet_verification_status audit_packet_verification_path <<<"$audit_packet_verification"

  archive_status="$(atlas_archive_status "$closeout_verification_status" "$audit_packet_verification_status")"
  archive_next_step="$(atlas_archive_next_step "$closeout_verification_status" "$audit_packet_verification_status")"

  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  if [ -f "$ledger_file" ]; then
    ledger_events="$(atlas_closeout_ledger_event_count "$ledger_file")"
    ledger_sha="$(atlas_closeout_sha_for_file "$ledger_file")"
  fi

  ATLAS_ARCHIVE_LATEST_REPORT_AT="$report_at"
  ATLAS_ARCHIVE_LATEST_REPORT_PATH="$report_path"
  ATLAS_ARCHIVE_LATEST_REPORT_SHA="$report_sha"
  ATLAS_ARCHIVE_BUNDLE_AT="$bundle_at"
  ATLAS_ARCHIVE_BUNDLE_SLUG="$bundle_slug"
  ATLAS_ARCHIVE_BUNDLE_DIR="$bundle_dir"
  ATLAS_ARCHIVE_BUNDLE_MANIFEST="$manifest_file"
  ATLAS_ARCHIVE_BUNDLE_MANIFEST_SHA="$manifest_sha"
  ATLAS_ARCHIVE_BUNDLE_FILES="$bundle_files"
  ATLAS_ARCHIVE_BUNDLE_INCLUDE_UNREDACTED="$include_unredacted"
  ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS="$closeout_verification_status"
  ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH="$closeout_verification_path"
  ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS="$closeout_verification_problems"
  ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS="$audit_packet_verification_status"
  ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_PATH="$audit_packet_verification_path"
  ATLAS_ARCHIVE_STATUS="$archive_status"
  ATLAS_ARCHIVE_NEXT_STEP="$archive_next_step"
  ATLAS_ARCHIVE_LEDGER_FILE="$ledger_file"
  ATLAS_ARCHIVE_LEDGER_EVENTS="$ledger_events"
  ATLAS_ARCHIVE_LEDGER_SHA="$ledger_sha"
}

atlas_archive_print() {
  atlas_archive_collect

  ui_heading "Operation Archive Snapshot"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Operation Status" "$ATLAS_OP_STATUS"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Archive Status" "$ATLAS_ARCHIVE_STATUS"
  ui_kv "Next Archive Step" "$ATLAS_ARCHIVE_NEXT_STEP"
  ui_rule
  ui_subheading "Readiness"
  ui_kv "Close Readiness" "$ATLAS_READINESS_STATUS"
  ui_kv "Readiness Next Step" "$ATLAS_READINESS_NEXT_STEP"
  ui_kv "Evidence Records" "$ATLAS_READINESS_EVIDENCE_COUNT"
  ui_kv "Open Findings" "$ATLAS_READINESS_OPEN_FINDINGS_COUNT"
  ui_kv "Pending Validation" "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
  ui_kv "Report Freshness" "$ATLAS_READINESS_REPORT_FRESHNESS"
  ui_kv "Bundle Freshness" "$ATLAS_READINESS_BUNDLE_FRESHNESS"
  ui_kv "Handoff Freshness" "$ATLAS_READINESS_HANDOFF_FRESHNESS"
  ui_kv "Closeout Freshness" "$ATLAS_READINESS_CLOSEOUT_FRESHNESS"
  ui_kv "Audit Packet Freshness" "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS"
  ui_rule
  ui_subheading "Verification"
  ui_kv "Closeout Verification" "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS manifest=$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH problems=$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS"
  ui_kv "Audit Packet Verification" "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS packet=$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_PATH"
  ui_rule
  ui_subheading "Archive Artifacts"
  if [ -n "$ATLAS_ARCHIVE_LATEST_REPORT_PATH" ]; then
    ui_kv "Latest Report" "$ATLAS_ARCHIVE_LATEST_REPORT_AT $ATLAS_ARCHIVE_LATEST_REPORT_PATH sha256=$ATLAS_ARCHIVE_LATEST_REPORT_SHA"
  else
    ui_kv "Latest Report" "none generated yet"
  fi
  if [ -n "$ATLAS_ARCHIVE_BUNDLE_DIR" ]; then
    ui_kv "Evidence Bundle" "$ATLAS_ARCHIVE_BUNDLE_AT $ATLAS_ARCHIVE_BUNDLE_DIR slug=${ATLAS_ARCHIVE_BUNDLE_SLUG:-unknown} files=${ATLAS_ARCHIVE_BUNDLE_FILES:-0} include_unredacted=${ATLAS_ARCHIVE_BUNDLE_INCLUDE_UNREDACTED:-0}"
    ui_kv "Evidence Manifest" "$ATLAS_ARCHIVE_BUNDLE_MANIFEST sha256=$ATLAS_ARCHIVE_BUNDLE_MANIFEST_SHA"
  else
    ui_kv "Evidence Bundle" "none generated yet"
    ui_kv "Evidence Manifest" "none"
  fi
  ui_kv "Latest Handoff" "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none generated yet}"
  ui_kv "Latest Closeout" "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none generated yet}"
  ui_kv "Latest Audit Packet" "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none generated yet}"
  ui_kv "Operation Ledger" "$ATLAS_ARCHIVE_LEDGER_FILE events=$ATLAS_ARCHIVE_LEDGER_EVENTS sha256=$ATLAS_ARCHIVE_LEDGER_SHA"
  ui_kv "Operation Directory" "$ATLAS_OP_DIR"
}

atlas_archive_markdown_artifacts() {
  if [ -n "$ATLAS_ARCHIVE_LATEST_REPORT_PATH" ]; then
    printf -- "- Latest report: \`%s\` generated=%s sha256=%s\n" "$ATLAS_ARCHIVE_LATEST_REPORT_PATH" "$ATLAS_ARCHIVE_LATEST_REPORT_AT" "$ATLAS_ARCHIVE_LATEST_REPORT_SHA"
  else
    printf -- '- Latest report: none generated yet\n'
  fi

  if [ -n "$ATLAS_ARCHIVE_BUNDLE_DIR" ]; then
    printf -- "- Evidence bundle: \`%s\` generated=%s slug=%s files=%s include_unredacted=%s\n" "$ATLAS_ARCHIVE_BUNDLE_DIR" "$ATLAS_ARCHIVE_BUNDLE_AT" "${ATLAS_ARCHIVE_BUNDLE_SLUG:-unknown}" "${ATLAS_ARCHIVE_BUNDLE_FILES:-0}" "${ATLAS_ARCHIVE_BUNDLE_INCLUDE_UNREDACTED:-0}"
    printf -- "- Evidence manifest: \`%s\` sha256=%s\n" "$ATLAS_ARCHIVE_BUNDLE_MANIFEST" "$ATLAS_ARCHIVE_BUNDLE_MANIFEST_SHA"
  else
    printf -- '- Evidence bundle: none generated yet\n'
    printf -- '- Evidence manifest: none\n'
  fi

  printf -- "- Latest handoff: \`%s\`\n" "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none}"
  printf -- "- Latest closeout: \`%s\`\n" "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none}"
  printf -- "- Latest audit packet: \`%s\`\n" "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none}"
  printf -- "- Operation ledger: \`%s\` events=%s sha256=%s\n" "$ATLAS_ARCHIVE_LEDGER_FILE" "$ATLAS_ARCHIVE_LEDGER_EVENTS" "$ATLAS_ARCHIVE_LEDGER_SHA"
  printf -- "- Operation directory: \`%s\`\n" "$ATLAS_OP_DIR"
}

atlas_archive_write_packet() {
  local file="$1"

  atlas_archive_collect

  {
    printf '# Atlas Operation Archive Packet\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Operation Status: %s\n' "$ATLAS_OP_STATUS"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    if [ -n "${ATLAS_OP_TARGET_ADDRESS:-}" ] && [ "$ATLAS_OP_TARGET_ADDRESS" != "$ATLAS_OP_TARGET" ]; then
      printf 'Address: %s\n' "$ATLAS_OP_TARGET_ADDRESS"
    fi
    printf '\nNo raw artifact contents are included in this archive packet.\n'

    printf '\n## Archive Status\n\n'
    printf -- '- Archive status: %s\n' "$ATLAS_ARCHIVE_STATUS"
    printf -- '- Next archive step: %s\n' "$ATLAS_ARCHIVE_NEXT_STEP"

    printf '\n## Readiness\n\n'
    printf -- '- Close readiness: %s\n' "$ATLAS_READINESS_STATUS"
    printf -- '- Evidence records: %s\n' "$ATLAS_READINESS_EVIDENCE_COUNT"
    printf -- '- Open findings: %s\n' "$ATLAS_READINESS_OPEN_FINDINGS_COUNT"
    printf -- '- Pending validation: %s\n' "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
    printf -- '- Report freshness: %s\n' "$ATLAS_READINESS_REPORT_FRESHNESS"
    printf -- '- Bundle freshness: %s\n' "$ATLAS_READINESS_BUNDLE_FRESHNESS"
    printf -- '- Handoff freshness: %s\n' "$ATLAS_READINESS_HANDOFF_FRESHNESS"
    printf -- '- Closeout freshness: %s\n' "$ATLAS_READINESS_CLOSEOUT_FRESHNESS"
    printf -- '- Audit packet freshness: %s\n' "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS"

    printf '\n## Verification\n\n'
    printf -- '- Closeout verification: %s manifest=%s problems=%s\n' "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS" "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH" "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS"
    printf -- '- Audit packet verification: %s packet=%s\n' "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS" "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_PATH"

    printf '\n## Archive Artifacts\n\n'
    atlas_archive_markdown_artifacts

    printf '\n## Retention Notes\n\n'
    printf -- '- Treat paths as local references; verify copied files against the recorded hashes before retention or transfer.\n'
    printf -- '- Keep this packet with the closeout manifest and audit packet for final review.\n'
  } >"$file"
}

cmd_op_archive() {
  [ "$#" -le 1 ] || fail "op archive [name]"

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  atlas_archive_print
}

cmd_op_archive_packet() {
  local packet_name="${2:-}"
  local packet_slug
  local archive_dir
  local packet_file

  [ "$#" -le 2 ] || fail "op archive-packet [name] [packet-name]"

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_OP_SLUG-archive"
  fi
  packet_slug="$(slugify "$packet_name")"
  [ -n "$packet_slug" ] || fail "archive packet name produced an empty slug"

  archive_dir="$ATLAS_OP_DIR/archive"
  mkdir -p "$archive_dir"
  chmod 700 "$archive_dir" 2>/dev/null || true
  packet_file="$archive_dir/$packet_slug.md"

  atlas_ledger_append_current "archive.packet.generated" "read-only" "atlas" "ok" "$packet_file"
  atlas_archive_write_packet "$packet_file"
  chmod 600 "$packet_file" 2>/dev/null || true
  record_operation_history "$ATLAS_OP_DIR" "archive-packet" "$packet_file"

  ui_ok "archive packet written"
  printf 'archive_packet: %s\n' "$packet_file"
}
