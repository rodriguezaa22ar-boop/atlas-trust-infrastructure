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

atlas_release_write_packet() {
  local file="$1"
  local packet_name="$2"
  local qa_status="$3"
  local qa_command="$4"
  local qa_note="$5"
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

cmd_release_packet() {
  local packet_name=""
  local packet_slug
  local packet_dir="$LAB_DOCS_DIR/retention/releases"
  local packet_file
  local qa_status="not-recorded"
  local qa_command="nix-shell --run './bin/dev-qa'"
  local qa_note="QA was not recorded by this packet command."

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
  atlas_release_write_packet "$packet_file" "$packet_name" "$qa_status" "$qa_command" "$qa_note"
  chmod 600 "$packet_file" 2>/dev/null || true

  ui_ok "release trust packet written"
  printf 'release_packet: %s\n' "$packet_file"
}
