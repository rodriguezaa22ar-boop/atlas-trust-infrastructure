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

atlas_web_url_base_path() {
  local rest
  local path

  rest="${1#*://}"
  case "$rest" in
  */*)
    path="/${rest#*/}"
    ;;
  *)
    printf '\n'
    return 0
    ;;
  esac

  path="${path%%\#*}"
  path="${path%%\?*}"
  while [ "$path" != "/" ] && [ "${path%/}" != "$path" ]; do
    path="${path%/}"
  done
  [ "$path" = "/" ] && path=""
  printf '%s\n' "$path"
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

atlas_web_default_api_paths() {
  cat <<'EOF'
/api/auth/me
/api/billing/status
/api/health
/api/status
EOF
}

atlas_web_validate_api_path() {
  case "$1" in
  /*)
    return 0
    ;;
  *)
    fail "web assess API paths must start with /; got: $1"
    ;;
  esac
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

atlas_web_fetch_api_url() {
  local url="$1"
  local path="$2"
  local method="$3"
  local out_dir="$4"
  local timeout="$5"
  local cors_origin="$6"
  local api_file="$7"
  local curl_bin
  local route_slug
  local headers_file
  local body_file
  local err_file
  local status_code="000"
  local content_type=""
  local server=""
  local allow_origin=""
  local allow_credentials=""
  local allow_methods=""
  local vary_header=""
  local body_sha=""
  local body_size="0"
  local curl_status="ok"
  local curl_args=()

  curl_bin="$(atlas_web_curl_bin)"
  command -v "$curl_bin" >/dev/null 2>&1 || fail "command not found: $curl_bin"

  route_slug="$(slugify "api-$method-$path")"
  [ -n "$route_slug" ] || route_slug="api-$method"
  headers_file="$out_dir/$route_slug.headers"
  body_file="$out_dir/$route_slug.body"
  err_file="$out_dir/$route_slug.err"

  curl_args=(-sS --max-time "$timeout" -D "$headers_file" -o "$body_file")
  if [ "$method" = "OPTIONS" ]; then
    curl_args+=(
      -X OPTIONS
      -H "Origin: $cors_origin"
      -H "Access-Control-Request-Method: GET"
    )
  fi
  curl_args+=("$url")

  if "$curl_bin" "${curl_args[@]}" 2>"$err_file"; then
    status_code="$(atlas_web_extract_http_status "$headers_file")"
    [ -n "$status_code" ] || status_code="000"
    content_type="$(atlas_web_extract_header_value "$headers_file" "Content-Type")"
    server="$(atlas_web_extract_header_value "$headers_file" "Server")"
    allow_origin="$(atlas_web_extract_header_value "$headers_file" "Access-Control-Allow-Origin")"
    allow_credentials="$(atlas_web_extract_header_value "$headers_file" "Access-Control-Allow-Credentials")"
    allow_methods="$(atlas_web_extract_header_value "$headers_file" "Access-Control-Allow-Methods")"
    vary_header="$(atlas_web_extract_header_value "$headers_file" "Vary")"
    body_sha="$(atlas_evidence_hash_path "$body_file")"
    body_size="$(wc -c <"$body_file" | tr -d ' ')"
  else
    curl_status="failed"
    : >"$headers_file"
    : >"$body_file"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$path" \
    "$method" \
    "$url" \
    "$status_code" \
    "$content_type" \
    "$server" \
    "$allow_origin" \
    "$allow_credentials" \
    "$allow_methods" \
    "$vary_header" \
    "$body_size" \
    "$body_sha" \
    "$curl_status" \
    "$headers_file" >>"$api_file"
}

atlas_web_write_summary() {
  local file="$1"
  local url="$2"
  local origin="$3"
  local base_path="$4"
  local http_checked_url="$5"
  local routes_file="$6"
  local api_file="$7"
  local cors_origin="$8"
  local finding_count="$9"

  {
    printf '# Atlas Web Assessment Packet\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    printf 'URL: %s\n' "$url"
    printf 'Origin: %s\n' "$origin"
    printf 'Base Path: %s\n' "${base_path:-/}"
    printf 'HTTP Origin Checked: %s\n' "$http_checked_url"
    printf 'CORS Probe Origin: %s\n' "$cors_origin"
    printf 'Finding Count: %s\n' "$finding_count"
    printf '\nNo raw response bodies are embedded in this packet. Route/API bodies and headers are retained as local operation artifacts.\n'
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
    printf '\n## API/CORS Checks\n\n'
    printf '| Path | Method | Status | Content-Type | Server | Allow-Origin | Allow-Credentials |\n'
    printf '| --- | --- | --- | --- | --- | --- | --- |\n'
    awk -F'\t' '{
      ctype = $5 == "" ? "-" : $5
      server = $6 == "" ? "-" : $6
      allow_origin = $7 == "" ? "-" : $7
      allow_credentials = $8 == "" ? "-" : $8
      printf "| `%s` | %s | %s | %s | %s | %s | %s |\n", $1, $2, $4, ctype, server, allow_origin, allow_credentials
    }' "$api_file"
    printf '\n## Retained Files\n\n'
    printf -- "- Routes TSV: \`%s\`\n" "$routes_file"
    printf -- "- API/CORS TSV: \`%s\`\n" "$api_file"
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

atlas_web_credentialed_cors_count() {
  local api_file="$1"
  local origin="$2"

  awk -F'\t' -v origin="$origin" '
    $2 == "OPTIONS" && $4 ~ /^[23]/ {
      allow_origin = $7
      allow_credentials = tolower($8)
      if (allow_credentials == "true" && allow_origin != "" && allow_origin != origin) {
        count++
      }
    }
    END { print count + 0 }
  ' "$api_file"
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

atlas_web_is_assessment_finding_title() {
  case "$1" in
  "Missing browser hardening headers" | \
    "HTTP origin does not redirect to HTTPS" | \
    "Metadata routes return application HTML" | \
    "Admin-style routes return successful responses" | \
    "Credentialed CORS allows probe origin")
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

atlas_web_assessment_finding_rows() {
  local finding_id="${1:-}"
  local index_file

  intel_require_jq
  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg finding_id "$finding_id" '
      def severity_rank:
        {
          "critical": 5,
          "high": 4,
          "medium": 3,
          "low": 2,
          "info": 1
        }[.] // 0;
      def web_assessment_title:
        . == "Missing browser hardening headers" or
        . == "HTTP origin does not redirect to HTTPS" or
        . == "Metadata routes return application HTML" or
        . == "Admin-style routes return successful responses" or
        . == "Credentialed CORS allows probe origin";
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(
          (.status // "") == "open" and
          ((.title // "") | web_assessment_title) and
          ($finding_id == "" or .id == $finding_id)
        ))
      | sort_by((.severity // "info" | severity_rank), (.created_at // ""), (.id // ""))
      | reverse
      | .[]
      | [
          (.id // ""),
          (.title // ""),
          (.severity // ""),
          ((.evidence // []) | join(" "))
        ]
      | @tsv
    ' "$index_file"
}

atlas_web_finding_has_validation_plan() {
  local finding_id="$1"
  local index_file

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 1

  jq -se \
    --arg finding_id "$finding_id" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | any(.finding == $finding_id)
    ' "$index_file" >/dev/null
}

atlas_web_validation_plan_rows() {
  local plan_id="${1:-}"
  local validation_index
  local id
  local status
  local finding_id
  local lane
  local record
  local title
  local severity

  intel_require_jq
  validation_index="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$validation_index" ] || return 0

  while IFS=$'\t' read -r id status finding_id lane; do
    [ -n "$id" ] || continue
    [ -z "$plan_id" ] || [ "$id" = "$plan_id" ] || continue
    [ -n "$finding_id" ] || continue

    record="$(atlas_findings_latest_record "$finding_id" || true)"
    [ -n "$record" ] || continue
    title="$(printf '%s\n' "$record" | jq -r '.title // ""')"
    atlas_web_is_assessment_finding_title "$title" || continue
    severity="$(printf '%s\n' "$record" | jq -r '.severity // ""')"

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$status" "$lane" "$finding_id" "$title" "$severity"
  done < <(
    jq -sr '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | sort_by(.created_at, .id)
      | .[]
      | [
          (.id // ""),
          (.status // ""),
          (.finding // ""),
          (.lane // "")
        ]
      | @tsv
    ' "$validation_index"
  )
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

atlas_web_publish_api_intel() {
  local target="$1"
  local api_file="$2"
  local origin="$3"
  local path
  local method
  local url
  local status_code
  local content_type
  local server
  local allow_origin
  local allow_credentials
  local payload

  while IFS=$'\t' read -r path method url status_code content_type server allow_origin allow_credentials _ _ _ _ _ _; do
    [ -n "$url" ] || continue
    payload="$(
      jq -cn \
        --arg observed_at "$(timestamp)" \
        --arg target "$target" \
        --arg endpoint "$url" \
        --arg path "$path" \
        --arg method "$method" \
        --arg status_code "$status_code" \
        --arg content_type "$content_type" \
        --arg server "$server" \
        --arg allow_origin "$allow_origin" \
        --arg allow_credentials "$allow_credentials" \
        '{
          observed_at: $observed_at,
          source_tool: "atlas",
          source_kind: "web-assessment",
          source_name: "web-assess",
          target: $target,
          observation_type: "api_probe",
          confidence: "medium",
          value: {
            endpoint: $endpoint,
            path: $path,
            method: $method,
            status_code: $status_code,
            content_type: $content_type,
            server: $server,
            allow_origin: $allow_origin,
            allow_credentials: $allow_credentials
          }
        }'
    )"
    intel_append_record observations "$payload"

    if [ "$method" = "OPTIONS" ] &&
      [ "$(printf '%s\n' "$allow_credentials" | tr '[:upper:]' '[:lower:]')" = "true" ] &&
      [ -n "$allow_origin" ] &&
      [ "$allow_origin" != "$origin" ]; then
      payload="$(
        jq -cn \
          --arg observed_at "$(timestamp)" \
          --arg target "$target" \
          --arg endpoint "$url" \
          --arg detail "allow-origin=$allow_origin allow-credentials=$allow_credentials" \
          '{
            observed_at: $observed_at,
            source_tool: "atlas",
            source_kind: "web-assessment",
            source_name: "web-assess",
            target: $target,
            observation_type: "cors_posture_finding",
            confidence: "medium",
            value: {
              severity: "medium",
              label: "credentialed-cors-probe-origin",
              url: $endpoint,
              detail: $detail
            }
          }'
      )"
      intel_append_record observations "$payload"
    fi
  done <"$api_file"
}

cmd_web_assess() {
  need_args 1 "$#" "web assess <url> [assessment-name] [--target name] [--scope-status status] [--criticality level] [--owner owner] [--timeout seconds] [--api-path path] [--cors-origin origin] [--skip-api]"
  local url="$1"
  local assessment_name=""
  local target_name=""
  local scope_status="review"
  local criticality="medium"
  local owner=""
  local timeout="8"
  local cors_origin="https://example.com"
  local skip_api="0"
  local api_paths=()
  local host
  local origin
  local http_origin
  local base_path
  local route_base_url
  local http_probe_url
  local target_file
  local operation_output
  local op_slug
  local assess_dir
  local routes_file
  local api_file
  local summary_file
  local route_path
  local route_url
  local api_path
  local api_url
  local http_headers
  local http_body
  local http_routes_file
  local api_evidence_output
  local api_evidence_id
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
  local credentialed_cors_count
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
    --api-path)
      need_args 2 "$#" "web assess <url> --api-path <path>"
      atlas_web_validate_api_path "$2"
      api_paths+=("$2")
      shift 2
      ;;
    --cors-origin)
      need_args 2 "$#" "web assess <url> --cors-origin <origin>"
      cors_origin="$2"
      shift 2
      ;;
    --skip-api)
      skip_api="1"
      shift
      ;;
    -*)
      fail "unknown web assess option: $1"
      ;;
    *)
      if [ -n "$assessment_name" ]; then
        fail "web assess <url> [assessment-name] [--target name] [--scope-status status] [--criticality level] [--owner owner] [--timeout seconds] [--api-path path] [--cors-origin origin] [--skip-api]"
      fi
      assessment_name="$1"
      shift
      ;;
    esac
  done

  atlas_web_validate_url "$url"
  atlas_web_validate_url "$cors_origin"
  host="$(atlas_web_url_host "$url")"
  origin="$(atlas_web_url_origin "$url")"
  http_origin="$(atlas_web_http_origin "$url")"
  base_path="$(atlas_web_url_base_path "$url")"
  route_base_url="$origin$base_path"
  http_probe_url="$(atlas_web_append_path "$http_origin$base_path" "/")"
  if [ -z "$target_name" ]; then
    target_name="$host"
    [ -z "$base_path" ] || target_name="$host$base_path"
  fi
  [ -n "$assessment_name" ] || assessment_name="web-assessment-$host"
  atlas_web_validate_scope_status "$scope_status"
  atlas_web_validate_criticality "$criticality"
  if [ "${#api_paths[@]}" -eq 0 ] && [ "$skip_api" != "1" ]; then
    while IFS= read -r api_path; do
      [ -n "$api_path" ] || continue
      api_paths+=("$api_path")
    done < <(atlas_web_default_api_paths)
  fi

  target_file="$(atlas_web_ensure_target "$target_name" "$url" "$scope_status" "$criticality" "$owner")"
  operation_output="$(cmd_op_start "$assessment_name" "$target_name" "web assessment packetization for $route_base_url")"
  op_slug="$(printf '%s\n' "$operation_output" | awk -F': ' '$1 == "active_operation" { print $2; exit }')"
  [ -n "$op_slug" ] || fail "unable to determine web assessment operation id"
  load_atlas_operation "$op_slug"

  assess_dir="$ATLAS_OP_DIR/web-assessment"
  mkdir -p "$assess_dir"
  chmod 700 "$assess_dir" 2>/dev/null || true
  routes_file="$assess_dir/routes.tsv"
  api_file="$assess_dir/api.tsv"
  summary_file="$assess_dir/summary.md"
  : >"$routes_file"
  : >"$api_file"
  chmod 600 "$routes_file" 2>/dev/null || true
  chmod 600 "$api_file" 2>/dev/null || true

  http_routes_file="$assess_dir/http-origin.tsv"
  : >"$http_routes_file"
  http_headers="$assess_dir/http-origin.headers"
  http_body="$assess_dir/http-origin.body"
  atlas_web_fetch_url "$http_probe_url" "http-origin" "$assess_dir" "$timeout" "$http_routes_file"

  while IFS= read -r route_path; do
    [ -n "$route_path" ] || continue
    route_url="$(atlas_web_append_path "$route_base_url" "$route_path")"
    atlas_web_fetch_url "$route_url" "$route_path" "$assess_dir" "$timeout" "$routes_file"
  done < <(atlas_web_routes)

  if [ "$skip_api" != "1" ]; then
    for api_path in "${api_paths[@]}"; do
      atlas_web_validate_api_path "$api_path"
      api_url="$(atlas_web_append_path "$route_base_url" "$api_path")"
      atlas_web_fetch_api_url "$api_url" "$api_path" "GET" "$assess_dir" "$timeout" "$cors_origin" "$api_file"
      atlas_web_fetch_api_url "$api_url" "$api_path" "OPTIONS" "$assess_dir" "$timeout" "$cors_origin" "$api_file"
    done
  fi

  # Keep predictable names for the HTTP-origin probe in the retained packet.
  [ -f "$assess_dir/http-origin.headers" ] || : >"$http_headers"
  [ -f "$assess_dir/http-origin.body" ] || : >"$http_body"

  routes_evidence_output="$(cmd_evidence_add "$routes_file" --kind web-assessment-routes --classification public)"
  routes_evidence_id="$(printf '%s\n' "$routes_evidence_output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$routes_evidence_id" ] || fail "unable to record web assessment routes evidence"

  api_evidence_output="$(cmd_evidence_add "$api_file" --kind web-assessment-api --classification public)"
  api_evidence_id="$(printf '%s\n' "$api_evidence_output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$api_evidence_id" ] || fail "unable to record web assessment API evidence"

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

  credentialed_cors_count="$(atlas_web_credentialed_cors_count "$api_file" "$origin")"
  if [ "$credentialed_cors_count" -gt 0 ]; then
    finding_ids+=("$(atlas_web_add_finding \
      "Credentialed CORS allows probe origin" \
      "medium" \
      "Restrict credentialed CORS to explicitly trusted application origins and avoid reflecting arbitrary Origin values." \
      "$api_evidence_id")")
  fi

  atlas_web_write_summary "$summary_file" "$url" "$origin" "$base_path" "$http_probe_url" "$routes_file" "$api_file" "$cors_origin" "${#finding_ids[@]}"
  summary_evidence_output="$(cmd_evidence_add "$summary_file" --kind web-assessment-summary --classification public)"
  summary_evidence_id="$(printf '%s\n' "$summary_evidence_output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$summary_evidence_id" ] || fail "unable to record web assessment summary evidence"

  atlas_ledger_append_current "web.assessment.generated" "read-only" "atlas" "ok" "url=$url findings=${#finding_ids[@]} summary=$summary_file"
  record_operation_history "$ATLAS_OP_DIR" "web-assessment" "$summary_file"
  atlas_web_publish_intel "$ATLAS_OP_TARGET" "$routes_file"
  atlas_web_publish_api_intel "$ATLAS_OP_TARGET" "$api_file" "$origin"

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
  printf 'base_path: %s\n' "${base_path:-/}"
  printf 'summary: %s\n' "$summary_file"
  printf 'routes: %s\n' "$routes_file"
  printf 'api: %s\n' "$api_file"
  printf 'summary_evidence: %s\n' "$summary_evidence_id"
  printf 'routes_evidence: %s\n' "$routes_evidence_id"
  printf 'api_evidence: %s\n' "$api_evidence_id"
  printf 'findings: %s\n' "${#finding_ids[@]}"
  if [ "${#finding_ids[@]}" -gt 0 ]; then
    printf 'finding_ids: %s\n' "${finding_ids[*]}"
  fi
  printf 'bundle: %s\n' "$bundle_dir"
  printf 'report: %s\n' "$report_path"
  printf 'handoff: %s\n' "$handoff_path"
}

cmd_web_validation_plan() {
  local all="0"
  local finding_id=""
  local lane="posture"
  local rows=()
  local row
  local id
  local title
  local severity
  local evidence_text
  local evidence_id
  local plan_args=()
  local plan_output
  local plan_id
  local planned_ids=()
  local skipped_ids=()
  local considered_count=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --all)
      all="1"
      shift
      ;;
    --finding)
      need_args 2 "$#" "web validation-plan --finding <id>"
      finding_id="$2"
      shift 2
      ;;
    --lane)
      need_args 2 "$#" "web validation-plan --lane <lane>"
      lane="$2"
      shift 2
      ;;
    *)
      fail "unknown web validation-plan option: $1"
      ;;
    esac
  done

  if [ "$all" = "1" ] && [ -n "$finding_id" ]; then
    fail "web validation-plan accepts either --all or --finding, not both"
  fi

  load_active_operation

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    rows+=("$row")
  done < <(atlas_web_assessment_finding_rows "$finding_id")

  if [ "${#rows[@]}" -eq 0 ]; then
    if [ -n "$finding_id" ]; then
      fail "no open web assessment finding found for: $finding_id"
    fi
    ui_note "no open web assessment findings are waiting for a validation plan"
    return 0
  fi

  if [ "$all" != "1" ] && [ -z "$finding_id" ]; then
    rows=("${rows[0]}")
  fi

  for row in "${rows[@]}"; do
    IFS=$'\t' read -r id title severity evidence_text <<<"$row"
    [ -n "$id" ] || continue
    considered_count=$((considered_count + 1))

    if ! atlas_web_is_assessment_finding_title "$title"; then
      skipped_ids+=("$id")
      continue
    fi

    if atlas_web_finding_has_validation_plan "$id"; then
      skipped_ids+=("$id")
      continue
    fi

    plan_args=("$lane" --finding "$id" --reason "validate $severity web assessment finding: $title")
    for evidence_id in $evidence_text; do
      [ -n "$evidence_id" ] || continue
      plan_args+=(--evidence "$evidence_id")
    done

    plan_output="$(cmd_validation_plan "${plan_args[@]}")"
    plan_id="$(printf '%s\n' "$plan_output" | awk -F': ' '$1 == "id" { print $2; exit }')"
    [ -n "$plan_id" ] || fail "unable to record validation plan for finding: $id"
    planned_ids+=("$plan_id")
  done

  ui_ok "web validation plans queued"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'target: %s\n' "$ATLAS_OP_TARGET"
  printf 'lane: %s\n' "$lane"
  printf 'considered: %s\n' "$considered_count"
  printf 'planned: %s\n' "${#planned_ids[@]}"
  printf 'skipped: %s\n' "${#skipped_ids[@]}"
  if [ "${#planned_ids[@]}" -gt 0 ]; then
    printf 'plan_ids: %s\n' "${planned_ids[*]}"
  fi
  if [ "${#skipped_ids[@]}" -gt 0 ]; then
    printf 'skipped_findings: %s\n' "${skipped_ids[*]}"
  fi
}

cmd_web_validation_approve() {
  local all="0"
  local plan_id=""
  local reason=""
  local rows=()
  local row
  local id
  local status
  local lane
  local finding_id
  local title
  local severity
  local approved_ids=()
  local skipped_ids=()
  local considered_count=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --all)
      all="1"
      shift
      ;;
    --plan)
      need_args 2 "$#" "web validation-approve --plan <id>"
      plan_id="$2"
      shift 2
      ;;
    --reason)
      need_args 2 "$#" "web validation-approve --reason <text>"
      reason="$2"
      shift 2
      ;;
    *)
      fail "unknown web validation-approve option: $1"
      ;;
    esac
  done

  [ -n "$reason" ] || fail "web validation-approve requires --reason <text>"
  if [ "$all" = "1" ] && [ -n "$plan_id" ]; then
    fail "web validation-approve accepts either --all or --plan, not both"
  fi

  load_active_operation

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    rows+=("$row")
  done < <(atlas_web_validation_plan_rows "$plan_id")

  if [ "${#rows[@]}" -eq 0 ]; then
    if [ -n "$plan_id" ]; then
      fail "no web validation plan found for: $plan_id"
    fi
    ui_note "no web validation plans are waiting for approval"
    return 0
  fi

  if [ "$all" != "1" ] && [ -z "$plan_id" ]; then
    rows=("${rows[0]}")
  fi

  for row in "${rows[@]}"; do
    IFS=$'\t' read -r id status lane finding_id title severity <<<"$row"
    [ -n "$id" ] || continue
    considered_count=$((considered_count + 1))

    if [ "$status" != "planned" ]; then
      skipped_ids+=("$id")
      continue
    fi

    cmd_validation_approve "$id" "$reason" >/dev/null
    approved_ids+=("$id")
  done

  ui_ok "web validation plans approved"
  printf 'operation: %s\n' "$ATLAS_OP_SLUG"
  printf 'target: %s\n' "$ATLAS_OP_TARGET"
  printf 'reason: %s\n' "$reason"
  printf 'considered: %s\n' "$considered_count"
  printf 'approved: %s\n' "${#approved_ids[@]}"
  printf 'skipped: %s\n' "${#skipped_ids[@]}"
  if [ "${#approved_ids[@]}" -gt 0 ]; then
    printf 'approved_plan_ids: %s\n' "${approved_ids[*]}"
  fi
  if [ "${#skipped_ids[@]}" -gt 0 ]; then
    printf 'skipped_plan_ids: %s\n' "${skipped_ids[*]}"
  fi
}
