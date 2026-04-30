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
  find "$packet_dir" -maxdepth 1 -type f \( -name '*.md' -o -name '*.json' \) ! -name '*.provenance.json' ! -name '*.manifest.json' ! -name '*.slsa.json' 2>/dev/null |
    sort -V |
    tail -n 1
}

atlas_release_latest_manifest() {
  local packet_dir="$LAB_DOCS_DIR/retention/releases"

  [ -d "$packet_dir" ] || return 0
  find "$packet_dir" -maxdepth 1 -type f -name '*.manifest.json' 2>/dev/null |
    sort -V |
    tail -n 1
}

atlas_release_latest_provenance_packet() {
  local packet_dir="$LAB_DOCS_DIR/retention/releases"

  [ -d "$packet_dir" ] || return 0
  find "$packet_dir" -maxdepth 1 -type f -name '*.provenance.json' 2>/dev/null |
    sort -V |
    tail -n 1
}

atlas_release_latest_slsa_reference() {
  local packet_dir="$LAB_DOCS_DIR/retention/releases"

  [ -d "$packet_dir" ] || return 0
  find "$packet_dir" -maxdepth 1 -type f -name '*.slsa.json' 2>/dev/null |
    sort -V |
    tail -n 1
}

atlas_release_resolve_slsa_reference() {
  local slsa_arg="$1"
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local candidate
  local slsa_base
  local slsa_slug

  if [ -z "$slsa_arg" ]; then
    candidate="$(atlas_release_latest_slsa_reference)"
    [ -n "$candidate" ] || fail "no SLSA provenance reference found"
    printf '%s\n' "$candidate"
    return 0
  fi

  if [ -f "$slsa_arg" ]; then
    readlink -f "$slsa_arg"
    return 0
  fi

  candidate="$(atlas_release_resolve_repo_file "$slsa_arg" 2>/dev/null || true)"
  if [ -n "$candidate" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  candidate="$packet_dir/$slsa_arg"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  slsa_base="${slsa_arg%.slsa.json}"
  slsa_base="${slsa_base%.json}"
  slsa_slug="$(slugify "$slsa_base")"
  candidate="$packet_dir/$slsa_slug.slsa.json"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  fail "unknown SLSA provenance reference: $slsa_arg"
}

atlas_release_latest_dry_run_note() {
  local production_dir="$LAB_DOCS_DIR/retention/production"

  [ -d "$production_dir" ] || return 0
  find "$production_dir" -maxdepth 1 -type f -name 'PRODUCTION_DRY_RUN_*.md' 2>/dev/null |
    sort -V |
    tail -n 1
}

atlas_release_find_packet_by_commit() {
  local expected_commit="$1"
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local candidate
  local packet_commit
  local packet_commit_full

  [ -n "$expected_commit" ] || return 1
  [ -d "$packet_dir" ] || return 1

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    packet_commit="$(atlas_release_packet_commit "$candidate")"
    [ -n "$packet_commit" ] || continue
    packet_commit_full="$(atlas_release_full_commit "$packet_commit" 2>/dev/null || true)"
    if [ "$packet_commit" = "$expected_commit" ] || [ "$packet_commit_full" = "$expected_commit" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find "$packet_dir" -maxdepth 1 -type f \( -name '*.md' -o -name '*.json' \) ! -name '*.provenance.json' ! -name '*.manifest.json' ! -name '*.slsa.json' 2>/dev/null | sort -Vr)

  return 1
}

atlas_release_find_provenance_by_commit() {
  local expected_commit="$1"
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local candidate
  local provenance_commit
  local provenance_commit_full

  [ -n "$expected_commit" ] || return 1
  [ -d "$packet_dir" ] || return 1

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    provenance_commit="$(jq -r '.commit // ""' "$candidate" 2>/dev/null || true)"
    [ -n "$provenance_commit" ] || continue
    provenance_commit_full="$(atlas_release_full_commit "$provenance_commit" 2>/dev/null || true)"
    if [ "$provenance_commit" = "$expected_commit" ] || [ "$provenance_commit_full" = "$expected_commit" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find "$packet_dir" -maxdepth 1 -type f -name '*.provenance.json' 2>/dev/null | sort -Vr)

  return 1
}

atlas_release_find_dry_run_note_by_commit() {
  local expected_commit="$1"
  local production_dir="$LAB_DOCS_DIR/retention/production"
  local candidate

  [ -n "$expected_commit" ] || return 1
  [ -d "$production_dir" ] || return 1

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    if grep -q "^Commit: $expected_commit$" "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find "$production_dir" -maxdepth 1 -type f -name 'PRODUCTION_DRY_RUN_*.md' 2>/dev/null | sort -Vr)

  return 1
}

atlas_release_latest_milestone_note() {
  local notes_dir="$LAB_DOCS_DIR/retention/milestones"

  [ -d "$notes_dir" ] || return 0
  find "$notes_dir" -maxdepth 1 -type f -name 'MILESTONE_*.md' | sort -V | tail -n 1
}

atlas_release_resolve_repo_file() {
  local path="$1"
  local candidate
  local resolved
  local root

  [ -n "$path" ] || return 1
  case "$path" in
  /*)
    candidate="$path"
    ;;
  *)
    candidate="$LAB_ROOT/$path"
    ;;
  esac

  [ -f "$candidate" ] || return 1
  resolved="$(readlink -f "$candidate" 2>/dev/null || true)"
  root="$(readlink -f "$LAB_ROOT" 2>/dev/null || true)"
  [ -n "$resolved" ] || return 1
  [ -n "$root" ] || return 1
  case "$resolved" in
  "$root"/*)
    printf '%s\n' "$resolved"
    ;;
  *)
    return 1
    ;;
  esac
}

atlas_release_file_sha256() {
  local path="$1"

  sha256sum "$path" | awk '{ print $1 }'
}

atlas_release_full_commit() {
  local commit="$1"

  [ -n "$commit" ] || return 1
  git -C "$LAB_ROOT" rev-parse "$commit^{commit}" 2>/dev/null || return 1
}

atlas_release_json_forbidden_content_paths() {
  local json_file="$1"

  jq -r '
    def pathstr($p): $p | map(tostring) | join(".");
    def ignored($p): (($p[0] // "") == "metadata_boundary") or (($p[0] // "") == "known_limitations");
    def bad_key: test("^(raw_runtime_artifacts|target_secrets|session_contents|packet_captures|credential_material|private_keys|tokens|password|passwd|api_key|secret|authorization|cookie|session)$"; "i");
    def bad_value: test("password=|passwd=|api_key=|secret=|token=|authorization:|bearer[[:space:]]|set-cookie:|BEGIN RSA|BEGIN OPENSSH|session=|cookie="; "i");
    (
      [
        paths as $p
        | select(($p | length) > 0 and (ignored($p) | not))
        | select((($p[-1] | type) == "string") and (($p[-1] | tostring) | bad_key))
        | pathstr($p)
      ] +
      [
        paths(scalars) as $p
        | select(ignored($p) | not)
        | select(((getpath($p) | type) == "string") and (getpath($p) | bad_value))
        | pathstr($p)
      ]
    ) | unique | .[]
  ' "$json_file" 2>/dev/null || true
}

atlas_release_slsa_reference_valid() {
  local slsa_file="$1"
  local expected_commit="$2"
  local source_commit
  local artifact_sha
  local subject_digest
  local workflow_path

  [ -n "$slsa_file" ] || return 1
  [ -f "$slsa_file" ] || return 1
  [ -n "$expected_commit" ] || return 1

  jq -e '
    .schema_version == "atlas.slsa_provenance.v1" and
    .metadata_only == true and
    .no_certification_overclaim == true and
    ((.artifact.path // "") | type == "string" and length > 0) and
    ((.artifact.sha256 // "") | test("^[a-f0-9]{64}$")) and
    ((.source.repository // "") | type == "string" and length > 0) and
    ((.source.commit // "") | type == "string" and length > 0) and
    ((.source.ref // "") | type == "string" and length > 0) and
    ((.workflow.name // "") | type == "string" and length > 0) and
    ((.workflow.path // "") | type == "string" and length > 0) and
    ((.workflow.run_id // "") | tostring | length > 0) and
    ((.workflow.run_url // "") | type == "string" and startswith("https://github.com/")) and
    ((.attestation.subject_digest // "") | type == "string" and length > 0) and
    ((.attestation.verification_command // "") | type == "string" and contains("gh attestation verify")) and
    .attestation.verification_status == "verified" and
    (((.known_limitations // []) | type) == "array" and ((.known_limitations // []) | length > 0))
  ' "$slsa_file" >/dev/null 2>&1 || return 1

  [ -z "$(atlas_release_json_forbidden_content_paths "$slsa_file")" ] || return 1

  source_commit="$(jq -r '.source.commit // ""' "$slsa_file")"
  atlas_release_commit_matches "$source_commit" "$expected_commit" || return 1

  artifact_sha="$(jq -r '.artifact.sha256 // ""' "$slsa_file")"
  subject_digest="$(jq -r '.attestation.subject_digest // ""' "$slsa_file")"
  subject_digest="${subject_digest#sha256:}"
  [ "$artifact_sha" = "$subject_digest" ] || return 1

  workflow_path="$(jq -r '.workflow.path // ""' "$slsa_file")"
  atlas_release_resolve_repo_file "$workflow_path" >/dev/null 2>&1 || return 1
}

atlas_release_slsa_verify_failures=0

atlas_release_slsa_verify_row() {
  local label="$1"
  local status="$2"
  local detail="$3"

  ui_kv "$label" "$status $detail"
  [ "$status" = "ok" ] || atlas_release_slsa_verify_failures=$((atlas_release_slsa_verify_failures + 1))
}

atlas_release_slsa_verify_reference() {
  local slsa_file="$1"
  local expected_commit="$2"
  local artifact_file="${3:-}"
  local online_verify="${4:-0}"
  local repository_override="${5:-}"
  local display_path
  local source_commit
  local source_repository
  local source_ref
  local artifact_path
  local artifact_sha
  local local_artifact_sha
  local subject_digest
  local workflow_path
  local workflow_run_url
  local verification_command
  local verification_status
  local known_count
  local forbidden
  local online_repository
  local gh_output
  local gh_detail

  [ -f "$slsa_file" ] || fail "SLSA provenance reference is not a file: $slsa_file"
  intel_require_jq

  display_path="$(atlas_release_display_path "$slsa_file")"
  source_commit="$(jq -r '.source.commit // ""' "$slsa_file" 2>/dev/null || true)"
  [ -n "$expected_commit" ] || expected_commit="$source_commit"
  [ -n "$expected_commit" ] || fail "SLSA provenance reference is missing source.commit: $display_path"

  atlas_release_slsa_verify_failures=0

  ui_heading "Atlas SLSA Provenance Reference Verification"
  ui_rule
  ui_kv "Reference" "$display_path"
  ui_kv "Commit" "$expected_commit"

  if jq -e '.schema_version == "atlas.slsa_provenance.v1"' "$slsa_file" >/dev/null 2>&1; then
    atlas_release_slsa_verify_row "Schema" "ok" "atlas.slsa_provenance.v1"
  else
    atlas_release_slsa_verify_row "Schema" "fail" "expected=atlas.slsa_provenance.v1"
  fi

  if jq -e '.metadata_only == true and .no_certification_overclaim == true' "$slsa_file" >/dev/null 2>&1; then
    atlas_release_slsa_verify_row "Metadata Boundary" "ok" "metadata_only=true no_certification_overclaim=true"
  else
    atlas_release_slsa_verify_row "Metadata Boundary" "fail" "expected metadata_only=true no_certification_overclaim=true"
  fi

  forbidden="$(atlas_release_json_forbidden_content_paths "$slsa_file")"
  if [ -z "$forbidden" ]; then
    atlas_release_slsa_verify_row "Forbidden Content" "ok" "no forbidden raw-content markers"
  else
    atlas_release_slsa_verify_row "Forbidden Content" "fail" "$(printf '%s' "$forbidden" | paste -sd, -)"
  fi

  source_repository="$(jq -r '.source.repository // ""' "$slsa_file" 2>/dev/null || true)"
  source_ref="$(jq -r '.source.ref // ""' "$slsa_file" 2>/dev/null || true)"
  if [ -n "$source_repository" ] && [ -n "$source_ref" ]; then
    atlas_release_slsa_verify_row "Source Identity" "ok" "repository=$source_repository ref=$source_ref"
  else
    atlas_release_slsa_verify_row "Source Identity" "fail" "repository=${source_repository:-missing} ref=${source_ref:-missing}"
  fi

  if atlas_release_commit_matches "$source_commit" "$expected_commit"; then
    atlas_release_slsa_verify_row "Source Commit" "ok" "$source_commit"
  else
    atlas_release_slsa_verify_row "Source Commit" "fail" "expected=$expected_commit actual=${source_commit:-missing}"
  fi

  artifact_path="$(jq -r '.artifact.path // ""' "$slsa_file" 2>/dev/null || true)"
  artifact_sha="$(jq -r '.artifact.sha256 // ""' "$slsa_file" 2>/dev/null || true)"
  subject_digest="$(jq -r '.attestation.subject_digest // ""' "$slsa_file" 2>/dev/null || true)"
  subject_digest="${subject_digest#sha256:}"
  if [ -n "$artifact_path" ] &&
    [[ "$artifact_sha" =~ ^[a-f0-9]{64}$ ]] &&
    [ "$artifact_sha" = "$subject_digest" ]; then
    atlas_release_slsa_verify_row "Artifact Digest" "ok" "path=$artifact_path sha256=$artifact_sha"
  else
    atlas_release_slsa_verify_row "Artifact Digest" "fail" "path=${artifact_path:-missing} artifact_sha=${artifact_sha:-missing} subject_sha=${subject_digest:-missing}"
  fi

  workflow_path="$(jq -r '.workflow.path // ""' "$slsa_file" 2>/dev/null || true)"
  workflow_run_url="$(jq -r '.workflow.run_url // ""' "$slsa_file" 2>/dev/null || true)"
  if atlas_release_resolve_repo_file "$workflow_path" >/dev/null 2>&1; then
    atlas_release_slsa_verify_row "Workflow Path" "ok" "$workflow_path"
  else
    atlas_release_slsa_verify_row "Workflow Path" "fail" "missing path=${workflow_path:-missing}"
  fi
  if [ -n "$workflow_run_url" ] && [[ "$workflow_run_url" == https://github.com/* ]]; then
    atlas_release_slsa_verify_row "Workflow Run" "ok" "$workflow_run_url"
  else
    atlas_release_slsa_verify_row "Workflow Run" "fail" "expected GitHub run URL actual=${workflow_run_url:-missing}"
  fi

  verification_command="$(jq -r '.attestation.verification_command // ""' "$slsa_file" 2>/dev/null || true)"
  verification_status="$(jq -r '.attestation.verification_status // ""' "$slsa_file" 2>/dev/null || true)"
  if [ "$verification_status" = "verified" ] && [[ "$verification_command" == *"gh attestation verify"* ]]; then
    atlas_release_slsa_verify_row "Attestation Verification" "ok" "$verification_status"
  else
    atlas_release_slsa_verify_row "Attestation Verification" "fail" "status=${verification_status:-missing}"
  fi

  known_count="$(jq -r '((.known_limitations // []) | length)' "$slsa_file" 2>/dev/null || printf '0')"
  if [ "$known_count" -gt 0 ] 2>/dev/null; then
    atlas_release_slsa_verify_row "Known Limitations" "ok" "count=$known_count"
  else
    atlas_release_slsa_verify_row "Known Limitations" "fail" "missing"
  fi

  if [ -n "$artifact_file" ]; then
    if [ ! -f "$artifact_file" ]; then
      atlas_release_slsa_verify_row "Local Artifact" "fail" "missing path=$artifact_file"
    else
      local_artifact_sha="$(atlas_release_file_sha256 "$artifact_file")"
      if [ "$local_artifact_sha" = "$artifact_sha" ]; then
        atlas_release_slsa_verify_row "Local Artifact" "ok" "sha256=$local_artifact_sha path=$artifact_file"
      else
        atlas_release_slsa_verify_row "Local Artifact" "fail" "expected_sha=$artifact_sha actual_sha=$local_artifact_sha path=$artifact_file"
      fi
    fi
  fi

  if [ "$online_verify" = "1" ]; then
    if [ -z "$artifact_file" ]; then
      atlas_release_slsa_verify_row "Online Attestation" "fail" "--online requires --artifact <path>"
    elif [ ! -f "$artifact_file" ]; then
      atlas_release_slsa_verify_row "Online Attestation" "fail" "artifact missing path=$artifact_file"
    elif ! command -v gh >/dev/null 2>&1; then
      atlas_release_slsa_verify_row "Online Attestation" "fail" "missing gh"
    else
      online_repository="${repository_override:-$source_repository}"
      if [ -z "$online_repository" ]; then
        atlas_release_slsa_verify_row "Online Attestation" "fail" "missing source.repository"
      else
        gh_output="$(mktemp)"
        if gh attestation verify "$artifact_file" --repo "$online_repository" >"$gh_output" 2>&1; then
          atlas_release_slsa_verify_row "Online Attestation" "ok" "gh attestation verify repo=$online_repository"
        else
          gh_detail="$(head -n 1 "$gh_output" 2>/dev/null || true)"
          atlas_release_slsa_verify_row "Online Attestation" "fail" "repo=$online_repository ${gh_detail:-gh attestation verify failed}"
        fi
        rm -f "$gh_output"
      fi
    fi
  fi

  if atlas_release_slsa_reference_valid "$slsa_file" "$expected_commit"; then
    atlas_release_slsa_verify_row "Reference Contract" "ok" "verified"
  else
    atlas_release_slsa_verify_row "Reference Contract" "fail" "verification failed"
  fi

  if [ "$atlas_release_slsa_verify_failures" -gt 0 ]; then
    fail "SLSA provenance reference verification failed: $display_path"
  fi

  ui_ok "SLSA provenance reference verified"
  printf 'slsa_reference: %s\n' "$slsa_file"
}

atlas_release_manifest_verify_failures=0

atlas_release_manifest_verify_row() {
  local label="$1"
  local status="$2"
  local detail="$3"

  ui_kv "$label" "$status $detail"
  [ "$status" = "ok" ] || atlas_release_manifest_verify_failures=$((atlas_release_manifest_verify_failures + 1))
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

atlas_release_resolve_manifest() {
  local manifest_arg="$1"
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local candidate
  local manifest_base
  local manifest_slug

  if [ -z "$manifest_arg" ]; then
    candidate="$(atlas_release_latest_manifest)"
    [ -n "$candidate" ] || fail "no release artifact manifest found"
    printf '%s\n' "$candidate"
    return 0
  fi

  if [ -f "$manifest_arg" ]; then
    readlink -f "$manifest_arg"
    return 0
  fi

  candidate="$packet_dir/$manifest_arg"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  manifest_base="${manifest_arg%.manifest.json}"
  manifest_base="${manifest_base%.json}"
  manifest_slug="$(slugify "$manifest_base")"
  candidate="$packet_dir/$manifest_slug.manifest.json"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  fail "unknown release artifact manifest: $manifest_arg"
}

atlas_release_packet_commit() {
  local packet_file="$1"

  case "$packet_file" in
  *.json)
    jq -r 'select(type == "object") | .commit // empty' "$packet_file" 2>/dev/null || true
    ;;
  *)
    atlas_release_packet_field "$packet_file" "Commit"
    ;;
  esac
}

atlas_release_manifest_write() {
  local file="$1"
  local manifest_name="$2"
  local packet_file="$3"
  local provenance_file="$4"
  local dry_run_note="$5"
  local milestone_note="$6"
  local tag_name="$7"
  local slsa_file="${8:-}"
  local generated
  local packet_rel
  local provenance_rel
  local dry_run_rel
  local milestone_rel=""
  local slsa_present=0
  local slsa_rel=""
  local slsa_sha=""
  local slsa_artifact_path=""
  local slsa_artifact_sha=""
  local slsa_source_repository=""
  local slsa_source_commit=""
  local slsa_source_ref=""
  local slsa_workflow_name=""
  local slsa_workflow_path=""
  local slsa_workflow_run_id=""
  local slsa_workflow_run_url=""
  local slsa_attestation_subject_digest=""
  local slsa_attestation_url=""
  local slsa_attestation_rekor_log_url=""
  local slsa_attestation_verification_command=""
  local public_key_path
  local public_key_file
  local public_key_rel
  local packet_sha
  local provenance_sha
  local dry_run_sha
  local milestone_sha=""
  local public_key_sha
  local release_commit
  local release_commit_full
  local retention_commit
  local branch
  local clean_state
  local sync_state
  local tag_target
  local tag_object

  intel_require_jq
  generated="$(timestamp)"
  packet_rel="$(atlas_release_display_path "$packet_file")"
  provenance_rel="$(atlas_release_display_path "$provenance_file")"
  dry_run_rel="$(atlas_release_display_path "$dry_run_note")"
  if [ -n "$milestone_note" ]; then
    milestone_rel="$(atlas_release_display_path "$milestone_note")"
    milestone_sha="$(atlas_release_file_sha256 "$milestone_note")"
  fi

  release_commit="$(jq -r '.commit // ""' "$provenance_file")"
  [ -n "$release_commit" ] || release_commit="$(atlas_release_packet_commit "$packet_file")"
  release_commit_full="$(atlas_release_full_commit "$release_commit")" || fail "release manifest could not resolve release commit: $release_commit"
  retention_commit="$(git -C "$LAB_ROOT" rev-parse HEAD 2>/dev/null || atlas_release_commit)"
  branch="$(atlas_release_branch)"
  clean_state="$(atlas_release_clean_state)"
  sync_state="$(atlas_release_sync_state)"

  packet_sha="$(atlas_release_file_sha256 "$packet_file")"
  provenance_sha="$(atlas_release_file_sha256 "$provenance_file")"
  dry_run_sha="$(atlas_release_file_sha256 "$dry_run_note")"

  public_key_path="$(jq -r '.signed_tag.public_key_path // ""' "$provenance_file")"
  public_key_file="$(atlas_release_resolve_repo_file "$public_key_path")" || fail "release manifest could not resolve signing public key: $public_key_path"
  public_key_rel="$(atlas_release_display_path "$public_key_file")"
  public_key_sha="$(atlas_release_file_sha256 "$public_key_file")"

  [ -n "$tag_name" ] || tag_name="$(jq -r '.signed_tag.name // ""' "$provenance_file")"
  [ -n "$tag_name" ] || fail "release manifest requires a signed tag name"
  tag_target="$(git -C "$LAB_ROOT" rev-parse "$tag_name^{}" 2>/dev/null || true)"
  tag_object="$(git -C "$LAB_ROOT" rev-parse "$tag_name^{tag}" 2>/dev/null || true)"
  [ -n "$tag_target" ] || fail "release manifest could not resolve signed tag target: $tag_name"
  [ -n "$tag_object" ] || fail "release manifest could not resolve signed tag object: $tag_name"

  atlas_release_verify_packet "$packet_file" "$release_commit_full" >/dev/null 2>&1 ||
    fail "release manifest requires a verifiable release packet: $packet_rel"
  atlas_production_release_provenance_valid "$provenance_file" "$release_commit_full" ||
    fail "release manifest requires verifiable signed provenance: $provenance_rel"
  atlas_production_dry_run_note_valid "$dry_run_note" "$release_commit_full" ||
    fail "release manifest requires a valid production dry-run note: $dry_run_rel"
  atlas_production_verify_signed_tag "$tag_name" "$public_key_file" ||
    fail "release manifest requires signed tag verification with retained public key: $tag_name"

  if [ -n "$slsa_file" ]; then
    atlas_release_slsa_reference_valid "$slsa_file" "$release_commit_full" ||
      fail "release manifest requires a verified SLSA provenance reference matching release commit: $(atlas_release_display_path "$slsa_file")"
    slsa_present=1
    slsa_rel="$(atlas_release_display_path "$slsa_file")"
    slsa_sha="$(atlas_release_file_sha256 "$slsa_file")"
    slsa_artifact_path="$(jq -r '.artifact.path // ""' "$slsa_file")"
    slsa_artifact_sha="$(jq -r '.artifact.sha256 // ""' "$slsa_file")"
    slsa_source_repository="$(jq -r '.source.repository // ""' "$slsa_file")"
    slsa_source_commit="$(jq -r '.source.commit // ""' "$slsa_file")"
    slsa_source_ref="$(jq -r '.source.ref // ""' "$slsa_file")"
    slsa_workflow_name="$(jq -r '.workflow.name // ""' "$slsa_file")"
    slsa_workflow_path="$(jq -r '.workflow.path // ""' "$slsa_file")"
    slsa_workflow_run_id="$(jq -r '.workflow.run_id // ""' "$slsa_file")"
    slsa_workflow_run_url="$(jq -r '.workflow.run_url // ""' "$slsa_file")"
    slsa_attestation_subject_digest="$(jq -r '.attestation.subject_digest // ""' "$slsa_file")"
    slsa_attestation_url="$(jq -r '.attestation.url // ""' "$slsa_file")"
    slsa_attestation_rekor_log_url="$(jq -r '.attestation.rekor_log_url // ""' "$slsa_file")"
    slsa_attestation_verification_command="$(jq -r '.attestation.verification_command // ""' "$slsa_file")"
  fi

  jq -n \
    --arg schema_version "atlas.release_artifact_manifest.v1" \
    --arg generated "$generated" \
    --arg manifest "$manifest_name" \
    --arg release_commit "$release_commit_full" \
    --arg retention_commit "$retention_commit" \
    --arg branch "${branch:-unknown}" \
    --arg clean_state "$clean_state" \
    --arg sync_state "$sync_state" \
    --arg packet_path "$packet_rel" \
    --arg packet_sha "$packet_sha" \
    --arg provenance_path "$provenance_rel" \
    --arg provenance_sha "$provenance_sha" \
    --arg dry_run_path "$dry_run_rel" \
    --arg dry_run_sha "$dry_run_sha" \
    --arg milestone_path "$milestone_rel" \
    --arg milestone_sha "$milestone_sha" \
    --arg public_key_path "$public_key_rel" \
    --arg public_key_sha "$public_key_sha" \
    --arg tag_name "$tag_name" \
    --arg tag_target "$tag_target" \
    --arg tag_object "$tag_object" \
    --arg slsa_present "$slsa_present" \
    --arg slsa_path "$slsa_rel" \
    --arg slsa_sha "$slsa_sha" \
    --arg slsa_artifact_path "$slsa_artifact_path" \
    --arg slsa_artifact_sha "$slsa_artifact_sha" \
    --arg slsa_source_repository "$slsa_source_repository" \
    --arg slsa_source_commit "$slsa_source_commit" \
    --arg slsa_source_ref "$slsa_source_ref" \
    --arg slsa_workflow_name "$slsa_workflow_name" \
    --arg slsa_workflow_path "$slsa_workflow_path" \
    --arg slsa_workflow_run_id "$slsa_workflow_run_id" \
    --arg slsa_workflow_run_url "$slsa_workflow_run_url" \
    --arg slsa_attestation_subject_digest "$slsa_attestation_subject_digest" \
    --arg slsa_attestation_url "$slsa_attestation_url" \
    --arg slsa_attestation_rekor_log_url "$slsa_attestation_rekor_log_url" \
    --arg slsa_attestation_verification_command "$slsa_attestation_verification_command" '
      {
        schema_version: $schema_version,
        generated: $generated,
        manifest: $manifest,
        metadata_only: true,
        raw_artifacts_embedded: false,
        release: {
          commit: $release_commit,
          retained_by_commit: $retention_commit,
          branch_at_manifest: $branch
        },
        repository: {
          state_before_manifest: $clean_state,
          upstream_sync_before_manifest: $sync_state
        },
        signed_tag: {
          name: $tag_name,
          target: $tag_target,
          tag_object: $tag_object,
          verification: "verified"
        },
        release_packet: {
          path: $packet_path,
          sha256: $packet_sha,
          verified: true
        },
        provenance: {
          path: $provenance_path,
          sha256: $provenance_sha,
          verified: true
        },
        production_dry_run: {
          path: $dry_run_path,
          sha256: $dry_run_sha,
          verified: true
        },
        signing_public_key: {
          path: $public_key_path,
          sha256: $public_key_sha,
          verified: true
        },
        slsa_provenance: (
          if $slsa_present == "1" then {
            path: $slsa_path,
            sha256: $slsa_sha,
            schema_version: "atlas.slsa_provenance.v1",
            verified: true,
            artifact: {
              path: $slsa_artifact_path,
              sha256: $slsa_artifact_sha
            },
            source: {
              repository: $slsa_source_repository,
              commit: $slsa_source_commit,
              ref: $slsa_source_ref
            },
            workflow: {
              name: $slsa_workflow_name,
              path: $slsa_workflow_path,
              run_id: $slsa_workflow_run_id,
              run_url: $slsa_workflow_run_url
            },
            attestation: {
              subject_digest: $slsa_attestation_subject_digest,
              url: $slsa_attestation_url,
              rekor_log_url: $slsa_attestation_rekor_log_url,
              verification_command: $slsa_attestation_verification_command,
              verification_status: "verified"
            },
            no_certification_overclaim: true
          }
          else null
          end
        ),
        milestone_note: (
          if $milestone_path == "" then null
          else {
            path: $milestone_path,
            sha256: $milestone_sha,
            retained: true
          }
          end
        ),
        artifacts: (
          [
            {kind: "release_packet", path: $packet_path, sha256: $packet_sha, required: true},
            {kind: "release_provenance", path: $provenance_path, sha256: $provenance_sha, required: true},
            {kind: "production_dry_run", path: $dry_run_path, sha256: $dry_run_sha, required: true},
            {kind: "signing_public_key", path: $public_key_path, sha256: $public_key_sha, required: true}
          ] +
          (if $milestone_path == "" then [] else [{kind: "milestone_note", path: $milestone_path, sha256: $milestone_sha, required: false}] end) +
          (if $slsa_present == "1" then [{kind: "slsa_provenance", path: $slsa_path, sha256: $slsa_sha, required: false}] else [] end)
        ),
        metadata_boundary: {
          stores: ["paths", "sha256 hashes", "commit ids", "tag ids", "verification states", "known limitations"],
          excludes: ["raw runtime artifacts", "target secrets", "session contents", "packet captures", "credential material", "private keys", "tokens", "evidence bodies"]
        },
        contract: {
          schema_document: "docs/schemas/release-artifact-manifest.v1.md",
          guidance_document: "docs/atlas/RELEASE_ARTIFACT_MANIFEST.md",
          slsa_schema_document: "docs/schemas/slsa-provenance.v1.md",
          known_limitations_reference: "known_limitations"
        },
        known_limitations: [
          "Release artifact manifests are metadata-only local release indexes, not external audit attestations.",
          "SLSA provenance references record verification metadata only and do not claim external SLSA certification.",
          "Artifact files are hash-bound by this manifest but are not individually signed.",
          "Signed tag verification depends on the retained public key and local Git object availability.",
          "This manifest does not claim deployment certification, enterprise certification, or legal compliance."
        ],
        no_production_overclaim: true
      }
    ' >"$file"
}

atlas_release_manifest_verify_artifact_hashes() {
  local manifest_file="$1"
  local kind
  local path
  local expected_sha
  local required
  local file
  local actual_sha

  if ! jq -e '(.artifacts // null | type) == "array"' "$manifest_file" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Artifact Hashes" "fail" "artifacts array missing"
    return 0
  fi

  while IFS=$'\t' read -r kind path expected_sha required; do
    [ -n "$kind" ] || continue
    file="$(atlas_release_resolve_repo_file "$path" 2>/dev/null || true)"
    if [ -z "$file" ]; then
      atlas_release_manifest_verify_row "Artifact $kind" "fail" "missing path=$path required=$required"
      continue
    fi
    actual_sha="$(atlas_release_file_sha256 "$file")"
    if [ "$actual_sha" = "$expected_sha" ]; then
      atlas_release_manifest_verify_row "Artifact $kind" "ok" "sha256=$actual_sha path=$path"
    else
      atlas_release_manifest_verify_row "Artifact $kind" "fail" "expected_sha=$expected_sha actual_sha=$actual_sha path=$path"
    fi
  done < <(jq -r '.artifacts[] | [.kind, .path, .sha256, (.required | tostring)] | @tsv' "$manifest_file")
}

atlas_release_manifest_verify_completeness() {
  local manifest_file="$1"
  local artifact_count
  local required_count
  local missing=""
  local kind

  artifact_count="$(jq -r 'if ((.artifacts // null | type) == "array") then (.artifacts | length) else -1 end' "$manifest_file")"
  required_count="$(jq -r 'if ((.artifacts // null | type) == "array") then ([.artifacts[] | select(.required == true)] | length) else 0 end' "$manifest_file")"
  if [ "$artifact_count" -ge 4 ] && [ "$required_count" -ge 4 ]; then
    atlas_release_manifest_verify_row "Artifact Count" "ok" "total=$artifact_count required=$required_count"
  else
    atlas_release_manifest_verify_row "Artifact Count" "fail" "expected_at_least=4 total=$artifact_count required=$required_count"
  fi

  for kind in release_packet release_provenance production_dry_run signing_public_key; do
    if ! jq -e --arg kind "$kind" '
      [(.artifacts // [])[]?
        | select(
          .kind == $kind and
          .required == true and
          ((.path // "") | type == "string" and length > 0) and
          ((.sha256 // "") | test("^[a-f0-9]{64}$"))
        )
      ] | length == 1
    ' "$manifest_file" >/dev/null 2>&1; then
      missing="${missing:+$missing,}$kind"
    fi
  done

  if [ -z "$missing" ]; then
    atlas_release_manifest_verify_row "Artifact Classes" "ok" "required classes present"
  else
    atlas_release_manifest_verify_row "Artifact Classes" "fail" "missing_or_invalid=$missing"
  fi
}

atlas_release_manifest_verify_path_field() {
  local manifest_file="$1"
  local label="$2"
  local jq_expr="$3"
  local path
  local file

  path="$(jq -r "$jq_expr" "$manifest_file" 2>/dev/null || true)"
  if [ -n "$path" ]; then
    file="$(atlas_release_resolve_repo_file "$path" 2>/dev/null || true)"
  else
    file=""
  fi

  if [ -n "$file" ]; then
    atlas_release_manifest_verify_row "$label" "ok" "path=$path"
  else
    atlas_release_manifest_verify_row "$label" "fail" "missing path=${path:-missing}"
  fi
}

atlas_release_manifest_verify_generated_metadata() {
  local manifest_file="$1"
  local expected_commit="$2"
  local generated_commit
  local tag_name
  local tag_target
  local tag_object
  local actual_tag_object

  generated_commit="$(jq -r '.release.retained_by_commit // ""' "$manifest_file")"
  if [ -n "$generated_commit" ] && git -C "$LAB_ROOT" rev-parse --verify --quiet "$generated_commit^{commit}" >/dev/null; then
    atlas_release_manifest_verify_row "Generated Commit" "ok" "$generated_commit"
  else
    atlas_release_manifest_verify_row "Generated Commit" "fail" "missing_or_unavailable=${generated_commit:-missing}"
  fi

  tag_name="$(jq -r '.signed_tag.name // ""' "$manifest_file")"
  tag_target="$(jq -r '.signed_tag.target // ""' "$manifest_file")"
  tag_object="$(jq -r '.signed_tag.tag_object // ""' "$manifest_file")"
  actual_tag_object="$(git -C "$LAB_ROOT" rev-parse "$tag_name^{tag}" 2>/dev/null || true)"
  if [ -n "$tag_name" ] &&
    atlas_release_commit_matches "$tag_target" "$expected_commit" &&
    [ -n "$tag_object" ] &&
    [ "$tag_object" = "$actual_tag_object" ] &&
    jq -e '.signed_tag.verification == "verified"' "$manifest_file" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Generated Tag" "ok" "tag=$tag_name target=$tag_target"
  else
    atlas_release_manifest_verify_row "Generated Tag" "fail" "tag=${tag_name:-missing} target=${tag_target:-missing} tag_object=${tag_object:-missing}"
  fi
}

atlas_release_manifest_verify_contract_refs() {
  local manifest_file="$1"
  local schema_doc
  local guidance_doc
  local slsa_schema_doc
  local known_ref

  schema_doc="$(jq -r '.contract.schema_document // ""' "$manifest_file")"
  if [ -n "$schema_doc" ] && atlas_release_resolve_repo_file "$schema_doc" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Schema Docs Reference" "ok" "$schema_doc"
  else
    atlas_release_manifest_verify_row "Schema Docs Reference" "fail" "missing path=${schema_doc:-missing}"
  fi

  guidance_doc="$(jq -r '.contract.guidance_document // ""' "$manifest_file")"
  if [ -n "$guidance_doc" ] && atlas_release_resolve_repo_file "$guidance_doc" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Manifest Contract Reference" "ok" "$guidance_doc"
  else
    atlas_release_manifest_verify_row "Manifest Contract Reference" "fail" "missing path=${guidance_doc:-missing}"
  fi

  slsa_schema_doc="$(jq -r '.contract.slsa_schema_document // ""' "$manifest_file")"
  if [ -n "$slsa_schema_doc" ]; then
    if atlas_release_resolve_repo_file "$slsa_schema_doc" >/dev/null 2>&1; then
      atlas_release_manifest_verify_row "SLSA Schema Reference" "ok" "$slsa_schema_doc"
    else
      atlas_release_manifest_verify_row "SLSA Schema Reference" "fail" "missing path=$slsa_schema_doc"
    fi
  fi

  known_ref="$(jq -r '.contract.known_limitations_reference // ""' "$manifest_file")"
  if [ "$known_ref" = "known_limitations" ] && jq -e '((.known_limitations // []) | length > 0)' "$manifest_file" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Known Limitations Reference" "ok" "$known_ref"
  else
    atlas_release_manifest_verify_row "Known Limitations Reference" "fail" "missing reference=${known_ref:-missing}"
  fi
}

atlas_release_manifest_verify_slsa_reference() {
  local manifest_file="$1"
  local expected_commit="$2"
  local slsa_path
  local slsa_sha
  local slsa_file
  local actual_sha

  if ! jq -e '.slsa_provenance != null' "$manifest_file" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "SLSA Provenance" "ok" "not-recorded optional"
    return 0
  fi

  slsa_path="$(jq -r '.slsa_provenance.path // ""' "$manifest_file")"
  slsa_sha="$(jq -r '.slsa_provenance.sha256 // ""' "$manifest_file")"
  slsa_file="$(atlas_release_resolve_repo_file "$slsa_path" 2>/dev/null || true)"
  if [ -z "$slsa_file" ]; then
    atlas_release_manifest_verify_row "SLSA Provenance" "fail" "missing path=${slsa_path:-missing}"
    return 0
  fi

  actual_sha="$(atlas_release_file_sha256 "$slsa_file")"
  if [ "$actual_sha" != "$slsa_sha" ]; then
    atlas_release_manifest_verify_row "SLSA Provenance" "fail" "expected_sha=$slsa_sha actual_sha=$actual_sha path=$slsa_path"
    return 0
  fi

  if jq -e --arg path "$slsa_path" --arg sha "$slsa_sha" '
      .slsa_provenance.schema_version == "atlas.slsa_provenance.v1" and
      .slsa_provenance.verified == true and
      .slsa_provenance.no_certification_overclaim == true and
      .slsa_provenance.attestation.verification_status == "verified" and
      ([.artifacts[]? | select(.kind == "slsa_provenance" and .required == false and .path == $path and .sha256 == $sha)] | length == 1)
    ' "$manifest_file" >/dev/null 2>&1 &&
    jq -e --slurpfile slsa "$slsa_file" '
      ($slsa[0]) as $reference |
      .slsa_provenance.schema_version == $reference.schema_version and
      .slsa_provenance.no_certification_overclaim == $reference.no_certification_overclaim and
      .slsa_provenance.artifact == $reference.artifact and
      .slsa_provenance.source == $reference.source and
      .slsa_provenance.workflow == $reference.workflow and
      .slsa_provenance.attestation.subject_digest == $reference.attestation.subject_digest and
      .slsa_provenance.attestation.url == ($reference.attestation.url // "") and
      .slsa_provenance.attestation.rekor_log_url == ($reference.attestation.rekor_log_url // "") and
      .slsa_provenance.attestation.verification_command == $reference.attestation.verification_command and
      .slsa_provenance.attestation.verification_status == $reference.attestation.verification_status
    ' "$manifest_file" >/dev/null 2>&1 &&
    atlas_release_slsa_reference_valid "$slsa_file" "$expected_commit"; then
    atlas_release_manifest_verify_row "SLSA Provenance" "ok" "verified path=$slsa_path"
  else
    atlas_release_manifest_verify_row "SLSA Provenance" "fail" "verification failed path=$slsa_path"
  fi
}

atlas_release_manifest_verify_forbidden_content() {
  local manifest_file="$1"
  local forbidden

  forbidden="$(atlas_release_json_forbidden_content_paths "$manifest_file")"

  if [ -z "$forbidden" ]; then
    atlas_release_manifest_verify_row "Forbidden Content" "ok" "no forbidden raw-content markers"
  else
    atlas_release_manifest_verify_row "Forbidden Content" "fail" "$(printf '%s' "$forbidden" | paste -sd, -)"
  fi
}

atlas_release_manifest_verify_packet() {
  local manifest_file="$1"
  local expected_commit="$2"
  local release_commit
  local packet_path
  local packet_file
  local provenance_path
  local provenance_file
  local dry_run_path
  local dry_run_note
  local public_key_path
  local public_key_file
  local tag_name
  local repo_state
  local sync_state

  [ -f "$manifest_file" ] || fail "release artifact manifest is not a file: $manifest_file"
  [ -n "$expected_commit" ] || expected_commit="$(jq -r '.release.commit // ""' "$manifest_file" 2>/dev/null || true)"
  [ -n "$expected_commit" ] || fail "release artifact manifest is missing release.commit: $manifest_file"
  expected_commit="$(atlas_release_full_commit "$expected_commit")" || fail "release artifact manifest commit is not available locally: $expected_commit"
  atlas_release_manifest_verify_failures=0

  ui_heading "Atlas Release Artifact Manifest Verification"
  ui_rule
  ui_kv "Manifest" "$manifest_file"
  ui_kv "Commit" "$expected_commit"

  if jq -e '.schema_version == "atlas.release_artifact_manifest.v1"' "$manifest_file" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Schema" "ok" "atlas.release_artifact_manifest.v1"
  else
    atlas_release_manifest_verify_row "Schema" "fail" "expected=atlas.release_artifact_manifest.v1"
  fi

  if jq -e '.metadata_only == true and .raw_artifacts_embedded == false and .no_production_overclaim == true' "$manifest_file" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Metadata Boundary" "ok" "metadata_only=true raw_artifacts_embedded=false"
  else
    atlas_release_manifest_verify_row "Metadata Boundary" "fail" "expected metadata_only=true raw_artifacts_embedded=false no_production_overclaim=true"
  fi

  atlas_release_manifest_verify_forbidden_content "$manifest_file"

  release_commit="$(jq -r '.release.commit // ""' "$manifest_file")"
  if atlas_release_commit_matches "$release_commit" "$expected_commit"; then
    atlas_release_manifest_verify_row "Release Commit" "ok" "$release_commit"
  else
    atlas_release_manifest_verify_row "Release Commit" "fail" "expected=$expected_commit actual=${release_commit:-missing}"
  fi
  atlas_release_manifest_verify_generated_metadata "$manifest_file" "$expected_commit"

  repo_state="$(jq -r '.repository.state_before_manifest // ""' "$manifest_file")"
  if [ "$repo_state" = "clean" ]; then
    atlas_release_manifest_verify_row "Repository State" "ok" "$repo_state"
  elif [ "$repo_state" = "dirty" ]; then
    atlas_release_manifest_verify_row "Repository State" "ok" "dirty retention-artifact-assembly"
  else
    atlas_release_manifest_verify_row "Repository State" "fail" "expected=clean-or-dirty actual=${repo_state:-missing}"
  fi

  sync_state="$(jq -r '.repository.upstream_sync_before_manifest // ""' "$manifest_file")"
  if [ "$sync_state" = "synced" ]; then
    atlas_release_manifest_verify_row "Upstream Sync" "ok" "$sync_state"
  else
    atlas_release_manifest_verify_row "Upstream Sync" "fail" "expected=synced actual=${sync_state:-missing}"
  fi

  atlas_release_manifest_verify_completeness "$manifest_file"
  atlas_release_manifest_verify_path_field "$manifest_file" "Release Packet Path" '.release_packet.path // ""'
  atlas_release_manifest_verify_path_field "$manifest_file" "Provenance Path" '.provenance.path // ""'
  atlas_release_manifest_verify_path_field "$manifest_file" "Production Dry Run Path" '.production_dry_run.path // ""'
  atlas_release_manifest_verify_path_field "$manifest_file" "Signing Public Key Path" '.signing_public_key.path // ""'
  atlas_release_manifest_verify_contract_refs "$manifest_file"
  atlas_release_manifest_verify_artifact_hashes "$manifest_file"
  atlas_release_manifest_verify_slsa_reference "$manifest_file" "$expected_commit"

  packet_path="$(jq -r '.release_packet.path // ""' "$manifest_file")"
  packet_file="$(atlas_release_resolve_repo_file "$packet_path" 2>/dev/null || true)"
  if [ -n "$packet_file" ] && atlas_release_verify_packet "$packet_file" "$expected_commit" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Release Packet" "ok" "verified path=$packet_path"
  else
    atlas_release_manifest_verify_row "Release Packet" "fail" "verification failed path=${packet_path:-missing}"
  fi

  provenance_path="$(jq -r '.provenance.path // ""' "$manifest_file")"
  provenance_file="$(atlas_release_resolve_repo_file "$provenance_path" 2>/dev/null || true)"
  if [ -n "$provenance_file" ] && atlas_production_release_provenance_valid "$provenance_file" "$expected_commit"; then
    atlas_release_manifest_verify_row "Provenance" "ok" "verified path=$provenance_path"
  else
    atlas_release_manifest_verify_row "Provenance" "fail" "verification failed path=${provenance_path:-missing}"
  fi

  dry_run_path="$(jq -r '.production_dry_run.path // ""' "$manifest_file")"
  dry_run_note="$(atlas_release_resolve_repo_file "$dry_run_path" 2>/dev/null || true)"
  if [ -n "$dry_run_note" ] && atlas_production_dry_run_note_valid "$dry_run_note" "$expected_commit"; then
    atlas_release_manifest_verify_row "Production Dry Run" "ok" "verified path=$dry_run_path"
  else
    atlas_release_manifest_verify_row "Production Dry Run" "fail" "verification failed path=${dry_run_path:-missing}"
  fi

  public_key_path="$(jq -r '.signing_public_key.path // ""' "$manifest_file")"
  public_key_file="$(atlas_release_resolve_repo_file "$public_key_path" 2>/dev/null || true)"
  tag_name="$(jq -r '.signed_tag.name // ""' "$manifest_file")"
  if [ -n "$public_key_file" ] && atlas_production_verify_signed_tag "$tag_name" "$public_key_file"; then
    atlas_release_manifest_verify_row "Signed Tag" "ok" "verified tag=$tag_name"
  else
    atlas_release_manifest_verify_row "Signed Tag" "fail" "verification failed tag=${tag_name:-missing}"
  fi

  if jq -e '((.known_limitations // []) | length > 0) and (((.metadata_boundary.excludes // []) | index("raw runtime artifacts")) != null)' "$manifest_file" >/dev/null 2>&1; then
    atlas_release_manifest_verify_row "Known Limitations" "ok" "present"
  else
    atlas_release_manifest_verify_row "Known Limitations" "fail" "missing metadata boundary or limitations"
  fi

  ui_rule
  if [ "$atlas_release_manifest_verify_failures" -eq 0 ]; then
    ui_ok "release artifact manifest verified"
  else
    ui_alert "release artifact manifest verification failed"
  fi

  return "$atlas_release_manifest_verify_failures"
}

atlas_release_replay_run() {
  local label="$1"
  local log_file="$2"
  shift 2

  if "$@" >"$log_file" 2>&1; then
    ui_kv "$label" "ok"
    return 0
  fi

  ui_kv "$label" "fail"
  sed -n '1,160p' "$log_file" >&2
  return 1
}

atlas_release_replay_clean_env() {
  env \
    -u LAB_ROOT \
    -u LAB_CONFIG \
    -u LAB_BIN_DIR \
    -u LAB_LIB_DIR \
    -u LAB_PERSIST_DIR \
    -u LAB_STATE_DIR \
    -u LAB_TARGETS_DIR \
    -u LAB_SESSIONS_DIR \
    -u LAB_TOOLS_DIR \
    -u LAB_REPORTS_DIR \
    -u LAB_LOGS_DIR \
    -u LAB_DOCS_DIR \
    -u LAB_RELEASES_DIR \
    -u LAB_INTEL_DIR \
    -u LAB_INTEL_OBSERVATIONS_FILE \
    -u LAB_INTEL_ENTITIES_FILE \
    -u LAB_INTEL_OUTCOMES_FILE \
    -u LAB_INTEL_RELATIONSHIPS_FILE \
    "$@"
}

atlas_release_replay_cleanup() {
  if [ -n "${atlas_release_replay_cleanup_parent:-}" ]; then
    rm -rf "$atlas_release_replay_cleanup_parent"
  fi
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

cmd_release_manifest() {
  local manifest_name=""
  local packet_arg=""
  local provenance_arg=""
  local dry_run_arg=""
  local milestone_arg=""
  local slsa_arg=""
  local tag_name=""
  local allow_dirty=0
  local allow_unsynced=0
  local manifest_slug
  local manifest_dir="$LAB_DOCS_DIR/retention/releases"
  local manifest_file
  local packet_file
  local provenance_file
  local dry_run_note
  local milestone_note=""
  local slsa_file=""
  local slsa_commit=""
  local release_commit=""
  local release_commit_full=""
  local clean_state
  local sync_state

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --packet)
      [ "$#" -ge 2 ] || fail "release manifest [manifest-name] [--packet packet] [--provenance provenance] [--dry-run note] [--milestone-note note] [--slsa slsa-reference] [--tag tag]"
      packet_arg="$2"
      shift 2
      ;;
    --provenance)
      [ "$#" -ge 2 ] || fail "release manifest [manifest-name] [--packet packet] [--provenance provenance] [--dry-run note] [--milestone-note note] [--slsa slsa-reference] [--tag tag]"
      provenance_arg="$2"
      shift 2
      ;;
    --dry-run)
      [ "$#" -ge 2 ] || fail "release manifest [manifest-name] [--packet packet] [--provenance provenance] [--dry-run note] [--milestone-note note] [--slsa slsa-reference] [--tag tag]"
      dry_run_arg="$2"
      shift 2
      ;;
    --milestone-note)
      [ "$#" -ge 2 ] || fail "release manifest [manifest-name] [--packet packet] [--provenance provenance] [--dry-run note] [--milestone-note note] [--slsa slsa-reference] [--tag tag]"
      milestone_arg="$2"
      shift 2
      ;;
    --slsa)
      [ "$#" -ge 2 ] || fail "release manifest [manifest-name] [--packet packet] [--provenance provenance] [--dry-run note] [--milestone-note note] [--slsa slsa-reference] [--tag tag]"
      slsa_arg="$2"
      shift 2
      ;;
    --tag)
      [ "$#" -ge 2 ] || fail "release manifest [manifest-name] [--packet packet] [--provenance provenance] [--dry-run note] [--milestone-note note] [--slsa slsa-reference] [--tag tag]"
      tag_name="$2"
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
    -*)
      fail "unknown release manifest option: $1"
      ;;
    *)
      if [ -n "$manifest_name" ]; then
        fail "release manifest [manifest-name] [--packet packet] [--provenance provenance] [--dry-run note] [--milestone-note note] [--slsa slsa-reference] [--tag tag]"
      fi
      manifest_name="$1"
      shift
      ;;
    esac
  done

  [ -n "$manifest_name" ] || manifest_name="atlas-release-manifest-$(atlas_release_commit)"
  manifest_slug="$(slugify "$manifest_name")"
  [ -n "$manifest_slug" ] || fail "release manifest name produced an empty slug"

  clean_state="$(atlas_release_clean_state)"
  if [ "$clean_state" != "clean" ] && [ "$allow_dirty" != "1" ]; then
    fail "release manifest requires a clean repository; commit or discard changes, or pass --allow-dirty"
  fi
  sync_state="$(atlas_release_sync_state)"
  if [ "$sync_state" != "synced" ] && [ "$allow_unsynced" != "1" ]; then
    fail "release manifest requires synced upstream state; push/pull first, or pass --allow-unsynced"
  fi

  if [ -n "$slsa_arg" ]; then
    slsa_file="$(atlas_release_resolve_repo_file "$slsa_arg")" || fail "unknown SLSA provenance reference: $slsa_arg"
    slsa_commit="$(jq -r '.source.commit // ""' "$slsa_file" 2>/dev/null || true)"
    if [ -n "$slsa_commit" ]; then
      slsa_commit="$(atlas_release_full_commit "$slsa_commit" 2>/dev/null || printf '%s\n' "$slsa_commit")"
    fi
  fi

  if [ -n "$packet_arg" ]; then
    packet_file="$(atlas_release_resolve_packet "$packet_arg")"
  elif [ -n "$slsa_commit" ]; then
    packet_file="$(atlas_release_find_packet_by_commit "$slsa_commit" || true)"
    [ -n "$packet_file" ] || fail "no release trust packet found for SLSA provenance commit: $slsa_commit"
  else
    packet_file="$(atlas_release_resolve_packet "$packet_arg")"
  fi

  release_commit="$(atlas_release_packet_commit "$packet_file")"
  [ -n "$release_commit" ] || fail "release manifest could not determine release packet commit"
  release_commit_full="$(atlas_release_full_commit "$release_commit")" || fail "release manifest could not resolve release packet commit: $release_commit"

  if [ -n "$provenance_arg" ]; then
    provenance_file="$(atlas_release_resolve_repo_file "$provenance_arg")" || fail "unknown release provenance packet: $provenance_arg"
  else
    provenance_file="$(atlas_release_find_provenance_by_commit "$release_commit_full" || true)"
    [ -n "$provenance_file" ] || provenance_file="$(atlas_release_latest_provenance_packet)"
    [ -n "$provenance_file" ] || fail "no release provenance packet found"
  fi
  if [ -n "$dry_run_arg" ]; then
    dry_run_note="$(atlas_release_resolve_repo_file "$dry_run_arg")" || fail "unknown production dry-run note: $dry_run_arg"
  else
    dry_run_note="$(atlas_release_find_dry_run_note_by_commit "$release_commit_full" || true)"
    [ -n "$dry_run_note" ] || dry_run_note="$(atlas_release_latest_dry_run_note)"
    [ -n "$dry_run_note" ] || fail "no production dry-run note found"
  fi
  if [ -n "$milestone_arg" ]; then
    milestone_note="$(atlas_release_resolve_repo_file "$milestone_arg")" || fail "unknown milestone note: $milestone_arg"
  else
    milestone_note="$(atlas_release_latest_milestone_note)"
  fi
  mkdir -p "$manifest_dir"
  manifest_file="$manifest_dir/$manifest_slug.manifest.json"
  atlas_release_manifest_write "$manifest_file" "$manifest_name" "$packet_file" "$provenance_file" "$dry_run_note" "$milestone_note" "$tag_name" "$slsa_file"
  chmod 600 "$manifest_file" 2>/dev/null || true

  ui_ok "release artifact manifest written"
  printf 'release_manifest: %s\n' "$manifest_file"
}

cmd_release_manifest_verify() {
  local manifest_arg=""
  local expected_commit=""
  local manifest_file

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --commit)
      [ "$#" -ge 2 ] || fail "release manifest-verify [manifest] [--commit sha]"
      expected_commit="$2"
      shift 2
      ;;
    -*)
      fail "unknown release manifest-verify option: $1"
      ;;
    *)
      if [ -n "$manifest_arg" ]; then
        fail "release manifest-verify [manifest] [--commit sha]"
      fi
      manifest_arg="$1"
      shift
      ;;
    esac
  done

  manifest_file="$(atlas_release_resolve_manifest "$manifest_arg")"
  atlas_release_manifest_verify_packet "$manifest_file" "$expected_commit"
}

cmd_release_slsa_verify() {
  local slsa_arg=""
  local expected_commit=""
  local artifact_arg=""
  local online_verify=0
  local repository_override=""
  local slsa_file

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --commit)
      [ "$#" -ge 2 ] || fail "release slsa-verify [reference] [--commit sha] [--artifact path] [--online] [--repo owner/repo]"
      expected_commit="$2"
      shift 2
      ;;
    --artifact)
      [ "$#" -ge 2 ] || fail "release slsa-verify [reference] [--commit sha] [--artifact path] [--online] [--repo owner/repo]"
      artifact_arg="$2"
      shift 2
      ;;
    --online)
      online_verify=1
      shift
      ;;
    --repo)
      [ "$#" -ge 2 ] || fail "release slsa-verify [reference] [--commit sha] [--artifact path] [--online] [--repo owner/repo]"
      repository_override="$2"
      shift 2
      ;;
    -*)
      fail "unknown release slsa-verify option: $1"
      ;;
    *)
      if [ -n "$slsa_arg" ]; then
        fail "release slsa-verify [reference] [--commit sha] [--artifact path] [--online] [--repo owner/repo]"
      fi
      slsa_arg="$1"
      shift
      ;;
    esac
  done

  slsa_file="$(atlas_release_resolve_slsa_reference "$slsa_arg")"
  atlas_release_slsa_verify_reference "$slsa_file" "$expected_commit" "$artifact_arg" "$online_verify" "$repository_override"
}

cmd_release_replay() {
  local packet_arg=""
  local packet_file
  local commit
  local run_qa=1
  local keep_worktree=0
  local replay_parent=""
  local replay_checkout=""
  local replay_branch=""
  local qa_log
  local v1_log
  local verify_log

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --skip-qa)
      run_qa=0
      shift
      ;;
    --keep-worktree)
      keep_worktree=1
      shift
      ;;
    -*)
      fail "unknown release replay option: $1"
      ;;
    *)
      if [ -n "$packet_arg" ]; then
        fail "release replay [packet] [--skip-qa] [--keep-worktree]"
      fi
      packet_arg="$1"
      shift
      ;;
    esac
  done

  atlas_release_git_available || fail "release replay requires a git checkout"

  packet_file="$(atlas_release_resolve_packet "$packet_arg")"
  commit="$(atlas_release_packet_commit "$packet_file")"
  [ -n "$commit" ] || fail "release replay could not determine packet commit"
  git -C "$LAB_ROOT" rev-parse --verify "$commit^{commit}" >/dev/null 2>&1 ||
    fail "release replay commit is not available locally: $commit"

  replay_parent="$(mktemp -d)"
  replay_checkout="$replay_parent/checkout"
  replay_branch="atlas-replay-$(printf '%s' "$commit" | cut -c1-12)-$$"
  qa_log="$replay_parent/dev-qa.log"
  v1_log="$replay_parent/v1-status.log"
  verify_log="$replay_parent/release-verify.log"

  if [ "$keep_worktree" = "0" ]; then
    atlas_release_replay_cleanup_parent="$replay_parent"
    trap atlas_release_replay_cleanup EXIT
  fi

  ui_heading "Atlas Release Replay"
  ui_rule
  ui_kv "Packet" "$packet_file"
  ui_kv "Commit" "$commit"
  ui_kv "Branch" "$replay_branch"
  ui_kv "Checkout" "$replay_checkout"
  ui_rule

  git clone --no-local --quiet "$LAB_ROOT" "$replay_checkout" >/dev/null 2>&1 ||
    fail "release replay could not create isolated replay checkout"
  git -C "$replay_checkout" checkout -B "$replay_branch" "$commit" >/dev/null 2>&1 ||
    fail "release replay could not check out $commit"
  if git -C "$replay_checkout" rev-parse --verify refs/remotes/origin/main >/dev/null 2>&1; then
    git -C "$replay_checkout" branch --set-upstream-to=origin/main "$replay_branch" >/dev/null 2>&1 || true
  fi

  if [ "$run_qa" = "1" ]; then
    command -v nix-shell >/dev/null 2>&1 || fail "release replay requires nix-shell for QA; pass --skip-qa for metadata-only replay"
    atlas_release_replay_run "QA" "$qa_log" atlas_release_replay_clean_env bash -c "cd \"\$1\" && nix-shell --run './bin/dev-qa'" _ "$replay_checkout" ||
      return 1
  else
    ui_kv "QA" "skipped"
  fi

  atlas_release_replay_run "V1 Status" "$v1_log" atlas_release_replay_clean_env "$replay_checkout/tools/atlas/bin/atlas" v1 status --strict ||
    return 1
  atlas_release_replay_run "Release Verify" "$verify_log" atlas_release_replay_clean_env "$replay_checkout/tools/atlas/bin/atlas" release verify "$packet_file" --commit "$commit" ||
    return 1

  if [ "$keep_worktree" = "1" ]; then
    ui_kv "Cleanup" "kept checkout=$replay_checkout"
  else
    rm -rf "$replay_parent"
    atlas_release_replay_cleanup_parent=""
    trap - EXIT
    ui_kv "Cleanup" "removed"
  fi

  ui_rule
  ui_ok "release replay verified"
}
