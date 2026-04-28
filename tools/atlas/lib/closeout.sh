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

atlas_closeout_latest_manifest() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "closeout.manifest.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
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
    printf -- '- Expired accepted risks: %s\n' "$ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT"
    printf -- '- Validation plans: %s\n' "$ATLAS_READINESS_VALIDATION_COUNT"
    printf -- '- Pending validation: %s\n' "$ATLAS_READINESS_PENDING_VALIDATION_COUNT"
    printf -- '- Report freshness: %s\n' "$ATLAS_READINESS_REPORT_FRESHNESS"
    printf -- '- Bundle freshness: %s\n' "$ATLAS_READINESS_BUNDLE_FRESHNESS"
    printf -- '- Handoff freshness: %s\n' "$ATLAS_READINESS_HANDOFF_FRESHNESS"
    printf -- '- Closeout freshness: %s\n' "$ATLAS_READINESS_CLOSEOUT_FRESHNESS"

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

atlas_closeout_write_json_manifest() {
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
  local op_env_sha=""
  local scope_sha=""
  local evidence_index_sha=""
  local findings_index_sha=""
  local validation_index_sha=""

  atlas_scope_load_snapshot
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
  op_env_sha="$(atlas_closeout_sha_for_file "$ATLAS_OP_FILE")"
  scope_sha="$(atlas_closeout_sha_for_file "$scope_file")"
  evidence_index_sha="$(atlas_closeout_sha_for_file "$evidence_index")"
  findings_index_sha="$(atlas_closeout_sha_for_file "$findings_index")"
  validation_index_sha="$(atlas_closeout_sha_for_file "$validation_index")"

  jq -n \
    --arg schema_version "atlas.closeout_manifest.v1" \
    --arg generated_at "$generated_at" \
    --arg operation_name "$ATLAS_OP_NAME" \
    --arg operation_id "$ATLAS_OP_SLUG" \
    --arg operation_status "$ATLAS_OP_STATUS" \
    --arg closed_at "${ATLAS_OP_CLOSED_AT:-}" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg address "${ATLAS_OP_TARGET_ADDRESS:-}" \
    --arg profile "$ATLAS_SCOPE_PROFILE" \
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
    --arg closeout_freshness "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" \
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
    --arg handoff_path "$handoff_path" \
    --arg handoff_generated_at "$handoff_at" \
    --arg handoff_sha256 "$handoff_sha" \
    --arg ledger_path "$ledger_file" \
    --argjson ledger_events "$ledger_events" \
    --arg ledger_sha256 "$ledger_sha" \
    --arg op_env_path "$ATLAS_OP_FILE" \
    --arg op_env_sha256 "$op_env_sha" \
    --arg scope_path "$scope_file" \
    --arg scope_sha256 "$scope_sha" \
    --arg evidence_index_path "$evidence_index" \
    --arg evidence_index_sha256 "$evidence_index_sha" \
    --arg finding_index_path "$findings_index" \
    --arg finding_index_sha256 "$findings_index_sha" \
    --arg validation_index_path "$validation_index" \
    --arg validation_index_sha256 "$validation_index_sha" '
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
          closed_at: nullable($closed_at),
          target: $target,
          address: nullable($address),
          profile: $profile
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
            handoff: $handoff_freshness,
            closeout: $closeout_freshness
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
          },
          latest_handoff: {
            path: anchor_path($handoff_path; $handoff_sha256),
            generated_at: nullable($handoff_generated_at),
            sha256: nullable($handoff_sha256)
          }
        },
        integrity: {
          operation_ledger: {
            path: anchor_path($ledger_path; $ledger_sha256),
            events: $ledger_events,
            sha256: nullable($ledger_sha256)
          },
          operation_env: {
            path: anchor_path($op_env_path; $op_env_sha256),
            sha256: nullable($op_env_sha256)
          },
          scope_snapshot: {
            path: anchor_path($scope_path; $scope_sha256),
            sha256: nullable($scope_sha256)
          },
          evidence_index: {
            path: anchor_path($evidence_index_path; $evidence_index_sha256),
            sha256: nullable($evidence_index_sha256)
          },
          finding_index: {
            path: anchor_path($finding_index_path; $finding_index_sha256),
            sha256: nullable($finding_index_sha256)
          },
          validation_index: {
            path: anchor_path($validation_index_path; $validation_index_sha256),
            sha256: nullable($validation_index_sha256)
          }
        },
        known_limitations: [
          "Closeout manifests are metadata-only and retain local references, hashes, counts, freshness states, and verification anchors.",
          "Raw report, handoff, evidence, finding, validation, and ledger contents are not embedded.",
          "Closeout verification tolerates later audit, archive, and accepted-risk review packet ledger events when the recorded ledger prefix still matches.",
          "Closeout verification is not external audit, legal compliance evidence, or cryptographic immutability."
        ]
      }
    ' >"$file"
}

