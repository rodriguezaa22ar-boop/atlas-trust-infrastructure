#!/usr/bin/env bash

atlas_reviewer_package_root() {
  printf '%s/retention/reviewer-packages\n' "$LAB_DOCS_DIR"
}

atlas_reviewer_package_forbidden_path() {
  local path="$1"
  local lowered

  lowered="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"
  case "$lowered" in
  *secret* | *credential* | *token* | *private-key* | *private_key* | *session-cookie* | *packet-capture* | *pcap* | *raw-invoice* | *raw_invoice* | *raw-contract* | *raw_contract* | *customer-data* | *customer_data* | *payment-data* | *payment_data* | *request-body* | *request_body* | *response-body* | *response_body* | *runtime-artifact* | *runtime_artifact* | *unredacted*)
    return 0
    ;;
  esac
  return 1
}

atlas_reviewer_package_require_file() {
  local source_path="$1"
  local resolved

  resolved="$(atlas_release_resolve_repo_file "$source_path" 2>/dev/null || true)"
  [ -n "$resolved" ] || fail "reviewer package missing required file: $source_path"
  if atlas_reviewer_package_forbidden_path "$(atlas_release_display_path "$resolved")"; then
    fail "reviewer package rejected forbidden sensitive path: $(atlas_release_display_path "$resolved")"
  fi
  printf '%s\n' "$resolved"
}

atlas_reviewer_package_add_item() {
  local items_file="$1"
  local kind="$2"
  local source_path="$3"
  local package_path="$4"
  local sha256="$5"
  local required="$6"

  jq -n \
    --arg kind "$kind" \
    --arg source_path "$source_path" \
    --arg package_path "$package_path" \
    --arg sha256 "$sha256" \
    --argjson required "$required" \
    '{
      kind: $kind,
      source_path: $source_path,
      package_path: $package_path,
      sha256: $sha256,
      required: $required
    }' >>"$items_file"
}

atlas_reviewer_package_copy_file() {
  local items_file="$1"
  local package_dir="$2"
  local kind="$3"
  local source_path="$4"
  local required="$5"
  local source_file
  local source_rel
  local package_rel
  local dest
  local sha256

  source_file="$(atlas_reviewer_package_require_file "$source_path")"
  source_rel="$(atlas_release_display_path "$source_file")"
  package_rel="files/$source_rel"
  dest="$package_dir/$package_rel"
  mkdir -p "$(dirname "$dest")"
  cp "$source_file" "$dest"
  sha256="$(atlas_release_file_sha256 "$source_file")"
  atlas_reviewer_package_add_item "$items_file" "$kind" "$source_rel" "$package_rel" "$sha256" "$required"
}

