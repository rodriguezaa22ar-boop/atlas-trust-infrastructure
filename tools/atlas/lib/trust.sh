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

atlas_trust_chain_ndjson_count() {
  local file="$1"
  local count

  if [ ! -s "$file" ]; then
    printf '0\n'
    return 0
  fi

  count="$(jq -sr 'length' "$file" 2>/dev/null)" ||
    count="$(awk 'NF { count++ } END { print count + 0 }' "$file")"
  printf '%s\n' "$count"
}

atlas_trust_chain_file_count() {
  local dir="$1"
  local pattern="$2"

  if [ ! -d "$dir" ]; then
    printf '0\n'
    return 0
  fi

  find "$dir" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
}

atlas_trust_chain_business_flow_status() {
  local operation_links="$1"
  local packet_count="$2"
  local json_packet_count="$3"

  if [ "$operation_links" -eq 0 ]; then
    printf 'not-recorded\n'
  elif [ "$packet_count" -eq 0 ] && [ "$json_packet_count" -eq 0 ]; then
    printf 'linked\n'
  else
    printf 'packetized\n'
  fi
}

atlas_trust_chain_latest_timestamp() {
  local latest=""
  local value

  for value in "$@"; do
    [ -n "$value" ] || continue
    if [ -z "$latest" ] || atlas_flow_timestamp_after "$value" "$latest"; then
      latest="$value"
    fi
  done

  printf '%s\n' "$latest"
}

atlas_trust_chain_issue_json() {
  local issues="$1"

  if [ -z "$issues" ]; then
    printf '[]\n'
    return 0
  fi

  printf '%s\n' "$issues" | jq -Rsc 'split("\n") | map(select(length > 0))'
}

atlas_trust_chain_issue_detail() {
  local issues="$1"

  if [ -z "$issues" ]; then
    printf '\n'
    return 0
  fi

  printf '%s\n' "$issues" |
    awk 'NF { if (out != "") { out = out "; " $0 } else { out = $0 } } END { print out }'
}

atlas_trust_chain_business_flow_packet_summary() {
  local flow_id="$1"
  local operation="$2"
  local packet_dir="$3"
  local packet_json_dir="$4"
  local latest_material_at="$5"
  local count=0
  local status="missing"
  local format="none"
  local path="none"
  local generated_at=""
  local candidate_generated_at
  local candidate_operation
  local file

  if [ -d "$packet_json_dir" ]; then
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      if jq -e --arg flow_id "$flow_id" --arg operation "$operation" \
        'type == "object" and (.flow.flow_id // "") == $flow_id and ((if (.operation | type) == "object" then (.operation.slug // "") else (.operation // "") end) == $operation)' \
        "$file" >/dev/null 2>&1; then
        count=$((count + 1))
        candidate_generated_at="$(jq -r '.freshness.packet_generated_at // .generated_at // ""' "$file" 2>/dev/null || true)"
        if [ -z "$generated_at" ] || atlas_flow_timestamp_after "$candidate_generated_at" "$generated_at"; then
          generated_at="$candidate_generated_at"
          format="json"
          path="$file"
        fi
      fi
    done < <(find "$packet_json_dir" -maxdepth 1 -type f -name '*.json' 2>/dev/null | sort)
  fi

  if [ -d "$packet_dir" ]; then
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      if grep -Fq "Flow ID: $flow_id" "$file" 2>/dev/null &&
        grep -Fq "Operation: $operation" "$file" 2>/dev/null; then
        count=$((count + 1))
        candidate_operation="$(atlas_flow_packet_field "$file" "Operation")"
        [ "$candidate_operation" = "$operation" ] || continue
        candidate_generated_at="$(atlas_flow_packet_field "$file" "Packet Generated At")"
        if [ -z "$candidate_generated_at" ]; then
          candidate_generated_at="$(atlas_flow_packet_field "$file" "Generated At")"
        fi
        if [ -z "$generated_at" ] || atlas_flow_timestamp_after "$candidate_generated_at" "$generated_at"; then
          generated_at="$candidate_generated_at"
          format="markdown"
          path="$file"
        fi
      fi
    done < <(find "$packet_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
  fi

  if [ "$count" -eq 0 ]; then
    status="missing"
  elif [ -z "$generated_at" ]; then
    status="blocked"
  elif atlas_flow_timestamp_after "$latest_material_at" "$generated_at"; then
    status="stale"
  else
    status="current"
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$count" "$status" "$format" "$path" "${generated_at:-none}"
}

atlas_trust_chain_business_flow_packet_counts_current() {
  local packet_format="$1"
  local packet_path="$2"
  local evidence_links="$3"
  local finding_links="$4"
  local validation_links="$5"
  local approval_links="$6"
  local retention_links="$7"
  local packet_evidence_links
  local packet_finding_links
  local packet_validation_links
  local packet_approval_links
  local packet_retention_links

  case "$packet_format" in
  json)
    packet_evidence_links="$(jq -r '.freshness.evidence_link_count // ""' "$packet_path" 2>/dev/null || true)"
    packet_finding_links="$(jq -r '.freshness.finding_link_count // ""' "$packet_path" 2>/dev/null || true)"
    packet_validation_links="$(jq -r '.freshness.validation_link_count // ""' "$packet_path" 2>/dev/null || true)"
    packet_approval_links="$(jq -r '.freshness.approval_link_count // ""' "$packet_path" 2>/dev/null || true)"
    packet_retention_links="$(jq -r '.freshness.retention_link_count // ""' "$packet_path" 2>/dev/null || true)"
    ;;
  markdown)
    packet_evidence_links="$(atlas_flow_packet_field "$packet_path" "Evidence Link Count")"
    packet_finding_links="$(atlas_flow_packet_field "$packet_path" "Finding Link Count")"
    packet_validation_links="$(atlas_flow_packet_field "$packet_path" "Validation Link Count")"
    packet_approval_links="$(atlas_flow_packet_field "$packet_path" "Approval Link Count")"
    packet_retention_links="$(atlas_flow_packet_field "$packet_path" "Retention Link Count")"
    ;;
  *)
    return 1
    ;;
  esac

  [ "$packet_evidence_links" = "$evidence_links" ] &&
    [ "$packet_finding_links" = "$finding_links" ] &&
    [ "$packet_validation_links" = "$validation_links" ] &&
    [ "$packet_approval_links" = "$approval_links" ] &&
    [ "$packet_retention_links" = "$retention_links" ]
}

