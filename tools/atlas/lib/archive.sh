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

atlas_archive_review_packet_verification_status() {
  local packet_path="${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-}"

  if [ "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" -eq 0 ]; then
    printf 'not-required\t-\n'
    return 0
  fi

  if [ -z "$packet_path" ]; then
    printf 'missing\t-\n'
    return 0
  fi

  if [ ! -f "$packet_path" ]; then
    printf 'missing\t%s\n' "$packet_path"
    return 0
  fi

  if (atlas_findings_verify_review_packet "$packet_path" >/dev/null 2>&1); then
    printf 'verified\t%s\n' "$packet_path"
  else
    printf 'attention-required\t%s\n' "$packet_path"
  fi
}

atlas_archive_status() {
  local closeout_verification_status="$1"
  local audit_packet_verification_status="$2"
  local review_packet_verification_status="${3:-not-required}"

  if [ "$ATLAS_READINESS_STATUS" != "ready" ]; then
    printf 'attention-required\n'
  elif [ "$ATLAS_READINESS_REPORT_FRESHNESS" != "current" ]; then
    printf 'attention-required\n'
  elif [ "$ATLAS_READINESS_BUNDLE_FRESHNESS" = "stale" ] ||
    [ "$ATLAS_READINESS_HANDOFF_FRESHNESS" = "stale" ] ||
    [ "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" = "stale" ] ||
    { [ "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" -gt 0 ] && [ "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS" = "stale" ]; } ||
    [ "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" = "stale" ] ||
    [ "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS" = "stale" ]; then
    printf 'attention-required\n'
  elif [ -z "$ATLAS_READINESS_LATEST_CLOSEOUT" ] ||
    { [ "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" -gt 0 ] && [ -z "$ATLAS_READINESS_LATEST_REVIEW_PACKET" ]; } ||
    [ -z "$ATLAS_READINESS_LATEST_AUDIT_PACKET" ] ||
    [ -z "$ATLAS_READINESS_LATEST_ARCHIVE_PACKET" ]; then
    printf 'incomplete\n'
  elif [ "$closeout_verification_status" != "verified" ] ||
    { [ "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" -gt 0 ] && [ "$review_packet_verification_status" != "verified" ]; } ||
    [ "$audit_packet_verification_status" != "verified" ]; then
    printf 'attention-required\n'
  else
    printf 'current\n'
  fi
}

