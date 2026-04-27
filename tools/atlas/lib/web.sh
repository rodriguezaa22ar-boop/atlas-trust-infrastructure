#!/usr/bin/env bash

atlas_web_curl_bin() {
  printf '%s\n' "${LAB_ATLAS_CURL_BIN:-${ATLAS_WEB_CURL_BIN:-curl}}"
}

atlas_web_validate_url() {
  case "$1" in
  http://* | https://*)
    return 0
    ;;
  *)
    fail "web assess requires an http:// or https:// URL"
    ;;
  esac
}

atlas_web_url_scheme() {
  printf '%s\n' "${1%%://*}"
}

atlas_web_url_hostport() {
  local rest

  rest="${1#*://}"
  printf '%s\n' "${rest%%/*}"
}

atlas_web_url_host() {
  local hostport

  hostport="$(atlas_web_url_hostport "$1")"
  printf '%s\n' "${hostport%%:*}"
}

atlas_web_url_origin() {
  local scheme
  local hostport

  scheme="$(atlas_web_url_scheme "$1")"
  hostport="$(atlas_web_url_hostport "$1")"
  printf '%s://%s\n' "$scheme" "$hostport"
}

atlas_web_http_origin() {
  local hostport

  hostport="$(atlas_web_url_hostport "$1")"
  printf 'http://%s\n' "$hostport"
}

atlas_web_target_file() {
  local target_name="$1"
  local target_slug

  target_slug="$(slugify "$target_name")"
  [ -n "$target_slug" ] || fail "web target name produced an empty slug"
  printf '%s/%s.env\n' "$LAB_TARGETS_DIR" "$target_slug"
}

atlas_web_validate_scope_status() {
  case "$1" in
  unknown | review | in-scope | out-of-scope)
    return 0
    ;;
  *)
    fail "expected web target scope status unknown, review, in-scope, or out-of-scope; got: $1"
    ;;
  esac
}

atlas_web_validate_criticality() {
  case "$1" in
  unknown | low | medium | high | critical)
    return 0
    ;;
  *)
    fail "expected web target criticality unknown, low, medium, high, or critical; got: $1"
    ;;
  esac
}

atlas_web_ensure_target() {
  local target_name="$1"
  local target_address="$2"
  local scope_status="$3"
  local criticality="$4"
  local owner="$5"
  local target_file

  mkdir -p "$LAB_TARGETS_DIR"
  target_file="$(atlas_web_target_file "$target_name")"
  if [ -f "$target_file" ]; then
    printf '%s\n' "$target_file"
    return 0
  fi

  : >"$target_file"
  chmod 600 "$target_file" 2>/dev/null || true
  upsert_env "$target_file" NAME "$target_name"
  upsert_env "$target_file" ADDRESS "$target_address"
  upsert_env "$target_file" SCOPE_STATUS "$scope_status"
  upsert_env "$target_file" CRITICALITY "$criticality"
  upsert_env "$target_file" TAGS "web public"
  upsert_env "$target_file" OWNER "$owner"
  upsert_env "$target_file" NOTES "created by atlas web assess for $target_address"
  upsert_env "$target_file" CREATED_AT "$(timestamp)"
  printf '%s\n' "$target_file"
}

atlas_web_extract_header_value() {
  local file="$1"
  local header_name="$2"

  awk -F': *' -v key="$header_name" '
    BEGIN { IGNORECASE = 1 }
    tolower($1) == tolower(key) {
      value = substr($0, index($0, ":") + 1)
      sub(/^[[:space:]]+/, "", value)
      sub(/\r$/, "", value)
      print value
      exit
    }
  ' "$file"
}

atlas_web_extract_http_status() {
  local file="$1"

  awk '
    toupper($1) ~ /^HTTP/ {
      status = $2
    }
    END {
      if (status != "") {
        print status
      }
    }
  ' "$file"
}

atlas_web_extract_html_title() {
  local file="$1"

  tr '\n' ' ' <"$file" |
    sed -nE 's/.*<[Tt][Ii][Tt][Ll][Ee][^>]*>([^<]+)<\/[Tt][Ii][Tt][Ll][Ee]>.*/\1/p' |
    head -n 1 |
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

atlas_web_success_status() {
  case "$1" in
  2* | 3*) return 0 ;;
  *) return 1 ;;
  esac
}

