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

atlas_production_check_release_manifest() {
  local latest_manifest
  local commit
  local parent_commit

  latest_manifest="$(atlas_release_latest_manifest)"
  if [ -z "$latest_manifest" ]; then
    atlas_production_add_gate \
      "release_artifact_manifest" \
      "Release Artifact Manifest" \
      1 \
      "blocked" \
      "no release artifact manifest found" \
      "docs/retention/releases/" \
      "atlas release manifest; atlas release manifest-verify" \
      "production promotion requires a current verified metadata-only release artifact manifest"
    return 0
  fi

  commit="$(git -C "$LAB_ROOT" rev-parse HEAD 2>/dev/null || atlas_release_commit)"
  if atlas_release_manifest_verify_packet "$latest_manifest" "$commit" >/dev/null 2>&1; then
    atlas_production_add_gate \
      "release_artifact_manifest" \
      "Release Artifact Manifest" \
      1 \
      "ready" \
      "latest release artifact manifest verifies against the current commit" \
      "$latest_manifest" \
      "atlas release manifest-verify --commit $commit" \
      "release artifact manifests are metadata-only local indexes, not external audit attestations"
    return 0
  fi

  parent_commit="$(git -C "$LAB_ROOT" rev-parse HEAD^ 2>/dev/null || true)"
  if [ -n "$parent_commit" ] && atlas_release_manifest_verify_packet "$latest_manifest" "$parent_commit" >/dev/null 2>&1; then
    atlas_production_add_gate \
      "release_artifact_manifest" \
      "Release Artifact Manifest" \
      1 \
      "ready" \
      "latest release artifact manifest verifies against the retained release commit before the manifest-retention commit" \
      "$latest_manifest" \
      "atlas release manifest-verify --commit $parent_commit" \
      "release artifact manifests are metadata-only local indexes, not external audit attestations"
    return 0
  fi

  atlas_production_add_gate \
    "release_artifact_manifest" \
    "Release Artifact Manifest" \
    1 \
    "blocked" \
    "latest release artifact manifest does not verify against the current commit or retained release commit" \
    "$latest_manifest" \
    "atlas release manifest; atlas release manifest-verify" \
    "regenerate the release artifact manifest after release packets, provenance, dry-run notes, signing keys, or release commits change"
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

atlas_production_check_business_flow_evidence() {
  local policy="${LAB_ATLAS_BUSINESS_FLOWS:-${LAB_ATLAS_BUSINESS_FLOWS_STATUS:-enabled}}"
  local flow_records="0"

  case "$policy" in
  disabled)
    atlas_production_add_gate \
      "business_flow_evidence" \
      "Business Flow Evidence" \
      0 \
      "disabled" \
      "optional Business Flow Evidence is explicitly disabled by environment policy" \
      "docs/atlas/BUSINESS_FLOW_EVIDENCE.md" \
      "atlas flow add; atlas flow link-evidence; atlas flow link-finding; atlas flow link-validation; atlas flow link-approval; atlas flow link-retention; atlas flow packet; atlas flow packet --json; atlas flow verify; atlas flow verify --json; atlas flow assurance; atlas flow assurance --json; atlas flow trust-chain; atlas flow trust-chain --json" \
      "business-flow evidence is optional and does not block production readiness yet"
    return 0
    ;;
  planned)
    atlas_production_add_gate \
      "business_flow_evidence" \
      "Business Flow Evidence" \
      0 \
      "planned" \
      "optional Business Flow Evidence is marked planned" \
      "docs/atlas/BUSINESS_FLOW_EVIDENCE.md" \
      "atlas flow add; atlas flow link-evidence; atlas flow link-finding; atlas flow link-validation; atlas flow link-approval; atlas flow link-retention; atlas flow packet; atlas flow packet --json; atlas flow verify; atlas flow verify --json; atlas flow assurance; atlas flow assurance --json; atlas flow trust-chain; atlas flow trust-chain --json" \
      "business-flow evidence is optional and does not block production readiness yet"
    return 0
    ;;
  esac

  if ! declare -F cmd_flow_add >/dev/null 2>&1 ||
    ! declare -F cmd_flow_link_finding >/dev/null 2>&1 ||
    ! declare -F cmd_flow_link_validation >/dev/null 2>&1 ||
    ! declare -F cmd_flow_link_approval >/dev/null 2>&1 ||
    ! declare -F cmd_flow_link_retention >/dev/null 2>&1 ||
    ! declare -F cmd_flow_packet >/dev/null 2>&1 ||
    ! declare -F cmd_flow_verify >/dev/null 2>&1 ||
    ! declare -F cmd_flow_assurance >/dev/null 2>&1 ||
    ! declare -F cmd_flow_trust_chain >/dev/null 2>&1; then
    atlas_production_add_gate \
      "business_flow_evidence" \
      "Business Flow Evidence" \
      0 \
      "planned" \
      "optional Business Flow Evidence commands are not fully enabled yet" \
      "docs/atlas/BUSINESS_FLOW_EVIDENCE.md" \
      "atlas flow add; atlas flow link-evidence; atlas flow link-finding; atlas flow link-validation; atlas flow link-approval; atlas flow link-retention; atlas flow packet; atlas flow packet --json; atlas flow verify; atlas flow verify --json; atlas flow assurance; atlas flow assurance --json; atlas flow trust-chain; atlas flow trust-chain --json" \
      "business-flow evidence is optional and does not block production readiness yet"
    return 0
  fi

  if declare -F atlas_flow_record_count >/dev/null 2>&1; then
    flow_records="$(atlas_flow_record_count)"
  fi

  atlas_production_add_gate \
    "business_flow_evidence" \
    "Business Flow Evidence" \
    0 \
    "ready" \
    "optional metadata-only Business Flow Evidence commands, retention links, packets, and verification are available; flow_records=$flow_records" \
    "docs/atlas/BUSINESS_FLOW_EVIDENCE.md" \
    "atlas flow add; atlas flow link-evidence; atlas flow link-finding; atlas flow link-validation; atlas flow link-approval; atlas flow link-retention; atlas flow packet; atlas flow packet --json; atlas flow verify; atlas flow verify --json; atlas flow assurance; atlas flow assurance --json; atlas flow trust-chain; atlas flow trust-chain --json" \
    "optional gate; not required for local production readiness until Business Flow Evidence is promoted to a required pillar"
}