atlas_archive_next_step() {
  local closeout_verification_status="$1"
  local audit_packet_verification_status="$2"
  local review_packet_verification_status="${3:-not-required}"

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
  elif [ "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" -gt 0 ] && [ -z "$ATLAS_READINESS_LATEST_REVIEW_PACKET" ]; then
    printf 'Generate an accepted-risk review packet before final archive review.\n'
  elif [ "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" -gt 0 ] && [ "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS" = "stale" ]; then
    printf 'Regenerate the accepted-risk review packet before final archive review.\n'
  elif [ "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" -gt 0 ] && [ "$review_packet_verification_status" != "verified" ]; then
    printf 'Resolve accepted-risk review packet verification issues before final archive review.\n'
  elif [ -z "$ATLAS_READINESS_LATEST_AUDIT_PACKET" ]; then
    printf 'Generate an audit packet before final archive review.\n'
  elif [ "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" = "stale" ]; then
    printf 'Regenerate the audit packet before final archive review.\n'
  elif [ "$audit_packet_verification_status" != "verified" ]; then
    printf 'Resolve audit packet verification issues before final archive review.\n'
  elif [ -z "$ATLAS_READINESS_LATEST_ARCHIVE_PACKET" ]; then
    printf 'Generate an archive packet before final archive review.\n'
  elif [ "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS" = "stale" ]; then
    printf 'Regenerate the archive packet before final archive review.\n'
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
  local review_packet_verification
  local review_packet_verification_status
  local review_packet_verification_path
  local archive_status
  local archive_next_step
  local ledger_file
  local ledger_events="0"
  local ledger_sha=""
  local handoff_sha=""
  local closeout_sha=""
  local review_packet_sha=""
  local audit_packet_sha=""

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

  review_packet_verification="$(atlas_archive_review_packet_verification_status)"
  IFS=$'\t' read -r review_packet_verification_status review_packet_verification_path <<<"$review_packet_verification"

  archive_status="$(atlas_archive_status "$closeout_verification_status" "$audit_packet_verification_status" "$review_packet_verification_status")"
  archive_next_step="$(atlas_archive_next_step "$closeout_verification_status" "$audit_packet_verification_status" "$review_packet_verification_status")"

  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  if [ -f "$ledger_file" ]; then
    ledger_events="$(atlas_closeout_ledger_event_count "$ledger_file")"
    ledger_sha="$(atlas_closeout_sha_for_file "$ledger_file")"
  fi
  handoff_sha="$(atlas_closeout_sha_for_file "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-}")"
  closeout_sha="$(atlas_closeout_sha_for_file "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-}")"
  review_packet_sha="$(atlas_closeout_sha_for_file "${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-}")"
  audit_packet_sha="$(atlas_closeout_sha_for_file "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-}")"

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
  ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_STATUS="$review_packet_verification_status"
  ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_PATH="$review_packet_verification_path"
  ATLAS_ARCHIVE_STATUS="$archive_status"
  ATLAS_ARCHIVE_NEXT_STEP="$archive_next_step"
  ATLAS_ARCHIVE_LEDGER_FILE="$ledger_file"
  ATLAS_ARCHIVE_LEDGER_EVENTS="$ledger_events"
  ATLAS_ARCHIVE_LEDGER_SHA="$ledger_sha"
  ATLAS_ARCHIVE_HANDOFF_SHA="$handoff_sha"
  ATLAS_ARCHIVE_CLOSEOUT_SHA="$closeout_sha"
  ATLAS_ARCHIVE_REVIEW_PACKET_SHA="$review_packet_sha"
  ATLAS_ARCHIVE_AUDIT_PACKET_SHA="$audit_packet_sha"
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
  ui_kv "Accepted Risks" "$ATLAS_READINESS_ACCEPTED_RISK_COUNT"
  ui_kv "Expired Accepted Risks" "$ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT"
  ui_kv "Pending Validation" "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
  ui_kv "Report Freshness" "$ATLAS_READINESS_REPORT_FRESHNESS"
  ui_kv "Bundle Freshness" "$ATLAS_READINESS_BUNDLE_FRESHNESS"
  ui_kv "Handoff Freshness" "$ATLAS_READINESS_HANDOFF_FRESHNESS"
  ui_kv "Closeout Freshness" "$ATLAS_READINESS_CLOSEOUT_FRESHNESS"
  ui_kv "Accepted Risk Review Packet Freshness" "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS"
  ui_kv "Audit Packet Freshness" "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS"
  ui_kv "Archive Packet Freshness" "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS"
  ui_rule
  ui_subheading "Verification"
  ui_kv "Closeout Verification" "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS manifest=$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH problems=$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS"
  ui_kv "Accepted Risk Review Packet Verification" "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_STATUS packet=$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_PATH"
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
  ui_kv "Latest Accepted Risk Review Packet" "${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-none generated yet}"
  ui_kv "Latest Audit Packet" "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none generated yet}"
  ui_kv "Latest Archive Packet" "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none generated yet}"
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

  printf -- "- Latest handoff: \`%s\`" "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none}"
  if [ -n "${ATLAS_ARCHIVE_HANDOFF_SHA:-}" ]; then
    printf ' sha256=%s' "$ATLAS_ARCHIVE_HANDOFF_SHA"
  fi
  printf '\n'
  printf -- "- Latest closeout: \`%s\`" "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none}"
  if [ -n "${ATLAS_ARCHIVE_CLOSEOUT_SHA:-}" ]; then
    printf ' sha256=%s' "$ATLAS_ARCHIVE_CLOSEOUT_SHA"
  fi
  printf '\n'
  printf -- "- Latest accepted-risk review packet: \`%s\`" "${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-none}"
  if [ -n "${ATLAS_ARCHIVE_REVIEW_PACKET_SHA:-}" ]; then
    printf ' sha256=%s' "$ATLAS_ARCHIVE_REVIEW_PACKET_SHA"
  fi
  printf '\n'
  printf -- "- Latest audit packet: \`%s\`" "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none}"
  if [ -n "${ATLAS_ARCHIVE_AUDIT_PACKET_SHA:-}" ]; then
    printf ' sha256=%s' "$ATLAS_ARCHIVE_AUDIT_PACKET_SHA"
  fi
  printf '\n'
  printf -- "- Latest archive packet: \`%s\`\n" "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none}"
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
    printf -- '- Accepted risks: %s\n' "$ATLAS_READINESS_ACCEPTED_RISK_COUNT"
    printf -- '- Expired accepted risks: %s\n' "$ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT"
    printf -- '- Pending validation: %s\n' "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
    printf -- '- Report freshness: %s\n' "$ATLAS_READINESS_REPORT_FRESHNESS"
    printf -- '- Bundle freshness: %s\n' "$ATLAS_READINESS_BUNDLE_FRESHNESS"
    printf -- '- Handoff freshness: %s\n' "$ATLAS_READINESS_HANDOFF_FRESHNESS"
    printf -- '- Closeout freshness: %s\n' "$ATLAS_READINESS_CLOSEOUT_FRESHNESS"
    printf -- '- Accepted-risk review packet freshness: %s\n' "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS"
    printf -- '- Audit packet freshness: %s\n' "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS"
    printf -- '- Archive packet freshness: %s\n' "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS"

    printf '\n## Verification\n\n'
    printf -- '- Closeout verification: %s manifest=%s problems=%s\n' "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS" "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH" "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS"
    printf -- '- Accepted-risk review packet verification: %s packet=%s\n' "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_STATUS" "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_PATH"
    printf -- '- Audit packet verification: %s packet=%s\n' "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS" "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_PATH"

    printf '\n## Archive Artifacts\n\n'
    atlas_archive_markdown_artifacts

    printf '\n## Retention Notes\n\n'
    printf -- '- Treat paths as local references; verify copied files against the recorded hashes before retention or transfer.\n'
    printf -- '- Keep this packet with the closeout manifest and audit packet for final review.\n'
  } >"$file"
}

