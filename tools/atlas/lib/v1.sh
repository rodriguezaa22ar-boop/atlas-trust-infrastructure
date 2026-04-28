#!/usr/bin/env bash

atlas_v1_rows_file=""
atlas_v1_blocked=0
atlas_v1_warnings=0
atlas_v1_required_not_ready=0

atlas_v1_status_valid() {
  case "$1" in
  ready | warning | blocked | planned | disabled | not-implemented)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

atlas_v1_add_pillar() {
  local key="$1"
  local label="$2"
  local required="$3"
  local status="$4"
  local reason="$5"
  local tests="$6"
  local commands="$7"
  local artifacts="$8"
  local limitations="$9"

  atlas_v1_status_valid "$status" || fail "invalid v1 pillar status: $status"

  case "$status" in
  ready) ;;
  warning)
    atlas_v1_warnings=$((atlas_v1_warnings + 1))
    [ "$required" = "1" ] && atlas_v1_required_not_ready=$((atlas_v1_required_not_ready + 1))
    ;;
  blocked | not-implemented)
    atlas_v1_blocked=$((atlas_v1_blocked + 1))
    [ "$required" = "1" ] && atlas_v1_required_not_ready=$((atlas_v1_required_not_ready + 1))
    ;;
  planned | disabled)
    [ "$required" = "1" ] && atlas_v1_required_not_ready=$((atlas_v1_required_not_ready + 1))
    ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$key" "$label" "$required" "$status" "$reason" "$tests" "$commands" "$artifacts" "$limitations" >>"$atlas_v1_rows_file"
}

atlas_v1_check_dir() {
  local key="$1"
  local label="$2"
  local required="$3"
  local dir="$4"
  local reason="$5"
  local tests="$6"
  local commands="$7"
  local artifacts="$8"
  local limitations="$9"

  if [ -d "$dir" ] && [ -w "$dir" ]; then
    atlas_v1_add_pillar "$key" "$label" "$required" "ready" "$reason" "$tests" "$commands" "$artifacts" "$limitations"
  elif [ -d "$dir" ]; then
    atlas_v1_add_pillar "$key" "$label" "$required" "blocked" "not writable: $dir" "$tests" "$commands" "$artifacts" "$limitations"
  else
    atlas_v1_add_pillar "$key" "$label" "$required" "blocked" "missing: $dir" "$tests" "$commands" "$artifacts" "$limitations"
  fi
}

atlas_v1_check_executable() {
  local key="$1"
  local label="$2"
  local required="$3"
  local path="$4"
  local reason="$5"
  local tests="$6"
  local commands="$7"
  local artifacts="$8"
  local limitations="$9"

  if [ -x "$path" ]; then
    atlas_v1_add_pillar "$key" "$label" "$required" "ready" "$reason" "$tests" "$commands" "$artifacts" "$limitations"
  else
    atlas_v1_add_pillar "$key" "$label" "$required" "blocked" "missing executable: $path" "$tests" "$commands" "$artifacts" "$limitations"
  fi
}

atlas_v1_check_command() {
  local key="$1"
  local label="$2"
  local required="$3"
  local command_name="$4"
  local reason="$5"
  local tests="$6"
  local commands="$7"
  local artifacts="$8"
  local limitations="$9"
  local resolved

  resolved="$(command -v "$command_name" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    atlas_v1_add_pillar "$key" "$label" "$required" "ready" "$reason" "$tests" "$commands" "$artifacts" "$limitations"
  else
    atlas_v1_add_pillar "$key" "$label" "$required" "blocked" "command not found: $command_name" "$tests" "$commands" "$artifacts" "$limitations"
  fi
}

atlas_v1_count_targets() {
  [ -d "$LAB_TARGETS_DIR" ] || {
    printf '0\n'
    return 0
  }
  find "$LAB_TARGETS_DIR" -maxdepth 1 -type f -name '*.env' 2>/dev/null | wc -l | tr -d ' '
}

atlas_v1_count_operations() {
  [ -d "$LAB_SESSIONS_DIR" ] || {
    printf '0\n'
    return 0
  }
  find "$LAB_SESSIONS_DIR" -mindepth 2 -maxdepth 2 -type f -name 'session.env' 2>/dev/null | wc -l | tr -d ' '
}

