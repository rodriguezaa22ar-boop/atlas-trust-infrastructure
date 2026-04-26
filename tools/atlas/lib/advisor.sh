#!/usr/bin/env bash

atlas_advisor_evidence_counts() {
  local index_file

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf '0\t0\t0\t0\t0\n'
    return 0
  fi

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" '
      map(select(.target == $target)) as $records
      | [
          ($records | length),
          ($records | map(select((.redacted // false) == true)) | length),
          ($records | map(select((.redacted // false) == false)) | length),
          ($records | map(select((.classification // "internal") != "public")) | length),
          ($records | map(select((.redacted // false) == false and (.classification // "internal") != "public")) | length)
        ]
      | @tsv
    ' "$index_file"
}

atlas_advisor_priority_finding_rows() {
  local index_file
  local limit="${1:-8}"

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" \
    --argjson limit "$limit" '
      def severity_weight:
        if . == "critical" then 5
        elif . == "high" then 4
        elif . == "medium" then 3
        elif . == "low" then 2
        elif . == "info" then 1
        else 0 end;
      map(select(.target == $target))
      | sort_by([((.severity // "info") | severity_weight), (.created_at // "")])
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.severity // "info"),
          (.level // "inferred"),
          (.status // "open"),
          (.title // "untitled finding"),
          (if (.level // "inferred") != "validated" then
            "create validation plan"
          elif (.status // "open") != "resolved" then
            "track remediation"
          else
            "monitor"
          end)
        ]
      | @tsv
    ' "$index_file"
}

atlas_advisor_validation_queue_rows() {
  local index_file
  local limit="${1:-8}"

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" \
    --argjson limit "$limit" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(.target == $target))
      | sort_by(.updated_at, .id)
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.lane // "?"),
          (.status // "?"),
          (.result_status // "-"),
          (.finding // "-")
        ]
      | @tsv
    ' "$index_file"
}

atlas_advisor_print_redaction_status() {
  local counts
  local total
  local redacted
  local unredacted
  local non_public
  local review_required

  counts="$(atlas_advisor_evidence_counts)"
  IFS=$'\t' read -r total redacted unredacted non_public review_required <<<"$counts"

  ui_kv "Evidence Redaction" "total=$total, redacted=$redacted, unredacted=$unredacted, non_public=$non_public, review_required=$review_required"
  if [ "$review_required" -gt 0 ]; then
    ui_alert "redaction required before external AI handoff"
  else
    ui_ok "recorded evidence metadata is ready for advisor review"
  fi
  ui_note "advisor output is planning text only; execute target-touching work through explicit Atlas commands"
}

atlas_advisor_redaction_markdown() {
  local counts
  local total
  local redacted
  local unredacted
  local non_public
  local review_required

  counts="$(atlas_advisor_evidence_counts)"
  IFS=$'\t' read -r total redacted unredacted non_public review_required <<<"$counts"

  printf -- '- Evidence records: %s\n' "$total"
  printf -- '- Redacted evidence records: %s\n' "$redacted"
  printf -- '- Unredacted evidence records: %s\n' "$unredacted"
  printf -- '- Non-public evidence records: %s\n' "$non_public"
  printf -- '- Evidence records requiring review before external handoff: %s\n' "$review_required"
  if [ "$review_required" -gt 0 ]; then
    printf -- '- External handoff status: review required before sharing artifacts or raw evidence.\n'
  else
    printf -- '- External handoff status: metadata-only packet is ready for advisor review.\n'
  fi
}

atlas_advisor_print_priority_findings() {
  local output

  output="$(
    atlas_advisor_priority_finding_rows 8 |
      awk -F'\t' '{ printf "%-24s %-8s %-10s %-10s %-32s %s\n", $1, $2, $3, $4, $5, $6 }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "no findings recorded yet"
  fi
}

atlas_advisor_priority_findings_markdown() {
  local output

  output="$(
    atlas_advisor_priority_finding_rows 12 |
      awk -F'\t' '{
        printf "- %s / %s / %s / %s: %s. Advisor cue: %s.\n", $1, $2, $3, $4, $5, $6
      }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    printf -- '- No findings recorded yet.\n'
  fi
}

atlas_advisor_print_validation_queue() {
  local output

  output="$(
    atlas_advisor_validation_queue_rows 8 |
      awk -F'\t' '{ printf "%-24s %-12s %-10s %-10s %s\n", $1, $2, $3, $4, $5 }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "no validation plans recorded yet"
  fi
}

atlas_advisor_validation_queue_markdown() {
  local output

  output="$(
    atlas_advisor_validation_queue_rows 12 |
      awk -F'\t' '{
        printf "- %s / %s / %s / result=%s / finding=%s\n", $1, $2, $3, $4, $5
      }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    printf -- '- No validation plans recorded yet.\n'
  fi
}

atlas_advisor_next_moves() {
  local counts
  local _total
  local _redacted
  local _unredacted
  local _non_public
  local review_required

  atlas_brief_collect "$ATLAS_OP_TARGET" "1"
  counts="$(atlas_advisor_evidence_counts)"
  IFS=$'\t' read -r _total _redacted _unredacted _non_public review_required <<<"$counts"

  if [ "$review_required" -gt 0 ]; then
    printf -- '- Review and redact evidence before sharing raw artifacts with an external AI system.\n'
  fi

  if [ "$ATLAS_BRIEF_APPROVED_COUNT" -gt 0 ]; then
    printf -- '- Run the approved validation plan and record the resulting evidence.\n'
  elif [ "$ATLAS_BRIEF_PLANNED_COUNT" -gt 0 ]; then
    printf -- '- Approve, revise, or retire the planned validation before execution.\n'
  elif [ "$ATLAS_BRIEF_FINDING_COUNT" -gt 0 ] && [ "$ATLAS_BRIEF_VALIDATION_COUNT" -eq 0 ]; then
    printf -- '- Create a validation plan for the highest-value finding.\n'
  elif [ "$ATLAS_BRIEF_EXECUTED_COUNT" -gt 0 ]; then
    printf -- '- Review validation output, update finding status, and refresh the report.\n'
  elif [ "$ATLAS_BRIEF_SERVICE_COUNT" -gt 0 ] || [ "$ATLAS_BRIEF_WEB_COUNT" -gt 0 ]; then
    printf -- '- Review candidate lanes and record findings for material issues.\n'
  else
    printf -- '- Run operation-aware recon to establish host state and service evidence.\n'
  fi

  printf -- '- Keep execution manual: use advisor output for planning, then run explicit Atlas commands.\n'
}

atlas_advisor_write_prompt() {
  local file="$1"

  atlas_scope_load_snapshot

  {
    printf '# Atlas AI Advisor Packet\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    if [ -n "${ATLAS_OP_TARGET_ADDRESS:-}" ] && [ "$ATLAS_OP_TARGET_ADDRESS" != "$ATLAS_OP_TARGET" ]; then
      printf 'Address: %s\n' "$ATLAS_OP_TARGET_ADDRESS"
    fi
    printf '\nThis packet is metadata and summary text for AI-assisted review. No raw artifact contents are included.\n'

    printf '\n## Safety Constraints\n\n'
    printf -- '- Stay inside the recorded operation scope and authorization boundary.\n'
    printf -- '- Do not recommend exploitation, payload delivery, persistence, denial of service, brute forcing, credential stuffing, or data extraction.\n'
    printf -- '- Keep execution manual; suggest explicit Atlas commands for the operator to run.\n'
    printf -- '- Treat unredacted non-public evidence as unsafe for external handoff until the operator reviews it.\n'

    printf '\n## Operation State\n\n'
    atlas_brief_report_markdown "$ATLAS_OP_TARGET"

    printf '\n## Redaction Status\n\n'
    atlas_advisor_redaction_markdown

    printf '\n## Priority Findings\n\n'
    atlas_advisor_priority_findings_markdown

    printf '\n## Validation Queue\n\n'
    atlas_advisor_validation_queue_markdown

    printf '\n## Suggested Operator Moves\n\n'
    atlas_advisor_next_moves

    printf '\n## Requested Output\n\n'
    printf -- '- Summarize the operator situation in five bullets or fewer.\n'
    printf -- '- Identify missing evidence and the safest next Atlas commands.\n'
    printf -- '- Draft concise report language using only recorded facts from this packet.\n'
  } >"$file"
}

cmd_advisor_brief() {
  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  ui_heading "AI Advisor Brief"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Target" "$(format_operation_target)"
  ui_kv "Status" "$ATLAS_OP_STATUS"
  ui_kv "Dir" "$ATLAS_OP_DIR"
  ui_rule

  ui_subheading "Current State"
  atlas_brief_print_operation "$ATLAS_OP_TARGET"
  ui_rule

  ui_subheading "AI Handoff Guardrails"
  atlas_advisor_print_redaction_status
  ui_rule

  ui_subheading "Priority Findings"
  atlas_advisor_print_priority_findings
  ui_rule

  ui_subheading "Validation Queue"
  atlas_advisor_print_validation_queue
  ui_rule

  ui_subheading "Suggested Operator Moves"
  atlas_advisor_next_moves
}

cmd_advisor_prompt() {
  local packet_name="${2:-}"
  local packet_slug
  local advisor_dir
  local packet_file

  if [ "$#" -gt 0 ]; then
    load_atlas_operation "$1"
  else
    load_active_operation
  fi

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_OP_SLUG-advisor-packet"
  fi
  packet_slug="$(slugify "$packet_name")"
  [ -n "$packet_slug" ] || fail "advisor packet name produced an empty slug"

  advisor_dir="$ATLAS_OP_DIR/advisor"
  mkdir -p "$advisor_dir"
  chmod 700 "$advisor_dir" 2>/dev/null || true
  packet_file="$advisor_dir/$packet_slug.md"
  atlas_advisor_write_prompt "$packet_file"
  chmod 600 "$packet_file" 2>/dev/null || true

  atlas_ledger_append_current "advisor.packet.generated" "read-only" "atlas" "ok" "$packet_file"
  record_operation_history "$ATLAS_OP_DIR" "advisor-prompt" "$packet_file"

  ui_ok "advisor packet written"
  printf 'packet: %s\n' "$packet_file"
}
