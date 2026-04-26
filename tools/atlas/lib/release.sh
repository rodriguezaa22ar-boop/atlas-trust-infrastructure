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

atlas_release_print_limitations() {
  local v1_json="$1"

  printf '%s\n' "$v1_json" |
    jq -r '.pillars | to_entries[] | "- " + .value.label + ": " + .value.limitations'
}

atlas_release_guard_packet() {
  local clean_state="$1"
  local sync_state="$2"
  local v1_overall="$3"
  local allow_dirty="$4"
  local allow_unsynced="$5"
  local allow_not_ready="$6"

  if [ "$clean_state" != "clean" ] && [ "$allow_dirty" != "1" ]; then
    fail "release packet requires a clean repository; commit or discard changes, or pass --allow-dirty"
  fi

  if [ "$sync_state" != "synced" ] && [ "$allow_unsynced" != "1" ]; then
    fail "release packet requires synced upstream state; push/pull first, or pass --allow-unsynced"
  fi

  if [ "$v1_overall" != "ready" ] && [ "$allow_not_ready" != "1" ]; then
    fail "release packet requires v1 readiness overall=ready; resolve readiness first, or pass --allow-not-ready"
  fi
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

  atlas_release_guard_packet "$clean_state" "$sync_state" "$v1_overall" "$allow_dirty" "$allow_unsynced" "$allow_not_ready"

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
  find "$packet_dir" -maxdepth 1 -type f -name '*.md' -printf '%T@\t%p\n' 2>/dev/null |
    sort -nr |
    awk -F'\t' 'NR == 1 { print $2 }'
}

atlas_release_resolve_packet() {
  local packet_arg="$1"
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local candidate
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

  packet_slug="$(slugify "${packet_arg%.md}")"
  candidate="$packet_dir/$packet_slug.md"
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
  if [ "$packet_commit" = "$expected_commit" ]; then
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

  while IFS= read -r note_path; do
    [ -n "$note_path" ] || continue
    note_path="$(atlas_release_display_path "$note_path")"
    if grep -q -- "\`$note_path\`" "$packet_file"; then
      atlas_release_verify_row "Retention Note" "ok" "$note_path"
    else
      atlas_release_verify_row "Retention Note" "fail" "missing $note_path"
    fi
  done <<<"$(atlas_release_retention_notes)"

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

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --qa-status)
      [ "$#" -ge 2 ] || fail "release packet [packet-name] [--qa-status status] [--qa-command command] [--qa-note text]"
      qa_status="$2"
      shift 2
      ;;
    --qa-command)
      [ "$#" -ge 2 ] || fail "release packet [packet-name] [--qa-status status] [--qa-command command] [--qa-note text]"
      qa_command="$2"
      shift 2
      ;;
    --qa-note)
      [ "$#" -ge 2 ] || fail "release packet [packet-name] [--qa-status status] [--qa-command command] [--qa-note text]"
      qa_note="$2"
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
        fail "release packet [packet-name] [--qa-status status] [--qa-command command] [--qa-note text]"
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

  mkdir -p "$packet_dir"
  packet_file="$packet_dir/$packet_slug.md"
  atlas_release_write_packet "$packet_file" "$packet_name" "$qa_status" "$qa_command" "$qa_note" "$allow_dirty" "$allow_unsynced" "$allow_not_ready"
  chmod 600 "$packet_file" 2>/dev/null || true

  ui_ok "release trust packet written"
  printf 'release_packet: %s\n' "$packet_file"
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
