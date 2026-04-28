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
    printf -- '- Expired accepted risks: %s\n' "$ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT"
    printf -- '- Validation plans: %s\n' "$ATLAS_READINESS_VALIDATION_COUNT"
    printf -- '- Pending validation: %s\n' "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
    printf -- '- Report freshness: %s\n' "$ATLAS_READINESS_REPORT_FRESHNESS"
    printf -- '- Bundle freshness: %s\n' "$ATLAS_READINESS_BUNDLE_FRESHNESS"
    printf -- '- Handoff freshness before this packet: %s\n' "$ATLAS_READINESS_HANDOFF_FRESHNESS"
    if [ -n "$ATLAS_READINESS_LATEST_CHANGE" ]; then
      printf -- '- Latest state change: %s %s\n' "$ATLAS_READINESS_LATEST_CHANGE_AT" "$ATLAS_READINESS_LATEST_CHANGE_EVENT"
    else
      printf -- '- Latest state change: none\n'
    fi
    if [ -n "$ATLAS_READINESS_LATEST_EVIDENCE_CHANGE" ]; then
      printf -- '- Latest evidence change: %s %s\n' "$ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_AT" "$ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_EVENT"
    else
      printf -- '- Latest evidence change: none\n'
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

atlas_handoff_write_json_packet() {
  local file="$1"
  local generated_at="$2"
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
  local bundle_files="0"
  local include_unredacted="0"
  local ledger_file
  local ledger_events="0"
  local ledger_sha=""

  atlas_readiness_collect "$ATLAS_OP_TARGET"
  intel_require_jq

  latest_report="$(atlas_handoff_latest_report_fields)"
  if [ -n "$latest_report" ]; then
    IFS=$'\t' read -r report_at report_path report_sha <<<"$latest_report"
  fi
  latest_bundle="$(atlas_handoff_latest_bundle_fields)"
  if [ -n "$latest_bundle" ]; then
    IFS=$'\t' read -r bundle_at bundle_slug bundle_dir manifest_file manifest_sha bundle_files include_unredacted <<<"$latest_bundle"
  fi

  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  if [ -f "$ledger_file" ]; then
    ledger_events="$(atlas_closeout_ledger_event_count "$ledger_file")"
    ledger_sha="$(atlas_closeout_sha_for_file "$ledger_file")"
  fi

  jq -n \
    --arg schema_version "atlas.handoff_packet.v1" \
    --arg generated_at "$generated_at" \
    --arg operation_name "$ATLAS_OP_NAME" \
    --arg operation_id "$ATLAS_OP_SLUG" \
    --arg operation_status "$ATLAS_OP_STATUS" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg address "${ATLAS_OP_TARGET_ADDRESS:-}" \
    --arg close_readiness "$ATLAS_READINESS_STATUS" \
    --arg next_step "$ATLAS_READINESS_NEXT_STEP" \
    --argjson evidence_records "${ATLAS_READINESS_EVIDENCE_COUNT:-0}" \
    --argjson findings "${ATLAS_READINESS_FINDING_COUNT:-0}" \
    --argjson open_findings "${ATLAS_READINESS_OPEN_FINDINGS_COUNT:-0}" \
    --argjson expired_accepted_risks "${ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT:-0}" \
    --argjson validation_plans "${ATLAS_READINESS_VALIDATION_COUNT:-0}" \
    --argjson pending_validation "${ATLAS_READINESS_PENDING_VALIDATION_COUNT:-0}" \
    --arg report_freshness "$ATLAS_READINESS_REPORT_FRESHNESS" \
    --arg bundle_freshness "$ATLAS_READINESS_BUNDLE_FRESHNESS" \
    --arg handoff_freshness "$ATLAS_READINESS_HANDOFF_FRESHNESS" \
    --arg latest_state_change_at "${ATLAS_READINESS_LATEST_CHANGE_AT:-}" \
    --arg latest_state_change_event "${ATLAS_READINESS_LATEST_CHANGE_EVENT:-}" \
    --arg latest_evidence_change_at "${ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_AT:-}" \
    --arg latest_evidence_change_event "${ATLAS_READINESS_LATEST_EVIDENCE_CHANGE_EVENT:-}" \
    --arg report_path "$report_path" \
    --arg report_generated_at "$report_at" \
    --arg report_sha256 "$report_sha" \
    --arg bundle_path "$bundle_dir" \
    --arg bundle_slug "$bundle_slug" \
    --arg bundle_generated_at "$bundle_at" \
    --argjson bundle_files "${bundle_files:-0}" \
    --arg include_unredacted "${include_unredacted:-0}" \
    --arg manifest_path "$manifest_file" \
    --arg manifest_sha256 "$manifest_sha" \
    --arg ledger_path "$ledger_file" \
    --argjson ledger_events "$ledger_events" \
    --arg ledger_sha256 "$ledger_sha" \
    --arg operation_dir "$ATLAS_OP_DIR" '
      def nullable($v):
        if $v == "" or $v == "-" or $v == "none" then null else $v end;
      def anchor_path($path; $sha):
        if $sha == "" or $sha == "-" or $sha == "none" then null else nullable($path) end;
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
        readiness: {
          close_readiness: $close_readiness,
          next_step: $next_step,
          evidence_records: $evidence_records,
          findings: $findings,
          open_findings: $open_findings,
          expired_accepted_risks: $expired_accepted_risks,
          validation_plans: $validation_plans,
          pending_validation: $pending_validation,
          freshness: {
            report: $report_freshness,
            bundle: $bundle_freshness,
            handoff_before_packet: $handoff_freshness
          },
          latest_state_change: {
            at: nullable($latest_state_change_at),
            event: nullable($latest_state_change_event)
          },
          latest_evidence_change: {
            at: nullable($latest_evidence_change_at),
            event: nullable($latest_evidence_change_event)
          }
        },
        artifacts: {
          latest_report: {
            path: anchor_path($report_path; $report_sha256),
            generated_at: nullable($report_generated_at),
            sha256: nullable($report_sha256)
          },
          evidence_bundle: {
            path: nullable($bundle_path),
            slug: nullable($bundle_slug),
            generated_at: nullable($bundle_generated_at),
            files: $bundle_files,
            include_unredacted: ($include_unredacted == "1" or $include_unredacted == "true")
          },
          evidence_manifest: {
            path: anchor_path($manifest_path; $manifest_sha256),
            sha256: nullable($manifest_sha256)
          }
        },
        integrity: {
          operation_ledger: {
            path: anchor_path($ledger_path; $ledger_sha256),
            events: $ledger_events,
            sha256: nullable($ledger_sha256)
          },
          operation_directory: {
            path: nullable($operation_dir)
          }
        },
        metadata_boundary: {
          stores: ["paths", "hashes", "counts", "freshness states", "readiness states", "known limitations"],
          excludes: ["raw report bodies", "raw evidence bodies", "finding bodies", "validation output", "secrets", "tokens", "credentials", "packet captures", "session contents"]
        },
        known_limitations: [
          "Handoff packets are metadata-only and retain local references, hashes, counts, freshness states, and readiness state.",
          "Raw report, evidence, finding, validation, and ledger contents are not embedded.",
          "Handoff JSON is not external audit, legal compliance evidence, or cryptographic immutability."
        ]
      }
    ' >"$file"
}

