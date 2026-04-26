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

atlas_archive_print() {
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

  ui_heading "Operation Archive Snapshot"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Operation Status" "$ATLAS_OP_STATUS"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Archive Status" "$archive_status"
  ui_kv "Next Archive Step" "$archive_next_step"
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
  ui_kv "Closeout Verification" "$closeout_verification_status manifest=$closeout_verification_path problems=$closeout_verification_problems"
  ui_kv "Audit Packet Verification" "$audit_packet_verification_status packet=$audit_packet_verification_path"
  ui_rule
  ui_subheading "Archive Artifacts"
  if [ -n "$report_path" ]; then
    ui_kv "Latest Report" "$report_at $report_path sha256=$report_sha"
  else
    ui_kv "Latest Report" "none generated yet"
  fi
  if [ -n "$bundle_dir" ]; then
    ui_kv "Evidence Bundle" "$bundle_at $bundle_dir slug=${bundle_slug:-unknown} files=${bundle_files:-0} include_unredacted=${include_unredacted:-0}"
    ui_kv "Evidence Manifest" "$manifest_file sha256=$manifest_sha"
  else
    ui_kv "Evidence Bundle" "none generated yet"
    ui_kv "Evidence Manifest" "none"
  fi
  ui_kv "Latest Handoff" "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none generated yet}"
  ui_kv "Latest Closeout" "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none generated yet}"
  ui_kv "Latest Audit Packet" "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none generated yet}"
  ui_kv "Operation Ledger" "$ledger_file events=$ledger_events sha256=$ledger_sha"
  ui_kv "Operation Directory" "$ATLAS_OP_DIR"
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