atlas_v1_commit() {
  local commit

  if ! git -C "$LAB_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'unknown\n'
    return 0
  fi

  commit="$(git -C "$LAB_ROOT" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  if ! git -C "$LAB_ROOT" diff --quiet --ignore-submodules -- 2>/dev/null ||
    ! git -C "$LAB_ROOT" diff --cached --quiet --ignore-submodules -- 2>/dev/null ||
    [ -n "$(git -C "$LAB_ROOT" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    commit="$commit-dirty"
  fi

  printf '%s\n' "$commit"
}

atlas_v1_overall() {
  if [ "$atlas_v1_blocked" -gt 0 ]; then
    printf 'blocked\n'
  elif [ "$atlas_v1_required_not_ready" -gt 0 ]; then
    printf 'not ready\n'
  elif [ "$atlas_v1_warnings" -gt 0 ]; then
    printf 'warning\n'
  else
    printf 'ready\n'
  fi
}

atlas_v1_operation_loaded() {
  [ -n "${ATLAS_OP_SLUG:-}" ] && [ -n "${ATLAS_OP_DIR:-}" ]
}

atlas_v1_collect_core() {
  atlas_v1_check_executable \
    "core_cli" \
    "Core CLI" \
    1 \
    "$TOOL_DIR/bin/atlas" \
    "shell-native atlas entrypoint is executable" \
    "tests/atlas.bats help and v1 status tests" \
    "atlas help; atlas v1 status" \
    "tools/atlas/bin/atlas" \
    "shell-native interface; no multi-user server yet"

  atlas_v1_check_dir \
    "target_registry" \
    "Target Registry" \
    1 \
    "$LAB_TARGETS_DIR" \
    "target env records and scope metadata directory are writable" \
    "tests/atlas.bats target metadata tests" \
    "atlas target add; atlas target update; atlas target show" \
    "$LAB_TARGETS_DIR" \
    "env-record storage remains intentionally simple"

  atlas_v1_check_executable \
    "recon" \
    "Recon" \
    1 \
    "$WIREMAP_BIN" \
    "wiremap adapter is available for operation-aware recon" \
    "tests/atlas.bats wiremap workflow tests" \
    "atlas op recon; atlas recon workflow" \
    "$WIREMAP_BIN" \
    "network probing still depends on operator authorization and local backends"

  atlas_v1_check_executable \
    "action_planner" \
    "Action Planner" \
    1 \
    "$VECTOR_BIN" \
    "vector adapter is available for ranked lanes and bounded outcomes" \
    "tests/atlas.bats vector lane and action tests" \
    "atlas action candidates; atlas op action plan" \
    "$VECTOR_BIN" \
    "execution remains manual and approval-gated"

  atlas_v1_check_executable \
    "intel_graph" \
    "Intel Graph" \
    1 \
    "$INTELCTL_BIN" \
    "intelctl adapter is available for graph and path views" \
    "tests/atlas.bats intel graph and paths tests" \
    "atlas intel graph; atlas intel paths" \
    "$LAB_INTEL_DIR" \
    "graph is file-backed NDJSON, not a graph database"

  atlas_v1_check_command \
    "evidence" \
    "Evidence" \
    1 \
    "sha256sum" \
    "hashing backend is available for artifact integrity" \
    "tests/atlas.bats evidence vault and bundle tests" \
    "atlas evidence add; atlas evidence bundle; atlas evidence hash" \
    "operation evidence directory and bundle manifests" \
    "no cryptographic signing yet"
}

atlas_v1_collect_operation_core() {
  local ledger_file
  local scope_snapshot

  if atlas_v1_operation_loaded; then
    ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
    if [ -s "$ledger_file" ]; then
      atlas_v1_add_pillar \
        "ledger" \
        "Ledger" \
        1 \
        "ready" \
        "operation ledger is present and nonempty" \
        "tests/atlas.bats operation ledger assertions" \
        "atlas op audit; atlas op status" \
        "$ledger_file" \
        "append-only file semantics, not immutable storage"
    else
      atlas_v1_add_pillar \
        "ledger" \
        "Ledger" \
        1 \
        "blocked" \
        "operation ledger is missing or empty: $ledger_file" \
        "tests/atlas.bats v1 negative ledger test" \
        "atlas op audit; atlas op status" \
        "$ledger_file" \
        "append-only file semantics, not immutable storage"
    fi

    scope_snapshot="$ATLAS_OP_DIR/scope.snapshot.env"
    if [ -s "$scope_snapshot" ]; then
      atlas_v1_add_pillar \
        "scopeguard" \
        "ScopeGuard" \
        1 \
        "ready" \
        "operation scope snapshot is present" \
        "tests/atlas.bats scopeguard and v1 negative snapshot tests" \
        "atlas scope status; atlas scope check" \
        "$scope_snapshot" \
        "policy model remains profile/env based"
    else
      atlas_v1_add_pillar \
        "scopeguard" \
        "ScopeGuard" \
        1 \
        "blocked" \
        "operation scope snapshot is missing: $scope_snapshot" \
        "tests/atlas.bats scopeguard and v1 negative snapshot tests" \
        "atlas scope status; atlas scope check" \
        "$scope_snapshot" \
        "policy model remains profile/env based"
    fi
  else
    atlas_v1_check_dir \
      "ledger" \
      "Ledger" \
      1 \
      "$LAB_SESSIONS_DIR" \
      "operation directories can hold append-only ledgers" \
      "tests/atlas.bats operation lifecycle tests" \
      "atlas op audit; atlas op status" \
      "$LAB_SESSIONS_DIR" \
      "append-only file semantics, not immutable storage"

    atlas_v1_check_dir \
      "scopeguard" \
      "ScopeGuard" \
      1 \
      "$ATLAS_STATE_DIR" \
      "scope profiles, approvals, and preflight state directory are available" \
      "tests/atlas.bats scopeguard tests" \
      "atlas scope status; atlas scope check" \
      "$ATLAS_STATE_DIR" \
      "policy model remains profile/env based"
  fi
}

atlas_v1_collect_operation_readiness() {
  local latest_bundle_fields
  local _bundle_at
  local _bundle_slug
  local _bundle_dir
  local manifest_file
  local _manifest_sha
  local _bundle_files
  local _include_unredacted

  if ! atlas_v1_operation_loaded; then
    atlas_v1_add_pillar \
      "findings" \
      "Findings" \
      1 \
      "ready" \
      "finding lifecycle commands are available" \
      "tests/atlas.bats finding lifecycle and accepted-risk tests" \
      "atlas finding add; atlas finding update; atlas finding accept; atlas finding review; atlas finding review-queue; atlas finding review-packet; atlas finding review-verify; atlas finding resolve" \
      "operation finding index and accepted-risk review packets" \
      "finding records are NDJSON files; accepted-risk expiry is checked during operation readiness"
    atlas_v1_add_pillar \
      "validation" \
      "Validation" \
      1 \
      "ready" \
      "approval-gated validation commands are available" \
      "tests/atlas.bats validation plan, run, and retest tests" \
      "atlas validation plan; atlas validation approve; atlas validation retest" \
      "operation validation plan index" \
      "validation execution is bounded by configured local backends"
    atlas_v1_add_pillar \
      "reports" \
      "Reports" \
      1 \
      "ready" \
      "report generation commands are available" \
      "tests/atlas.bats report and story tests" \
      "atlas op report; atlas op readiness" \
      "$LAB_REPORTS_DIR" \
      "Markdown reports are not digitally signed"
    atlas_v1_add_pillar \
      "retention" \
      "Retention" \
      1 \
      "ready" \
      "handoff, closeout, audit, archive, release trust, and freshness commands are available" \
      "tests/atlas.bats retention, archive, and release packet tests" \
      "atlas op closeout; atlas op audit-packet; atlas op archive-verify; atlas release packet; atlas release verify" \
      "closeout manifest, audit packet, archive packet, release trust packet" \
      "no cryptographic signing yet"
    return 0
  fi

  atlas_readiness_collect "$ATLAS_OP_TARGET"

  latest_bundle_fields="$(atlas_handoff_latest_bundle_fields)"
  if [ -n "$latest_bundle_fields" ]; then
    IFS=$'\t' read -r _bundle_at _bundle_slug _bundle_dir manifest_file _manifest_sha _bundle_files _include_unredacted <<<"$latest_bundle_fields"
    if [ -n "$manifest_file" ] && [ ! -f "$manifest_file" ]; then
      atlas_v1_add_pillar \
        "evidence" \
        "Evidence" \
        1 \
        "blocked" \
        "latest evidence bundle manifest is missing: $manifest_file" \
        "tests/atlas.bats v1 negative evidence manifest test" \
        "atlas evidence bundle" \
        "$manifest_file" \
        "no cryptographic signing yet"
    fi
  fi

  if [ "$ATLAS_READINESS_OPEN_FINDINGS_COUNT" -gt 0 ]; then
    atlas_v1_add_pillar \
      "findings" \
      "Findings" \
      1 \
      "warning" \
      "operation has unresolved findings: $ATLAS_READINESS_OPEN_FINDINGS_COUNT" \
      "tests/atlas.bats finding lifecycle and accepted-risk tests" \
      "atlas finding list; atlas finding accept; atlas finding review; atlas finding review-queue; atlas finding review-packet; atlas finding review-verify; atlas finding resolve" \
      "${ATLAS_OP_DIR}/findings.ndjson" \
      "accepted-risk workflow is file-backed and metadata-only"
  elif [ "$ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT" -gt 0 ]; then
    atlas_v1_add_pillar \
      "findings" \
      "Findings" \
      1 \
      "warning" \
      "operation has expired accepted risks: $ATLAS_READINESS_EXPIRED_ACCEPTED_RISK_COUNT" \
      "tests/atlas.bats accepted-risk expiry tests" \
      "atlas finding list; atlas finding review; atlas finding review-queue; atlas finding review-packet; atlas finding review-verify; atlas op readiness" \
      "${ATLAS_OP_DIR}/findings.ndjson" \
      "accepted-risk expiry is date-based; no reminder scheduler yet"
  else
    atlas_v1_add_pillar \
      "findings" \
      "Findings" \
      1 \
      "ready" \
      "finding lifecycle is implemented and no unresolved findings block this operation" \
      "tests/atlas.bats finding lifecycle and accepted-risk tests" \
      "atlas finding list; atlas finding accept; atlas finding review; atlas finding review-queue; atlas finding review-packet; atlas finding review-verify; atlas finding resolve" \
      "${ATLAS_OP_DIR}/findings.ndjson" \
      "accepted-risk workflow is file-backed and metadata-only; expiry is checked during operation readiness"
  fi

  if [ "$ATLAS_READINESS_PENDING_VALIDATION_COUNT" -gt 0 ]; then
    atlas_v1_add_pillar \
      "validation" \
      "Validation" \
      1 \
      "warning" \
      "operation has pending validation: $ATLAS_READINESS_PENDING_VALIDATION_COUNT" \
      "tests/atlas.bats validation plan, run, and retest tests" \
      "atlas validation list; atlas validation run" \
      "${ATLAS_OP_DIR}/validation.ndjson" \
      "validation execution is bounded by configured local backends"
  else
    atlas_v1_add_pillar \
      "validation" \
      "Validation" \
      1 \
      "ready" \
      "approval-gated validation is implemented and no pending validation blocks this operation" \
      "tests/atlas.bats validation plan, run, and retest tests" \
      "atlas validation list; atlas validation run" \
      "${ATLAS_OP_DIR}/validation.ndjson" \
      "validation execution is bounded by configured local backends"
  fi

  case "$ATLAS_READINESS_REPORT_FRESHNESS" in
  current)
    atlas_v1_add_pillar \
      "reports" \
      "Reports" \
      1 \
      "ready" \
      "latest operation report is current" \
      "tests/atlas.bats report freshness tests" \
      "atlas op report; atlas op readiness" \
      "${ATLAS_READINESS_LATEST_REPORT_PATH:-none}" \
      "Markdown reports are not digitally signed"
    ;;
  missing)
    atlas_v1_add_pillar \
      "reports" \
      "Reports" \
      1 \
      "warning" \
      "operation has no generated report yet" \
      "tests/atlas.bats report freshness tests" \
      "atlas op report; atlas op readiness" \
      "none" \
      "Markdown reports are not digitally signed"
    ;;
  *)
    atlas_v1_add_pillar \
      "reports" \
      "Reports" \
      1 \
      "blocked" \
      "operation report freshness is $ATLAS_READINESS_REPORT_FRESHNESS" \
      "tests/atlas.bats v1 negative report freshness test" \
      "atlas op report; atlas op readiness" \
      "${ATLAS_READINESS_LATEST_REPORT_PATH:-none}" \
      "Markdown reports are not digitally signed"
    ;;
  esac

  case "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS" in
  current)
    atlas_v1_add_pillar \
      "retention" \
      "Retention" \
      1 \
      "ready" \
      "archive packet freshness is current" \
      "tests/atlas.bats retention, archive, and release packet tests" \
      "atlas op archive; atlas op archive-verify; atlas op readiness; atlas release verify" \
      "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none}" \
      "no cryptographic signing yet"
    ;;
  stale)
    atlas_v1_add_pillar \
      "retention" \
      "Retention" \
      1 \
      "warning" \
      "archive packet freshness is stale" \
      "tests/atlas.bats v1 archive-stale test" \
      "atlas op archive; atlas op archive-verify; atlas op readiness; atlas release verify" \
      "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none}" \
      "no cryptographic signing yet"
    ;;
  *)
    atlas_v1_add_pillar \
      "retention" \
      "Retention" \
      1 \
      "ready" \
      "retention and release trust commands are implemented; no current archive packet is required for this operation state" \
      "tests/atlas.bats retention, archive, and release packet tests" \
      "atlas op closeout; atlas op audit-packet; atlas op archive-packet; atlas release packet; atlas release verify" \
      "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none}" \
      "no cryptographic signing yet"
    ;;
  esac
}