cmd_op_closeout() {
  local json_output=0
  local operation_name=""
  local manifest_name=""
  local manifest_slug
  local closeout_dir
  local manifest_file
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
      fail "unknown op closeout option: $1"
      ;;
    *)
      if [ -z "$operation_name" ]; then
        operation_name="$1"
      elif [ -z "$manifest_name" ]; then
        manifest_name="$1"
      else
        fail "op closeout [--json] [name] [manifest-name]"
      fi
      shift
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "op closeout [--json] [name] [manifest-name]"

  if [ -n "$operation_name" ]; then
    load_atlas_operation "$operation_name"
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
  if [ "$json_output" -eq 1 ]; then
    manifest_file="$closeout_dir/$manifest_slug.json"
  else
    manifest_file="$closeout_dir/$manifest_slug.md"
  fi

  atlas_ledger_append_current "closeout.manifest.generated" "read-only" "atlas" "ok" "$manifest_file"
  generated_at="$(timestamp)"
  if [ "$json_output" -eq 1 ]; then
    atlas_closeout_write_json_manifest "$manifest_file" "$generated_at"
  else
    atlas_closeout_write_manifest "$manifest_file"
  fi
  chmod 600 "$manifest_file" 2>/dev/null || true
  record_operation_history "$ATLAS_OP_DIR" "closeout" "$manifest_file"

  if [ "$json_output" -eq 1 ]; then
    ui_ok "closeout JSON manifest written"
    printf 'closeout_json: %s\n' "$manifest_file"
  else
    ui_ok "closeout manifest written"
    printf 'closeout: %s\n' "$manifest_file"
  fi
}

atlas_closeout_manifest_field() {
  local manifest_file="$1"
  local field="$2"

  awk -F': ' -v wanted="$field" '$1 == wanted { print $2; exit }' "$manifest_file"
}

atlas_closeout_manifest_anchor_line() {
  local manifest_file="$1"
  local label="$2"

  awk -v prefix="- $label: " 'index($0, prefix) == 1 { print; exit }' "$manifest_file"
}

atlas_closeout_anchor_path() {
  local line="$1"
  local rest

  rest="${line#*\`}"
  [ "$rest" != "$line" ] || return 0
  printf '%s\n' "${rest%%\`*}"
}

atlas_closeout_anchor_token() {
  local line="$1"
  local key="$2"

  printf '%s\n' "$line" |
    tr ' ' '\n' |
    awk -F= -v wanted="$key" '$1 == wanted { print $2; exit }'
}

atlas_closeout_verify_row() {
  local label="$1"
  local status="$2"
  local path="$3"
  local detail="${4:-}"

  if [ -n "$detail" ]; then
    printf '%-20s %-14s %s (%s)\n' "$label" "$status" "$path" "$detail"
  else
    printf '%-20s %-14s %s\n' "$label" "$status" "$path"
  fi
}

atlas_closeout_verify_hash_anchor() {
  local manifest_file="$1"
  local manifest_label="$2"
  local display_label="$3"
  local line
  local path
  local expected_sha
  local actual_sha

  line="$(atlas_closeout_manifest_anchor_line "$manifest_file" "$manifest_label")"
  if [ -z "$line" ]; then
    atlas_closeout_verify_row "$display_label" "unverifiable" "-" "anchor missing from manifest"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  path="$(atlas_closeout_anchor_path "$line")"
  if [ -z "$path" ]; then
    atlas_closeout_verify_row "$display_label" "unverifiable" "-" "not recorded"
    ATLAS_CLOSEOUT_VERIFY_GAPS=$((ATLAS_CLOSEOUT_VERIFY_GAPS + 1))
    return 0
  fi

  expected_sha="$(atlas_closeout_anchor_token "$line" "sha256")"
  if [ -z "$expected_sha" ]; then
    if [ ! -f "$path" ]; then
      atlas_closeout_verify_row "$display_label" "unverifiable" "$path" "not recorded"
      ATLAS_CLOSEOUT_VERIFY_GAPS=$((ATLAS_CLOSEOUT_VERIFY_GAPS + 1))
    else
      atlas_closeout_verify_row "$display_label" "unverifiable" "$path" "missing expected sha256"
      ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    fi
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_closeout_verify_row "$display_label" "missing" "$path" "expected sha256=$expected_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_sha" = "$expected_sha" ]; then
    atlas_closeout_verify_row "$display_label" "verified" "$path"
    ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
  else
    atlas_closeout_verify_row "$display_label" "changed" "$path" "expected=$expected_sha actual=$actual_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
  fi
}