atlas_trust_chain_collect_business_flow_assurance() {
  local flow_links_file="$1"
  local evidence_links_file="$2"
  local finding_links_file="$3"
  local validation_links_file="$4"
  local approval_links_file="$5"
  local retention_links_file="$6"
  local packet_dir="$7"
  local packet_json_dir="$8"
  local flows_file
  local link_json
  local flow_id
  local flow_slug
  local flow_file
  local evidence_links
  local finding_links
  local open_findings
  local validation_links
  local validation_gaps
  local approval_links
  local retention_links
  local control_objectives
  local matching_packets
  local packet_summary
  local packet_status
  local packet_format
  local packet_path
  local packet_generated_at
  local latest_evidence_link
  local latest_finding_link
  local latest_validation_link
  local latest_approval_link
  local latest_retention_link
  local latest_material_at
  local status
  local detail
  local criticality
  local issues

  ATLAS_TRUST_FLOW_ASSURANCE_TOTAL=0
  ATLAS_TRUST_FLOW_ASSURANCE_CURRENT=0
  ATLAS_TRUST_FLOW_ASSURANCE_ATTENTION_REQUIRED=0
  ATLAS_TRUST_FLOW_ASSURANCE_BLOCKED=0
  ATLAS_TRUST_FLOW_ASSURANCE_NOT_RECORDED=0
  ATLAS_TRUST_FLOW_ASSURANCE_JSON='[]'

  if [ ! -s "$flow_links_file" ]; then
    ATLAS_TRUST_FLOW_ASSURANCE_NOT_RECORDED=1
    return 0
  fi

  flows_file="$(mktemp)"
  while IFS= read -r link_json || [ -n "$link_json" ]; do
    [ -n "$link_json" ] || continue
    issues=""
    packet_status="not-recorded"
    packet_format="none"
    packet_path="none"
    packet_generated_at="none"
    latest_material_at="none"
    if ! printf '%s\n' "$link_json" | jq -e 'type == "object"' >/dev/null 2>&1; then
      flow_id=""
      flow_slug=""
      status="blocked"
      detail="operation flow link is not valid JSON"
      criticality="unknown"
      evidence_links=0
      finding_links=0
      open_findings=0
      validation_links=0
      validation_gaps=0
      approval_links=0
      retention_links=0
      control_objectives=0
      matching_packets=0
      issues="operation flow link is not valid JSON"
    else
      flow_id="$(printf '%s\n' "$link_json" | jq -r '.flow_id // ""')"
      flow_slug="$(printf '%s\n' "$link_json" | jq -r '.flow_slug // ""')"
      if [ -z "$flow_id" ] || [ -z "$flow_slug" ]; then
        status="blocked"
        detail="operation flow link is missing flow_id or flow_slug"
        criticality="unknown"
        evidence_links=0
        finding_links=0
        open_findings=0
        validation_links=0
        validation_gaps=0
        approval_links=0
        retention_links=0
        control_objectives=0
        matching_packets=0
        issues="operation flow link is missing flow_id or flow_slug"
      else
        flow_file="$(atlas_flow_file_for_slug "$flow_slug")"
        if [ ! -f "$flow_file" ]; then
          status="blocked"
          detail="flow record missing for $flow_slug"
          criticality="unknown"
          evidence_links=0
          finding_links=0
          open_findings=0
          validation_links=0
          validation_gaps=0
          approval_links=0
          retention_links=0
          control_objectives=0
          matching_packets=0
          issues="flow record missing for $flow_slug"
        else
          atlas_flow_load_file "$flow_file"
          criticality="$ATLAS_FLOW_CRITICALITY"
          evidence_links="$(atlas_flow_evidence_link_count "$evidence_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          finding_links="$(atlas_flow_finding_link_count "$finding_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          open_findings="$(atlas_flow_current_open_finding_count "$finding_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          validation_links="$(atlas_flow_validation_link_count "$validation_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          validation_gaps="$(atlas_flow_validation_gap_count "$finding_links_file" "$validation_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          approval_links="$(atlas_flow_approval_link_count "$approval_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          retention_links="$(atlas_flow_retention_link_count "$retention_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          control_objectives="$(atlas_flow_control_objective_count "$ATLAS_FLOW_CONTROL_OBJECTIVES")"
          latest_evidence_link="$(atlas_flow_latest_evidence_linked_at "$evidence_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          latest_finding_link="$(atlas_flow_latest_finding_linked_at "$finding_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          latest_validation_link="$(atlas_flow_latest_validation_linked_at "$validation_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          latest_approval_link="$(atlas_flow_latest_approval_linked_at "$approval_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          latest_retention_link="$(atlas_flow_latest_retention_linked_at "$retention_links_file" "$flow_id" "$ATLAS_OP_SLUG")"
          latest_material_at="$(atlas_trust_chain_latest_timestamp "$ATLAS_FLOW_UPDATED_AT" "$latest_evidence_link" "$latest_finding_link" "$latest_validation_link" "$latest_approval_link" "$latest_retention_link")"
          packet_summary="$(atlas_trust_chain_business_flow_packet_summary "$flow_id" "$ATLAS_OP_SLUG" "$packet_dir" "$packet_json_dir" "$latest_material_at")"
          IFS=$'\t' read -r matching_packets packet_status packet_format packet_path packet_generated_at <<<"$packet_summary"
          if [ "$packet_status" = "current" ] &&
            ! atlas_trust_chain_business_flow_packet_counts_current "$packet_format" "$packet_path" "$evidence_links" "$finding_links" "$validation_links" "$approval_links" "$retention_links"; then
            packet_status="stale"
          fi

          if [ "$evidence_links" -eq 0 ]; then
            issues="${issues}${issues:+$'\n'}no evidence links recorded"
          fi
          if [ "$control_objectives" -eq 0 ]; then
            issues="${issues}${issues:+$'\n'}no control objectives declared"
          fi
          if [ "$open_findings" -gt 0 ]; then
            issues="${issues}${issues:+$'\n'}open_findings=$open_findings"
          fi
          if [ "$validation_gaps" -gt 0 ]; then
            issues="${issues}${issues:+$'\n'}validation_gaps=$validation_gaps"
          fi
          case "$packet_status" in
          current)
            ;;
          missing)
            issues="${issues}${issues:+$'\n'}no matching flow packet found"
            ;;
          stale)
            issues="${issues}${issues:+$'\n'}flow packet stale"
            ;;
          *)
            issues="${issues}${issues:+$'\n'}flow packet verification blocked"
            ;;
          esac
          if [ "$retention_links" -eq 0 ] && { [ "$criticality" = "high" ] || [ "$criticality" = "critical" ]; }; then
            issues="${issues}${issues:+$'\n'}high-criticality flow has no retention links"
          fi
          if [ "$packet_status" = "blocked" ]; then
            status="blocked"
            detail="$(atlas_trust_chain_issue_detail "$issues")"
          elif [ -n "$issues" ]; then
            status="attention-required"
            detail="$(atlas_trust_chain_issue_detail "$issues")"
          else
            status="current"
            detail="flow assurance prerequisites are represented in operation metadata"
          fi
        fi
      fi
    fi

    ATLAS_TRUST_FLOW_ASSURANCE_TOTAL=$((ATLAS_TRUST_FLOW_ASSURANCE_TOTAL + 1))
    case "$status" in
    current)
      ATLAS_TRUST_FLOW_ASSURANCE_CURRENT=$((ATLAS_TRUST_FLOW_ASSURANCE_CURRENT + 1))
      ;;
    blocked)
      ATLAS_TRUST_FLOW_ASSURANCE_BLOCKED=$((ATLAS_TRUST_FLOW_ASSURANCE_BLOCKED + 1))
      ;;
    not-recorded)
      ATLAS_TRUST_FLOW_ASSURANCE_NOT_RECORDED=$((ATLAS_TRUST_FLOW_ASSURANCE_NOT_RECORDED + 1))
      ;;
    *)
      ATLAS_TRUST_FLOW_ASSURANCE_ATTENTION_REQUIRED=$((ATLAS_TRUST_FLOW_ASSURANCE_ATTENTION_REQUIRED + 1))
      ;;
    esac

    jq -cn \
      --arg flow_id "$flow_id" \
      --arg flow_slug "$flow_slug" \
      --arg status "$status" \
      --arg detail "$detail" \
      --arg criticality "$criticality" \
      --argjson evidence_links "$evidence_links" \
      --argjson finding_links "$finding_links" \
      --argjson open_findings "$open_findings" \
      --argjson validation_links "$validation_links" \
      --argjson validation_gaps "$validation_gaps" \
      --argjson approval_links "$approval_links" \
      --argjson retention_links "$retention_links" \
      --argjson control_objectives "$control_objectives" \
      --argjson matching_packets "$matching_packets" \
      --arg packet_status "$packet_status" \
      --arg packet_format "$packet_format" \
      --arg packet_path "$packet_path" \
      --arg packet_generated_at "$packet_generated_at" \
      --arg latest_material_at "$latest_material_at" \
      --argjson issues "$(atlas_trust_chain_issue_json "$issues")" \
      '{
        flow_id: $flow_id,
        flow_slug: $flow_slug,
        status: $status,
        detail: $detail,
        criticality: $criticality,
        evidence_links: $evidence_links,
        finding_links: $finding_links,
        open_findings: $open_findings,
        validation_links: $validation_links,
        validation_gaps: $validation_gaps,
        approval_links: $approval_links,
        retention_links: $retention_links,
        control_objectives: $control_objectives,
        matching_packets: $matching_packets,
        packet_status: $packet_status,
        packet_format: $packet_format,
        packet_path: $packet_path,
        packet_generated_at: $packet_generated_at,
        latest_material_at: $latest_material_at,
        issues: $issues
      }' >>"$flows_file"
  done <"$flow_links_file"

  ATLAS_TRUST_FLOW_ASSURANCE_JSON="$(jq -s '.' "$flows_file")"
  rm -f "$flows_file"
}