atlas_v1_collect_advisor() {
  case "${LAB_ATLAS_AI_ADVISOR:-${LAB_ATLAS_AI_ADVISOR_STATUS:-enabled}}" in
  disabled)
    atlas_v1_add_pillar \
      "ai_advisor" \
      "AI Advisor" \
      0 \
      "disabled" \
      "AI Advisor is explicitly disabled by environment policy" \
      "tests/atlas.bats v1 advisor-disabled test" \
      "atlas advisor brief; atlas advisor prompt" \
      "advisor prompt packet" \
      "external model execution is outside Atlas"
    ;;
  planned)
    atlas_v1_add_pillar \
      "ai_advisor" \
      "AI Advisor" \
      0 \
      "planned" \
      "AI Advisor is marked planned and non-blocking" \
      "tests/atlas.bats advisor prompt tests" \
      "atlas advisor brief; atlas advisor prompt" \
      "advisor prompt packet" \
      "external model execution is outside Atlas"
    ;;
  *)
    if declare -F cmd_advisor_brief >/dev/null 2>&1 && declare -F cmd_advisor_prompt >/dev/null 2>&1; then
      atlas_v1_add_pillar \
        "ai_advisor" \
        "AI Advisor" \
        0 \
        "ready" \
        "metadata-only advisor brief and prompt packet commands are available" \
        "tests/atlas.bats advisor brief and prompt tests" \
        "atlas advisor brief; atlas advisor prompt" \
        "advisor prompt packet" \
        "external model execution is outside Atlas"
    else
      atlas_v1_add_pillar \
        "ai_advisor" \
        "AI Advisor" \
        0 \
        "not-implemented" \
        "advisor commands are not available" \
        "tests/atlas.bats advisor brief and prompt tests" \
        "atlas advisor brief; atlas advisor prompt" \
        "advisor prompt packet" \
        "external model execution is outside Atlas"
    fi
    ;;
  esac
}