atlas_archive_write_json_packet() {
  local file="$1"
  local generated_at="$2"

  atlas_archive_collect
  intel_require_jq

  jq -n \
    --arg schema_version "atlas.archive_packet.v1" \
    --arg generated_at "$generated_at" \
    --arg operation_name "$ATLAS_OP_NAME" \
    --arg operation_id "$ATLAS_OP_SLUG" \
    --arg operation_status "$ATLAS_OP_STATUS" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg address "${ATLAS_OP_TARGET_ADDRESS:-}" \
    --arg archive_status "$ATLAS_ARCHIVE_STATUS" \
    --arg archive_next_step "$ATLAS_ARCHIVE_NEXT_STEP" \
    --arg close_readiness "$ATLAS_READINESS_STATUS" \
    --arg readiness_next_step "$ATLAS_READINESS_NEXT_STEP" \
    --argjson evidence_records "${ATLAS_READINESS_EVIDENCE_COUNT:-0}" \
    --argjson open_findings "${ATLAS_READINESS_OPEN_FINDINGS_COUNT:-0}" \
    --argjson accepted_risks "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" \
    --argjson expired_accepted_risks "${ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT:-0}" \
    --argjson pending_validation "${ATLAS_READINESS_PENDING_VALIDATION_COUNT:-0}" \
    --arg report_freshness "$ATLAS_READINESS_REPORT_FRESHNESS" \
    --arg bundle_freshness "$ATLAS_READINESS_BUNDLE_FRESHNESS" \
    --arg handoff_freshness "$ATLAS_READINESS_HANDOFF_FRESHNESS" \
    --arg closeout_freshness "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" \
    --arg review_packet_freshness "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS" \
    --arg audit_packet_freshness "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" \
    --arg archive_packet_freshness "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS" \
    --arg closeout_verification_status "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS" \
    --arg closeout_verification_path "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH" \
    --argjson closeout_verification_problems "${ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS:-0}" \
    --arg review_packet_verification_status "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_STATUS" \
    --arg review_packet_verification_path "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_PATH" \
    --arg audit_packet_verification_status "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS" \
    --arg audit_packet_verification_path "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_PATH" \
    --arg latest_report_path "$ATLAS_ARCHIVE_LATEST_REPORT_PATH" \
    --arg latest_report_generated_at "$ATLAS_ARCHIVE_LATEST_REPORT_AT" \
    --arg latest_report_sha256 "$ATLAS_ARCHIVE_LATEST_REPORT_SHA" \
    --arg evidence_bundle_path "$ATLAS_ARCHIVE_BUNDLE_DIR" \
    --arg evidence_bundle_generated_at "$ATLAS_ARCHIVE_BUNDLE_AT" \
    --arg evidence_bundle_slug "$ATLAS_ARCHIVE_BUNDLE_SLUG" \
    --argjson evidence_bundle_files "${ATLAS_ARCHIVE_BUNDLE_FILES:-0}" \
    --arg evidence_bundle_include_unredacted "${ATLAS_ARCHIVE_BUNDLE_INCLUDE_UNREDACTED:-0}" \
    --arg evidence_manifest_path "$ATLAS_ARCHIVE_BUNDLE_MANIFEST" \
    --arg evidence_manifest_sha256 "$ATLAS_ARCHIVE_BUNDLE_MANIFEST_SHA" \
    --arg latest_handoff_path "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-}" \
    --arg latest_handoff_sha256 "$ATLAS_ARCHIVE_HANDOFF_SHA" \
    --arg latest_closeout_path "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-}" \
    --arg latest_closeout_sha256 "$ATLAS_ARCHIVE_CLOSEOUT_SHA" \
    --arg latest_review_packet_path "${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-}" \
    --arg latest_review_packet_sha256 "$ATLAS_ARCHIVE_REVIEW_PACKET_SHA" \
    --arg latest_audit_packet_path "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-}" \
    --arg latest_audit_packet_sha256 "$ATLAS_ARCHIVE_AUDIT_PACKET_SHA" \
    --arg latest_archive_packet_path "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-}" \
    --arg ledger_path "$ATLAS_ARCHIVE_LEDGER_FILE" \
    --argjson ledger_events "${ATLAS_ARCHIVE_LEDGER_EVENTS:-0}" \
    --arg ledger_sha256 "$ATLAS_ARCHIVE_LEDGER_SHA" \
    --arg operation_directory "$ATLAS_OP_DIR" '
      def nullable($v):
        if $v == "" or $v == "-" or $v == "none" then null else $v end;
      {
        schema_version: $schema_version,
        generated_at: $generated_at,
        operation: {
          name: $operation_name,
          id: $operation_id,
          status: $operation_status,
          target: $target,
          address: nullable($address)
        },
        metadata_only: true,
        raw_artifacts_embedded: false,
        archive_status: {
          status: $archive_status,
          next_step: $archive_next_step
        },
        readiness: {
          close_readiness: $close_readiness,
          next_step: $readiness_next_step,
          evidence_records: $evidence_records,
          open_findings: $open_findings,
          accepted_risks: $accepted_risks,
          expired_accepted_risks: $expired_accepted_risks,
          pending_validation: $pending_validation,
          freshness: {
            report: $report_freshness,
            bundle: $bundle_freshness,
            handoff: $handoff_freshness,
            closeout: $closeout_freshness,
            accepted_risk_review_packet: $review_packet_freshness,
            audit_packet: $audit_packet_freshness,
            archive_packet: $archive_packet_freshness
          }
        },
        verification: {
          closeout: {
            status: $closeout_verification_status,
            path: nullable($closeout_verification_path),
            problems: $closeout_verification_problems
          },
          accepted_risk_review_packet: {
            status: $review_packet_verification_status,
            path: nullable($review_packet_verification_path)
          },
          audit_packet: {
            status: $audit_packet_verification_status,
            path: nullable($audit_packet_verification_path)
          }
        },
        artifacts: {
          latest_report: {
            path: nullable($latest_report_path),
            generated_at: nullable($latest_report_generated_at),
            sha256: nullable($latest_report_sha256)
          },
          evidence_bundle: {
            path: nullable($evidence_bundle_path),
            generated_at: nullable($evidence_bundle_generated_at),
            slug: nullable($evidence_bundle_slug),
            files: $evidence_bundle_files,
            include_unredacted: ($evidence_bundle_include_unredacted == "1" or $evidence_bundle_include_unredacted == "true")
          },
          evidence_manifest: {
            path: nullable($evidence_manifest_path),
            sha256: nullable($evidence_manifest_sha256)
          },
          latest_handoff: {
            path: nullable($latest_handoff_path),
            sha256: nullable($latest_handoff_sha256)
          },
          latest_closeout: {
            path: nullable($latest_closeout_path),
            sha256: nullable($latest_closeout_sha256)
          },
          latest_accepted_risk_review_packet: {
            path: nullable($latest_review_packet_path),
            sha256: nullable($latest_review_packet_sha256)
          },
          latest_audit_packet: {
            path: nullable($latest_audit_packet_path),
            sha256: nullable($latest_audit_packet_sha256)
          },
          latest_archive_packet: {
            path: nullable($latest_archive_packet_path)
          },
          operation_ledger: {
            path: nullable($ledger_path),
            events: $ledger_events,
            sha256: nullable($ledger_sha256)
          },
          operation_directory: $operation_directory
        },
        known_limitations: [
          "Archive packets are metadata-only and retain references, hashes, counts, timestamps, freshness states, and verification states.",
          "Raw artifact contents are not embedded in archive packets.",
          "Archive packet verification checks retained file hash anchors and ledger anchors; it is not external audit or cryptographic immutability."
        ]
      }
    ' >"$file"
}

