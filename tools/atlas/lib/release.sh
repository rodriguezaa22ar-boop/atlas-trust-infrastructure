#!/usr/bin/env bash

atlas_release_git_available() {
  git -C "$LAB_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

atlas_release_commit() {
  if atlas_release_git_available; then
    git -C "$LAB_ROOT" rev-parse --short HEAD 2>/dev/null || printf 'unknown\n'
  else
    printf 'unknown\n'
  fi
}

atlas_release_branch() {
  if atlas_release_git_available; then
    git -C "$LAB_ROOT" branch --show-current 2>/dev/null || printf 'unknown\n'
  else
    printf 'unknown\n'
  fi
}

atlas_release_clean_state() {
  if ! atlas_release_git_available; then
    printf 'unknown\n'
    return 0
  fi

  if git -C "$LAB_ROOT" diff --quiet --ignore-submodules -- 2>/dev/null &&
    git -C "$LAB_ROOT" diff --cached --quiet --ignore-submodules -- 2>/dev/null &&
    [ -z "$(git -C "$LAB_ROOT" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    printf 'clean\n'
  else
    printf 'dirty\n'
  fi
}

atlas_release_upstream() {
  if atlas_release_git_available; then
    git -C "$LAB_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true
  fi
}

atlas_release_sync_state() {
  local upstream
  local counts
  local ahead=0
  local behind=0

  upstream="$(atlas_release_upstream)"
  if [ -z "$upstream" ]; then
    printf 'no-upstream\n'
    return 0
  fi

  counts="$(git -C "$LAB_ROOT" rev-list --left-right --count "HEAD...$upstream" 2>/dev/null || printf '0 0')"
  read -r ahead behind <<<"$counts"
  if [ "$ahead" = "0" ] && [ "$behind" = "0" ]; then
    printf 'synced'
  else
    printf 'ahead=%s behind=%s' "$ahead" "$behind"
  fi
}

atlas_release_tags_at_head() {
  if atlas_release_git_available; then
    git -C "$LAB_ROOT" tag --points-at HEAD 2>/dev/null | sort
  fi
}

atlas_release_retention_notes() {
  local notes_dir="$LAB_DOCS_DIR/retention/milestones"

  if [ -f "$LAB_DOCS_DIR/retention/MILESTONE_30.md" ]; then
    printf '%s\n' "$LAB_DOCS_DIR/retention/MILESTONE_30.md"
  fi

  if [ -d "$notes_dir" ]; then
    find "$notes_dir" -maxdepth 1 -type f -name 'MILESTONE_*.md' 2>/dev/null | sort
  fi
}

atlas_release_retention_notes_for_commit() {
  local expected_commit="$1"
  local path

  if [ -n "$expected_commit" ] &&
    atlas_release_git_available &&
    git -C "$LAB_ROOT" rev-parse --verify "$expected_commit^{commit}" >/dev/null 2>&1; then
    git -C "$LAB_ROOT" ls-tree -r --name-only "$expected_commit" -- \
      docs/retention/MILESTONE_30.md \
      docs/retention/milestones 2>/dev/null |
      sort |
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        printf '%s/%s\n' "$LAB_ROOT" "$path"
      done
    return 0
  fi

  atlas_release_retention_notes
}

atlas_release_commit_matches() {
  local actual="$1"
  local expected="$2"

  [ -n "$actual" ] || return 1
  [ -n "$expected" ] || return 1

  [ "$actual" = "$expected" ] ||
    [[ "$actual" == "$expected"* ]] ||
    [[ "$expected" == "$actual"* ]]
}

atlas_release_display_path() {
  local path="$1"

  case "$path" in
  "$LAB_ROOT"/*)
    printf '%s\n' "${path#"$LAB_ROOT"/}"
    ;;
  *)
    printf '%s\n' "$path"
    ;;
  esac
}

atlas_release_v1_json() {
  local old_rows_file="${atlas_v1_rows_file:-}"
  local rows_file
  local overall

  rows_file="$(mktemp)"
  atlas_v1_rows_file="$rows_file"
  atlas_v1_collect
  overall="$(atlas_v1_overall)"
  atlas_v1_print_json "$overall" 0
  rm -f "$rows_file"
  atlas_v1_rows_file="$old_rows_file"
}

atlas_release_print_tags() {
  local tags="$1"

  if [ -z "$tags" ]; then
    printf -- '- none\n'
    return 0
  fi

  while IFS= read -r tag_name; do
    [ -n "$tag_name" ] || continue
    printf -- "- \`%s\`\n" "$tag_name"
  done <<<"$tags"
}

atlas_release_print_retention_notes() {
  local notes="$1"

  if [ -z "$notes" ]; then
    printf -- '- none\n'
    return 0
  fi

  while IFS= read -r note_path; do
    [ -n "$note_path" ] || continue
    printf -- "- \`%s\`\n" "$(atlas_release_display_path "$note_path")"
  done <<<"$notes"
}

atlas_release_retention_note_paths() {
  local notes="$1"

  while IFS= read -r note_path; do
    [ -n "$note_path" ] || continue
    atlas_release_display_path "$note_path"
  done <<<"$notes"
}

atlas_release_print_limitations() {
  local v1_json="$1"

  printf '%s\n' "$v1_json" |
    jq -r '.pillars | to_entries[] | "- " + .value.label + ": " + .value.limitations'
}

atlas_release_limitations_json() {
  local v1_json="$1"

  printf '%s\n' "$v1_json" |
    jq '[.pillars | to_entries[] | {pillar: .value.label, limitation: (.value.limitations // "")}]'
}

atlas_release_guard_packet() {
  local clean_state="$1"
  local sync_state="$2"
  local v1_overall="$3"
  local operation_trust_status="$4"
  local allow_dirty="$5"
  local allow_unsynced="$6"
  local allow_not_ready="$7"

  if [ "$clean_state" != "clean" ] && [ "$allow_dirty" != "1" ]; then
    fail "release packet requires a clean repository; commit or discard changes, or pass --allow-dirty"
  fi

  if [ "$sync_state" != "synced" ] && [ "$allow_unsynced" != "1" ]; then
    fail "release packet requires synced upstream state; push/pull first, or pass --allow-unsynced"
  fi

  if [ "$v1_overall" != "ready" ] && [ "$allow_not_ready" != "1" ]; then
    fail "release packet requires v1 readiness overall=ready; resolve readiness first, or pass --allow-not-ready"
  fi

  if [ -n "$operation_trust_status" ] && [ "$operation_trust_status" != "current" ] && [ "$allow_not_ready" != "1" ]; then
    fail "release packet requires operation trust chain status=current; resolve trust chain first, or pass --allow-not-ready"
  fi
}

atlas_release_operation_trust_json() {
  if ! atlas_v1_operation_loaded; then
    printf 'null\n'
    return 0
  fi

  atlas_trust_chain_collect

  jq -n \
    --arg slug "$ATLAS_OP_SLUG" \
    --arg name "$ATLAS_OP_NAME" \
    --arg target "$ATLAS_OP_TARGET" \
    --arg operation_status "$ATLAS_OP_STATUS" \
    --arg status "$ATLAS_TRUST_CHAIN_STATUS" \
    --arg next_step "$ATLAS_TRUST_CHAIN_NEXT_STEP" \
    --arg close_readiness "$ATLAS_READINESS_STATUS" \
    --arg v1_overall "$ATLAS_TRUST_V1_OVERALL" \
    --argjson v1_required_not_ready "${ATLAS_TRUST_V1_REQUIRED_NOT_READY:-0}" \
    --arg report_freshness "$ATLAS_READINESS_REPORT_FRESHNESS" \
    --arg bundle_freshness "$ATLAS_READINESS_BUNDLE_FRESHNESS" \
    --arg handoff_freshness "$ATLAS_READINESS_HANDOFF_FRESHNESS" \
    --arg closeout_freshness "$ATLAS_READINESS_CLOSEOUT_FRESHNESS" \
    --arg review_packet_freshness "$ATLAS_READINESS_REVIEW_PACKET_FRESHNESS" \
    --arg audit_packet_freshness "$ATLAS_READINESS_AUDIT_PACKET_FRESHNESS" \
    --arg archive_packet_freshness "$ATLAS_READINESS_ARCHIVE_PACKET_FRESHNESS" \
    --arg closeout_verification "$ATLAS_ARCHIVE_CLOSEOUT_VERIFICATION_STATUS" \
    --arg review_packet_verification "$ATLAS_ARCHIVE_REVIEW_PACKET_VERIFICATION_STATUS" \
    --arg audit_packet_verification "$ATLAS_ARCHIVE_AUDIT_PACKET_VERIFICATION_STATUS" \
    --arg archive_packet_verification "$ATLAS_TRUST_ARCHIVE_PACKET_VERIFICATION_STATUS" \
    --arg report_path "${ATLAS_READINESS_LATEST_REPORT_PATH:-none}" \
    --arg closeout_path "${ATLAS_READINESS_LATEST_CLOSEOUT_PATH:-none}" \
    --arg review_packet_path "${ATLAS_READINESS_LATEST_REVIEW_PACKET_PATH:-none}" \
    --arg audit_packet_path "${ATLAS_READINESS_LATEST_AUDIT_PACKET_PATH:-none}" \
    --arg archive_packet_path "${ATLAS_READINESS_LATEST_ARCHIVE_PACKET_PATH:-none}" \
    --arg ledger_file "$ATLAS_ARCHIVE_LEDGER_FILE" \
    --argjson ledger_events "${ATLAS_ARCHIVE_LEDGER_EVENTS:-0}" \
    --arg ledger_sha "$ATLAS_ARCHIVE_LEDGER_SHA" \
    '{
      operation: {
        slug: $slug,
        name: $name,
        target: $target,
        status: $operation_status
      },
      status: $status,
      next_step: $next_step,
      close_readiness: $close_readiness,
      v1: {
        overall: $v1_overall,
        required_not_ready: $v1_required_not_ready
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
        closeout: $closeout_verification,
        accepted_risk_review_packet: $review_packet_verification,
        audit_packet: $audit_packet_verification,
        archive_packet: $archive_packet_verification
      },
      artifacts: {
        report: $report_path,
        closeout: $closeout_path,
        accepted_risk_review_packet: $review_packet_path,
        audit_packet: $audit_packet_path,
        archive_packet: $archive_packet_path
      },
      ledger: {
        path: $ledger_file,
        events: $ledger_events,
        sha256: $ledger_sha
      }
    }'
}

atlas_release_print_operation_trust() {
  local operation_trust_json="$1"
  local value

  if [ -z "$operation_trust_json" ] || [ "$operation_trust_json" = "null" ]; then
    printf -- '- Operation trust chain: not recorded\n'
    return 0
  fi

  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.operation.slug')"
  printf -- '- Operation ID: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.operation.target')"
  printf -- '- Operation target: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.status')"
  printf -- '- Trust chain status: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.close_readiness')"
  printf -- '- Close readiness: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.v1.overall + " required_not_ready=" + (.v1.required_not_ready | tostring)')"
  printf -- '- V1 readiness: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.freshness.archive_packet')"
  printf -- '- Archive packet freshness: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.verification.archive_packet')"
  printf -- '- Archive packet verification: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.artifacts.archive_packet')"
  printf -- '- Archive packet: %s\n' "$value"
  value="$(printf '%s\n' "$operation_trust_json" | jq -r '.ledger.path + " events=" + (.ledger.events | tostring) + " sha256=" + .ledger.sha256')"
  printf -- '- Operation ledger: %s\n' "$value"
}

atlas_release_write_packet() {
  local file="$1"
  local packet_name="$2"
  local qa_status="$3"
  local qa_command="$4"
  local qa_note="$5"
  local allow_dirty="$6"
  local allow_unsynced="$7"
  local allow_not_ready="$8"
  local generated
  local commit
  local branch
  local clean_state
  local upstream
  local sync_state
  local tags
  local retention_notes
  local v1_json
  local v1_overall
  local required_not_ready
  local blocked
  local warnings
  local operation_trust_json
  local operation_trust_status=""

  generated="$(timestamp)"
  commit="$(atlas_release_commit)"
  branch="$(atlas_release_branch)"
  clean_state="$(atlas_release_clean_state)"
  upstream="$(atlas_release_upstream)"
  sync_state="$(atlas_release_sync_state)"
  tags="$(atlas_release_tags_at_head)"
  retention_notes="$(atlas_release_retention_notes)"
  v1_json="$(atlas_release_v1_json)"
  v1_overall="$(printf '%s\n' "$v1_json" | jq -r '.overall')"
  required_not_ready="$(printf '%s\n' "$v1_json" | jq -r '.counts.required_not_ready')"
  blocked="$(printf '%s\n' "$v1_json" | jq -r '.counts.blocked')"
  warnings="$(printf '%s\n' "$v1_json" | jq -r '.counts.warning')"
  operation_trust_json="$(atlas_release_operation_trust_json)"
  if [ "$operation_trust_json" != "null" ]; then
    operation_trust_status="$(printf '%s\n' "$operation_trust_json" | jq -r '.status // ""')"
  fi

  atlas_release_guard_packet "$clean_state" "$sync_state" "$v1_overall" "$operation_trust_status" "$allow_dirty" "$allow_unsynced" "$allow_not_ready"

  {
    printf '# Atlas Release Trust Packet\n\n'
    printf 'Generated: %s\n' "$generated"
    printf 'Packet: %s\n' "$packet_name"
    printf 'Root: %s\n' "$LAB_ROOT"
    printf 'Commit: %s\n' "$commit"
    printf 'Branch: %s\n' "${branch:-unknown}"
    printf 'Upstream: %s\n' "${upstream:-none}"
    printf 'Repository state before packet: %s\n' "$clean_state"
    printf 'Upstream sync before packet: %s\n' "$sync_state"
    printf 'Runtime target: %s\n' "$LAB_RUNTIME_TARGET"
    printf '\nNo raw runtime artifacts, target secrets, session contents, packet captures, or evidence bodies are included in this release trust packet.\n'

    printf '\n## Readiness Summary\n\n'
    printf -- '- Overall: %s\n' "$v1_overall"
    printf -- '- Required not ready: %s\n' "$required_not_ready"
    printf -- '- Blocked pillars: %s\n' "$blocked"
    printf -- '- Warning pillars: %s\n' "$warnings"

    printf '\n## Operation Trust Chain\n\n'
    atlas_release_print_operation_trust "$operation_trust_json"

    printf '\n## QA Summary\n\n'
    printf -- '- QA status: %s\n' "$qa_status"
    printf -- "- QA command: \`%s\`\n" "$qa_command"
    printf -- '- QA note: %s\n' "$qa_note"

    printf '\n## Tags At Commit\n\n'
    atlas_release_print_tags "$tags"

    printf '\n## Retention Notes\n\n'
    atlas_release_print_retention_notes "$retention_notes"

    printf '\n## Known Limitations\n\n'
    atlas_release_print_limitations "$v1_json"

    printf '\n## V1 Readiness JSON\n\n'
    printf '```json\n'
    printf '%s\n' "$v1_json"
    printf '```\n'

    printf '\n## Release Trust Notes\n\n'
    printf -- '- This packet is metadata-only and safe to review without exposing raw operation artifacts.\n'
    printf -- '- Treat the repository workspace as sensitive if ignored runtime folders are present locally.\n'
    printf -- '- Re-run the QA command immediately before promoting a public or operator-facing release.\n'
  } >"$file"
}

atlas_release_write_json_packet() {
  local file="$1"
  local packet_name="$2"
  local qa_status="$3"
  local qa_command="$4"
  local qa_note="$5"
  local allow_dirty="$6"
  local allow_unsynced="$7"
  local allow_not_ready="$8"
  local generated
  local commit
  local branch
  local clean_state
  local upstream
  local sync_state
  local tags
  local retention_notes
  local retention_note_paths
  local v1_json
  local v1_overall
  local limitations_json
  local operation_trust_json
  local operation_trust_status=""

  generated="$(timestamp)"
  commit="$(atlas_release_commit)"
  branch="$(atlas_release_branch)"
  clean_state="$(atlas_release_clean_state)"
  upstream="$(atlas_release_upstream)"
  sync_state="$(atlas_release_sync_state)"
  tags="$(atlas_release_tags_at_head)"
  retention_notes="$(atlas_release_retention_notes)"
  retention_note_paths="$(atlas_release_retention_note_paths "$retention_notes")"
  v1_json="$(atlas_release_v1_json)"
  v1_overall="$(printf '%s\n' "$v1_json" | jq -r '.overall')"
  limitations_json="$(atlas_release_limitations_json "$v1_json")"
  operation_trust_json="$(atlas_release_operation_trust_json)"
  if [ "$operation_trust_json" != "null" ]; then
    operation_trust_status="$(printf '%s\n' "$operation_trust_json" | jq -r '.status // ""')"
  fi

  atlas_release_guard_packet "$clean_state" "$sync_state" "$v1_overall" "$operation_trust_status" "$allow_dirty" "$allow_unsynced" "$allow_not_ready"

  jq -n \
    --arg schema_version "atlas.release_trust.v1" \
    --arg generated "$generated" \
    --arg packet "$packet_name" \
    --arg root "$LAB_ROOT" \
    --arg commit "$commit" \
    --arg branch "${branch:-unknown}" \
    --arg upstream "${upstream:-none}" \
    --arg clean_state "$clean_state" \
    --arg sync_state "$sync_state" \
    --arg runtime_target "$LAB_RUNTIME_TARGET" \
    --arg qa_status "$qa_status" \
    --arg qa_command "$qa_command" \
    --arg qa_note "$qa_note" \
    --arg tags_text "$tags" \
    --arg retention_notes_text "$retention_note_paths" \
    --argjson limitations "$limitations_json" \
    --argjson operation_trust_chain "$operation_trust_json" \
    --argjson readiness "$v1_json" \
    '{
      schema_version: $schema_version,
      generated: $generated,
      packet: $packet,
      root: $root,
      commit: $commit,
      branch: $branch,
      upstream: $upstream,
      repository: {
        state_before_packet: $clean_state,
        upstream_sync_before_packet: $sync_state
      },
      runtime_target: $runtime_target,
      metadata_only: true,
      qa: {
        status: $qa_status,
        command: $qa_command,
        note: $qa_note
      },
      tags: ($tags_text | split("\n") | map(select(length > 0))),
      retention_notes: ($retention_notes_text | split("\n") | map(select(length > 0))),
      known_limitations: $limitations,
      operation_trust_chain: $operation_trust_chain,
      readiness: $readiness
    }' >"$file"
}

atlas_release_packet_field() {
  local packet_file="$1"
  local field="$2"

  awk -F': ' -v wanted="$field" '$1 == wanted { print substr($0, length(wanted) + 3); exit }' "$packet_file"
}

atlas_release_packet_bullet() {
  local packet_file="$1"
  local label="$2"

  awk -F': ' -v wanted="- $label" '$1 == wanted { print substr($0, length(wanted) + 3); exit }' "$packet_file"
}

atlas_release_packet_json() {
  local packet_file="$1"

  awk '
    /^```json$/ {
      in_json = 1
      next
    }
    /^```$/ && in_json {
      exit
    }
    in_json {
      print
    }
  ' "$packet_file"
}

atlas_release_latest_packet() {
  local packet_dir="$LAB_DOCS_DIR/retention/releases"

  [ -d "$packet_dir" ] || return 0
  find "$packet_dir" -maxdepth 1 -type f \( -name '*.md' -o -name '*.json' \) -printf '%T@\t%p\n' 2>/dev/null |
    sort -nr |
    awk -F'\t' 'NR == 1 { print $2 }'
}

atlas_release_resolve_packet() {
  local packet_arg="$1"
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local candidate
  local packet_base
  local packet_slug

  if [ -z "$packet_arg" ]; then
    candidate="$(atlas_release_latest_packet)"
    [ -n "$candidate" ] || fail "no release trust packet found"
    printf '%s\n' "$candidate"
    return 0
  fi

  if [ -f "$packet_arg" ]; then
    readlink -f "$packet_arg"
    return 0
  fi

  candidate="$packet_dir/$packet_arg"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  packet_base="${packet_arg%.md}"
  packet_base="${packet_base%.json}"
  packet_slug="$(slugify "$packet_base")"
  candidate="$packet_dir/$packet_slug.md"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  candidate="$packet_dir/$packet_slug.json"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  fail "unknown release trust packet: $packet_arg"
}

atlas_release_verify_failures=0

atlas_release_verify_row() {
  local label="$1"
  local status="$2"
  local detail="$3"

  ui_kv "$label" "$status $detail"
  [ "$status" = "ok" ] || atlas_release_verify_failures=$((atlas_release_verify_failures + 1))
}

atlas_release_replay_operation_trust_json() {
  local operation_slug="$1"
  local current_json
  local operation_file

  [ -n "$operation_slug" ] || return 1
  operation_file="$(atlas_op_file_for_slug "$(session_slug_for "$operation_slug")")"
  [ -f "$operation_file" ] || return 1

  load_atlas_operation "$operation_slug"
  current_json="$(atlas_release_operation_trust_json)"
  [ -n "$current_json" ] && [ "$current_json" != "null" ] || return 1
  printf '%s\n' "$current_json"
}

atlas_release_verify_operation_trust_json() {
  local packet_file="$1"
  local operation_slug
  local packet_status
  local current_json
  local current_status
  local packet_ledger_events
  local current_ledger_events
  local packet_ledger_sha
  local current_ledger_sha
  local packet_archive_path
  local current_archive_path
  local packet_archive_verification
  local current_archive_verification

  if ! jq -e 'has("operation_trust_chain") and .operation_trust_chain != null' "$packet_file" >/dev/null 2>&1; then
    atlas_release_verify_row "Operation Trust Chain" "ok" "not-recorded"
    return 0
  fi

  operation_slug="$(jq -r '.operation_trust_chain.operation.slug // ""' "$packet_file")"
  packet_status="$(jq -r '.operation_trust_chain.status // ""' "$packet_file")"
  if [ -z "$operation_slug" ]; then
    atlas_release_verify_row "Operation Trust Chain" "fail" "operation=missing status=${packet_status:-missing}"
    return 0
  fi

  current_json="$(atlas_release_replay_operation_trust_json "$operation_slug" 2>/dev/null || true)"
  if [ -z "$current_json" ]; then
    atlas_release_verify_row "Operation Trust Chain" "fail" "operation=$operation_slug replay=missing"
    return 0
  fi

  current_status="$(printf '%s\n' "$current_json" | jq -r '.status // ""')"
  if [ "$packet_status" = "current" ] && [ "$current_status" = "current" ]; then
    atlas_release_verify_row "Operation Trust Chain" "ok" "status=current replay=current operation=$operation_slug"
  else
    atlas_release_verify_row "Operation Trust Chain" "fail" "packet_status=${packet_status:-missing} replay_status=${current_status:-missing} operation=$operation_slug"
  fi

  packet_ledger_events="$(jq -r '.operation_trust_chain.ledger.events // ""' "$packet_file")"
  current_ledger_events="$(printf '%s\n' "$current_json" | jq -r '.ledger.events // ""')"
  packet_ledger_sha="$(jq -r '.operation_trust_chain.ledger.sha256 // ""' "$packet_file")"
  current_ledger_sha="$(printf '%s\n' "$current_json" | jq -r '.ledger.sha256 // ""')"
  if [ "$packet_ledger_events" = "$current_ledger_events" ] && [ "$packet_ledger_sha" = "$current_ledger_sha" ]; then
    atlas_release_verify_row "Operation Ledger Replay" "ok" "events=$current_ledger_events sha256=$current_ledger_sha"
  else
    atlas_release_verify_row "Operation Ledger Replay" "fail" "packet_events=${packet_ledger_events:-missing} replay_events=${current_ledger_events:-missing} packet_sha=${packet_ledger_sha:-missing} replay_sha=${current_ledger_sha:-missing}"
  fi

  packet_archive_path="$(jq -r '.operation_trust_chain.artifacts.archive_packet // ""' "$packet_file")"
  current_archive_path="$(printf '%s\n' "$current_json" | jq -r '.artifacts.archive_packet // ""')"
  packet_archive_verification="$(jq -r '.operation_trust_chain.verification.archive_packet // ""' "$packet_file")"
  current_archive_verification="$(printf '%s\n' "$current_json" | jq -r '.verification.archive_packet // ""')"
  if [ "$packet_archive_path" = "$current_archive_path" ] &&
    [ "$packet_archive_verification" = "verified" ] &&
    [ "$current_archive_verification" = "verified" ]; then
    atlas_release_verify_row "Operation Archive Replay" "ok" "verification=verified packet=$current_archive_path"
  else
    atlas_release_verify_row "Operation Archive Replay" "fail" "packet_verification=${packet_archive_verification:-missing} replay_verification=${current_archive_verification:-missing} packet_path=${packet_archive_path:-missing} replay_path=${current_archive_path:-missing}"
  fi
}

atlas_release_verify_operation_trust_markdown() {
  local packet_file="$1"
  local operation_slug
  local packet_status
  local current_json
  local current_status
  local packet_ledger
  local packet_ledger_events
  local packet_ledger_sha
  local current_ledger_events
  local current_ledger_sha
  local packet_archive_path
  local current_archive_path
  local packet_archive_verification
  local current_archive_verification

  operation_slug="$(atlas_release_packet_bullet "$packet_file" "Operation ID")"
  packet_status="$(atlas_release_packet_bullet "$packet_file" "Trust chain status")"
  if [ -z "$operation_slug" ] && [ -z "$packet_status" ]; then
    atlas_release_verify_row "Operation Trust Chain" "ok" "not-recorded"
    return 0
  fi

  if [ -z "$operation_slug" ]; then
    atlas_release_verify_row "Operation Trust Chain" "fail" "operation=missing status=${packet_status:-missing}"
    return 0
  fi

  current_json="$(atlas_release_replay_operation_trust_json "$operation_slug" 2>/dev/null || true)"
  if [ -z "$current_json" ]; then
    atlas_release_verify_row "Operation Trust Chain" "fail" "operation=$operation_slug replay=missing"
    return 0
  fi

  current_status="$(printf '%s\n' "$current_json" | jq -r '.status // ""')"
  if [ "$packet_status" = "current" ] && [ "$current_status" = "current" ]; then
    atlas_release_verify_row "Operation Trust Chain" "ok" "status=current replay=current operation=$operation_slug"
  else
    atlas_release_verify_row "Operation Trust Chain" "fail" "packet_status=${packet_status:-missing} replay_status=${current_status:-missing} operation=$operation_slug"
  fi

  packet_ledger="$(atlas_release_packet_bullet "$packet_file" "Operation ledger")"
  packet_ledger_events="$(atlas_closeout_anchor_token "$packet_ledger" "events")"
  packet_ledger_sha="$(atlas_closeout_anchor_token "$packet_ledger" "sha256")"
  current_ledger_events="$(printf '%s\n' "$current_json" | jq -r '.ledger.events // ""')"
  current_ledger_sha="$(printf '%s\n' "$current_json" | jq -r '.ledger.sha256 // ""')"
  if [ -n "$packet_ledger_events" ] &&
    [ "$packet_ledger_events" = "$current_ledger_events" ] &&
    [ "$packet_ledger_sha" = "$current_ledger_sha" ]; then
    atlas_release_verify_row "Operation Ledger Replay" "ok" "events=$current_ledger_events sha256=$current_ledger_sha"
  else
    atlas_release_verify_row "Operation Ledger Replay" "fail" "packet_events=${packet_ledger_events:-missing} replay_events=${current_ledger_events:-missing} packet_sha=${packet_ledger_sha:-missing} replay_sha=${current_ledger_sha:-missing}"
  fi

  packet_archive_path="$(atlas_release_packet_bullet "$packet_file" "Archive packet")"
  current_archive_path="$(printf '%s\n' "$current_json" | jq -r '.artifacts.archive_packet // ""')"
  packet_archive_verification="$(atlas_release_packet_bullet "$packet_file" "Archive packet verification")"
  current_archive_verification="$(printf '%s\n' "$current_json" | jq -r '.verification.archive_packet // ""')"
  if [ "$packet_archive_path" = "$current_archive_path" ] &&
    [ "$packet_archive_verification" = "verified" ] &&
    [ "$current_archive_verification" = "verified" ]; then
    atlas_release_verify_row "Operation Archive Replay" "ok" "verification=verified packet=$current_archive_path"
  else
    atlas_release_verify_row "Operation Archive Replay" "fail" "packet_verification=${packet_archive_verification:-missing} replay_verification=${current_archive_verification:-missing} packet_path=${packet_archive_path:-missing} replay_path=${current_archive_path:-missing}"
  fi
}

atlas_release_verify_json_packet() {
  local packet_file="$1"
  local expected_commit="$2"
  local packet_commit
  local repo_state
  local sync_state
  local qa_status
  local readiness_overall
  local required_not_ready
  local note_path

  if jq -e '.schema_version == "atlas.release_trust.v1"' "$packet_file" >/dev/null 2>&1; then
    atlas_release_verify_row "Schema" "ok" "atlas.release_trust.v1"
  else
    atlas_release_verify_row "Schema" "fail" "expected=atlas.release_trust.v1"
  fi

  if jq -e '.metadata_only == true' "$packet_file" >/dev/null 2>&1; then
    atlas_release_verify_row "Metadata Only" "ok" "true"
  else
    atlas_release_verify_row "Metadata Only" "fail" "expected=true"
  fi

  packet_commit="$(jq -r '.commit // ""' "$packet_file")"
  if atlas_release_commit_matches "$packet_commit" "$expected_commit"; then
    atlas_release_verify_row "Commit" "ok" "$packet_commit"
  else
    atlas_release_verify_row "Commit" "fail" "expected=$expected_commit actual=${packet_commit:-missing}"
  fi

  repo_state="$(jq -r '.repository.state_before_packet // ""' "$packet_file")"
  if [ "$repo_state" = "clean" ]; then
    atlas_release_verify_row "Repository State" "ok" "$repo_state"
  else
    atlas_release_verify_row "Repository State" "fail" "expected=clean actual=${repo_state:-missing}"
  fi

  sync_state="$(jq -r '.repository.upstream_sync_before_packet // ""' "$packet_file")"
  if [ "$sync_state" = "synced" ]; then
    atlas_release_verify_row "Upstream Sync" "ok" "$sync_state"
  else
    atlas_release_verify_row "Upstream Sync" "fail" "expected=synced actual=${sync_state:-missing}"
  fi

  qa_status="$(jq -r '.qa.status // ""' "$packet_file")"
  if [ "$qa_status" = "pass" ]; then
    atlas_release_verify_row "QA Status" "ok" "$qa_status"
  else
    atlas_release_verify_row "QA Status" "fail" "expected=pass actual=${qa_status:-missing}"
  fi

  readiness_overall="$(jq -r '.readiness.overall // ""' "$packet_file")"
  required_not_ready="$(jq -r '.readiness.counts.required_not_ready // ""' "$packet_file")"
  if [ "$readiness_overall" = "ready" ] && [ "$required_not_ready" = "0" ]; then
    atlas_release_verify_row "V1 Readiness" "ok" "overall=ready required_not_ready=0"
  else
    atlas_release_verify_row "V1 Readiness" "fail" "overall=${readiness_overall:-missing} required_not_ready=${required_not_ready:-missing}"
  fi

  atlas_release_verify_operation_trust_json "$packet_file"

  while IFS= read -r note_path; do
    [ -n "$note_path" ] || continue
    note_path="$(atlas_release_display_path "$note_path")"
    if jq -e --arg note_path "$note_path" '.retention_notes | index($note_path) != null' "$packet_file" >/dev/null 2>&1; then
      atlas_release_verify_row "Retention Note" "ok" "$note_path"
    else
      atlas_release_verify_row "Retention Note" "fail" "missing $note_path"
    fi
  done <<<"$(atlas_release_retention_notes_for_commit "$expected_commit")"

  if jq -e '(.known_limitations // []) | length > 0 and any(.[]; .pillar == "Core CLI" and (.limitation // "" | length > 0))' "$packet_file" >/dev/null 2>&1; then
    atlas_release_verify_row "Known Limitations" "ok" "present"
  else
    atlas_release_verify_row "Known Limitations" "fail" "missing or incomplete"
  fi

  ui_rule
  if [ "$atlas_release_verify_failures" -eq 0 ]; then
    ui_ok "release trust packet verified"
  else
    ui_alert "release trust packet verification failed"
  fi

  return "$atlas_release_verify_failures"
}

atlas_release_verify_packet() {
  local packet_file="$1"
  local expected_commit="$2"
  local packet_commit
  local repo_state
  local sync_state
  local qa_status
  local readiness_json
  local readiness_overall=""
  local required_not_ready=""
  local note_path

  [ -f "$packet_file" ] || fail "release trust packet is not a file: $packet_file"
  [ -n "$expected_commit" ] || expected_commit="$(atlas_release_commit)"
  atlas_release_verify_failures=0

  ui_heading "Atlas Release Packet Verification"
  ui_rule
  ui_kv "Packet" "$packet_file"

  if jq -e type "$packet_file" >/dev/null 2>&1; then
    atlas_release_verify_json_packet "$packet_file" "$expected_commit"
    return "$?"
  fi

  if grep -q '^# Atlas Release Trust Packet$' "$packet_file"; then
    atlas_release_verify_row "Header" "ok" "release trust packet"
  else
    atlas_release_verify_row "Header" "fail" "missing release trust packet header"
  fi

  if grep -q 'No raw runtime artifacts, target secrets, session contents, packet captures, or evidence bodies are included' "$packet_file"; then
    atlas_release_verify_row "Metadata Only" "ok" "guardrail present"
  else
    atlas_release_verify_row "Metadata Only" "fail" "metadata-only guardrail missing"
  fi

  packet_commit="$(atlas_release_packet_field "$packet_file" "Commit")"
  if atlas_release_commit_matches "$packet_commit" "$expected_commit"; then
    atlas_release_verify_row "Commit" "ok" "$packet_commit"
  else
    atlas_release_verify_row "Commit" "fail" "expected=$expected_commit actual=${packet_commit:-missing}"
  fi

  repo_state="$(atlas_release_packet_field "$packet_file" "Repository state before packet")"
  if [ "$repo_state" = "clean" ]; then
    atlas_release_verify_row "Repository State" "ok" "$repo_state"
  else
    atlas_release_verify_row "Repository State" "fail" "expected=clean actual=${repo_state:-missing}"
  fi

  sync_state="$(atlas_release_packet_field "$packet_file" "Upstream sync before packet")"
  if [ "$sync_state" = "synced" ]; then
    atlas_release_verify_row "Upstream Sync" "ok" "$sync_state"
  else
    atlas_release_verify_row "Upstream Sync" "fail" "expected=synced actual=${sync_state:-missing}"
  fi

  qa_status="$(atlas_release_packet_bullet "$packet_file" "QA status")"
  if [ "$qa_status" = "pass" ]; then
    atlas_release_verify_row "QA Status" "ok" "$qa_status"
  else
    atlas_release_verify_row "QA Status" "fail" "expected=pass actual=${qa_status:-missing}"
  fi

  readiness_json="$(atlas_release_packet_json "$packet_file")"
  if [ -n "$readiness_json" ] && printf '%s\n' "$readiness_json" | jq -e . >/dev/null 2>&1; then
    readiness_overall="$(printf '%s\n' "$readiness_json" | jq -r '.overall // ""')"
    required_not_ready="$(printf '%s\n' "$readiness_json" | jq -r '.counts.required_not_ready // ""')"
    if [ "$readiness_overall" = "ready" ] && [ "$required_not_ready" = "0" ]; then
      atlas_release_verify_row "V1 Readiness" "ok" "overall=ready required_not_ready=0"
    else
      atlas_release_verify_row "V1 Readiness" "fail" "overall=${readiness_overall:-missing} required_not_ready=${required_not_ready:-missing}"
    fi
  else
    atlas_release_verify_row "V1 Readiness" "fail" "missing or invalid JSON"
  fi

  atlas_release_verify_operation_trust_markdown "$packet_file"

  while IFS= read -r note_path; do
    [ -n "$note_path" ] || continue
    note_path="$(atlas_release_display_path "$note_path")"
    if grep -q -- "\`$note_path\`" "$packet_file"; then
      atlas_release_verify_row "Retention Note" "ok" "$note_path"
    else
      atlas_release_verify_row "Retention Note" "fail" "missing $note_path"
    fi
  done <<<"$(atlas_release_retention_notes_for_commit "$expected_commit")"

  if grep -q '^## Known Limitations$' "$packet_file" && grep -q 'Core CLI:' "$packet_file"; then
    atlas_release_verify_row "Known Limitations" "ok" "present"
  else
    atlas_release_verify_row "Known Limitations" "fail" "missing or incomplete"
  fi

  ui_rule
  if [ "$atlas_release_verify_failures" -eq 0 ]; then
    ui_ok "release trust packet verified"
  else
    ui_alert "release trust packet verification failed"
  fi

  return "$atlas_release_verify_failures"
}

cmd_release_packet() {
  local packet_name=""
  local packet_slug
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local packet_file
  local qa_status="not-recorded"
  local qa_command="nix-shell --run './bin/dev-qa'"
  local qa_note="QA was not recorded by this packet command."
  local allow_dirty=0
  local allow_unsynced=0
  local allow_not_ready=0
  local json=0
  local operation_name=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    --qa-status)
      [ "$#" -ge 2 ] || fail "release packet [packet-name] [--json] [--qa-status status] [--qa-command command] [--qa-note text]"
      qa_status="$2"
      shift 2
      ;;
    --qa-command)
      [ "$#" -ge 2 ] || fail "release packet [packet-name] [--json] [--qa-status status] [--qa-command command] [--qa-note text]"
      qa_command="$2"
      shift 2
      ;;
    --qa-note)
      [ "$#" -ge 2 ] || fail "release packet [packet-name] [--json] [--qa-status status] [--qa-command command] [--qa-note text]"
      qa_note="$2"
      shift 2
      ;;
    --operation)
      [ "$#" -ge 2 ] || fail "release packet [packet-name] [--json] [--operation name] [--qa-status status] [--qa-command command] [--qa-note text]"
      operation_name="$2"
      shift 2
      ;;
    --allow-dirty)
      allow_dirty=1
      shift
      ;;
    --allow-unsynced)
      allow_unsynced=1
      shift
      ;;
    --allow-not-ready)
      allow_not_ready=1
      shift
      ;;
    --force)
      allow_dirty=1
      allow_unsynced=1
      allow_not_ready=1
      shift
      ;;
    -*)
      fail "unknown release packet option: $1"
      ;;
    *)
      if [ -n "$packet_name" ]; then
        fail "release packet [packet-name] [--json] [--operation name] [--qa-status status] [--qa-command command] [--qa-note text]"
      fi
      packet_name="$1"
      shift
      ;;
    esac
  done

  if [ -z "$packet_name" ]; then
    packet_name="atlas-release-$(atlas_release_commit)"
  fi

  packet_slug="$(slugify "$packet_name")"
  [ -n "$packet_slug" ] || fail "release packet name produced an empty slug"

  if [ -n "$operation_name" ]; then
    load_atlas_operation "$operation_name"
  fi

  mkdir -p "$packet_dir"
  if [ "$json" = "1" ]; then
    packet_file="$packet_dir/$packet_slug.json"
    atlas_release_write_json_packet "$packet_file" "$packet_name" "$qa_status" "$qa_command" "$qa_note" "$allow_dirty" "$allow_unsynced" "$allow_not_ready"
  else
    packet_file="$packet_dir/$packet_slug.md"
    atlas_release_write_packet "$packet_file" "$packet_name" "$qa_status" "$qa_command" "$qa_note" "$allow_dirty" "$allow_unsynced" "$allow_not_ready"
  fi
  chmod 600 "$packet_file" 2>/dev/null || true

  ui_ok "release trust packet written"
  printf 'release_packet: %s\n' "$packet_file"
  if [ "$json" = "1" ]; then
    printf 'release_packet_json: %s\n' "$packet_file"
  fi
}

cmd_release_verify() {
  local packet_arg=""
  local expected_commit=""
  local packet_file

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --commit)
      [ "$#" -ge 2 ] || fail "release verify [packet] [--commit sha]"
      expected_commit="$2"
      shift 2
      ;;
    -*)
      fail "unknown release verify option: $1"
      ;;
    *)
      if [ -n "$packet_arg" ]; then
        fail "release verify [packet] [--commit sha]"
      fi
      packet_arg="$1"
      shift
      ;;
    esac
  done

  packet_file="$(atlas_release_resolve_packet "$packet_arg")"
  atlas_release_verify_packet "$packet_file" "$expected_commit"
}