atlas_web_ok_status() {
  case "$1" in
  2*) return 0 ;;
  *) return 1 ;;
  esac
}

atlas_web_missing_security_headers() {
  local headers_file="$1"
  local scheme="$2"
  local missing=()
  local header

  for header in \
    Content-Security-Policy \
    X-Frame-Options \
    X-Content-Type-Options \
    Referrer-Policy \
    Permissions-Policy; do
    if [ -z "$(atlas_web_extract_header_value "$headers_file" "$header")" ]; then
      missing+=("$header")
    fi
  done

  if [ "$scheme" = "https" ] && [ -z "$(atlas_web_extract_header_value "$headers_file" "Strict-Transport-Security")" ]; then
    missing+=("Strict-Transport-Security")
  fi

  (
    IFS=,
    printf '%s\n' "${missing[*]:-}"
  )
}

atlas_web_routes() {
  cat <<'EOF'
/
/robots.txt
/sitemap.xml
/.well-known/security.txt
/login
/admin
/wp-login.php
EOF
}

atlas_web_append_path() {
  local origin="${1%/}"
  local path="$2"

  if [ "$path" = "/" ]; then
    printf '%s/\n' "$origin"
  else
    printf '%s%s\n' "$origin" "$path"
  fi
}

atlas_web_fetch_url() {
  local url="$1"
  local path="$2"
  local out_dir="$3"
  local timeout="$4"
  local route_file="$5"
  local curl_bin
  local route_slug
  local headers_file
  local body_file
  local err_file
  local status_code="000"
  local content_type=""
  local server=""
  local location=""
  local title=""
  local missing_headers=""
  local body_sha=""
  local body_size="0"
  local curl_status="ok"
  local scheme

  curl_bin="$(atlas_web_curl_bin)"
  command -v "$curl_bin" >/dev/null 2>&1 || fail "command not found: $curl_bin"

  route_slug="$(slugify "${path:-root}")"
  [ -n "$route_slug" ] || route_slug="root"
  headers_file="$out_dir/$route_slug.headers"
  body_file="$out_dir/$route_slug.body"
  err_file="$out_dir/$route_slug.err"

  if "$curl_bin" -sS --max-time "$timeout" -D "$headers_file" -o "$body_file" "$url" 2>"$err_file"; then
    status_code="$(atlas_web_extract_http_status "$headers_file")"
    [ -n "$status_code" ] || status_code="000"
    content_type="$(atlas_web_extract_header_value "$headers_file" "Content-Type")"
    server="$(atlas_web_extract_header_value "$headers_file" "Server")"
    location="$(atlas_web_extract_header_value "$headers_file" "Location")"
    title="$(atlas_web_extract_html_title "$body_file")"
    body_sha="$(atlas_evidence_hash_path "$body_file")"
    body_size="$(wc -c <"$body_file" | tr -d ' ')"
    scheme="$(atlas_web_url_scheme "$url")"
    if [ "$path" = "/" ]; then
      missing_headers="$(atlas_web_missing_security_headers "$headers_file" "$scheme")"
    fi
  else
    curl_status="failed"
    : >"$headers_file"
    : >"$body_file"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$path" \
    "$url" \
    "$status_code" \
    "$content_type" \
    "$server" \
    "$location" \
    "$title" \
    "$missing_headers" \
    "$body_size" \
    "$body_sha" \
    "$curl_status" \
    "$headers_file" >>"$route_file"
}