atlas_v1_collect_business_flow_evidence() {
  local policy="${LAB_ATLAS_BUSINESS_FLOWS:-${LAB_ATLAS_BUSINESS_FLOWS_STATUS:-enabled}}"
  local flow_records="0"
  local operation_links="0"
  local operation_packets="0"
  local reason
  local artifacts

  case "$policy" in
  disabled)
    atlas_v1_add_pillar \
      "business_flow_evidence" \
      "Business Flow Evidence" \
      0 \
      "disabled" \
      "Business Flow Evidence is explicitly disabled by environment policy" \
      "tests/atlas.bats business-flow readiness tests" \
      "atlas flow add; atlas flow packet; atlas flow verify" \
      "state/atlas/flows" \
      "optional pillar; disabled state is non-blocking"
    return 0
    ;;
  planned)
    atlas_v1_add_pillar \
      "business_flow_evidence" \
      "Business Flow Evidence" \
      0 \
      "planned" \
      "Business Flow Evidence is marked planned and non-blocking" \
      "tests/atlas.bats business-flow readiness tests" \
      "atlas flow add; atlas flow packet; atlas flow verify" \
      "state/atlas/flows" \
      "optional pillar; planned state is non-blocking"
    return 0
    ;;
  esac

  if ! declare -F cmd_flow_add >/dev/null 2>&1 ||
    ! declare -F cmd_flow_packet >/dev/null 2>&1 ||
    ! declare -F cmd_flow_verify >/dev/null 2>&1; then
    atlas_v1_add_pillar \
      "business_flow_evidence" \
      "Business Flow Evidence" \
      0 \
      "planned" \
      "Business Flow Evidence commands are not fully enabled yet" \
      "tests/atlas.bats business-flow readiness tests" \
      "atlas flow add; atlas flow packet; atlas flow verify" \
      "state/atlas/flows" \
      "optional pillar; command availability must be proven before promotion"
    return 0
  fi

  if declare -F atlas_flow_record_count >/dev/null 2>&1; then
    flow_records="$(atlas_flow_record_count)"
  fi

  artifacts="state/atlas/flows"
  reason="optional metadata-only flow commands, packet generation, and verification are available; flow_records=$flow_records"
  if atlas_v1_operation_loaded && declare -F atlas_flow_operation_link_count >/dev/null 2>&1; then
    operation_links="$(atlas_flow_operation_link_count "$ATLAS_OP_DIR")"
    operation_packets="$(atlas_flow_operation_packet_count "$ATLAS_OP_DIR")"
    reason="$reason active_operation_links=$operation_links active_operation_packets=$operation_packets"
    artifacts="$artifacts; ${ATLAS_OP_DIR}/business_flows.ndjson; ${ATLAS_OP_DIR}/flow_packets; ${ATLAS_OP_DIR}/flow_packets_json"
  fi

  atlas_v1_add_pillar \
    "business_flow_evidence" \
    "Business Flow Evidence" \
    0 \
    "ready" \
    "$reason" \
    "tests/atlas.bats business-flow records, links, packets, verify, and readiness tests" \
    "atlas flow add; atlas flow list; atlas flow show; atlas flow link-evidence; atlas flow packet; atlas flow packet --json; atlas flow verify; atlas flow verify --json" \
    "$artifacts" \
    "optional non-blocking pillar; no automatic flow discovery, finding/validation links, or retention links yet"
}