atlas_production_latest_dry_run_note() {
  local production_dir="$LAB_DOCS_DIR/retention/production"

  [ -d "$production_dir" ] || return 0

  find "$production_dir" -maxdepth 1 -type f -name 'PRODUCTION_DRY_RUN_*.md' | sort -V | tail -n 1
}

atlas_production_dry_run_note_valid() {
  local note="$1"
  local expected_commit="$2"

  [ -n "$note" ] || return 1
  [ -f "$note" ] || return 1
  [ -n "$expected_commit" ] || return 1

  grep -q '^# Atlas Production Dry Run$' "$note" &&
    grep -q "^Commit: $expected_commit$" "$note" &&
    grep -q '^Result: retained$' "$note" &&
    grep -q '^QA status: pass$' "$note" &&
    grep -q '^V1 readiness: pass$' "$note" &&
    grep -q '^Production status observed: not-ready$' "$note" &&
    grep -q '^Known blockers:$' "$note" &&
    grep -q 'No production-ready claim is made' "$note"
}

atlas_production_latest_provenance_packet() {
  local release_dir="$LAB_DOCS_DIR/retention/releases"

  [ -d "$release_dir" ] || return 0

  find "$release_dir" -maxdepth 1 -type f -name '*.provenance.json' | sort -V | tail -n 1
}