atlas_web_write_summary() {
  local file="$1"
  local url="$2"
  local origin="$3"
  local http_origin="$4"
  local routes_file="$5"
  local finding_count="$6"

  {
    printf '# Atlas Web Assessment Packet\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    printf 'URL: %s\n' "$url"
    printf 'Origin: %s\n' "$origin"
    printf 'HTTP Origin Checked: %s\n' "$http_origin"
    printf 'Finding Count: %s\n' "$finding_count"
    printf '\nNo raw response bodies are embedded in this packet. Route bodies and headers are retained as local operation artifacts.\n'
    printf '\n## Route Checks\n\n'
    printf '| Path | URL | Status | Content-Type | Server | Location | Missing Security Headers |\n'
    printf '| --- | --- | --- | --- | --- | --- | --- |\n'
    awk -F'\t' '{
      missing = $8 == "" ? "-" : $8
      location = $6 == "" ? "-" : $6
      server = $5 == "" ? "-" : $5
      ctype = $4 == "" ? "-" : $4
      printf "| `%s` | `%s` | %s | %s | %s | %s | %s |\n", $1, $2, $3, ctype, server, location, missing
    }' "$routes_file"
    printf '\n## Retained Files\n\n'
    printf -- "- Routes TSV: \`%s\`\n" "$routes_file"
    printf -- "- Operation directory: \`%s\`\n" "$ATLAS_OP_DIR"
  } >"$file"
}

atlas_web_route_value() {
  local routes_file="$1"
  local path="$2"
  local field="$3"

  awk -F'\t' -v wanted="$path" -v field="$field" '$1 == wanted { print $field; exit }' "$routes_file"
}

atlas_web_routes_matching_shell_count() {
  local routes_file="$1"

  awk -F'\t' '
    ($1 == "/robots.txt" || $1 == "/sitemap.xml" || $1 == "/.well-known/security.txt") &&
    $3 ~ /^2/ &&
    tolower($4) ~ /text\/html/ {
      count++
    }
    END { print count + 0 }
  ' "$routes_file"
}

atlas_web_admin_route_count() {
  local routes_file="$1"

  awk -F'\t' '
    ($1 == "/admin" || $1 == "/wp-login.php") &&
    $3 ~ /^2/ {
      count++
    }
    END { print count + 0 }
  ' "$routes_file"
}

atlas_web_add_finding() {
  local title="$1"
  local severity="$2"
  local recommendation="$3"
  local evidence_id="$4"
  local output

  output="$(
    cmd_finding_add "$title" \
      --level observed \
      --severity "$severity" \
      --confidence high \
      --evidence "$evidence_id" \
      --recommendation "$recommendation"
  )"
  printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }'
}

atlas_web_publish_intel() {
  local target="$1"
  local routes_file="$2"
  local route_path
  local url
  local status_code
  local content_type
  local server
  local title
  local missing_headers
  local payload

  while IFS=$'\t' read -r route_path url status_code content_type server _ title missing_headers _ _ _ _; do
    [ -n "$url" ] || continue
    if [ "$route_path" = "/" ]; then
      payload="$(
        jq -cn \
          --arg observed_at "$(timestamp)" \
          --arg target "$target" \
          --arg endpoint "$url" \
          --arg status_code "$status_code" \
          --arg server "$server" \
          --arg title "$title" \
          '{
            observed_at: $observed_at,
            source_tool: "atlas",
            source_kind: "web-assessment",
            source_name: "web-assess",
            target: $target,
            observation_type: "web_probe",
            confidence: "medium",
            value: {
              endpoint: $endpoint,
              status_code: $status_code,
              server: $server,
              title: $title,
              detail: (($server + " " + $title) | gsub("^ +| +$"; ""))
            }
          }'
      )"
      intel_append_record observations "$payload"
    fi

    if [ -n "$missing_headers" ]; then
      payload="$(
        jq -cn \
          --arg observed_at "$(timestamp)" \
          --arg target "$target" \
          --arg url "$url" \
          --arg detail "$missing_headers" \
          '{
            observed_at: $observed_at,
            source_tool: "atlas",
            source_kind: "web-assessment",
            source_name: "web-assess",
            target: $target,
            observation_type: "http_posture_finding",
            confidence: "medium",
            value: {
              severity: "low",
              label: "missing-security-headers",
              url: $url,
              detail: $detail
            }
          }'
      )"
      intel_append_record observations "$payload"
    fi
  done <"$routes_file"
}

