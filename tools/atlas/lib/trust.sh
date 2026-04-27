#!/usr/bin/env bash

atlas_trust_chain_archive_packet_verification_status() {
  local packet_path="${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-}"

  if [ -z "$packet_path" ]; then
    printf 'missing\t-\n'
    return 0
  fi

  if [ ! -f "$packet_path" ]; then
    printf 'missing\t%s\n' "$packet_path"
    return 0
  fi

  if (atlas_archive_verify_packet "$packet_path" >/dev/null 2>&1); then
    printf 'verified\t%s\n' "$packet_path"
  else
    printf 'attention-required\t%s\n' "$packet_path"
  fi
}

atlas_trust_chain_v1_summary() {
  local previous_rows_file="${atlas_v1_rows_file:-}"
  local rows_file
  local overall
  local blocked
  local warnings
  local required_not_ready

  rows_file="$(mktemp)"
  atlas_v1_rows_file="$rows_file"
  atlas_v1_collect
  overall="$(atlas_v1_overall)"
  blocked="${atlas_v1_blocked:-0}"
  warnings="${atlas_v1_warnings:-0}"
  required_not_ready="${atlas_v1_required_not_ready:-0}"
  rm -f "$rows_file"
  atlas_v1_rows_file="$previous_rows_file"

  printf '%s\t%s\t%s\t%s\n' "$overall" "$blocked" "$warnings" "$required_not_ready"
}

atlas_trust_chain_status() {
  local archive_packet_verification_status="$1"
  local v1_overall="$2"

  if [ "$ATLAS_ARCHIVE_STATUS" != "current" ]; then
    printf '%s\n' "$ATLAS_ARCHIVE_STATUS"
  elif [ "$archive_packet_verification_status" != "verified" ]; then
    printf 'attention-required\n'
  elif [ "$v1_overall" != "ready" ]; then
    printf 'attention-required\n'
  else
    printf 'current\n'
  fi
}

atlas_trust_chain_next_step() {
  local archive_packet_verification_status="$1"
  local v1_overall="$2"

  if [ "$ATLAS_ARCHIVE_STATUS" != "current" ]; then
    printf '%s\n' "$ATLAS_ARCHIVE_NEXT_STEP"
  elif [ "$archive_packet_verification_status" != "verified" ]; then
    printf 'Resolve archive packet verification issues before trust-chain closeout.\n'
  elif [ "$v1_overall" != "ready" ]; then
    printf 'Resolve v1 readiness gaps before trust-chain closeout.\n'
  else
    printf 'Trust chain is current.\n'
  fi
}

atlas_trust_chain_collect() {
  local archive_packet_verification
  local archive_packet_verification_status
  local archive_packet_verification_path
  local v1_summary
  local v1_overall
  local v1_blocked
  local v1_warnings
  local v1_required_not_ready

  atlas_archive_collect

  archive_packet_verification="$(atlas_trust_chain_archive_packet_verification_status)"
  IFS=$'\t' read -r archive_packet_verification_status archive_packet_verification_path <<<"$archive_packet_verification"

  v1_summary="$(atlas_trust_chain_v1_summary)"
  IFS=$'\t' read -r v1_overall v1_blocked v1_warnings v1_required_not_ready <<<"$v1_summary"

  ATLAS_TRUST_ARCHIVE_PACKET_VERIFICATION_STATUS="$archive_packet_verification_status"
  ATLAS_TRUST_ARCHIVE_PACKET_VERIFICATION_PATH="$archive_packet_verification_path"
  ATLAS_TRUST_V1_OVERALL="$v1_overall"
  ATLAS_TRUST_V1_BLOCKED="$v1_blocked"
  ATLAS_TRUST_V1_WARNINGS="$v1_warnings"
  ATLAS_TRUST_V1_REQUIRED_NOT_READY="$v1_required_not_ready"
  ATLAS_TRUST_CHAIN_STATUS="$(atlas_trust_chain_status "$archive_packet_verification_status" "$v1_overall")"
  ATLAS_TRUST_CHAIN_NEXT_STEP="$(atlas_trust_chain_next_step "$archive_packet_verification_status" "$v1_overall")"
}