atlas_archive_latest_packet() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "archive.packet.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_archive_resolve_packet() {
  local packet_arg="$1"
  local latest_packet
  local latest_packet_path=""
  local candidate
  local packet_base
  local packet_slug

  if [ -z "$packet_arg" ]; then
    latest_packet="$(atlas_archive_latest_packet)"
    [ -n "$latest_packet" ] || fail "no archive packet recorded for operation '$ATLAS_OP_SLUG'"
    IFS=$'\t' read -r _ latest_packet_path <<<"$latest_packet"
    [ -f "$latest_packet_path" ] || fail "recorded archive packet is missing: $latest_packet_path"
    printf '%s\n' "$latest_packet_path"
    return 0
  fi

  if [ -f "$packet_arg" ]; then
    readlink -f "$packet_arg"
    return 0
  fi

  candidate="$ATLAS_OP_DIR/archive/$packet_arg"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  packet_base="${packet_arg%.md}"
  packet_base="${packet_base%.json}"
  packet_slug="$(slugify "$packet_base")"
  candidate="$ATLAS_OP_DIR/archive/$packet_slug.md"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi
  candidate="$ATLAS_OP_DIR/archive/$packet_slug.json"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  fail "unknown archive packet for operation '$ATLAS_OP_SLUG': $packet_arg"
}