atlas_reviewer_package_write_readme() {
  local file="$1"
  local package_name="$2"
  local generated="$3"
  local release_commit="$4"
  local release_tag="$5"
  local release_packet_rel="$6"
  local provenance_rel="$7"
  local manifest_rel="$8"
  local dry_run_rel="$9"
  local milestone_rel="${10}"

  cat >"$file" <<EOF
# Atlas External Reviewer Package

Generated: $generated
Package: $package_name
Release commit: $release_commit
Release tag: $release_tag

## Purpose

This package gives an outside reviewer a self-contained, metadata-only starting
point for reviewing Atlas' public trust model, public case studies, release
trust evidence, signed provenance, release artifact manifest, production
dry-run evidence, known limitations, and verification commands.

## Included Release Evidence

- Release packet: \`$release_packet_rel\`
- Signed provenance packet: \`$provenance_rel\`
- Release artifact manifest: \`$manifest_rel\`
- Production dry-run note: \`$dry_run_rel\`
- Latest retained milestone note: \`$milestone_rel\`

## Metadata-Only Boundary

This package includes documentation and retained metadata packets. It does not
include secrets, credentials, session cookies, raw target data, raw customer
data, payment data, raw invoices, raw contracts, packet captures, full request
or response bodies, raw runtime artifacts, unredacted evidence bodies, or
sensitive business records.

## Non-Guarantees

- This is not external audit.
- This is not certification.
- This is not legal compliance.
- This is not tamper-proof infrastructure.
- This does not certify SLSA status, payment approval, fraud prevention,
  enterprise deployment approval, or production security.

## Review Order

1. Read \`files/README.md\` and \`files/docs/ATLAS_ONE_PAGE.md\`.
2. Read the release trust and business-flow case studies.
3. Inspect \`REVIEWER_PACKAGE_MANIFEST.json\`.
4. Run the commands in \`VERIFICATION_COMMANDS.md\` from the repository root.
5. Compare any review conclusion against the known limitations and
   responsible-use boundary included in this package.
EOF
}

atlas_reviewer_package_write_commands() {
  local file="$1"
  local release_packet_rel="$2"
  local manifest_rel="$3"
  local release_commit="$4"
  local release_tag="$5"

  cat >"$file" <<EOF
# Atlas Reviewer Verification Commands

Run these commands from the repository root that generated the package.

\`\`\`bash
./tools/atlas/bin/atlas v1 status --strict
./tools/atlas/bin/atlas production status --strict
./tools/atlas/bin/atlas release verify $release_packet_rel --commit $release_commit
./tools/atlas/bin/atlas release manifest-verify $manifest_rel --commit $release_commit
git tag -v $release_tag
\`\`\`

These commands verify local Atlas readiness, the retained release packet, the
retained release artifact manifest, and the signed tag. They do not create
external audit, certification, legal compliance, or tamper-proof infrastructure.
EOF
}

atlas_reviewer_package_manifest() {
  local file="$1"
  local package_name="$2"
  local generated="$3"
  local release_commit="$4"
  local release_tag="$5"
  local output_path="$6"
  local release_packet_rel="$7"
  local provenance_rel="$8"
  local manifest_rel="$9"
  local dry_run_rel="${10}"
  local milestone_rel="${11}"
  local items_json="${12}"
  local package_manifest_rel

  package_manifest_rel="$(atlas_release_display_path "$file")"

  jq -n \
    --arg generated "$generated" \
    --arg package "$package_name" \
    --arg source_commit "$(git -C "$LAB_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')" \
    --arg source_branch "$(atlas_release_branch)" \
    --arg output_path "$(atlas_release_display_path "$output_path")" \
    --arg manifest_path "$package_manifest_rel" \
    --arg release_commit "$release_commit" \
    --arg release_tag "$release_tag" \
    --arg release_packet "$release_packet_rel" \
    --arg provenance "$provenance_rel" \
    --arg artifact_manifest "$manifest_rel" \
    --arg dry_run "$dry_run_rel" \
    --arg milestone "$milestone_rel" \
    --slurpfile files "$items_json" \
    '{
      schema_version: "atlas.external_reviewer_package.v1",
      generated: $generated,
      package: $package,
      metadata_only: true,
      raw_artifacts_embedded: false,
      source: {
        commit: $source_commit,
        branch: $source_branch
      },
      output_path: $output_path,
      package_manifest_path: $manifest_path,
      release: {
        commit: $release_commit,
        tag: $release_tag
      },
      latest_release_evidence: {
        release_packet: $release_packet,
        signed_provenance: $provenance,
        release_artifact_manifest: $artifact_manifest,
        production_dry_run: $dry_run,
        milestone_note: $milestone
      },
      files: $files[0],
      metadata_boundary: {
        stores: [
          "documentation paths",
          "retained packet paths",
          "SHA-256 hashes",
          "commit ids",
          "tag names",
          "verification commands",
          "known limitations"
        ],
        excludes: [
          "secrets",
          "credentials",
          "session cookies",
          "raw target data",
          "raw customer data",
          "payment data",
          "raw invoices",
          "raw contracts",
          "packet captures",
          "full request or response bodies",
          "raw runtime artifacts",
          "unredacted evidence bodies"
        ]
      },
      verification_commands: [
        "./tools/atlas/bin/atlas v1 status --strict",
        "./tools/atlas/bin/atlas production status --strict",
        "./tools/atlas/bin/atlas release verify " + $release_packet + " --commit " + $release_commit,
        "./tools/atlas/bin/atlas release manifest-verify " + $artifact_manifest + " --commit " + $release_commit,
        "git tag -v " + $release_tag
      ],
      non_guarantees: [
        "not external audit",
        "not certification",
        "not legal compliance",
        "not tamper-proof infrastructure",
        "not external SLSA certification",
        "not enterprise deployment approval"
      ],
      known_limitations: [
        "The reviewer package is generated from retained local Atlas evidence.",
        "The package is metadata-only and does not include raw runtime artifacts or sensitive business contents.",
        "External review still requires an independent reviewer to run checks and record conclusions.",
        "Atlas production readiness remains bounded to the local Atlas contract."
      ],
      no_external_audit_claim: true,
      no_certification_claim: true,
      no_legal_compliance_claim: true,
      no_tamper_proof_claim: true
    }' >"$file"
}

cmd_reviewer_package() {
  need_args 1 "$#" "reviewer package <name>"

  local package_name="$1"
  local package_slug
  local package_dir
  local generated
  local manifest_file
  local manifest_rel
  local release_commit
  local release_tag
  local release_packet_rel
  local provenance_rel
  local dry_run_rel
  local milestone_rel
  local release_packet_file
  local provenance_file
  local dry_run_file
  local milestone_file
  local temp_dir
  local items_file
  local files_json
  local package_manifest
  local package_readme
  local verification_commands
  local signing_public_key_rel
  local slsa_rel

  package_slug="$(slugify "$package_name")"
  [ -n "$package_slug" ] || fail "reviewer package name produced an empty slug"
  package_dir="$(atlas_reviewer_package_root)/$package_slug"
  generated="$(timestamp)"

  manifest_file="$(atlas_release_latest_manifest)"
  [ -n "$manifest_file" ] || fail "reviewer package requires a retained release artifact manifest"
  manifest_rel="$(atlas_release_display_path "$manifest_file")"
  release_commit="$(jq -r '.release.commit // ""' "$manifest_file")"
  [ -n "$release_commit" ] || fail "reviewer package requires release artifact manifest release.commit"
  release_commit="$(atlas_release_full_commit "$release_commit")" || fail "reviewer package could not resolve release commit: $release_commit"
  release_tag="$(jq -r '.signed_tag.name // ""' "$manifest_file")"
  [ -n "$release_tag" ] || fail "reviewer package requires release artifact manifest signed tag"

  release_packet_rel="$(jq -r '.release_packet.path // ""' "$manifest_file")"
  [ -n "$release_packet_rel" ] || fail "reviewer package requires a retained release packet"
  release_packet_file="$(atlas_release_resolve_repo_file "$release_packet_rel" 2>/dev/null || true)"
  [ -n "$release_packet_file" ] || fail "reviewer package requires a retained release packet: $release_packet_rel"

  provenance_rel="$(jq -r '.provenance.path // ""' "$manifest_file")"
  [ -n "$provenance_rel" ] || fail "reviewer package requires a retained provenance packet"
  provenance_file="$(atlas_release_resolve_repo_file "$provenance_rel" 2>/dev/null || true)"
  [ -n "$provenance_file" ] || fail "reviewer package requires a retained provenance packet: $provenance_rel"

  dry_run_rel="$(jq -r '.production_dry_run.path // ""' "$manifest_file")"
  [ -n "$dry_run_rel" ] || fail "reviewer package requires a retained production dry-run note"
  dry_run_file="$(atlas_release_resolve_repo_file "$dry_run_rel" 2>/dev/null || true)"
  [ -n "$dry_run_file" ] || fail "reviewer package requires a retained production dry-run note: $dry_run_rel"

  milestone_rel="$(jq -r '.milestone_note.path // ""' "$manifest_file")"
  [ -n "$milestone_rel" ] || fail "reviewer package requires a retained milestone note"
  milestone_file="$(atlas_release_resolve_repo_file "$milestone_rel" 2>/dev/null || true)"
  [ -n "$milestone_file" ] || fail "reviewer package requires a retained milestone note: $milestone_rel"

  atlas_release_verify_packet "$release_packet_file" "$release_commit" >/dev/null 2>&1 ||
    fail "reviewer package requires a verifiable retained release packet: $release_packet_rel"
  atlas_release_manifest_verify_packet "$manifest_file" "$release_commit" >/dev/null 2>&1 ||
    fail "reviewer package requires a verifiable retained release artifact manifest: $manifest_rel"
  atlas_production_release_provenance_valid "$provenance_file" "$release_commit" ||
    fail "reviewer package requires verifiable signed provenance: $provenance_rel"

  rm -rf "$package_dir"
  mkdir -p "$package_dir/files"
  chmod 700 "$package_dir" "$package_dir/files" 2>/dev/null || true

  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN
  items_file="$temp_dir/items.ndjson"
  files_json="$temp_dir/files.json"
  : >"$items_file"

  package_readme="$package_dir/README.md"
  verification_commands="$package_dir/VERIFICATION_COMMANDS.md"
  package_manifest="$package_dir/REVIEWER_PACKAGE_MANIFEST.json"

  atlas_reviewer_package_write_readme "$package_readme" "$package_slug" "$generated" "$release_commit" "$release_tag" "$release_packet_rel" "$provenance_rel" "$manifest_rel" "$dry_run_rel" "$milestone_rel"
  atlas_reviewer_package_write_commands "$verification_commands" "$release_packet_rel" "$manifest_rel" "$release_commit" "$release_tag"

  atlas_reviewer_package_add_item "$items_file" "package_readme" "generated" "README.md" "$(atlas_release_file_sha256 "$package_readme")" true
  atlas_reviewer_package_add_item "$items_file" "verification_commands" "generated" "VERIFICATION_COMMANDS.md" "$(atlas_release_file_sha256 "$verification_commands")" true

  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "public_readme" "README.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "atlas_one_page" "docs/ATLAS_ONE_PAGE.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "trust_lifecycle" "docs/TRUST_LIFECYCLE.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "release_trust" "docs/RELEASE_TRUST.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "slsa_claim" "docs/atlas/SLSA_CLAIM.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "production_readiness" "docs/atlas/PRODUCTION_READINESS.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "known_limitations" "docs/KNOWN_LIMITATIONS.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "responsible_use" "docs/RESPONSIBLE_USE.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "release_trust_case_study" "docs/case-studies/CASE_STUDY_RELEASE_TRUST.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "vendor_payment_change_case_study" "docs/case-studies/CASE_STUDY_VENDOR_PAYMENT_CHANGE.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "external_reviewer_package_contract" "docs/atlas/EXTERNAL_REVIEWER_PACKAGE.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "external_reviewer_package_schema" "docs/schemas/external-reviewer-package.v1.md" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "release_packet" "$release_packet_rel" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "release_provenance" "$provenance_rel" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "release_artifact_manifest" "$manifest_rel" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "production_dry_run" "$dry_run_rel" true
  atlas_reviewer_package_copy_file "$items_file" "$package_dir" "milestone_note" "$milestone_rel" true

  signing_public_key_rel="$(jq -r '.signing_public_key.path // ""' "$manifest_file")"
  if [ -n "$signing_public_key_rel" ]; then
    atlas_reviewer_package_copy_file "$items_file" "$package_dir" "signing_public_key" "$signing_public_key_rel" true
  fi

  slsa_rel="$(jq -r '.slsa_provenance.path // ""' "$manifest_file")"
  if [ -n "$slsa_rel" ] && [ "$slsa_rel" != "null" ]; then
    atlas_reviewer_package_copy_file "$items_file" "$package_dir" "slsa_provenance" "$slsa_rel" false
  fi

  jq -s '.' "$items_file" >"$files_json"
  atlas_reviewer_package_manifest "$package_manifest" "$package_slug" "$generated" "$release_commit" "$release_tag" "$package_dir" "$release_packet_rel" "$provenance_rel" "$manifest_rel" "$dry_run_rel" "$milestone_rel" "$files_json"
  jq -e '.schema_version == "atlas.external_reviewer_package.v1" and .metadata_only == true and .raw_artifacts_embedded == false' "$package_manifest" >/dev/null

  ui_ok "reviewer package written"
  printf 'reviewer_package: %s\n' "$package_dir"
  printf 'reviewer_manifest: %s\n' "$package_manifest"
  printf 'verification_commands: %s\n' "$verification_commands"
}