cmd_web_assess() {
  need_args 1 "$#" "web assess <url> [assessment-name] [--target name] [--scope-status status] [--criticality level] [--owner owner] [--timeout seconds]"
  local url="$1"
  local assessment_name=""
  local target_name=""
  local scope_status="review"
  local criticality="medium"
  local owner=""
  local timeout="8"
  local host
  local origin
  local http_origin
  local target_file
  local operation_output
  local op_slug
  local assess_dir
  local routes_file
  local summary_file
  local route_path
  local route_url
  local http_headers
  local http_body
  local http_routes_file
  local summary_evidence_output
  local routes_evidence_output
  local summary_evidence_id
  local routes_evidence_id
  local finding_ids=()
  local missing_headers
  local http_status
  local http_location
  local metadata_shell_count
  local admin_route_count
  local bundle_output
  local bundle_dir
  local report_output
  local report_path
  local handoff_output
  local handoff_path

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --target)
      need_args 2 "$#" "web assess <url> --target <name>"
      target_name="$2"
      shift 2
      ;;
    --scope-status)
      need_args 2 "$#" "web assess <url> --scope-status <status>"
      scope_status="$2"
      shift 2
      ;;
    --criticality)
      need_args 2 "$#" "web assess <url> --criticality <level>"
      criticality="$2"
      shift 2
      ;;
    --owner)
      need_args 2 "$#" "web assess <url> --owner <owner>"
      owner="$2"
      shift 2
      ;;
    --timeout)
      need_args 2 "$#" "web assess <url> --timeout <seconds>"
      timeout="$2"
      shift 2
      ;;
    -*)
      fail "unknown web assess option: $1"
      ;;
    *)
      if [ -n "$assessment_name" ]; then
        fail "web assess <url> [assessment-name] [--target name] [--scope-status status] [--criticality level] [--owner owner] [--timeout seconds]"
      fi
      assessment_name="$1"
      shift
      ;;
    esac
  done

  atlas_web_validate_url "$url"
  host="$(atlas_web_url_host "$url")"
  origin="$(atlas_web_url_origin "$url")"
  http_origin="$(atlas_web_http_origin "$url")"
  [ -n "$target_name" ] || target_name="$host"
  [ -n "$assessment_name" ] || assessment_name="web-assessment-$host"
  atlas_web_validate_scope_status "$scope_status"
  atlas_web_validate_criticality "$criticality"

  target_file="$(atlas_web_ensure_target "$target_name" "$origin" "$scope_status" "$criticality" "$owner")"
  operation_output="$(cmd_op_start "$assessment_name" "$target_name" "web assessment packetization for $origin")"
  op_slug="$(printf '%s\n' "$operation_output" | awk -F': ' '$1 == "active_operation" { print $2; exit }')"
  [ -n "$op_slug" ] || fail "unable to determine web assessment operation id"
  load_atlas_operation "$op_slug"

  assess_dir="$ATLAS_OP_DIR/web-assessment"
  mkdir -p "$assess_dir"
  chmod 700 "$assess_dir" 2>/dev/null || true
  routes_file="$assess_dir/routes.tsv"
  summary_file="$assess_dir/summary.md"
  : >"$routes_file"
  chmod 600 "$routes_file" 2>/dev/null || true

  http_routes_file="$assess_dir/http-origin.tsv"
  : >"$http_routes_file"
  http_headers="$assess_dir/http-origin.headers"
  http_body="$assess_dir/http-origin.body"
  atlas_web_fetch_url "$http_origin/" "http-origin" "$assess_dir" "$timeout" "$http_routes_file"

  while IFS= read -r route_path; do
    [ -n "$route_path" ] || continue
    route_url="$(atlas_web_append_path "$origin" "$route_path")"
    atlas_web_fetch_url "$route_url" "$route_path" "$assess_dir" "$timeout" "$routes_file"
  done < <(atlas_web_routes)

  # Keep predictable names for the HTTP-origin probe in the retained packet.
  [ -f "$assess_dir/http-origin.headers" ] || : >"$http_headers"
  [ -f "$assess_dir/http-origin.body" ] || : >"$http_body"

  routes_evidence_output="$(cmd_evidence_add "$routes_file" --kind web-assessment-routes --classification public)"
  routes_evidence_id="$(printf '%s\n' "$routes_evidence_output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$routes_evidence_id" ] || fail "unable to record web assessment routes evidence"

  missing_headers="$(atlas_web_route_value "$routes_file" "/" 8)"
  if [ -n "$missing_headers" ]; then
    finding_ids+=("$(atlas_web_add_finding \
      "Missing browser hardening headers" \
      "low" \
      "Add CSP, frame protections, content-type protection, referrer policy, permissions policy, and HSTS where appropriate." \
      "$routes_evidence_id")")
  fi

  http_status="$(atlas_web_route_value "$http_routes_file" "http-origin" 3)"
  http_location="$(atlas_web_route_value "$http_routes_file" "http-origin" 6)"
  if atlas_web_ok_status "$http_status" && [ -z "$http_location" ]; then
    finding_ids+=("$(atlas_web_add_finding \
      "HTTP origin does not redirect to HTTPS" \
      "medium" \
      "Force HTTP requests to redirect to the HTTPS origin before enabling HSTS." \
      "$routes_evidence_id")")
  fi

  metadata_shell_count="$(atlas_web_routes_matching_shell_count "$routes_file")"
  if [ "$metadata_shell_count" -gt 0 ]; then
    finding_ids+=("$(atlas_web_add_finding \
      "Metadata routes return application HTML" \
      "info" \
      "Serve real robots.txt, sitemap.xml, and security.txt files or return explicit 404 responses." \
      "$routes_evidence_id")")
  fi

  admin_route_count="$(atlas_web_admin_route_count "$routes_file")"
  if [ "$admin_route_count" -gt 0 ]; then
    finding_ids+=("$(atlas_web_add_finding \
      "Admin-style routes return successful responses" \
      "low" \
      "Return explicit 404 responses for unused admin-style routes, or protect real admin surfaces behind authentication." \
      "$routes_evidence_id")")
  fi

  atlas_web_write_summary "$summary_file" "$url" "$origin" "$http_origin" "$routes_file" "${#finding_ids[@]}"
  summary_evidence_output="$(cmd_evidence_add "$summary_file" --kind web-assessment-summary --classification public)"
  summary_evidence_id="$(printf '%s\n' "$summary_evidence_output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$summary_evidence_id" ] || fail "unable to record web assessment summary evidence"

  atlas_ledger_append_current "web.assessment.generated" "read-only" "atlas" "ok" "url=$url findings=${#finding_ids[@]} summary=$summary_file"
  record_operation_history "$ATLAS_OP_DIR" "web-assessment" "$summary_file"
  atlas_web_publish_intel "$ATLAS_OP_TARGET" "$routes_file"

  bundle_output="$(cmd_evidence_bundle "$ATLAS_OP_SLUG-web-assessment")"
  bundle_dir="$(printf '%s\n' "$bundle_output" | awk -F': ' '$1 == "bundle" { print $2; exit }')"

  report_output="$(cmd_op_report "$ATLAS_OP_SLUG" "$ATLAS_OP_SLUG-web-report")"
  report_path="$(printf '%s\n' "$report_output" | awk -F': ' '$1 == "report" { print $2; exit }')"

  handoff_output="$(cmd_op_handoff "$ATLAS_OP_SLUG" "$ATLAS_OP_SLUG-web-handoff")"
  handoff_path="$(printf '%s\n' "$handoff_output" | awk -F': ' '$1 == "handoff" { print $2; exit }')"

  ui_ok "web assessment packetized"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'target: %s\n' "$ATLAS_OP_TARGET"
  printf 'target_file: %s\n' "$target_file"
  printf 'url: %s\n' "$url"
  printf 'origin: %s\n' "$origin"
  printf 'summary: %s\n' "$summary_file"
  printf 'routes: %s\n' "$routes_file"
  printf 'summary_evidence: %s\n' "$summary_evidence_id"
  printf 'routes_evidence: %s\n' "$routes_evidence_id"
  printf 'findings: %s\n' "${#finding_ids[@]}"
  if [ "${#finding_ids[@]}" -gt 0 ]; then
    printf 'finding_ids: %s\n' "${finding_ids[*]}"
  fi
  printf 'bundle: %s\n' "$bundle_dir"
  printf 'report: %s\n' "$report_path"
  printf 'handoff: %s\n' "$handoff_path"
}