atlas_archive_verify_row() {
  local label="$1"
  local status="$2"
  local path="$3"
  local detail="${4:-}"

  if [ -n "$detail" ]; then
    printf '%-22s %-14s %s (%s)\n' "$label" "$status" "$path" "$detail"
  else
    printf '%-22s %-14s %s\n' "$label" "$status" "$path"
  fi
}

atlas_archive_verify_hash_anchor() {
  local packet_file="$1"
  local packet_label="$2"
  local display_label="$3"
  local line
  local path
  local expected_sha
  local actual_sha

  line="$(atlas_closeout_manifest_anchor_line "$packet_file" "$packet_label")"
  if [ -z "$line" ]; then
    atlas_archive_verify_row "$display_label" "unverifiable" "-" "anchor missing from packet"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  path="$(atlas_closeout_anchor_path "$line")"
  if [ -z "$path" ] || [ "$path" = "none" ]; then
    atlas_archive_verify_row "$display_label" "not-recorded" "${path:--}"
    ATLAS_ARCHIVE_VERIFY_GAPS=$((ATLAS_ARCHIVE_VERIFY_GAPS + 1))
    return 0
  fi

  expected_sha="$(atlas_closeout_anchor_token "$line" "sha256")"
  if [ -z "$expected_sha" ]; then
    atlas_archive_verify_row "$display_label" "unverifiable" "$path" "missing expected sha256"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_archive_verify_row "$display_label" "missing" "$path" "expected sha256=$expected_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_sha" = "$expected_sha" ]; then
    atlas_archive_verify_row "$display_label" "verified" "$path"
    ATLAS_ARCHIVE_VERIFY_VERIFIED=$((ATLAS_ARCHIVE_VERIFY_VERIFIED + 1))
  else
    atlas_archive_verify_row "$display_label" "changed" "$path" "expected=$expected_sha actual=$actual_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
  fi
}

atlas_archive_verify_ledger_anchor() {
  local packet_file="$1"
  local line
  local path
  local expected_events
  local actual_events
  local expected_sha
  local actual_sha

  line="$(atlas_closeout_manifest_anchor_line "$packet_file" "Operation ledger")"
  if [ -z "$line" ]; then
    atlas_archive_verify_row "Operation Ledger" "unverifiable" "-" "anchor missing from packet"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  path="$(atlas_closeout_anchor_path "$line")"
  expected_events="$(atlas_closeout_anchor_token "$line" "events")"
  expected_sha="$(atlas_closeout_anchor_token "$line" "sha256")"
  if [ -z "$path" ] || [ -z "$expected_events" ] || [ -z "$expected_sha" ]; then
    atlas_archive_verify_row "Operation Ledger" "unverifiable" "${path:--}" "missing events or sha256"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_archive_verify_row "Operation Ledger" "missing" "$path" "expected events=$expected_events sha256=$expected_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_events="$(atlas_closeout_ledger_event_count "$path")"
  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_events" = "$expected_events" ] && [ "$actual_sha" = "$expected_sha" ]; then
    atlas_archive_verify_row "Operation Ledger" "verified" "$path" "events=$actual_events"
    ATLAS_ARCHIVE_VERIFY_VERIFIED=$((ATLAS_ARCHIVE_VERIFY_VERIFIED + 1))
  else
    atlas_archive_verify_row "Operation Ledger" "changed" "$path" "expected_events=$expected_events actual_events=$actual_events expected_sha=$expected_sha actual_sha=$actual_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
  fi
}