atlas_production_resolve_release_path() {
  local path="$1"
  local candidate
  local resolved
  local release_dir

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
  release_dir="$(readlink -f "$LAB_DOCS_DIR/retention/releases" 2>/dev/null || true)"
  [ -n "$resolved" ] || return 1
  [ -n "$release_dir" ] || return 1

  case "$resolved" in
  "$release_dir"/*)
    printf '%s\n' "$resolved"
    ;;
  *)
    return 1
    ;;
  esac
}

atlas_production_file_sha256() {
  local path="$1"

  sha256sum "$path" | awk '{ print $1 }'
}

atlas_production_verify_signed_tag() {
  local tag_name="$1"
  local public_key_file="$2"
  local gpg_bin
  local temp_home
  local verify_status=1

  [ -n "$tag_name" ] || return 1
  [ -f "$public_key_file" ] || return 1

  gpg_bin="$(command -v gpg 2>/dev/null || true)"
  [ -n "$gpg_bin" ] || return 1

  temp_home="$(mktemp -d)"
  chmod 700 "$temp_home"
  if GNUPGHOME="$temp_home" "$gpg_bin" --batch --import "$public_key_file" >/dev/null 2>&1 &&
    GNUPGHOME="$temp_home" git -C "$LAB_ROOT" -c gpg.program="$gpg_bin" tag -v "$tag_name" >/dev/null 2>&1; then
    verify_status=0
  fi
  rm -rf "$temp_home"
  return "$verify_status"
}

atlas_production_release_provenance_valid() {
  local provenance_file="$1"
  local expected_commit="$2"
  local packet_path
  local packet_file
  local expected_packet_sha
  local actual_packet_sha
  local public_key_path
  local public_key_file
  local expected_public_key_sha
  local actual_public_key_sha
  local provenance_commit
  local tag_name
  local tag_target
  local recorded_tag_target

  [ -n "$provenance_file" ] || return 1
  [ -f "$provenance_file" ] || return 1
  [ -n "$expected_commit" ] || return 1

  jq -e '
    .schema_version == "atlas.release_provenance.v1" and
    .metadata_only == true and
    .qa.status == "pass" and
    .signed_tag.verification == "verified" and
    (.signed_tag.signer_fingerprint // "" | length > 0) and
    (.signed_tag.public_key_path // "" | length > 0) and
    (.signed_tag.public_key_sha256 // "" | test("^[a-f0-9]{64}$")) and
    (.release_packet.path // "" | length > 0) and
    (.release_packet.sha256 // "" | test("^[a-f0-9]{64}$")) and
    (.production_status.observed // "" | length > 0) and
    (.known_limitations // [] | length > 0) and
    .no_production_overclaim == true and
    (has("raw_runtime_artifacts") | not) and
    (has("target_secrets") | not) and
    (has("session_contents") | not) and
    (has("packet_captures") | not) and
    (has("credential_material") | not) and
    (has("private_keys") | not) and
    (has("tokens") | not) and
    (has("evidence_bodies") | not)
  ' "$provenance_file" >/dev/null 2>&1 || return 1

  provenance_commit="$(jq -r '.commit // ""' "$provenance_file")"
  atlas_release_commit_matches "$provenance_commit" "$expected_commit" || return 1

  packet_path="$(jq -r '.release_packet.path // ""' "$provenance_file")"
  packet_file="$(atlas_production_resolve_release_path "$packet_path")" || return 1
  expected_packet_sha="$(jq -r '.release_packet.sha256 // ""' "$provenance_file")"
  actual_packet_sha="$(atlas_production_file_sha256 "$packet_file")"
  [ "$actual_packet_sha" = "$expected_packet_sha" ] || return 1
  atlas_release_verify_packet "$packet_file" "$expected_commit" >/dev/null 2>&1 || return 1

  tag_name="$(jq -r '.signed_tag.name // ""' "$provenance_file")"
  [ -n "$tag_name" ] || return 1
  git -C "$LAB_ROOT" rev-parse --verify --quiet "refs/tags/$tag_name^{tag}" >/dev/null || return 1
  tag_target="$(git -C "$LAB_ROOT" rev-parse "$tag_name^{}" 2>/dev/null || true)"
  atlas_release_commit_matches "$tag_target" "$expected_commit" || return 1

  recorded_tag_target="$(jq -r '.signed_tag.target // ""' "$provenance_file")"
  atlas_release_commit_matches "$recorded_tag_target" "$expected_commit" || return 1

  public_key_path="$(jq -r '.signed_tag.public_key_path // ""' "$provenance_file")"
  public_key_file="$(atlas_production_resolve_release_path "$public_key_path")" || return 1
  expected_public_key_sha="$(jq -r '.signed_tag.public_key_sha256 // ""' "$provenance_file")"
  actual_public_key_sha="$(atlas_production_file_sha256 "$public_key_file")"
  [ "$actual_public_key_sha" = "$expected_public_key_sha" ] || return 1
  atlas_production_verify_signed_tag "$tag_name" "$public_key_file" || return 1
}

atlas_production_check_signing_provenance() {
  local latest_provenance
  local commit
  local parent_commit

  latest_provenance="$(atlas_production_latest_provenance_packet)"
  if [ -z "$latest_provenance" ]; then
    atlas_production_add_gate \
      "signing_provenance" \
      "Signing And Provenance" \
      1 \
      "blocked" \
      "no signed release provenance packet is retained" \
      "docs/retention/releases/" \
      "git tag -v; atlas release verify; atlas production status" \
      "local signature verification depends on the relevant public key being available"
    return 0
  fi

  commit="$(git -C "$LAB_ROOT" rev-parse HEAD 2>/dev/null || atlas_release_commit)"
  if atlas_production_release_provenance_valid "$latest_provenance" "$commit"; then
    atlas_production_add_gate \
      "signing_provenance" \
      "Signing And Provenance" \
      1 \
      "ready" \
      "latest release provenance verifies a signed tag and release packet for the current commit" \
      "$latest_provenance" \
      "git tag -v; atlas release verify; atlas production status" \
      "local signing is not an external audit or deployment certification"
    return 0
  fi

  parent_commit="$(git -C "$LAB_ROOT" rev-parse HEAD^ 2>/dev/null || true)"
  if [ -n "$parent_commit" ] && atlas_production_release_provenance_valid "$latest_provenance" "$parent_commit"; then
    atlas_production_add_gate \
      "signing_provenance" \
      "Signing And Provenance" \
      1 \
      "ready" \
      "latest release provenance verifies the retained signed release commit before the provenance-retention commit" \
      "$latest_provenance" \
      "git tag -v; atlas release verify --commit $parent_commit; atlas production status" \
      "local signing is not an external audit or deployment certification"
    return 0
  fi

  atlas_production_add_gate \
    "signing_provenance" \
    "Signing And Provenance" \
    1 \
    "blocked" \
    "latest release provenance is missing required fields, has a stale packet hash, lacks a verifiable signed tag, or does not match the release commit" \
    "$latest_provenance" \
    "git tag -v; atlas release verify; atlas production status" \
    "regenerate provenance after release commits, packets, or signing keys change"
}

atlas_production_check_dry_run() {
  local latest_note
  local commit
  local parent_commit

  latest_note="$(atlas_production_latest_dry_run_note)"
  if [ -z "$latest_note" ]; then
    atlas_production_add_gate \
      "production_dry_run" \
      "Production Dry Run" \
      1 \
      "blocked" \
      "no retained production dry-run or external validation note is present" \
      "docs/retention/production/" \
      "future production dry-run checklist" \
      "internal QA does not replace repeated operator dry runs or independent review"
    return 0
  fi

  commit="$(atlas_release_commit)"
  if atlas_production_dry_run_note_valid "$latest_note" "$commit"; then
    atlas_production_add_gate \
      "production_dry_run" \
      "Production Dry Run" \
      1 \
      "ready" \
      "latest production dry-run note verifies against the current commit" \
      "$latest_note" \
      "docs/retention/production/" \
      "dry-run evidence is retained locally and does not replace external audit"
    return 0
  fi

  parent_commit="$(git -C "$LAB_ROOT" rev-parse HEAD^ 2>/dev/null || true)"
  if [ -n "$parent_commit" ] && atlas_production_dry_run_note_valid "$latest_note" "$parent_commit"; then
    atlas_production_add_gate \
      "production_dry_run" \
      "Production Dry Run" \
      1 \
      "ready" \
      "latest production dry-run note verifies against the retained release commit before the dry-run retention commit" \
      "$latest_note" \
      "docs/retention/production/" \
      "dry-run evidence is retained locally and does not replace external audit"
    return 0
  fi

  atlas_production_add_gate \
    "production_dry_run" \
    "Production Dry Run" \
    1 \
    "blocked" \
    "latest production dry-run note is missing required fields or does not match the release commit" \
    "$latest_note" \
    "docs/retention/production/" \
    "dry-run evidence must be regenerated after release commits change"
}

atlas_production_check_future_hardening() {
  atlas_production_check_signing_provenance
  atlas_production_check_dry_run
}

atlas_production_collect() {
  atlas_production_blocked=0
  atlas_production_warnings=0
  atlas_production_required_not_ready=0

  atlas_production_check_v1
  atlas_production_check_repository
  atlas_production_check_release_packet
  atlas_production_check_release_manifest
  atlas_production_check_docs
  atlas_production_check_business_flow_evidence
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

atlas_production_explain_gate_field() {
  local key="$1"
  local field_index="$2"

  awk -F'\t' -v wanted="$key" -v field_index="$field_index" '
    $1 == wanted {
      print $field_index
      exit
    }
  ' "$atlas_production_rows_file"
}

atlas_production_explain_display() {
  local path="$1"

  if [ -z "$path" ]; then
    printf 'missing\n'
    return 0
  fi

  atlas_release_display_path "$path"
}

atlas_production_explain_release_path() {
  local manifest_file="$1"
  local jq_expr="$2"
  local fallback_file="$3"
  local rel=""

  if [ -n "$manifest_file" ] && [ -f "$manifest_file" ]; then
    rel="$(jq -r "$jq_expr // \"\"" "$manifest_file" 2>/dev/null || true)"
  fi

  if [ -n "$rel" ]; then
    printf '%s\n' "$rel"
  else
    atlas_production_explain_display "$fallback_file"
  fi
}

atlas_production_print_explain() {
  local overall="$1"
  local strict="$2"
  local latest_packet
  local latest_manifest
  local latest_provenance
  local latest_dry_run
  local packet_display
  local manifest_display
  local provenance_display
  local dry_run_display
  local public_key_display
  local release_commit=""
  local tag_name=""
  local v1_status
  local v1_reason
  local packet_cmd
  local manifest_cmd
  local tag_cmd
  local replay_cmd

  latest_packet="$(atlas_release_latest_packet)"
  latest_manifest="$(atlas_release_latest_manifest)"
  latest_provenance="$(atlas_production_latest_provenance_packet)"
  latest_dry_run="$(atlas_production_latest_dry_run_note)"

  packet_display="$(atlas_production_explain_release_path "$latest_manifest" '.release_packet.path' "$latest_packet")"
  manifest_display="$(atlas_production_explain_display "$latest_manifest")"
  provenance_display="$(atlas_production_explain_release_path "$latest_manifest" '.provenance.path' "$latest_provenance")"
  dry_run_display="$(atlas_production_explain_release_path "$latest_manifest" '.production_dry_run.path' "$latest_dry_run")"
  public_key_display="$(atlas_production_explain_release_path "$latest_manifest" '.signing_public_key.path' "")"

  if [ -n "$latest_packet" ] && [ -f "$latest_packet" ]; then
    release_commit="$(atlas_release_packet_commit "$latest_packet")"
    if [ -n "$release_commit" ]; then
      release_commit="$(atlas_release_full_commit "$release_commit" 2>/dev/null || printf '%s\n' "$release_commit")"
    fi
  fi
  if [ -z "$release_commit" ] && [ -n "$latest_manifest" ] && [ -f "$latest_manifest" ]; then
    release_commit="$(jq -r '.release.commit // ""' "$latest_manifest" 2>/dev/null || true)"
  fi

  if [ -n "$latest_manifest" ] && [ -f "$latest_manifest" ]; then
    tag_name="$(jq -r '.signed_tag.name // ""' "$latest_manifest" 2>/dev/null || true)"
  fi
  if [ -z "$tag_name" ] && [ -n "$latest_provenance" ] && [ -f "$latest_provenance" ]; then
    tag_name="$(jq -r '.signed_tag.name // ""' "$latest_provenance" 2>/dev/null || true)"
  fi

  v1_status="$(atlas_production_explain_gate_field v1_internal_readiness 4)"
  v1_reason="$(atlas_production_explain_gate_field v1_internal_readiness 5)"

  if [ "$packet_display" != "missing" ] && [ -n "$release_commit" ]; then
    packet_cmd="./tools/atlas/bin/atlas release verify $packet_display --commit $release_commit"
    replay_cmd="./tools/atlas/bin/atlas release replay $packet_display --json"
  else
    packet_cmd="unavailable - release packet missing"
    replay_cmd="unavailable - release packet missing"
  fi

  if [ "$manifest_display" != "missing" ] && [ -n "$release_commit" ]; then
    manifest_cmd="./tools/atlas/bin/atlas release manifest-verify $manifest_display --commit $release_commit"
  else
    manifest_cmd="unavailable - release artifact manifest missing"
  fi

  if [ -n "$tag_name" ]; then
    tag_cmd="git tag -v $tag_name"
  else
    tag_cmd="unavailable - signed tag missing"
  fi

  ui_heading "Atlas Production Status Explanation"
  ui_rule
  ui_kv "Root" "$LAB_ROOT"
  ui_kv "Commit" "$(atlas_release_commit)"
  ui_kv "Runtime Target" "$LAB_RUNTIME_TARGET"
  ui_kv "Strict" "$strict"
  if [ "$overall" = "production-ready" ]; then
    ui_kv "Overall" "production-ready under the local Atlas contract"
  else
    ui_kv "Overall" "$overall"
  fi
  ui_kv "V1 Readiness" "${v1_status:-missing} - ${v1_reason:-missing}"
  ui_rule

  ui_subheading "Retained Evidence"
  ui_kv "Release Packet" "$packet_display"
  ui_kv "Release Artifact Manifest" "$manifest_display"
  ui_kv "Signed Provenance" "$provenance_display"
  ui_kv "Signed Tag" "${tag_name:-missing}"
  ui_kv "Signing Public Key" "$public_key_display"
  ui_kv "Production Dry-Run Note" "$dry_run_display"
  ui_rule

  ui_subheading "Verification Commands"
  ui_kv "V1 Readiness" "./tools/atlas/bin/atlas v1 status --strict"
  ui_kv "Release Packet Verify" "$packet_cmd"
  ui_kv "Manifest Verify" "$manifest_cmd"
  ui_kv "Signed Tag Verify" "$tag_cmd"
  ui_kv "Release Replay" "$replay_cmd"
  ui_kv "Production Status JSON" "./tools/atlas/bin/atlas production status --json"
  ui_rule

  ui_subheading "Gate Details"
  printf '%-28s %-16s %-10s %s\n' "GATE" "STATUS" "REQUIRED" "REASON"
  awk -F'\t' '{
    required = ($3 == "1" ? "yes" : "no")
    printf "%-28s %-16s %-10s %s\n", $2, $4, required, $5
  }' "$atlas_production_rows_file"
  ui_rule

  ui_subheading "Known Limitations"
  printf -- '- Production readiness is a local Atlas contract based on retained metadata evidence.\n'
  printf -- '- Explain output is a reviewer aid, not an external certification result.\n'
  printf -- '- Release replay re-checks retained release trust evidence; it does not prove runtime safety or production deployability.\n'
  printf -- '- Metadata-only packets do not embed raw runtime artifacts, secrets, customer data, packet captures, request or response bodies, payment data, raw business records, or unredacted evidence bodies.\n'
  ui_rule

  ui_subheading "Non-Guarantees"
  printf -- '- not external audit\n'
  printf -- '- not certification\n'
  printf -- '- not legal compliance\n'
  printf -- '- not tamper-proof infrastructure\n'
  printf -- '- not enterprise deployment approval\n'
  printf -- '- not external SLSA certification\n'
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
  local explain=0
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
    --explain)
      explain=1
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
      fail "production status [--strict] [--json] [--explain]"
      ;;
    esac
  done
  [ "$#" -eq 0 ] || fail "production status [--strict] [--json] [--explain]"
  if [ "$json" -eq 1 ] && [ "$explain" -eq 1 ]; then
    fail "production status cannot combine --json and --explain"
  fi

  atlas_production_rows_file="$(mktemp)"
  atlas_production_collect
  overall="$(atlas_production_overall)"

  if [ "$json" -eq 1 ]; then
    atlas_production_print_json "$overall" "$strict"
  elif [ "$explain" -eq 1 ]; then
    atlas_production_print_explain "$overall" "$strict"
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