atlas_trust_chain_print() {
  atlas_trust_chain_collect

  ui_heading "Operation Trust Chain"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Operation Status" "$ATLAS_OP_STATUS"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Trust Chain Status" "$ATLAS_TRUST_CHAIN_STATUS"
  ui_kv "Next Trust Step" "$ATLAS_TRUST_CHAIN_NEXT_STEP"
  ui_rule
  ui_subheading "Readiness"
  ui_kv "Close Readiness" "$ATLAS_READINESS_STATUS"
  ui_kv "Evidence Records" "$ATLAS_READINESS_EVIDENCE_COUNT"
  ui_kv "Open Findings" "$ATLAS_READINESS_OPEN_FINDINGS_COUNT"
  ui_kv "Accepted Risks" "$ATLAS_READINESS_ACCEPTED_RISK_COUNT"
  ui_kv "Expired Accepted Risks" "$ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT"
  ui_kv "Pending Validation" "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
  ui_kv "V1 Readiness" "$ATLAS_TRUST_V1_OVERALL required_not_ready=$ATLAS_TRUST_V1_REQUIRED_NOT_READY blocked=$ATLAS_TRUST_V1_BLOCKED warnings=$ATLAS_TRUST_V1_WARNINGS"
  ui_rule
  ui_subheading "Freshness"
  ui_kv "Report" "$ATLAS_READINESS_REPORT_FRESHNESS path=${ATLAS_READINESS_LATEST_REPORT_PATH:-none}"
  ui_kv "Evidence Bundle" "$ATLAS_READINESS_BUNDLE_FRESHNESS detail=${ATLAS_READINESS_LATEST_BUNDLE_DETAIL:-none}"
  ui_kv "Handoff" "$ATLAS_READINESS_HANDOFF_FRESHNESS path=${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none}"
  ui_kv "Closeout" "$ATLAS_READINESS_CLOSEOUT_FRESHNESS path=${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none}"
  ui_kv "Accepted Risk Review Packet" "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS path=${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-none}"
  ui_kv "Audit Packet" "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS path=${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none}"
  ui_kv "Archive Packet" "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS path=${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none}"
  ui_rule
  ui_subheading "Verification"
  ui_kv "Closeout" "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS manifest=$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH problems=$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS"
  ui_kv "Accepted Risk Review Packet" "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_STATUS packet=$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_PATH"
  ui_kv "Audit Packet" "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS packet=$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_PATH"
  ui_kv "Archive Packet" "$ATLAS_TRUST_ARCHIVE_PACKET_VERIFICATION_STATUS packet=$ATLAS_TRUST_ARCHIVE_PACKET_VERIFICATION_PATH"
  ui_rule
  ui_subheading "Ledger"
  ui_kv "Operation Ledger" "$ATLAS_ARCHIVE_LEDGER_FILE events=$ATLAS_ARCHIVE_LEDGER_EVENTS sha256=$ATLAS_ARCHIVE_LEDGER_SHA"
  ui_kv "Latest Ledger Event" "${ATLAS_READINESS_LATEST_LEDGER_AT:-none} ${ATLAS_READINESS_LATEST_LEDGER_EVENT_NAME:-none}"
}