atlas_archive_verify_json_path_sha_anchor() {
  local packet_file="$1"
  local jq_path="$2"
  local display_label="$3"
  local path
  local expected_sha
  local actual_sha

  path="$(jq -r "$jq_path.path // \"\"" "$packet_file" 2>/dev/null || true)"
  expected_sha="$(jq -r "$jq_path.sha256 // \"\"" "$packet_file" 2>/dev/null || true)"
  if [ -z "$path" ]; then
    atlas_archive_verify_row "$display_label" "not-recorded" "-"
    ATLAS_ARCHIVE_VERIFY_GAPS=$((ATLAS_ARCHIVE_VERIFY_GAPS + 1))
    return 0
  fi

  if [ -z "$expected_sha" ]; then
    atlas_archive_verify_row "$display_label" "unverifiable" "$path" "missing expected sha256"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_archive_verify_row "$display_label" "missing" "$path" "expected sha256=$expected_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_sha" = "$expected_sha" ]; then
    atlas_archive_verify_row "$display_label" "verified" "$path"
    ATLAS_ARCHIVE_VERIFY_VERIFIED=$((ATLAS_ARCHIVE_VERIFY_VERIFIED + 1))
  else
    atlas_archive_verify_row "$display_label" "changed" "$path" "expected=$expected_sha actual=$actual_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
  fi
}

atlas_archive_verify_json_ledger_anchor() {
  local packet_file="$1"
  local path
  local expected_events
  local actual_events
  local expected_sha
  local actual_sha

  path="$(jq -r '.artifacts.operation_ledger.path // ""' "$packet_file" 2>/dev/null || true)"
  expected_events="$(jq -r '.artifacts.operation_ledger.events // ""' "$packet_file" 2>/dev/null || true)"
  expected_sha="$(jq -r '.artifacts.operation_ledger.sha256 // ""' "$packet_file" 2>/dev/null || true)"
  if [ -z "$path" ] || [ -z "$expected_events" ] || [ -z "$expected_sha" ]; then
    atlas_archive_verify_row "Operation Ledger" "unverifiable" "${path:--}" "missing events or sha256"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_archive_verify_row "Operation Ledger" "missing" "$path" "expected events=$expected_events sha256=$expected_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_events="$(atlas_closeout_ledger_event_count "$path")"
  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_events" = "$expected_events" ] && [ "$actual_sha" = "$expected_sha" ]; then
    atlas_archive_verify_row "Operation Ledger" "verified" "$path" "events=$actual_events"
    ATLAS_ARCHIVE_VERIFY_VERIFIED=$((ATLAS_ARCHIVE_VERIFY_VERIFIED + 1))
  else
    atlas_archive_verify_row "Operation Ledger" "changed" "$path" "expected_events=$expected_events actual_events=$actual_events expected_sha=$expected_sha actual_sha=$actual_sha"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
  fi
}

atlas_archive_json_packet_forbidden_content_present() {
  local packet_file="$1"

  jq -r '
    paths(scalars) as $path
    | getpath($path)
    | strings
  ' "$packet_file" 2>/dev/null |
    tr '[:upper:]' '[:lower:]' |
    grep -Eq 'password=|passwd=|api_key=|secret=|token=|authorization:|bearer[[:space:]]|set-cookie:|begin rsa|begin openssh|session=|cookie='
}