atlas_trust_chain_collect_business_flows() {
  local op_dir="$ATLAS_OP_DIR"
  local flow_links_file="$op_dir/business_flows.ndjson"
  local evidence_links_file="$op_dir/flow_evidence.ndjson"
  local finding_links_file="$op_dir/flow_findings.ndjson"
  local validation_links_file="$op_dir/flow_validation.ndjson"
  local approval_links_file="$op_dir/flow_approvals.ndjson"
  local retention_links_file="$op_dir/flow_retention.ndjson"
  local packet_dir="$op_dir/flow_packets"
  local packet_json_dir="$op_dir/flow_packets_json"

  ATLAS_TRUST_FLOW_LINKS_FILE="$flow_links_file"
  ATLAS_TRUST_FLOW_EVIDENCE_LINKS_FILE="$evidence_links_file"
  ATLAS_TRUST_FLOW_FINDING_LINKS_FILE="$finding_links_file"
  ATLAS_TRUST_FLOW_VALIDATION_LINKS_FILE="$validation_links_file"
  ATLAS_TRUST_FLOW_APPROVAL_LINKS_FILE="$approval_links_file"
  ATLAS_TRUST_FLOW_RETENTION_LINKS_FILE="$retention_links_file"
  ATLAS_TRUST_FLOW_PACKET_DIR="$packet_dir"
  ATLAS_TRUST_FLOW_PACKET_JSON_DIR="$packet_json_dir"
  ATLAS_TRUST_FLOW_OPERATION_LINKS="$(atlas_trust_chain_ndjson_count "$flow_links_file")"
  ATLAS_TRUST_FLOW_EVIDENCE_LINKS="$(atlas_trust_chain_ndjson_count "$evidence_links_file")"
  ATLAS_TRUST_FLOW_FINDING_LINKS="$(atlas_trust_chain_ndjson_count "$finding_links_file")"
  ATLAS_TRUST_FLOW_VALIDATION_LINKS="$(atlas_trust_chain_ndjson_count "$validation_links_file")"
  ATLAS_TRUST_FLOW_APPROVAL_LINKS="$(atlas_trust_chain_ndjson_count "$approval_links_file")"
  ATLAS_TRUST_FLOW_RETENTION_LINKS="$(atlas_trust_chain_ndjson_count "$retention_links_file")"
  ATLAS_TRUST_FLOW_PACKET_COUNT="$(atlas_trust_chain_file_count "$packet_dir" '*.md')"
  ATLAS_TRUST_FLOW_PACKET_JSON_COUNT="$(atlas_trust_chain_file_count "$packet_json_dir" '*.json')"
  ATLAS_TRUST_FLOW_STATUS="$(atlas_trust_chain_business_flow_status "$ATLAS_TRUST_FLOW_OPERATION_LINKS" "$ATLAS_TRUST_FLOW_PACKET_COUNT" "$ATLAS_TRUST_FLOW_PACKET_JSON_COUNT")"
  atlas_trust_chain_collect_business_flow_assurance \
    "$flow_links_file" \
    "$evidence_links_file" \
    "$finding_links_file" \
    "$validation_links_file" \
    "$approval_links_file" \
    "$retention_links_file" \
    "$packet_dir" \
    "$packet_json_dir"
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
  atlas_trust_chain_collect_business_flows

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
  ui_subheading "Business Flow Evidence"
  ui_kv "Status" "$ATLAS_TRUST_FLOW_STATUS"
  ui_kv "Operation Links" "$ATLAS_TRUST_FLOW_OPERATION_LINKS path=$ATLAS_TRUST_FLOW_LINKS_FILE"
  ui_kv "Evidence Links" "$ATLAS_TRUST_FLOW_EVIDENCE_LINKS path=$ATLAS_TRUST_FLOW_EVIDENCE_LINKS_FILE"
  ui_kv "Finding Links" "$ATLAS_TRUST_FLOW_FINDING_LINKS path=$ATLAS_TRUST_FLOW_FINDING_LINKS_FILE"
  ui_kv "Validation Links" "$ATLAS_TRUST_FLOW_VALIDATION_LINKS path=$ATLAS_TRUST_FLOW_VALIDATION_LINKS_FILE"
  ui_kv "Approval Links" "$ATLAS_TRUST_FLOW_APPROVAL_LINKS path=$ATLAS_TRUST_FLOW_APPROVAL_LINKS_FILE"
  ui_kv "Retention Links" "$ATLAS_TRUST_FLOW_RETENTION_LINKS path=$ATLAS_TRUST_FLOW_RETENTION_LINKS_FILE"
  ui_kv "Markdown Packets" "$ATLAS_TRUST_FLOW_PACKET_COUNT path=$ATLAS_TRUST_FLOW_PACKET_DIR"
  ui_kv "JSON Packets" "$ATLAS_TRUST_FLOW_PACKET_JSON_COUNT path=$ATLAS_TRUST_FLOW_PACKET_JSON_DIR"
  ui_kv "Assurance Total" "$ATLAS_TRUST_FLOW_ASSURANCE_TOTAL"
  ui_kv "Assurance Current" "$ATLAS_TRUST_FLOW_ASSURANCE_CURRENT"
  ui_kv "Assurance Attention Required" "$ATLAS_TRUST_FLOW_ASSURANCE_ATTENTION_REQUIRED"
  ui_kv "Assurance Blocked" "$ATLAS_TRUST_FLOW_ASSURANCE_BLOCKED"
  ui_kv "Assurance Not Recorded" "$ATLAS_TRUST_FLOW_ASSURANCE_NOT_RECORDED"
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
    --arg business_flow_status "$ATLAS_TRUST_FLOW_STATUS" \
    --arg flow_links_file "$ATLAS_TRUST_FLOW_LINKS_FILE" \
    --arg flow_evidence_links_file "$ATLAS_TRUST_FLOW_EVIDENCE_LINKS_FILE" \
    --arg flow_finding_links_file "$ATLAS_TRUST_FLOW_FINDING_LINKS_FILE" \
    --arg flow_validation_links_file "$ATLAS_TRUST_FLOW_VALIDATION_LINKS_FILE" \
    --arg flow_approval_links_file "$ATLAS_TRUST_FLOW_APPROVAL_LINKS_FILE" \
    --arg flow_retention_links_file "$ATLAS_TRUST_FLOW_RETENTION_LINKS_FILE" \
    --arg flow_packet_dir "$ATLAS_TRUST_FLOW_PACKET_DIR" \
    --arg flow_packet_json_dir "$ATLAS_TRUST_FLOW_PACKET_JSON_DIR" \
    --argjson flow_operation_links "${ATLAS_TRUST_FLOW_OPERATION_LINKS:-0}" \
    --argjson flow_evidence_links "${ATLAS_TRUST_FLOW_EVIDENCE_LINKS:-0}" \
    --argjson flow_finding_links "${ATLAS_TRUST_FLOW_FINDING_LINKS:-0}" \
    --argjson flow_validation_links "${ATLAS_TRUST_FLOW_VALIDATION_LINKS:-0}" \
    --argjson flow_approval_links "${ATLAS_TRUST_FLOW_APPROVAL_LINKS:-0}" \
    --argjson flow_retention_links "${ATLAS_TRUST_FLOW_RETENTION_LINKS:-0}" \
    --argjson flow_packets "${ATLAS_TRUST_FLOW_PACKET_COUNT:-0}" \
    --argjson flow_json_packets "${ATLAS_TRUST_FLOW_PACKET_JSON_COUNT:-0}" \
    --argjson flow_assurance_total "${ATLAS_TRUST_FLOW_ASSURANCE_TOTAL:-0}" \
    --argjson flow_assurance_current "${ATLAS_TRUST_FLOW_ASSURANCE_CURRENT:-0}" \
    --argjson flow_assurance_attention_required "${ATLAS_TRUST_FLOW_ASSURANCE_ATTENTION_REQUIRED:-0}" \
    --argjson flow_assurance_blocked "${ATLAS_TRUST_FLOW_ASSURANCE_BLOCKED:-0}" \
    --argjson flow_assurance_not_recorded "${ATLAS_TRUST_FLOW_ASSURANCE_NOT_RECORDED:-0}" \
    --argjson flow_assurance_flows "${ATLAS_TRUST_FLOW_ASSURANCE_JSON:-[]}" \
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
      business_flow_evidence: {
        status: $business_flow_status,
        operation_links: $flow_operation_links,
        evidence_links: $flow_evidence_links,
        finding_links: $flow_finding_links,
        validation_links: $flow_validation_links,
        approval_links: $flow_approval_links,
        retention_links: $flow_retention_links,
        markdown_packets: $flow_packets,
        json_packets: $flow_json_packets,
        assurance: {
          total: $flow_assurance_total,
          current: $flow_assurance_current,
          attention_required: $flow_assurance_attention_required,
          blocked: $flow_assurance_blocked,
          not_recorded: $flow_assurance_not_recorded,
          flows: $flow_assurance_flows
        },
        artifacts: {
          operation_links: $flow_links_file,
          evidence_links: $flow_evidence_links_file,
          finding_links: $flow_finding_links_file,
          validation_links: $flow_validation_links_file,
          approval_links: $flow_approval_links_file,
          retention_links: $flow_retention_links_file,
          markdown_packets: $flow_packet_dir,
          json_packets: $flow_packet_json_dir
        },
        required: false
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