atlas_v1_collect() {
  atlas_v1_blocked=0
  atlas_v1_warnings=0
  atlas_v1_required_not_ready=0

  atlas_v1_collect_core
  atlas_v1_collect_operation_core
  atlas_v1_collect_operation_readiness
  atlas_v1_collect_business_flow_evidence
  atlas_v1_collect_advisor
}

atlas_v1_print_text() {
  local overall="$1"
  local strict="$2"

  ui_heading "Atlas V1 Status"
  ui_rule
  ui_kv "Root" "$LAB_ROOT"
  ui_kv "Commit" "$(atlas_v1_commit)"
  ui_kv "Runtime Target" "$LAB_RUNTIME_TARGET"
  if atlas_v1_operation_loaded; then
    ui_kv "Operation" "$ATLAS_OP_SLUG"
    ui_kv "Operation Status" "$ATLAS_OP_STATUS"
    ui_kv "Target" "$ATLAS_OP_TARGET"
  else
    ui_kv "Operation" "none loaded"
  fi
  ui_kv "Target Records" "$(atlas_v1_count_targets)"
  ui_kv "Operations" "$(atlas_v1_count_operations)"
  ui_kv "Strict" "$strict"
  ui_rule

  ui_subheading "V1 Pillars"
  printf '%-22s %-16s %-10s %s\n' "PILLAR" "STATUS" "REQUIRED" "REASON"
  awk -F'\t' '{
    required = ($3 == "1" ? "yes" : "no")
    printf "%-22s %-16s %-10s %s\n", $2, $4, required, $5
  }' "$atlas_v1_rows_file"
  ui_rule
  ui_kv "Overall" "$overall"
  ui_kv "Blocked Pillars" "$atlas_v1_blocked"
  ui_kv "Warning Pillars" "$atlas_v1_warnings"
  ui_kv "Required Not Ready" "$atlas_v1_required_not_ready"
}

