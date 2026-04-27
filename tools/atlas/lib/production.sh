#!/usr/bin/env bash

atlas_production_rows_file=""
atlas_production_blocked=0
atlas_production_warnings=0
atlas_production_required_not_ready=0

atlas_production_status_valid() {
  case "$1" in
  ready | warning | blocked | planned | disabled | not-implemented)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

atlas_production_add_gate() {
  local key="$1"
  local label="$2"
  local required="$3"
  local status="$4"
  local reason="$5"
  local evidence="$6"
  local command_ref="$7"
  local limitations="$8"

  atlas_production_status_valid "$status" || fail "invalid production readiness status: $status"

  case "$status" in
  ready) ;;
  warning)
    atlas_production_warnings=$((atlas_production_warnings + 1))
    [ "$required" = "1" ] && atlas_production_required_not_ready=$((atlas_production_required_not_ready + 1))
    ;;
  blocked | not-implemented)
    atlas_production_blocked=$((atlas_production_blocked + 1))
    [ "$required" = "1" ] && atlas_production_required_not_ready=$((atlas_production_required_not_ready + 1))
    ;;
  planned | disabled)
    [ "$required" = "1" ] && atlas_production_required_not_ready=$((atlas_production_required_not_ready + 1))
    ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$key" "$label" "$required" "$status" "$reason" "$evidence" "$command_ref" "$limitations" >>"$atlas_production_rows_file"
}

atlas_production_overall() {
  if [ "$atlas_production_blocked" -gt 0 ] || [ "$atlas_production_required_not_ready" -gt 0 ]; then
    printf 'not-ready\n'
  elif [ "$atlas_production_warnings" -gt 0 ]; then
    printf 'warning\n'
  else
    printf 'production-ready\n'
  fi
}

atlas_production_check_v1() {
  local v1_json
  local overall
  local required_not_ready

  v1_json="$(atlas_release_v1_json)"
  overall="$(printf '%s\n' "$v1_json" | jq -r '.overall // ""')"
  required_not_ready="$(printf '%s\n' "$v1_json" | jq -r '.counts.required_not_ready // ""')"

  if [ "$overall" = "ready" ] && [ "$required_not_ready" = "0" ]; then
    atlas_production_add_gate \
      "v1_internal_readiness" \
      "V1 Internal Readiness" \
      1 \
      "ready" \
      "v1 readiness is ready with no required pillar gaps" \
      "docs/atlas/V1_PILLAR_READINESS.md" \
      "atlas v1 status --strict; atlas v1 status --json" \
      "v1 readiness remains internal readiness, not production certification"
  else
    atlas_production_add_gate \
      "v1_internal_readiness" \
      "V1 Internal Readiness" \
      1 \
      "blocked" \
      "v1 readiness is ${overall:-missing} with required_not_ready=${required_not_ready:-missing}" \
      "docs/atlas/V1_PILLAR_READINESS.md" \
      "atlas v1 status --strict; atlas v1 status --json" \
      "resolve required v1 pillar gaps before production promotion"
  fi
}

atlas_production_check_repository() {
  local clean_state
  local sync_state

  clean_state="$(atlas_release_clean_state)"
  if [ "$clean_state" = "clean" ]; then
    atlas_production_add_gate \
      "repository_clean" \
      "Repository Clean" \
      1 \
      "ready" \
      "repository has no tracked, staged, or untracked changes" \
      "git status --short" \
      "git status --short --branch" \
      "ignored local runtime state may still exist outside tracked release evidence"
  else
    atlas_production_add_gate \
      "repository_clean" \
      "Repository Clean" \
      1 \
      "blocked" \
      "repository state is $clean_state" \
      "git status --short" \
      "git status --short --branch" \
      "production promotion requires a clean release commit"
  fi

  sync_state="$(atlas_release_sync_state)"
  if [ "$sync_state" = "synced" ]; then
    atlas_production_add_gate \
      "upstream_sync" \
      "Upstream Sync" \
      1 \
      "ready" \
      "local branch is synced with configured upstream" \
      "origin/main" \
      "git rev-list --left-right --count HEAD...@{u}" \
      "requires a configured upstream branch"
  else
    atlas_production_add_gate \
      "upstream_sync" \
      "Upstream Sync" \
      1 \
      "blocked" \
      "upstream sync state is $sync_state" \
      "origin/main" \
      "git rev-list --left-right --count HEAD...@{u}" \
      "production promotion requires a synced upstream state"
  fi
}

atlas_production_check_release_packet() {
  local latest_packet
  local commit
  local parent_commit

  latest_packet="$(atlas_release_latest_packet)"
  if [ -z "$latest_packet" ]; then
    atlas_production_add_gate \
      "release_trust_packet" \
      "Release Trust Packet" \
      1 \
      "blocked" \
      "no release trust packet found" \
      "docs/retention/releases/" \
      "atlas release packet --json; atlas release verify" \
      "production promotion requires a current verified release trust packet"
    return 0
  fi

  commit="$(atlas_release_commit)"
  if atlas_release_verify_packet "$latest_packet" "$commit" >/dev/null 2>&1; then
    atlas_production_add_gate \
      "release_trust_packet" \
      "Release Trust Packet" \
      1 \
      "ready" \
      "latest release trust packet verifies against the current commit" \
      "$latest_packet" \
      "atlas release verify" \
      "release packets are metadata-only and still require signing/provenance before production"
    return 0
  fi

  parent_commit="$(git -C "$LAB_ROOT" rev-parse --short HEAD^ 2>/dev/null || true)"
  if [ -n "$parent_commit" ] && atlas_release_verify_packet "$latest_packet" "$parent_commit" >/dev/null 2>&1; then
    atlas_production_add_gate \
      "release_trust_packet" \
      "Release Trust Packet" \
      1 \
      "ready" \
      "latest release trust packet verifies against the retained release commit before the packet-retention commit" \
      "$latest_packet" \
      "atlas release verify --commit $parent_commit" \
      "release packets are metadata-only and still require signing/provenance before production"
  else
    atlas_production_add_gate \
      "release_trust_packet" \
      "Release Trust Packet" \
      1 \
      "blocked" \
      "latest release trust packet does not verify against the current commit" \
      "$latest_packet" \
      "atlas release verify" \
      "regenerate and verify a release trust packet after the release commit is final"
  fi
}