atlas_closeout_numeric_token() {
  local value="$1"

  case "$value" in
  "" | *[!0-9]*)
    return 1
    ;;
  *)
    return 0
    ;;
  esac
}

atlas_closeout_ledger_prefix_sha() {
  local ledger_file="$1"
  local event_count="$2"

  atlas_closeout_numeric_token "$event_count" || return 1
  head -n "$event_count" "$ledger_file" | sha256sum | awk '{ print $1 }'
}

atlas_closeout_disallowed_later_ledger_events() {
  local ledger_file="$1"
  local expected_events="$2"

  atlas_closeout_numeric_token "$expected_events" || return 1
  tail -n +"$((expected_events + 1))" "$ledger_file" |
    jq -r '
      select(
        ((.event // "") != "audit.packet.generated")
        and ((.event // "") != "archive.packet.generated")
        and ((.event // "") != "finding.review_packet.generated")
      )
      | (.event // "?")
    ' |
    sort -u |
    paste -sd, -
}

atlas_closeout_ledger_anchor_matches() {
  local path="$1"
  local expected_events="$2"
  local expected_sha="$3"
  local actual_events
  local actual_sha
  local prefix_sha
  local disallowed_events

  [ -f "$path" ] || return 1
  atlas_closeout_numeric_token "$expected_events" || return 1

  actual_events="$(atlas_closeout_ledger_event_count "$path")"
  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_events" = "$expected_events" ] && [ "$actual_sha" = "$expected_sha" ]; then
    return 0
  fi

  atlas_closeout_numeric_token "$actual_events" || return 1
  [ "$actual_events" -gt "$expected_events" ] || return 1

  prefix_sha="$(atlas_closeout_ledger_prefix_sha "$path" "$expected_events")"
  [ "$prefix_sha" = "$expected_sha" ] || return 1

  disallowed_events="$(atlas_closeout_disallowed_later_ledger_events "$path" "$expected_events")"
  [ -z "$disallowed_events" ]
}

atlas_closeout_verify_ledger_anchor() {
  local manifest_file="$1"
  local line
  local path
  local expected_events
  local actual_events
  local expected_sha
  local actual_sha
  local prefix_sha
  local disallowed_events

  line="$(atlas_closeout_manifest_anchor_line "$manifest_file" "Operation ledger")"
  if [ -z "$line" ]; then
    atlas_closeout_verify_row "Operation Ledger" "unverifiable" "-" "anchor missing from manifest"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  path="$(atlas_closeout_anchor_path "$line")"
  expected_events="$(atlas_closeout_anchor_token "$line" "events")"
  expected_sha="$(atlas_closeout_anchor_token "$line" "sha256")"
  if [ -z "$path" ] || [ -z "$expected_events" ] || [ -z "$expected_sha" ]; then
    atlas_closeout_verify_row "Operation Ledger" "unverifiable" "${path:--}" "missing events or sha256"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_closeout_verify_row "Operation Ledger" "missing" "$path" "expected events=$expected_events sha256=$expected_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_events="$(atlas_closeout_ledger_event_count "$path")"
  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_events" = "$expected_events" ] && [ "$actual_sha" = "$expected_sha" ]; then
    atlas_closeout_verify_row "Operation Ledger" "verified" "$path" "events=$actual_events"
    ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
  elif atlas_closeout_numeric_token "$expected_events" &&
    atlas_closeout_numeric_token "$actual_events" &&
    [ "$actual_events" -gt "$expected_events" ]; then
    prefix_sha="$(atlas_closeout_ledger_prefix_sha "$path" "$expected_events")"
    disallowed_events="$(atlas_closeout_disallowed_later_ledger_events "$path" "$expected_events")"
    if [ "$prefix_sha" = "$expected_sha" ] && [ -z "$disallowed_events" ]; then
      atlas_closeout_verify_row "Operation Ledger" "verified" "$path" "events=$actual_events anchored_events=$expected_events later_allowed_events=$((actual_events - expected_events))"
      ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
    else
      atlas_closeout_verify_row "Operation Ledger" "changed" "$path" "expected_events=$expected_events actual_events=$actual_events expected_sha=$expected_sha actual_sha=$actual_sha disallowed_later_events=${disallowed_events:-none}"
      ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    fi
  else
    atlas_closeout_verify_row "Operation Ledger" "changed" "$path" "expected_events=$expected_events actual_events=$actual_events expected_sha=$expected_sha actual_sha=$actual_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
  fi
}

atlas_closeout_verify_json_hash_anchor() {
  local manifest_file="$1"
  local jq_path="$2"
  local display_label="$3"
  local path
  local expected_sha
  local actual_sha

  path="$(jq -r "$jq_path.path // \"\"" "$manifest_file" 2>/dev/null || true)"
  expected_sha="$(jq -r "$jq_path.sha256 // \"\"" "$manifest_file" 2>/dev/null || true)"
  if [ -z "$path" ]; then
    atlas_closeout_verify_row "$display_label" "unverifiable" "-" "not recorded"
    ATLAS_CLOSEOUT_VERIFY_GAPS=$((ATLAS_CLOSEOUT_VERIFY_GAPS + 1))
    return 0
  fi

  if [ -z "$expected_sha" ]; then
    atlas_closeout_verify_row "$display_label" "unverifiable" "$path" "missing expected sha256"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_closeout_verify_row "$display_label" "missing" "$path" "expected sha256=$expected_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_sha" = "$expected_sha" ]; then
    atlas_closeout_verify_row "$display_label" "verified" "$path"
    ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
  else
    atlas_closeout_verify_row "$display_label" "changed" "$path" "expected=$expected_sha actual=$actual_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
  fi
}

atlas_closeout_verify_json_ledger_anchor() {
  local manifest_file="$1"
  local path
  local expected_events
  local actual_events
  local expected_sha
  local actual_sha
  local prefix_sha
  local disallowed_events

  path="$(jq -r '.integrity.operation_ledger.path // ""' "$manifest_file" 2>/dev/null || true)"
  expected_events="$(jq -r '.integrity.operation_ledger.events // ""' "$manifest_file" 2>/dev/null || true)"
  expected_sha="$(jq -r '.integrity.operation_ledger.sha256 // ""' "$manifest_file" 2>/dev/null || true)"
  if [ -z "$path" ] || [ -z "$expected_events" ] || [ -z "$expected_sha" ]; then
    atlas_closeout_verify_row "Operation Ledger" "unverifiable" "${path:--}" "missing events or sha256"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  if [ ! -f "$path" ]; then
    atlas_closeout_verify_row "Operation Ledger" "missing" "$path" "expected events=$expected_events sha256=$expected_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    return 0
  fi

  actual_events="$(atlas_closeout_ledger_event_count "$path")"
  actual_sha="$(atlas_closeout_sha_for_file "$path")"
  if [ "$actual_events" = "$expected_events" ] && [ "$actual_sha" = "$expected_sha" ]; then
    atlas_closeout_verify_row "Operation Ledger" "verified" "$path" "events=$actual_events"
    ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
  elif atlas_closeout_numeric_token "$expected_events" &&
    atlas_closeout_numeric_token "$actual_events" &&
    [ "$actual_events" -gt "$expected_events" ]; then
    prefix_sha="$(atlas_closeout_ledger_prefix_sha "$path" "$expected_events")"
    disallowed_events="$(atlas_closeout_disallowed_later_ledger_events "$path" "$expected_events")"
    if [ "$prefix_sha" = "$expected_sha" ] && [ -z "$disallowed_events" ]; then
      atlas_closeout_verify_row "Operation Ledger" "verified" "$path" "events=$actual_events anchored_events=$expected_events later_allowed_events=$((actual_events - expected_events))"
      ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
    else
      atlas_closeout_verify_row "Operation Ledger" "changed" "$path" "expected_events=$expected_events actual_events=$actual_events expected_sha=$expected_sha actual_sha=$actual_sha disallowed_later_events=${disallowed_events:-none}"
      ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
    fi
  else
    atlas_closeout_verify_row "Operation Ledger" "changed" "$path" "expected_events=$expected_events actual_events=$actual_events expected_sha=$expected_sha actual_sha=$actual_sha"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
  fi
}

atlas_closeout_json_manifest_forbidden_content_present() {
  local manifest_file="$1"

  jq -r '
    paths(scalars) as $path
    | getpath($path)
    | strings
  ' "$manifest_file" 2>/dev/null |
    tr '[:upper:]' '[:lower:]' |
    grep -Eq 'password=|passwd=|api_key=|secret=|token=|authorization:|bearer[[:space:]]|set-cookie:|begin rsa|begin openssh|session=|cookie='
}

atlas_closeout_resolve_manifest() {
  local manifest_arg="$1"
  local latest_manifest
  local latest_manifest_path=""
  local candidate
  local manifest_base
  local manifest_slug

  if [ -z "$manifest_arg" ]; then
    latest_manifest="$(atlas_closeout_latest_manifest)"
    [ -n "$latest_manifest" ] || fail "no closeout manifest recorded for operation '$ATLAS_OP_SLUG'"
    IFS=$'\t' read -r _ latest_manifest_path <<<"$latest_manifest"
    [ -f "$latest_manifest_path" ] || fail "recorded closeout manifest is missing: $latest_manifest_path"
    printf '%s\n' "$latest_manifest_path"
    return 0
  fi

  if [ -f "$manifest_arg" ]; then
    readlink -f "$manifest_arg"
    return 0
  fi

  candidate="$ATLAS_OP_DIR/closeout/$manifest_arg"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  manifest_base="${manifest_arg%.md}"
  manifest_base="${manifest_base%.json}"
  manifest_slug="$(slugify "$manifest_base")"
  candidate="$ATLAS_OP_DIR/closeout/$manifest_slug.md"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi
  candidate="$ATLAS_OP_DIR/closeout/$manifest_slug.json"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  fail "unknown closeout manifest for operation '$ATLAS_OP_SLUG': $manifest_arg"
}

atlas_closeout_verify_json_manifest() {
  local manifest_file="$1"
  local manifest_operation
  local verification_status="verified"

  [ -f "$manifest_file" ] || fail "closeout manifest is not a file: $manifest_file"
  intel_require_jq
  jq -e 'type == "object"' "$manifest_file" >/dev/null 2>&1 || fail "closeout JSON manifest is invalid: $manifest_file"
  jq -e '.schema_version == "atlas.closeout_manifest.v1"' "$manifest_file" >/dev/null 2>&1 || fail "closeout JSON manifest has unsupported schema: $manifest_file"
  manifest_operation="$(jq -r '.operation.id // ""' "$manifest_file")"
  [ -n "$manifest_operation" ] || fail "closeout JSON manifest is missing operation.id: $manifest_file"
  [ "$manifest_operation" = "$ATLAS_OP_SLUG" ] || fail "closeout manifest belongs to '$manifest_operation', not '$ATLAS_OP_SLUG'"

  ATLAS_CLOSEOUT_VERIFY_PROBLEMS=0
  ATLAS_CLOSEOUT_VERIFY_GAPS=0
  ATLAS_CLOSEOUT_VERIFY_VERIFIED=0

  ui_heading "Closeout Verification"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Manifest" "$manifest_file"
  ui_rule
  printf '%-20s %-14s %s\n' "ARTIFACT" "STATUS" "PATH"

  if jq -e '.metadata_only == true' "$manifest_file" >/dev/null 2>&1; then
    atlas_closeout_verify_row "Metadata Only" "verified" "true"
    ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
  else
    atlas_closeout_verify_row "Metadata Only" "blocked" "expected=true"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
  fi

  if jq -e '.raw_artifacts_embedded == false' "$manifest_file" >/dev/null 2>&1; then
    atlas_closeout_verify_row "Raw Artifacts" "verified" "embedded=false"
    ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
  else
    atlas_closeout_verify_row "Raw Artifacts" "blocked" "expected embedded=false"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
  fi

  if atlas_closeout_json_manifest_forbidden_content_present "$manifest_file"; then
    atlas_closeout_verify_row "Forbidden Content" "blocked" "$manifest_file" "raw-content marker detected"
    ATLAS_CLOSEOUT_VERIFY_PROBLEMS=$((ATLAS_CLOSEOUT_VERIFY_PROBLEMS + 1))
  else
    atlas_closeout_verify_row "Forbidden Content" "verified" "$manifest_file"
    ATLAS_CLOSEOUT_VERIFY_VERIFIED=$((ATLAS_CLOSEOUT_VERIFY_VERIFIED + 1))
  fi

  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".artifacts.latest_report" "Latest Report"
  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".artifacts.evidence_manifest" "Evidence Manifest"
  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".artifacts.latest_handoff" "Latest Handoff"
  atlas_closeout_verify_json_ledger_anchor "$manifest_file"
  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".integrity.operation_env" "Operation Env"
  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".integrity.scope_snapshot" "Scope Snapshot"
  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".integrity.evidence_index" "Evidence Index"
  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".integrity.finding_index" "Finding Index"
  atlas_closeout_verify_json_hash_anchor "$manifest_file" ".integrity.validation_index" "Validation Index"
  ui_rule

  if [ "$ATLAS_CLOSEOUT_VERIFY_PROBLEMS" -gt 0 ]; then
    verification_status="attention-required"
  fi
  ui_kv "Verification Status" "$verification_status"
  ui_kv "Verified Anchors" "$ATLAS_CLOSEOUT_VERIFY_VERIFIED"
  ui_kv "Verification Gaps" "$ATLAS_CLOSEOUT_VERIFY_GAPS"
  ui_kv "Verification Problems" "$ATLAS_CLOSEOUT_VERIFY_PROBLEMS"

  [ "$ATLAS_CLOSEOUT_VERIFY_PROBLEMS" -eq 0 ] || return 1
}

atlas_closeout_verify_markdown_manifest() {
  local manifest_file="$1"
  local manifest_operation
  local verification_status="verified"

  [ -f "$manifest_file" ] || fail "closeout manifest is not a file: $manifest_file"
  manifest_operation="$(atlas_closeout_manifest_field "$manifest_file" "Operation ID")"
  [ -n "$manifest_operation" ] || fail "closeout manifest is missing Operation ID: $manifest_file"
  [ "$manifest_operation" = "$ATLAS_OP_SLUG" ] || fail "closeout manifest belongs to '$manifest_operation', not '$ATLAS_OP_SLUG'"

  ATLAS_CLOSEOUT_VERIFY_PROBLEMS=0
  ATLAS_CLOSEOUT_VERIFY_GAPS=0
  ATLAS_CLOSEOUT_VERIFY_VERIFIED=0

  ui_heading "Closeout Verification"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Manifest" "$manifest_file"
  ui_rule
  printf '%-20s %-14s %s\n' "ARTIFACT" "STATUS" "PATH"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Latest report" "Latest Report"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Evidence manifest" "Evidence Manifest"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Latest handoff" "Latest Handoff"
  atlas_closeout_verify_ledger_anchor "$manifest_file"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Operation env" "Operation Env"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Scope snapshot" "Scope Snapshot"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Evidence index" "Evidence Index"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Finding index" "Finding Index"
  atlas_closeout_verify_hash_anchor "$manifest_file" "Validation index" "Validation Index"
  ui_rule

  if [ "$ATLAS_CLOSEOUT_VERIFY_PROBLEMS" -gt 0 ]; then
    verification_status="attention-required"
  fi
  ui_kv "Verification Status" "$verification_status"
  ui_kv "Verified Anchors" "$ATLAS_CLOSEOUT_VERIFY_VERIFIED"
  ui_kv "Verification Gaps" "$ATLAS_CLOSEOUT_VERIFY_GAPS"
  ui_kv "Verification Problems" "$ATLAS_CLOSEOUT_VERIFY_PROBLEMS"

  [ "$ATLAS_CLOSEOUT_VERIFY_PROBLEMS" -eq 0 ] || return 1
}

atlas_closeout_verify_manifest() {
  local manifest_file="$1"

  [ -f "$manifest_file" ] || fail "closeout manifest is not a file: $manifest_file"
  if jq -e '.schema_version == "atlas.closeout_manifest.v1"' "$manifest_file" >/dev/null 2>&1; then
    atlas_closeout_verify_json_manifest "$manifest_file"
  else
    atlas_closeout_verify_markdown_manifest "$manifest_file"
  fi
}

cmd_op_verify() {
  local operation_name=""
  local manifest_arg=""
  local manifest_file
  local slug

  [ "$#" -le 2 ] || fail "op verify [name] [closeout-manifest]"

  if [ "$#" -eq 0 ]; then
    load_active_operation
  elif [ "$#" -eq 1 ]; then
    slug="$(session_slug_for "$1")"
    if [ -f "$(atlas_op_file_for_slug "$slug")" ]; then
      load_atlas_operation "$1"
    else
      load_active_operation
      manifest_arg="$1"
    fi
  else
    operation_name="$1"
    manifest_arg="$2"
    load_atlas_operation "$operation_name"
  fi

  manifest_file="$(atlas_closeout_resolve_manifest "$manifest_arg")"
  atlas_closeout_verify_manifest "$manifest_file"
}