atlas_archive_verify_json_packet() {
  local packet_file="$1"
  local packet_operation
  local verification_status="verified"

  [ -f "$packet_file" ] || fail "archive packet is not a file: $packet_file"
  intel_require_jq
  jq -e 'type == "object"' "$packet_file" >/dev/null 2>&1 || fail "archive JSON packet is invalid: $packet_file"
  jq -e '.schema_version == "atlas.archive_packet.v1"' "$packet_file" >/dev/null 2>&1 || fail "archive JSON packet has unsupported schema: $packet_file"
  packet_operation="$(jq -r '.operation.id // ""' "$packet_file")"
  [ -n "$packet_operation" ] || fail "archive JSON packet is missing operation.id: $packet_file"
  [ "$packet_operation" = "$ATLAS_OP_SLUG" ] || fail "archive packet belongs to '$packet_operation', not '$ATLAS_OP_SLUG'"

  ATLAS_ARCHIVE_VERIFY_PROBLEMS=0
  ATLAS_ARCHIVE_VERIFY_GAPS=0
  ATLAS_ARCHIVE_VERIFY_VERIFIED=0

  ui_heading "Archive Packet Verification"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Packet" "$packet_file"
  ui_rule
  printf '%-22s %-14s %s\n' "ARTIFACT" "STATUS" "PATH"

  if jq -e '.metadata_only == true' "$packet_file" >/dev/null 2>&1; then
    atlas_archive_verify_row "Metadata Only" "verified" "true"
    ATLAS_ARCHIVE_VERIFY_VERIFIED=$((ATLAS_ARCHIVE_VERIFY_VERIFIED + 1))
  else
    atlas_archive_verify_row "Metadata Only" "blocked" "expected=true"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
  fi

  if jq -e '.raw_artifacts_embedded == false' "$packet_file" >/dev/null 2>&1; then
    atlas_archive_verify_row "Raw Artifacts" "verified" "embedded=false"
    ATLAS_ARCHIVE_VERIFY_VERIFIED=$((ATLAS_ARCHIVE_VERIFY_VERIFIED + 1))
  else
    atlas_archive_verify_row "Raw Artifacts" "blocked" "expected embedded=false"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
  fi

  if atlas_archive_json_packet_forbidden_content_present "$packet_file"; then
    atlas_archive_verify_row "Forbidden Content" "blocked" "$packet_file" "raw-content marker detected"
    ATLAS_ARCHIVE_VERIFY_PROBLEMS=$((ATLAS_ARCHIVE_VERIFY_PROBLEMS + 1))
  else
    atlas_archive_verify_row "Forbidden Content" "verified" "$packet_file"
    ATLAS_ARCHIVE_VERIFY_VERIFIED=$((ATLAS_ARCHIVE_VERIFY_VERIFIED + 1))
  fi

  atlas_archive_verify_json_path_sha_anchor "$packet_file" ".artifacts.latest_report" "Latest Report"
  atlas_archive_verify_json_path_sha_anchor "$packet_file" ".artifacts.evidence_manifest" "Evidence Manifest"
  atlas_archive_verify_json_path_sha_anchor "$packet_file" ".artifacts.latest_handoff" "Latest Handoff"
  atlas_archive_verify_json_path_sha_anchor "$packet_file" ".artifacts.latest_closeout" "Latest Closeout"
  atlas_archive_verify_json_path_sha_anchor "$packet_file" ".artifacts.latest_accepted_risk_review_packet" "Accepted Risk Review Packet"
  atlas_archive_verify_json_path_sha_anchor "$packet_file" ".artifacts.latest_audit_packet" "Latest Audit Packet"
  atlas_archive_verify_json_ledger_anchor "$packet_file"
  ui_rule

  if [ "$ATLAS_ARCHIVE_VERIFY_PROBLEMS" -gt 0 ]; then
    verification_status="attention-required"
  fi
  ui_kv "Verification Status" "$verification_status"
  ui_kv "Verified Anchors" "$ATLAS_ARCHIVE_VERIFY_VERIFIED"
  ui_kv "Verification Gaps" "$ATLAS_ARCHIVE_VERIFY_GAPS"
  ui_kv "Verification Problems" "$ATLAS_ARCHIVE_VERIFY_PROBLEMS"

  [ "$ATLAS_ARCHIVE_VERIFY_PROBLEMS" -eq 0 ] || return 1
}