atlas_production_check_docs() {
  local contract="$LAB_DOCS_DIR/atlas/PRODUCTION_READINESS.md"

  if [ -s "$contract" ]; then
    atlas_production_add_gate \
      "production_contract" \
      "Production Contract" \
      1 \
      "ready" \
      "production readiness contract is documented" \
      "$contract" \
      "atlas production status" \
      "contract must stay conservative as production gates mature"
  else
    atlas_production_add_gate \
      "production_contract" \
      "Production Contract" \
      1 \
      "blocked" \
      "production readiness contract is missing" \
      "$contract" \
      "atlas production status" \
      "define production-ready before claiming production readiness"
  fi
}

atlas_production_check_future_hardening() {
  atlas_production_add_gate \
    "signing_provenance" \
    "Signing And Provenance" \
    1 \
    "blocked" \
    "release trust packets are not cryptographically signed and no provenance packet is retained" \
    "docs/retention/releases/" \
    "atlas release packet; future signing/provenance command" \
    "SHA-256 anchors are present, but they are not signatures or SLSA-style provenance"

  atlas_production_add_gate \
    "production_dry_run" \
    "Production Dry Run" \
    1 \
    "blocked" \
    "no retained production dry-run or external validation note is present" \
    "docs/retention/production/" \
    "future production dry-run checklist" \
    "internal QA does not replace repeated operator dry runs or independent review"
}

atlas_production_collect() {
  atlas_production_blocked=0
  atlas_production_warnings=0
  atlas_production_required_not_ready=0

  atlas_production_check_v1
  atlas_production_check_repository
  atlas_production_check_release_packet
  atlas_production_check_docs
  atlas_production_check_future_hardening
}

atlas_production_print_text() {
  local overall="$1"
  local strict="$2"

  ui_heading "Atlas Production Readiness"
  ui_rule
  ui_kv "Root" "$LAB_ROOT"
  ui_kv "Commit" "$(atlas_release_commit)"
  ui_kv "Runtime Target" "$LAB_RUNTIME_TARGET"
  ui_kv "Strict" "$strict"
  ui_rule

  ui_subheading "Production Gates"
  printf '%-28s %-16s %-10s %s\n' "GATE" "STATUS" "REQUIRED" "REASON"
  awk -F'\t' '{
    required = ($3 == "1" ? "yes" : "no")
    printf "%-28s %-16s %-10s %s\n", $2, $4, required, $5
  }' "$atlas_production_rows_file"
  ui_rule
  ui_kv "Overall" "$overall"
  ui_kv "Blocked Gates" "$atlas_production_blocked"
  ui_kv "Warning Gates" "$atlas_production_warnings"
  ui_kv "Required Not Ready" "$atlas_production_required_not_ready"
}

atlas_production_print_json() {
  local overall="$1"
  local strict="$2"

  jq -Rn \
    --arg schema_version "atlas.production_readiness.v1" \
    --arg overall "$overall" \
    --arg commit "$(atlas_release_commit)" \
    --arg root "$LAB_ROOT" \
    --arg runtime_target "$LAB_RUNTIME_TARGET" \
    --arg strict "$strict" \
    --argjson blocked "$atlas_production_blocked" \
    --argjson warnings "$atlas_production_warnings" \
    --argjson required_not_ready "$atlas_production_required_not_ready" '
      [inputs | split("\t")] as $rows
      | {
          schema_version: $schema_version,
          overall: $overall,
          commit: $commit,
          root: $root,
          runtime_target: $runtime_target,
          strict: ($strict == "1"),
          counts: {
            blocked: $blocked,
            warning: $warnings,
            required_not_ready: $required_not_ready
          },
          gates: (
            $rows
            | map({
                key: .[0],
                value: {
                  label: .[1],
                  required: (.[2] == "1"),
                  status: .[3],
                  reason: .[4],
                  evidence: .[5],
                  commands: .[6],
                  limitations: .[7]
                }
              })
            | from_entries
          )
        }
    ' <"$atlas_production_rows_file"
}

cmd_production_status() {
  local strict=0
  local json=0
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
      fail "unknown production status option: $1"
      ;;
    *)
      fail "production status [--strict] [--json]"
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "production status [--strict] [--json]"

  atlas_production_rows_file="$(mktemp)"
  atlas_production_collect
  overall="$(atlas_production_overall)"

  if [ "$json" -eq 1 ]; then
    atlas_production_print_json "$overall" "$strict"
  else
    atlas_production_print_text "$overall" "$strict"
  fi

  if [ "$atlas_production_blocked" -gt 0 ]; then
    exit_status=1
  elif [ "$strict" -eq 1 ] && [ "$overall" != "production-ready" ]; then
    exit_status=1
  fi

  rm -f "$atlas_production_rows_file"
  return "$exit_status"
}