atlas_v1_print_json() {
  local overall="$1"
  local strict="$2"
  local operation_slug=""
  local operation_status=""
  local operation_target=""

  if atlas_v1_operation_loaded; then
    operation_slug="$ATLAS_OP_SLUG"
    operation_status="$ATLAS_OP_STATUS"
    operation_target="$ATLAS_OP_TARGET"
  fi

  jq -Rn \
    --arg overall "$overall" \
    --arg commit "$(atlas_v1_commit)" \
    --arg root "$LAB_ROOT" \
    --arg runtime_target "$LAB_RUNTIME_TARGET" \
    --arg operation_slug "$operation_slug" \
    --arg operation_status "$operation_status" \
    --arg operation_target "$operation_target" \
    --arg strict "$strict" \
    --argjson blocked "$atlas_v1_blocked" \
    --argjson warnings "$atlas_v1_warnings" \
    --argjson required_not_ready "$atlas_v1_required_not_ready" '
      [inputs | split("\t")] as $rows
      | {
          overall: $overall,
          commit: $commit,
          root: $root,
          runtime_target: $runtime_target,
          strict: ($strict == "1"),
          operation: (
            if $operation_slug == "" then null
            else {
              slug: $operation_slug,
              status: $operation_status,
              target: $operation_target
            }
            end
          ),
          counts: {
            blocked: $blocked,
            warning: $warnings,
            required_not_ready: $required_not_ready
          },
          pillars: (
            $rows
            | map({
                key: .[0],
                value: {
                  label: .[1],
                  required: (.[2] == "1"),
                  status: .[3],
                  reason: .[4],
                  tests: .[5],
                  commands: .[6],
                  artifacts: .[7],
                  limitations: .[8]
                }
              })
            | from_entries
          )
        }
    ' <"$atlas_v1_rows_file"
}

cmd_v1_status() {
  local strict=0
  local json=0
  local operation_name=""
  local overall
  local exit_status=0

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
      fail "unknown v1 status option: $1"
      ;;
    *)
      if [ -n "$operation_name" ]; then
        fail "v1 status [name] [--strict] [--json]"
      fi
      operation_name="$1"
      shift
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "v1 status [name] [--strict] [--json]"

  if [ -n "$operation_name" ]; then
    load_atlas_operation "$operation_name"
  elif has_active_operation; then
    load_active_operation
  fi

  atlas_v1_rows_file="$(mktemp)"
  atlas_v1_collect
  overall="$(atlas_v1_overall)"

  if [ "$json" -eq 1 ]; then
    atlas_v1_print_json "$overall" "$strict"
  else
    atlas_v1_print_text "$overall" "$strict"
  fi

  if [ "$atlas_v1_blocked" -gt 0 ]; then
    exit_status=1
  elif [ "$strict" -eq 1 ] && [ "$overall" != "ready" ]; then
    exit_status=1
  fi

  rm -f "$atlas_v1_rows_file"
  return "$exit_status"
}