cmd_op_handoff() {
  local json_output=0
  local operation_name=""
  local packet_name=""
  local packet_slug
  local handoff_dir
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
      fail "unknown op handoff option: $1"
      ;;
    *)
      if [ -z "$operation_name" ]; then
        operation_name="$1"
      elif [ -z "$packet_name" ]; then
        packet_name="$1"
      else
        fail "op handoff [--json] [name] [handoff-name]"
      fi
      shift
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "op handoff [--json] [name] [handoff-name]"

  if [ -n "$operation_name" ]; then
    load_atlas_operation "$operation_name"
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
  if [ "$json_output" -eq 1 ]; then
    packet_file="$handoff_dir/$packet_slug.json"
  else
    packet_file="$handoff_dir/$packet_slug.md"
  fi

  generated_at="$(timestamp)"
  if [ "$json_output" -eq 1 ]; then
    atlas_handoff_write_json_packet "$packet_file" "$generated_at"
  else
    atlas_handoff_write_packet "$packet_file"
  fi
  chmod 600 "$packet_file" 2>/dev/null || true

  atlas_ledger_append_current "handoff.generated" "read-only" "atlas" "ok" "$packet_file"
  record_operation_history "$ATLAS_OP_DIR" "handoff" "$packet_file"

  if [ "$json_output" -eq 1 ]; then
    ui_ok "handoff JSON packet written"
    printf 'handoff_json: %s\n' "$packet_file"
  else
    ui_ok "handoff packet written"
    printf 'handoff: %s\n' "$packet_file"
  fi
}