atlas_trust_chain_print_json() {
  atlas_trust_chain_collect

  jq -n \
    --arg schema_version "atlas.operation_trust_chain.v1" \
    --arg slug "$ATLAS_OP_SLUG" \
    --arg name "$ATLAS_OP_NAME" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg operation_status "$ATLAS_OP_STATUS" \
    --arg status "$ATLAS_TRUST_CHAIN_STATUS" \
    --arg next_step "$ATLAS_TRUST_CHAIN_NEXT_STEP" \
    --arg close_readiness "$ATLAS_READINESS_STATUS" \
    --arg readiness_next_step "$ATLAS_READINESS_NEXT_STEP" \
    --argjson evidence_records "${ATLAS_READINESS_EVIDENCE_COUNT:-0}" \
    --argjson open_findings "${ATLAS_READINESS_OPEN_FINDINGS_COUNT:-0}" \
    --argjson accepted_risks "${ATLAS_READINESS_ACCEPTED_RISK_COUNT:-0}" \
    --argjson expired_accepted_risks "${ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT:-0}" \
    --argjson pending_validation "${ATLAS_READINESS_PENDING_VALIDATION_COUNT:-0}" \
    --arg v1_overall "$ATLAS_TRUST_V1_OVERALL" \
    --argjson v1_required_not_ready "${ATLAS_TRUST_V1_REQUIRED_NOT_READY:-0}" \
    --argjson v1_blocked "${ATLAS_TRUST_V1_BLOCKED:-0}" \
    --argjson v1_warnings "${ATLAS_TRUST_V1_WARNINGS:-0}" \
    --arg report_freshness "$ATLAS_READINESS_REPORT_FRESHNESS" \
    --arg bundle_freshness "$ATLAS_READINESS_BUNDLE_FRESHNESS" \
    --arg handoff_freshness "$ATLAS_READINESS_HANDOFF_FRESHNESS" \
    --arg closeout_freshness "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" \
    --arg review_packet_freshness "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS" \
    --arg audit_packet_freshness "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" \
    --arg archive_packet_freshness "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS" \
    --arg closeout_verification "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS" \
    --argjson closeout_problems "${ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PROBLEMS:-0}" \
    --arg review_packet_verification "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_STATUS" \
    --arg audit_packet_verification "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS" \
    --arg archive_packet_verification "$ATLAS_TRUST_ARCHIVE_PACKET_VERIFICATION_STATUS" \
    --arg report_path "${ATLAS_READINESS_LATEST_REPORT_PATH:-none}" \
    --arg evidence_bundle "${ATLAS_READINESS_LATEST_BUNDLE_DETAIL:-none}" \
    --arg handoff_path "${ATLAS_READINESS_LATEST_HANDOFF_PATH:-none}" \
    --arg closeout_path "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none}" \
    --arg review_packet_path "${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-none}" \
    --arg audit_packet_path "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none}" \
    --arg archive_packet_path "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none}" \
    --arg closeout_verification_path "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_PATH" \
    --arg review_packet_verification_path "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_PATH" \
    --arg audit_packet_verification_path "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_PATH" \
    --arg archive_packet_verification_path "$ATLAS_TRUST_ARCHIVE_PACKET_VERIFICATION_PATH" \
    --arg ledger_file "$ATLAS_ARCHIVE_LEDGER_FILE" \
    --argjson ledger_events "${ATLAS_ARCHIVE_LEDGER_EVENTS:-0}" \
    --arg ledger_sha "$ATLAS_ARCHIVE_LEDGER_SHA" \
    --arg latest_ledger_at "${ATLAS_READINESS_LATEST_LEDGER_AT:-none}" \
    --arg latest_ledger_event "${ATLAS_READINESS_LATEST_LEDGER_EVENT_NAME:-none}" \
    '{
      schema_version: $schema_version,
      operation: {
        slug: $slug,
        name: $name,
        target: $target,
        status: $operation_status
      },
      status: $status,
      next_step: $next_step,
      readiness: {
        close: $close_readiness,
        next_step: $readiness_next_step,
        evidence_records: $evidence_records,
        open_findings: $open_findings,
        accepted_risks: $accepted_risks,
        expired_accepted_risks: $expired_accepted_risks,
        pending_validation: $pending_validation
      },
      v1: {
        overall: $v1_overall,
        required_not_ready: $v1_required_not_ready,
        blocked: $v1_blocked,
        warnings: $v1_warnings
      },
      freshness: {
        report: $report_freshness,
        evidence_bundle: $bundle_freshness,
        handoff: $handoff_freshness,
        closeout: $closeout_freshness,
        accepted_risk_review_packet: $review_packet_freshness,
        audit_packet: $audit_packet_freshness,
        archive_packet: $archive_packet_freshness
      },
      verification: {
        closeout: {
          status: $closeout_verification,
          path: $closeout_verification_path,
          problems: $closeout_problems
        },
        accepted_risk_review_packet: {
          status: $review_packet_verification,
          path: $review_packet_verification_path
        },
        audit_packet: {
          status: $audit_packet_verification,
          path: $audit_packet_verification_path
        },
        archive_packet: {
          status: $archive_packet_verification,
          path: $archive_packet_verification_path
        }
      },
      artifacts: {
        report: $report_path,
        evidence_bundle: $evidence_bundle,
        handoff: $handoff_path,
        closeout: $closeout_path,
        accepted_risk_review_packet: $review_packet_path,
        audit_packet: $audit_packet_path,
        archive_packet: $archive_packet_path
      },
      ledger: {
        path: $ledger_file,
        events: $ledger_events,
        sha256: $ledger_sha,
        latest_event_at: $latest_ledger_at,
        latest_event: $latest_ledger_event
      }
    }'
}

cmd_op_trust_chain() {
  local operation_name=""
  local strict=0
  local json=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --strict)
      strict=1
      shift
      ;;
    --json)
      json=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail "unknown op trust-chain option: $1"
      ;;
    *)
      if [ -n "$operation_name" ]; then
        fail "op trust-chain [name] [--strict] [--json]"
      fi
      operation_name="$1"
      shift
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "op trust-chain [name] [--strict] [--json]"

  if [ -n "$operation_name" ]; then
    load_atlas_operation "$operation_name"
  else
    load_active_operation
  fi

  if [ "$json" -eq 1 ]; then
    atlas_trust_chain_print_json
  else
    atlas_trust_chain_print
  fi
  if [ "$strict" -eq 1 ] && [ "$ATLAS_TRUST_CHAIN_STATUS" != "current" ]; then
    return 1
  fi
}