atlas_archive_verify_markdown_packet() {
  local packet_file="$1"
  local packet_operation
  local verification_status="verified"

  [ -f "$packet_file" ] || fail "archive packet is not a file: $packet_file"
  packet_operation="$(atlas_audit_packet_field "$packet_file" "Operation ID")"
  [ -n "$packet_operation" ] || fail "archive packet is missing Operation ID: $packet_file"
  [ "$packet_operation" = "$ATLAS_OP_SLUG" ] || fail "archive packet belongs to '$packet_operation', not '$ATLAS_OP_SLUG'"

  ATLAS_ARCHIVE_VERIFY_PROBLEMS=0
  ATLAS_ARCHIVE_VERIFY_GAPS=0
  ATLAS_ARCHIVE_VERIFY_VERIFIED=0

  ui_heading "Archive Packet Verification"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Packet" "$packet_file"
  ui_rule
  printf '%-22s %-14s %s\n' "ARTIFACT" "STATUS" "PATH"
  atlas_archive_verify_hash_anchor "$packet_file" "Latest report" "Latest Report"
  atlas_archive_verify_hash_anchor "$packet_file" "Evidence manifest" "Evidence Manifest"
  atlas_archive_verify_hash_anchor "$packet_file" "Latest handoff" "Latest Handoff"
  atlas_archive_verify_hash_anchor "$packet_file" "Latest closeout" "Latest Closeout"
  atlas_archive_verify_hash_anchor "$packet_file" "Latest accepted-risk review packet" "Accepted Risk Review Packet"
  atlas_archive_verify_hash_anchor "$packet_file" "Latest audit packet" "Latest Audit Packet"
  atlas_archive_verify_ledger_anchor "$packet_file"
  ui_rule

  if [ "$ATLAS_ARCHIVE_VERIFY_PROBLEMS" -gt 0 ]; then
    verification_status="attention-required"
  fi
  ui_kv "Verification Status" "$verification_status"
  ui_kv "Verified Anchors" "$ATLAS_ARCHIVE_VERIFY_VERIFIED"
  ui_kv "Verification Gaps" "$ATLAS_ARCHIVE_VERIFY_GAPS"
  ui_kv "Verification Problems" "$ATLAS_ARCHIVE_VERIFY_PROBLEMS"

  [ "$ATLAS_ARCHIVE_VERIFY_PROBLEMS" -eq 0 ] || return 1
}

atlas_archive_verify_packet() {
  local packet_file="$1"

  [ -f "$packet_file" ] || fail "archive packet is not a file: $packet_file"
  if jq -e '.schema_version == "atlas.archive_packet.v1"' "$packet_file" >/dev/null 2>&1; then
    atlas_archive_verify_json_packet "$packet_file"
  else
    atlas_archive_verify_markdown_packet "$packet_file"
  fi
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
  local json_output=0
  local operation_name=""
  local packet_name=""
  local packet_slug
  local archive_dir
  local packet_file
  local generated_at

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json_output=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail "unknown op archive-packet option: $1"
      ;;
    *)
      if [ -z "$operation_name" ]; then
        operation_name="$1"
      elif [ -z "$packet_name" ]; then
        packet_name="$1"
      else
        fail "op archive-packet [--json] [name] [packet-name]"
      fi
      shift
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "op archive-packet [--json] [name] [packet-name]"

  if [ -n "$operation_name" ]; then
    load_atlas_operation "$operation_name"
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
  if [ "$json_output" -eq 1 ]; then
    packet_file="$archive_dir/$packet_slug.json"
  else
    packet_file="$archive_dir/$packet_slug.md"
  fi

  atlas_ledger_append_current "archive.packet.generated" "read-only" "atlas" "ok" "$packet_file"
  generated_at="$(timestamp)"
  if [ "$json_output" -eq 1 ]; then
    atlas_archive_write_json_packet "$packet_file" "$generated_at"
  else
    atlas_archive_write_packet "$packet_file"
  fi
  chmod 600 "$packet_file" 2>/dev/null || true
  record_operation_history "$ATLAS_OP_DIR" "archive-packet" "$packet_file"

  if [ "$json_output" -eq 1 ]; then
    ui_ok "archive JSON packet written"
    printf 'archive_packet_json: %s\n' "$packet_file"
  else
    ui_ok "archive packet written"
    printf 'archive_packet: %s\n' "$packet_file"
  fi
}

cmd_op_archive_verify() {
  local operation_name=""
  local packet_arg=""
  local packet_file
  local slug

  [ "$#" -le 2 ] || fail "op archive-verify [name] [archive-packet]"

  if [ "$#" -eq 0 ]; then
    load_active_operation
  elif [ "$#" -eq 1 ]; then
    slug="$(session_slug_for "$1")"
    if [ -f "$(atlas_op_file_for_slug "$slug")" ]; then
      load_atlas_operation "$1"
    else
      load_active_operation
      packet_arg="$1"
    fi
  else
    operation_name="$1"
    packet_arg="$2"
    load_atlas_operation "$operation_name"
  fi

  packet_file="$(atlas_archive_resolve_packet "$packet_arg")"
  atlas_archive_verify_packet "$packet_file"
}
