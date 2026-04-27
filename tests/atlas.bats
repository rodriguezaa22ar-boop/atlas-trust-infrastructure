#!/usr/bin/env bats

setup() {
  export TEST_ROOT
  TEST_ROOT="$(mktemp -d)"
  cp -R "$BATS_TEST_DIRNAME/.." "$TEST_ROOT/toolkit"
  rm -rf \
    "$TEST_ROOT/toolkit/.tmp" \
    "$TEST_ROOT/toolkit/logs" \
    "$TEST_ROOT/toolkit/releases" \
    "$TEST_ROOT/toolkit/reports" \
    "$TEST_ROOT/toolkit/sessions" \
    "$TEST_ROOT/toolkit/shared" \
    "$TEST_ROOT/toolkit/state"
  rm -f "$TEST_ROOT/toolkit/targets/"*.env
  chmod +x \
    "$TEST_ROOT/toolkit/bin/intelctl" \
    "$TEST_ROOT/toolkit/bin/labctl" \
    "$TEST_ROOT/toolkit/lib/common.sh" \
    "$TEST_ROOT/toolkit/lib/intel.sh" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" \
    "$TEST_ROOT/toolkit/tools/vector/bin/vector"
  unset LAB_CONFIG
  export LAB_ROOT="$TEST_ROOT/toolkit"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

make_repo_clean_and_synced() {
  git -C "$TEST_ROOT/toolkit" config user.email "atlas-tests@example.invalid"
  git -C "$TEST_ROOT/toolkit" config user.name "Atlas Tests"
  if [ -n "$(git -C "$TEST_ROOT/toolkit" status --short)" ]; then
    git -C "$TEST_ROOT/toolkit" add -A
    git -C "$TEST_ROOT/toolkit" commit -m "test clean release state" >/dev/null
  fi
  git -C "$TEST_ROOT/toolkit" update-ref refs/remotes/origin/main HEAD
}

@test "root AGENTS guidance preserves Atlas agent safety contract" {
  agents_file="$TEST_ROOT/toolkit/AGENTS.md"

  [ -f "$agents_file" ]
  grep -qi 'authorized assessment' "$agents_file"
  grep -q 'autonomous exploitation' "$agents_file"
  grep -q 'Do not collapse these domains' "$agents_file"
  grep -q 'metadata-only' "$agents_file"
  grep -q 'Commands documented as read-only must not mutate state' "$agents_file"
  grep -q "nix-shell --run './bin/dev-qa'" "$agents_file"
  grep -q 'It must not be treated as production certification' "$agents_file"
  grep -q 'atlas production status' "$agents_file"
  grep -q 'not-ready` for production' "$agents_file"
  grep -q 'not an execution engine' "$agents_file"
  grep -q 'Atlas OS, ISI, and kernel-level work are future layers' "$agents_file"

  [ -f "$TEST_ROOT/toolkit/docs/agents/AGENT_WORKFLOW.md" ]
  [ -f "$TEST_ROOT/toolkit/docs/agents/AGENT_VALIDATION.md" ]
  grep -q "bats tests/atlas.bats --filter \"root AGENTS guidance\"" \
    "$TEST_ROOT/toolkit/docs/agents/AGENT_VALIDATION.md"
}

@test "retention milestone index covers retained milestone notes" {
  index_file="$TEST_ROOT/toolkit/docs/retention/MILESTONE_INDEX.md"

  [ -f "$index_file" ]
  grep -q '| Milestone | Commit | Title | Category | Runtime Change? | Trust Impact | Verification | Tag |' "$index_file"
  grep -q '## Category Notes' "$index_file"
  grep -q '## Update Rule' "$index_file"

  for note_file in \
    "$TEST_ROOT/toolkit/docs/retention/MILESTONE_30.md" \
    "$TEST_ROOT/toolkit/docs/retention/milestones"/MILESTONE_*.md; do
    [ -f "$note_file" ] || continue
    note_name="$(basename "$note_file")"
    milestone="${note_name#MILESTONE_}"
    milestone="${milestone%.md}"
    grep -q "MILESTONE_${milestone}.md" "$index_file"
    grep -q "atlas-retention-m${milestone}" "$index_file"
  done

  grep -q 'release-trust' "$index_file"
  grep -q 'agent-governance' "$index_file"
  grep -q 'retention' "$index_file"
}

@test "release replay verification runbook preserves clean-checkout procedure" {
  replay_doc="$TEST_ROOT/toolkit/docs/retention/releases/REPLAY_VERIFICATION.md"

  [ -f "$replay_doc" ]
  grep -q 'Release replay verification proves' "$replay_doc"
  grep -q 'git worktree add --detach' "$replay_doc"
  grep -q "nix-shell --run './bin/dev-qa'" "$replay_doc"
  grep -q './tools/atlas/bin/atlas v1 status --strict' "$replay_doc"
  grep -q './tools/atlas/bin/atlas release verify "$packet" --commit "$commit"' "$replay_doc"
  grep -q 'metadata-only guardrails' "$replay_doc"
  grep -q 'cryptographic signing' "$replay_doc"
  grep -q 'Do not repair a failed historical packet in place' "$replay_doc"
}

@test "packet format parity matrix records implemented JSON and packet gaps" {
  parity_doc="$TEST_ROOT/toolkit/docs/atlas/PACKET_FORMAT_PARITY.md"

  [ -f "$parity_doc" ]
  grep -q '^# Atlas Packet Format Parity$' "$parity_doc"
  grep -q 'Markdown is for operators and retained review' "$parity_doc"
  grep -q 'JSON is for gates, replay,' "$parity_doc"
  grep -q 'future Atlas OS consumers' "$parity_doc"
  grep -q '## Current Matrix' "$parity_doc"
  grep -q 'atlas.release_trust.v1' "$parity_doc"
  grep -q 'atlas.production_readiness.v1' "$parity_doc"
  grep -q 'atlas.operation_trust_chain.v1' "$parity_doc"
  grep -q '`atlas op archive-packet`' "$parity_doc"
  grep -q '`atlas op audit-packet`' "$parity_doc"
  grep -q '`atlas op closeout`' "$parity_doc"
  grep -q '`atlas op handoff`' "$parity_doc"
  grep -q '`atlas finding review-packet`' "$parity_doc"
  grep -q '`atlas advisor prompt`' "$parity_doc"
  grep -q '## Missing JSON Packet Surfaces' "$parity_doc"
  grep -q '1. archive packet' "$parity_doc"
  grep -q 'metadata-only assertion' "$parity_doc"
  grep -q 'raw runtime artifacts' "$parity_doc"
}

@test "schema docs pin implemented Atlas JSON contracts" {
  schemas_dir="$TEST_ROOT/toolkit/docs/schemas"
  index_file="$schemas_dir/README.md"
  release_schema="$schemas_dir/release-trust.v1.md"
  production_schema="$schemas_dir/production-readiness.v1.md"
  trust_chain_schema="$schemas_dir/operation-trust-chain.v1.md"

  [ -f "$index_file" ]
  [ -f "$release_schema" ]
  [ -f "$production_schema" ]
  [ -f "$trust_chain_schema" ]

  grep -q 'atlas.release_trust.v1' "$index_file"
  grep -q 'atlas.production_readiness.v1' "$index_file"
  grep -q 'atlas.operation_trust_chain.v1' "$index_file"
  grep -q 'metadata-only' "$index_file"

  grep -q '^# `atlas.release_trust.v1`$' "$release_schema"
  grep -q 'atlas release packet <packet-name> --json' "$release_schema"
  grep -q '`schema_version`: must be `atlas.release_trust.v1`' "$release_schema"
  grep -q '`metadata_only`: must be `true`' "$release_schema"
  grep -q 'operation trust-chain replay' "$release_schema"
  grep -q 'raw runtime artifacts' "$release_schema"
  grep -q 'Cryptographic signing' "$release_schema"

  grep -q '^# `atlas.production_readiness.v1`$' "$production_schema"
  grep -q 'atlas production status --json' "$production_schema"
  grep -q '`schema_version`: must be `atlas.production_readiness.v1`' "$production_schema"
  grep -q '`counts.required_not_ready`' "$production_schema"
  grep -q 'retained production dry-run' "$production_schema"
  grep -q 'Mutating repository or operation state' "$production_schema"

  grep -q '^# `atlas.operation_trust_chain.v1`$' "$trust_chain_schema"
  grep -q 'atlas op trust-chain <operation> --json' "$trust_chain_schema"
  grep -q '`schema_version`: must be `atlas.operation_trust_chain.v1`' "$trust_chain_schema"
  grep -q '`ledger`: path, event count, SHA-256 anchor' "$trust_chain_schema"
  grep -q 'must be replayed' "$trust_chain_schema"
  grep -q 'from current retained operation state' "$trust_chain_schema"
  grep -q 'Expanding operation scope' "$trust_chain_schema"
}

@test "demo walkthrough preserves full Atlas trust path" {
  demo_dir="$TEST_ROOT/toolkit/docs/demo"
  demo_doc="$demo_dir/DEMO_OPERATION.md"
  trust_doc="$demo_dir/TRUST_CHAIN_WALKTHROUGH.md"
  samples_doc="$demo_dir/SAMPLE_OUTPUTS.md"

  [ -f "$demo_doc" ]
  [ -f "$trust_doc" ]
  [ -f "$samples_doc" ]

  grep -q 'authorized local demo operation' "$demo_doc"
  grep -q './tools/atlas/bin/atlas op start' "$demo_doc"
  grep -q './tools/atlas/bin/atlas evidence add' "$demo_doc"
  grep -q './tools/atlas/bin/atlas validation approve' "$demo_doc"
  grep -q './tools/atlas/bin/atlas op report' "$demo_doc"
  grep -q './tools/atlas/bin/atlas op handoff' "$demo_doc"
  grep -q './tools/atlas/bin/atlas op closeout' "$demo_doc"
  grep -q './tools/atlas/bin/atlas op audit-packet' "$demo_doc"
  grep -q './tools/atlas/bin/atlas op archive-packet' "$demo_doc"
  grep -q './tools/atlas/bin/atlas op trust-chain demo-operation --json' "$demo_doc"
  grep -q './tools/atlas/bin/atlas release packet demo-operation-release --json --operation demo-operation --qa-status pass' "$demo_doc"
  grep -q 'raw secrets, packet captures, credentials, tokens' "$demo_doc"
  grep -q 'Stop Conditions' "$demo_doc"

  grep -q 'metadata-only' "$trust_doc"
  grep -q 'docs/schemas/operation-trust-chain.v1.md' "$trust_doc"
  grep -q 'must replay' "$trust_doc"
  grep -q 'Production readiness remains blocked' "$trust_doc"

  grep -q 'Trust Chain Status: current' "$samples_doc"
  grep -q '"schema_version": "atlas.operation_trust_chain.v1"' "$samples_doc"
  grep -q 'Schema: ok atlas.release_trust.v1' "$samples_doc"
  grep -q 'Trust Chain Status: attention-required' "$samples_doc"
}

@test "external legibility docs preserve Atlas trust boundaries" {
  docs_dir="$TEST_ROOT/toolkit/docs"
  trust_doc="$docs_dir/TRUST_MODEL.md"
  security_doc="$docs_dir/SECURITY_MODEL.md"
  responsible_doc="$docs_dir/RESPONSIBLE_USE.md"
  limitations_doc="$docs_dir/KNOWN_LIMITATIONS.md"
  roadmap_doc="$docs_dir/ROADMAP.md"

  [ -f "$trust_doc" ]
  [ -f "$security_doc" ]
  [ -f "$responsible_doc" ]
  [ -f "$limitations_doc" ]
  [ -f "$roadmap_doc" ]

  grep -q 'shell-native control plane for authorized security assessment' "$trust_doc"
  grep -q 'workflows' "$trust_doc"
  grep -q 'not production-certified' "$trust_doc"
  grep -q 'release signing/provenance' "$trust_doc"
  grep -q 'retained' "$trust_doc"
  grep -q 'production dry-run' "$trust_doc"

  grep -q 'Authorized Use' "$security_doc"
  grep -q 'Tier 5: destructive, blocked by default' "$security_doc"
  grep -q 'Metadata-only packets must not include raw runtime artifacts' "$security_doc"
  grep -q 'production-certified security infrastructure' "$security_doc"

  grep -q 'Use it only where' "$responsible_doc"
  grep -q 'you have permission' "$responsible_doc"
  grep -q 'Disallowed Workflows' "$responsible_doc"
  grep -q 'autonomous exploitation' "$responsible_doc"
  grep -q 'must not be' "$responsible_doc"
  grep -q 'treated as an execution engine' "$responsible_doc"

  grep -q 'ready-to-refine, not production-certified' "$limitations_doc"
  grep -q 'Release trust packets are not cryptographically signed' "$limitations_doc"
  grep -q 'Production readiness is blocked' "$limitations_doc"
  grep -q 'Avoid describing Atlas as production-ready' "$limitations_doc"

  grep -q 'trust consolidation lane' "$roadmap_doc"
  grep -q 'CI / GitHub Actions QA gate' "$roadmap_doc"
  grep -q 'Atlas OS' "$roadmap_doc"
  grep -q 'Do not jump to Atlas' "$roadmap_doc"
}

@test "ci workflow mirrors local Atlas QA gate" {
  workflow="$TEST_ROOT/toolkit/.github/workflows/qa.yml"
  ci_doc="$TEST_ROOT/toolkit/docs/CI.md"

  [ -f "$workflow" ]
  [ -f "$ci_doc" ]

  grep -q '^name: QA$' "$workflow"
  grep -q 'pull_request:' "$workflow"
  grep -q 'workflow_dispatch:' "$workflow"
  grep -q 'actions/checkout@v4' "$workflow"
  grep -q 'cachix/install-nix-action@v31' "$workflow"
  grep -q 'nix_path: nixpkgs=channel:nixos-unstable' "$workflow"
  grep -q 'git diff --check' "$workflow"
  grep -q "nix-shell --run './bin/dev-qa'" "$workflow"
  grep -q "nix-shell --run './tools/atlas/bin/atlas v1 status --strict'" "$workflow"
  ! grep -q 'atlas production status' "$workflow"

  grep -q '.github/workflows/qa.yml' "$ci_doc"
  grep -q "nix-shell --run './bin/dev-qa'" "$ci_doc"
  grep -q "nix-shell --run './tools/atlas/bin/atlas v1 status --strict'" "$ci_doc"
  grep -q 'does not claim production readiness' "$ci_doc"
  grep -q 'does not run live target assessments' "$ci_doc"
  grep -q 'replay verification from a clean checkout' "$ci_doc"
}

@test "atlas help groups target-first workflow and story commands" {
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" help

  [ "$status" -eq 0 ]
  [[ "$output" == *"quick flow:"* ]]
  [[ "$output" == *"atlas doctor"* ]]
  [[ "$output" == *"atlas v1 status"* ]]
  [[ "$output" == *"atlas production status"* ]]
  [[ "$output" == *"atlas release packet [packet-name]"* ]]
  [[ "$output" == *"atlas release packet [packet-name] [--json]"* ]]
  [[ "$output" == *"atlas release verify [packet]"* ]]
  [[ "$output" == *"atlas web assess <url> [assessment-name]"* ]]
  [[ "$output" == *"atlas web validation-plan [--all]"* ]]
  [[ "$output" == *"atlas web validation-approve [--all] --reason text"* ]]
  [[ "$output" == *"atlas scope status"* ]]
  [[ "$output" == *"atlas evidence add <path> [--kind kind]"* ]]
  [[ "$output" == *"atlas evidence redact <id> <redacted-path>"* ]]
  [[ "$output" == *"atlas evidence bundle [bundle-name]"* ]]
  [[ "$output" == *"atlas finding add <title> [--level observed|inferred|validated]"* ]]
  [[ "$output" == *"atlas finding update <id> [--level level] [--status status]"* ]]
  [[ "$output" == *"atlas finding accept <id> --reason text"* ]]
  [[ "$output" == *"atlas finding review <id> --reason text"* ]]
  [[ "$output" == *"atlas finding review-queue [--within days]"* ]]
  [[ "$output" == *"atlas finding review-packet [packet-name] [--within days]"* ]]
  [[ "$output" == *"atlas finding review-verify [packet]"* ]]
  [[ "$output" == *"atlas finding resolve <id> [--evidence id] [--validation id]"* ]]
  [[ "$output" == *"atlas validation plan <lane> [--finding id] [--evidence id]"* ]]
  [[ "$output" == *"atlas validation retest <id> --result resolved|still-open"* ]]
  [[ "$output" == *"atlas validation supersede <id> --by replacement-id --reason text"* ]]
  [[ "$output" == *"atlas advisor brief [name]"* ]]
  [[ "$output" == *"atlas advisor prompt [name] [packet-name]"* ]]
  [[ "$output" == *"atlas cycle [target]"* ]]
  [[ "$output" == *"targets:"* ]]
  [[ "$output" == *"operations:"* ]]
  [[ "$output" == *"story views:"* ]]
  [[ "$output" == *"cycle views:"* ]]
  [[ "$output" == *"scope:"* ]]
  [[ "$output" == *"validation:"* ]]
  [[ "$output" == *"advisor:"* ]]
  [[ "$output" == *"v1:"* ]]
  [[ "$output" == *"production:"* ]]
  [[ "$output" == *"release:"* ]]
  [[ "$output" == *"atlas target story <target>"* ]]
  [[ "$output" == *"atlas target cycle <target>"* ]]
  [[ "$output" == *"atlas op cycle [name]"* ]]
  [[ "$output" == *"atlas target update <name> [--scope-status status] [--criticality level]"* ]]
  [[ "$output" == *"atlas intel graph [target] [--format dot|ndjson]"* ]]
  [[ "$output" == *"atlas intel paths [target] [--format text|ndjson]"* ]]
  [[ "$output" == *"atlas story demo-web-app"* ]]
  [[ "$output" == *"atlas op show [name]"* ]]
  [[ "$output" == *"atlas op story [name]"* ]]
  [[ "$output" == *"atlas op report [name] [report-name]"* ]]
  [[ "$output" == *"atlas op readiness [name]"* ]]
  [[ "$output" == *"atlas op handoff [name] [handoff-name]"* ]]
  [[ "$output" == *"atlas op closeout [name] [manifest-name]"* ]]
  [[ "$output" == *"atlas op verify [name] [closeout-manifest]"* ]]
  [[ "$output" == *"atlas op audit [name]"* ]]
  [[ "$output" == *"atlas op audit-packet [name] [packet-name]"* ]]
  [[ "$output" == *"atlas op audit-verify [name] [audit-packet]"* ]]
  [[ "$output" == *"atlas op archive [name]"* ]]
  [[ "$output" == *"atlas op archive-packet [name] [packet-name]"* ]]
  [[ "$output" == *"atlas op archive-verify [name] [archive-packet]"* ]]
  [[ "$output" == *"atlas op trust-chain [name] [--strict] [--json]"* ]]
  [[ "$output" == *"atlas op close [name] [--force]"* ]]
  [[ "$output" == *"atlas target brief <target>"* ]]
}

@test "atlas web assess packetizes bounded web posture into operation evidence" {
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/curl" <<'EOF'
#!/usr/bin/env bash
headers=""
body=""
url=""
method="GET"
while [ "$#" -gt 0 ]; do
  case "$1" in
  -D)
    headers="$2"
    shift 2
    ;;
  -o)
    body="$2"
    shift 2
    ;;
  --max-time)
    shift 2
    ;;
  -X)
    method="$2"
    shift 2
    ;;
  -H)
    shift 2
    ;;
  -sS)
    shift
    ;;
  *)
    url="$1"
    shift
    ;;
  esac
done

status="200 OK"
content_type="text/html; charset=utf-8"
server="fake-edge"
location=""

case "$url" in
https://example.test/static*)
  content_type="application/javascript"
  ;;
esac

{
  printf 'HTTP/1.1 %s\r\n' "$status"
  printf 'Content-Type: %s\r\n' "$content_type"
  printf 'Server: %s\r\n' "$server"
  if [ -n "$location" ]; then
    printf 'Location: %s\r\n' "$location"
  fi
  printf '\r\n'
} > "$headers"

if [ "$method" = "OPTIONS" ]; then
  : > "$body"
else
  cat > "$body" <<'HTML'
<!doctype html><html><head><title>Execution OS</title></head><body><div id="root"></div></body></html>
HTML
fi
EOF
  chmod +x "$TEST_ROOT/fake-bin/curl"

  run env LAB_ATLAS_CURL_BIN="$TEST_ROOT/fake-bin/curl" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" web assess https://example.test m37-web \
    --scope-status in-scope \
    --criticality medium \
    --owner platform

  [ "$status" -eq 0 ]
  [[ "$output" == *"web assessment packetized"* ]]
  [[ "$output" == *"operation: m37-web"* ]]
  [[ "$output" == *"target: example.test"* ]]
  [[ "$output" == *"findings: 4"* ]]

  summary_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "summary" { print $2; exit }')"
  routes_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "routes" { print $2; exit }')"
  api_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "api" { print $2; exit }')"
  bundle_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "bundle" { print $2; exit }')"
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  handoff_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "handoff" { print $2; exit }')"

  [ -f "$summary_path" ]
  [ -f "$routes_path" ]
  [ -f "$api_path" ]
  [ -d "$bundle_path" ]
  [ -f "$report_path" ]
  [ -f "$handoff_path" ]

  grep -q '^# Atlas Web Assessment Packet$' "$summary_path"
  grep -q 'Finding Count: 4' "$summary_path"
  grep -q 'CORS Probe Origin: https://example.com' "$summary_path"
  grep -q 'API/CORS Checks' "$summary_path"
  grep -q 'Missing Security Headers' "$summary_path"
  grep -q '/robots.txt' "$routes_path"
  grep -q '/api/auth/me' "$api_path"
  grep -q 'OPTIONS' "$api_path"
  grep -q 'Content-Security-Policy' "$routes_path"
  grep -q 'Missing browser hardening headers' "$report_path"
  grep -q 'HTTP origin does not redirect to HTTPS' "$report_path"
  grep -q 'Metadata routes return application HTML' "$report_path"
  grep -q 'Admin-style routes return successful responses' "$report_path"
  grep -q 'Close readiness: attention-required' "$handoff_path"

  grep -q '^NAME=example.test$' "$TEST_ROOT/toolkit/targets/example.test.env"
  grep -q '^ADDRESS=https://example.test$' "$TEST_ROOT/toolkit/targets/example.test.env"
  grep -q '^SCOPE_STATUS=in-scope$' "$TEST_ROOT/toolkit/targets/example.test.env"
  grep -q '^OWNER=platform$' "$TEST_ROOT/toolkit/targets/example.test.env"

  jq -e 'select(.event == "web.assessment.generated" and (.detail | contains("findings=4")))' \
    "$TEST_ROOT/toolkit/sessions/m37-web/ledger.ndjson"
  jq -s -e 'map(select(.kind == "web-assessment-summary" or .kind == "web-assessment-routes" or .kind == "web-assessment-api")) | length == 3' \
    "$TEST_ROOT/toolkit/sessions/m37-web/evidence.ndjson"
  jq -s -e 'map(select(.title == "Missing browser hardening headers" or .title == "HTTP origin does not redirect to HTTPS" or .title == "Metadata routes return application HTML" or .title == "Admin-style routes return successful responses")) | length == 4' \
    "$TEST_ROOT/toolkit/sessions/m37-web/findings.ndjson"
  jq -e 'select(.observation_type == "web_probe" and .target == "example.test")' \
    "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
  jq -e 'select(.observation_type == "http_posture_finding" and .target == "example.test")' \
    "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
  jq -e 'select(.observation_type == "api_probe" and .target == "example.test" and .value.path == "/api/auth/me")' \
    "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
}

@test "atlas web assess preserves URL base path for mounted applications" {
  mkdir -p "$TEST_ROOT/fake-bin"
  export LAB_FAKE_CURL_LOG="$TEST_ROOT/curl-urls.log"
  cat > "$TEST_ROOT/fake-bin/curl" <<'EOF'
#!/usr/bin/env bash
headers=""
body=""
url=""
method="GET"
while [ "$#" -gt 0 ]; do
  case "$1" in
  -D)
    headers="$2"
    shift 2
    ;;
  -o)
    body="$2"
    shift 2
    ;;
  --max-time)
    shift 2
    ;;
  -X)
    method="$2"
    shift 2
    ;;
  -H)
    shift 2
    ;;
  -sS)
    shift
    ;;
  *)
    url="$1"
    shift
    ;;
  esac
done

printf '%s %s\n' "$method" "$url" >> "$LAB_FAKE_CURL_LOG"

{
  printf 'HTTP/1.1 200 OK\r\n'
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Server: fake-edge\r\n'
  printf '\r\n'
} > "$headers"

cat > "$body" <<'HTML'
<!doctype html><html><head><title>Mounted App</title></head><body><div id="root"></div></body></html>
HTML
EOF
  chmod +x "$TEST_ROOT/fake-bin/curl"

  run env LAB_ATLAS_CURL_BIN="$TEST_ROOT/fake-bin/curl" \
    LAB_FAKE_CURL_LOG="$LAB_FAKE_CURL_LOG" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" web assess https://example.test/app/ mounted-web \
    --scope-status in-scope \
    --criticality medium \
    --owner platform \
    --skip-api

  [ "$status" -eq 0 ]
  [[ "$output" == *"web assessment packetized"* ]]
  [[ "$output" == *"target: example.test/app"* ]]
  [[ "$output" == *"base_path: /app"* ]]

  summary_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "summary" { print $2; exit }')"
  routes_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "routes" { print $2; exit }')"

  grep -q 'Base Path: /app' "$summary_path"
  grep -q 'HTTP Origin Checked: http://example.test/app/' "$summary_path"
  grep -q 'https://example.test/app/robots.txt' "$routes_path"
  grep -q '^ADDRESS=https://example.test/app/$' "$TEST_ROOT/toolkit/targets/example.test-app.env"
  grep -q 'GET http://example.test/app/' "$LAB_FAKE_CURL_LOG"
  grep -q 'GET https://example.test/app/admin' "$LAB_FAKE_CURL_LOG"
  ! grep -q 'GET https://example.test/admin' "$LAB_FAKE_CURL_LOG"
}

@test "atlas web assess flags credentialed CORS probe origin" {
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/curl" <<'EOF'
#!/usr/bin/env bash
headers=""
body=""
url=""
method="GET"
origin=""
while [ "$#" -gt 0 ]; do
  case "$1" in
  -D)
    headers="$2"
    shift 2
    ;;
  -o)
    body="$2"
    shift 2
    ;;
  --max-time)
    shift 2
    ;;
  -X)
    method="$2"
    shift 2
    ;;
  -H)
    case "$2" in
    Origin:\ *)
      origin="${2#Origin: }"
      ;;
    esac
    shift 2
    ;;
  -sS)
    shift
    ;;
  *)
    url="$1"
    shift
    ;;
  esac
done

status="200 OK"
content_type="text/html; charset=utf-8"
server="fake-edge"

case "$url" in
https://api.example.test/api/auth/me)
  if [ "$method" = "GET" ]; then
    status="401 Unauthorized"
    content_type="application/json"
  else
    status="204 No Content"
    content_type="text/plain"
  fi
  ;;
esac

{
  printf 'HTTP/1.1 %s\r\n' "$status"
  printf 'Content-Type: %s\r\n' "$content_type"
  printf 'Server: %s\r\n' "$server"
  if [ "$method" = "OPTIONS" ] && [ -n "$origin" ]; then
    printf 'Access-Control-Allow-Origin: %s\r\n' "$origin"
    printf 'Access-Control-Allow-Credentials: true\r\n'
    printf 'Access-Control-Allow-Methods: GET,POST,OPTIONS\r\n'
    printf 'Vary: Origin\r\n'
  fi
  printf '\r\n'
} > "$headers"

if [ "$method" = "OPTIONS" ]; then
  : > "$body"
else
  cat > "$body" <<'HTML'
<!doctype html><html><head><title>Execution OS</title></head><body><div id="root"></div></body></html>
HTML
fi
EOF
  chmod +x "$TEST_ROOT/fake-bin/curl"

  run env LAB_ATLAS_CURL_BIN="$TEST_ROOT/fake-bin/curl" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" web assess https://api.example.test m38-cors \
    --scope-status in-scope \
    --api-path /api/auth/me \
    --cors-origin https://untrusted.example

  [ "$status" -eq 0 ]
  [[ "$output" == *"web assessment packetized"* ]]
  [[ "$output" == *"findings: 5"* ]]

  summary_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "summary" { print $2; exit }')"
  api_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "api" { print $2; exit }')"
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"

  [ -f "$summary_path" ]
  [ -f "$api_path" ]
  [ -f "$report_path" ]

  grep -q 'CORS Probe Origin: https://untrusted.example' "$summary_path"
  grep -q 'https://untrusted.example' "$api_path"
  grep -q 'true' "$api_path"
  grep -q 'Credentialed CORS allows probe origin' "$report_path"

  jq -s -e 'map(select(.kind == "web-assessment-api")) | length == 1' \
    "$TEST_ROOT/toolkit/sessions/m38-cors/evidence.ndjson"
  jq -e 'select(.title == "Credentialed CORS allows probe origin" and .severity == "medium")' \
    "$TEST_ROOT/toolkit/sessions/m38-cors/findings.ndjson"
  jq -e 'select(.observation_type == "cors_posture_finding" and .target == "api.example.test")' \
    "$TEST_ROOT/toolkit/state/intel/observations.jsonl"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" web validation-plan --all

  [ "$status" -eq 0 ]
  [[ "$output" == *"web validation plans queued"* ]]
  [[ "$output" == *"operation: m38-cors"* ]]
  [[ "$output" == *"lane: posture"* ]]
  [[ "$output" == *"considered: 5"* ]]
  [[ "$output" == *"planned: 5"* ]]
  [[ "$output" == *"skipped: 0"* ]]
  [[ "$output" == *"plan_ids:"* ]]

  jq -s -e 'length == 5 and all(.[]; .lane == "posture" and .status == "planned" and .capability == "safe-validation" and (.finding != null))' \
    "$TEST_ROOT/toolkit/sessions/m38-cors/validation-plans.ndjson"
  jq -s -e 'map(select(.reason | contains("Credentialed CORS allows probe origin"))) | length == 1' \
    "$TEST_ROOT/toolkit/sessions/m38-cors/validation-plans.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" web validation-plan --all

  [ "$status" -eq 0 ]
  [[ "$output" == *"planned: 0"* ]]
  [[ "$output" == *"skipped: 5"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" web validation-approve --all --reason "approved bounded web validation"

  [ "$status" -eq 0 ]
  [[ "$output" == *"web validation plans approved"* ]]
  [[ "$output" == *"operation: m38-cors"* ]]
  [[ "$output" == *"considered: 5"* ]]
  [[ "$output" == *"approved: 5"* ]]
  [[ "$output" == *"skipped: 0"* ]]
  [[ "$output" == *"approved_plan_ids:"* ]]

  jq -s -e 'reduce .[] as $record ({}; .[$record.id] = $record) | [.[]] | length == 5 and all(.[]; .status == "approved" and .approval_reason == "approved bounded web validation" and .approved_by != null)' \
    "$TEST_ROOT/toolkit/sessions/m38-cors/validation-plans.ndjson"
  jq -e 'select(.event == "validation.approved")' \
    "$TEST_ROOT/toolkit/sessions/m38-cors/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" web validation-approve --all --reason "approved bounded web validation"

  [ "$status" -eq 0 ]
  [[ "$output" == *"approved: 0"* ]]
  [[ "$output" == *"skipped: 5"* ]]
}

@test "atlas v1 status reports product pillar readiness" {
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status

  [ "$status" -eq 0 ]
  [[ "$output" == *"Atlas V1 Status"* ]]
  [[ "$output" == *"V1 Pillars"* ]]
  [[ "$output" == *"Core CLI"* ]]
  [[ "$output" == *"Target Registry"* ]]
  [[ "$output" == *"Ledger"* ]]
  [[ "$output" == *"ScopeGuard"* ]]
  [[ "$output" == *"Recon"* ]]
  [[ "$output" == *"Action Planner"* ]]
  [[ "$output" == *"Intel Graph"* ]]
  [[ "$output" == *"Evidence"* ]]
  [[ "$output" == *"Findings"* ]]
  [[ "$output" == *"Validation"* ]]
  [[ "$output" == *"Reports"* ]]
  [[ "$output" == *"Retention"* ]]
  [[ "$output" == *"AI Advisor"* ]]
  [[ "$output" == *"Overall: ready"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status --json
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" |
    jq -e '.overall == "ready" and .strict == false and .pillars.core_cli.status == "ready" and .pillars.ai_advisor.required == false'

  run env LAB_ATLAS_AI_ADVISOR=disabled \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status --strict
  [ "$status" -eq 0 ]
  [[ "$output" == *"AI Advisor"* ]]
  [[ "$output" == *"disabled"* ]]
  [[ "$output" == *"Overall: ready"* ]]

  run env LAB_ATLAS_VECTOR_BIN="$TEST_ROOT/toolkit/missing-vector" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status --strict

  [ "$status" -ne 0 ]
  [[ "$output" == *"Action Planner"* ]]
  [[ "$output" == *"missing executable"* ]]
  [[ "$output" == *"Overall: blocked"* ]]
  [[ "$output" == *"Required Not Ready: 1"* ]]

  run env LAB_ATLAS_VECTOR_BIN="$TEST_ROOT/toolkit/missing-vector" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status --json --strict

  [ "$status" -ne 0 ]
  printf '%s\n' "$output" |
    jq -e '.overall == "blocked" and .pillars.action_planner.status == "blocked"'
}

@test "atlas production status reports conservative production blockers" {
  rm -rf "$TEST_ROOT/toolkit/docs/retention/production"
  make_repo_clean_and_synced

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" production status

  [ "$status" -ne 0 ]
  [[ "$output" == *"Atlas Production Readiness"* ]]
  [[ "$output" == *"Production Gates"* ]]
  [[ "$output" == *"V1 Internal Readiness"* ]]
  [[ "$output" == *"Repository Clean"* ]]
  [[ "$output" == *"Upstream Sync"* ]]
  [[ "$output" == *"Release Trust Packet"* ]]
  [[ "$output" == *"Production Contract"* ]]
  [[ "$output" == *"Signing And Provenance"* ]]
  [[ "$output" == *"Production Dry Run"* ]]
  [[ "$output" == *"Overall: not-ready"* ]]
  [[ "$output" == *"Required Not Ready:"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" production status --json

  [ "$status" -ne 0 ]
  printf '%s\n' "$output" |
    jq -e '
      .schema_version == "atlas.production_readiness.v1" and
      .overall == "not-ready" and
      .strict == false and
      .gates.v1_internal_readiness.status == "ready" and
      .gates.repository_clean.status == "ready" and
      .gates.upstream_sync.status == "ready" and
      .gates.production_contract.status == "ready" and
      .gates.release_trust_packet.status == "blocked" and
      .gates.signing_provenance.status == "blocked" and
      .gates.production_dry_run.status == "blocked" and
      .counts.required_not_ready >= 3
    '

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet production-current \
    --json \
    --qa-status pass \
    --qa-note "production status release packet proof"
  [ "$status" -eq 0 ]
  production_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "release_packet_json" { print $2; exit }')"
  [ -f "$production_packet_path" ]
  git -C "$TEST_ROOT/toolkit" add -f "$production_packet_path"
  git -C "$TEST_ROOT/toolkit" commit -m "retain production release packet" >/dev/null
  git -C "$TEST_ROOT/toolkit" update-ref refs/remotes/origin/main HEAD

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" production status --json

  [ "$status" -ne 0 ]
  printf '%s\n' "$output" |
    jq -e '
      .overall == "not-ready" and
      .gates.repository_clean.status == "ready" and
      .gates.upstream_sync.status == "ready" and
      .gates.release_trust_packet.status == "ready" and
      .gates.signing_provenance.status == "blocked" and
      .gates.production_dry_run.status == "blocked" and
      .counts.required_not_ready >= 2
    '

  dry_run_commit="$(git -C "$TEST_ROOT/toolkit" rev-parse HEAD)"
  dry_run_dir="$TEST_ROOT/toolkit/docs/retention/production"
  dry_run_note="$dry_run_dir/PRODUCTION_DRY_RUN_2026-04-27.md"
  mkdir -p "$dry_run_dir"
  cat > "$dry_run_note" <<EOF
# Atlas Production Dry Run

Commit: $dry_run_commit
Result: retained
QA status: pass
V1 readiness: pass
Production status observed: not-ready

Known blockers:
- signing/provenance is still blocked

No production-ready claim is made.
EOF
  git -C "$TEST_ROOT/toolkit" add "$dry_run_note"
  git -C "$TEST_ROOT/toolkit" commit -m "retain production dry run" >/dev/null
  git -C "$TEST_ROOT/toolkit" update-ref refs/remotes/origin/main HEAD

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" production status --json

  [ "$status" -ne 0 ]
  printf '%s\n' "$output" |
    jq -e '
      .overall == "not-ready" and
      .gates.repository_clean.status == "ready" and
      .gates.upstream_sync.status == "ready" and
      .gates.release_trust_packet.status == "blocked" and
      .gates.signing_provenance.status == "blocked" and
      .gates.production_dry_run.status == "ready" and
      .counts.required_not_ready >= 2
    '

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" production status --strict

  [ "$status" -ne 0 ]
  [[ "$output" == *"Overall: not-ready"* ]]
}

@test "atlas release packet writes and verifies metadata-only release trust packet" {
  make_repo_clean_and_synced

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet m33-release \
    --qa-status pass \
    --qa-note "dev-qa passed in release verification"

  [ "$status" -eq 0 ]
  [[ "$output" == *"release trust packet written"* ]]
  packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "release_packet" { print $2; exit }')"
  [ -f "$packet_path" ]
  [ "$packet_path" = "$TEST_ROOT/toolkit/docs/retention/releases/m33-release.md" ]

  grep -q '^# Atlas Release Trust Packet$' "$packet_path"
  grep -q 'No raw runtime artifacts, target secrets, session contents, packet captures, or evidence bodies are included' "$packet_path"
  grep -q 'QA status: pass' "$packet_path"
  grep -q "QA command: \`nix-shell --run './bin/dev-qa'\`" "$packet_path"
  grep -q 'QA note: dev-qa passed in release verification' "$packet_path"
  grep -q '^## V1 Readiness JSON$' "$packet_path"
  grep -q '"overall": "ready"' "$packet_path"
  grep -q '"required_not_ready": 0' "$packet_path"
  grep -q 'docs/retention/milestones/MILESTONE_32.md' "$packet_path"
  grep -q 'Core CLI: shell-native interface; no multi-user server yet' "$packet_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"release trust packet verified"* ]]
  [[ "$output" == *"Repository State: ok clean"* ]]
  [[ "$output" == *"Upstream Sync: ok synced"* ]]
  [[ "$output" == *"QA Status: ok pass"* ]]
  [[ "$output" == *"V1 Readiness: ok overall=ready required_not_ready=0"* ]]
  [[ "$output" == *"Operation Trust Chain: ok not-recorded"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet m35-release-json \
    --json \
    --qa-status pass \
    --qa-note "dev-qa passed in json release verification"

  [ "$status" -eq 0 ]
  [[ "$output" == *"release trust packet written"* ]]
  json_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "release_packet_json" { print $2; exit }')"
  [ -f "$json_packet_path" ]
  [ "$json_packet_path" = "$TEST_ROOT/toolkit/docs/retention/releases/m35-release-json.json" ]

  jq -e '
    .schema_version == "atlas.release_trust.v1" and
    .metadata_only == true and
    .qa.status == "pass" and
    .readiness.overall == "ready" and
    .readiness.counts.required_not_ready == 0 and
    (.retention_notes | index("docs/retention/milestones/MILESTONE_32.md")) and
    any(.known_limitations[]; .pillar == "Core CLI")
  ' "$json_packet_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$json_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Schema: ok atlas.release_trust.v1"* ]]
  [[ "$output" == *"Metadata Only: ok true"* ]]
  [[ "$output" == *"Operation Trust Chain: ok not-recorded"* ]]
  [[ "$output" == *"release trust packet verified"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify m35-release-json
  [ "$status" -eq 0 ]
  [[ "$output" == *"Schema: ok atlas.release_trust.v1"* ]]

  historical_commit="$(jq -r '.commit' "$json_packet_path")"
  future_note="$TEST_ROOT/toolkit/docs/retention/milestones/MILESTONE_999.md"
  printf '# Milestone 999: Future Note\n' > "$future_note"
  git -C "$TEST_ROOT/toolkit" add "$future_note"
  git -C "$TEST_ROOT/toolkit" commit -m "add future retention note" >/dev/null

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$json_packet_path" --commit "$historical_commit"
  [ "$status" -eq 0 ]
  [[ "$output" == *"release trust packet verified"* ]]
  [[ "$output" != *"MILESTONE_999.md"* ]]

  jq '.qa.status = "fail"' "$json_packet_path" > "$TEST_ROOT/bad-json-qa.json"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$TEST_ROOT/bad-json-qa.json"
  [ "$status" -ne 0 ]
  [[ "$output" == *"QA Status: fail expected=pass actual=fail"* ]]

  jq '.schema_version = "atlas.release_trust.v0"' "$json_packet_path" > "$TEST_ROOT/bad-json-schema.json"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$TEST_ROOT/bad-json-schema.json"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Schema: fail expected=atlas.release_trust.v1"* ]]

  cp "$packet_path" "$TEST_ROOT/bad-qa.md"
  sed -i 's/QA status: pass/QA status: fail/' "$TEST_ROOT/bad-qa.md"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$TEST_ROOT/bad-qa.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"QA Status: fail expected=pass actual=fail"* ]]

  cp "$packet_path" "$TEST_ROOT/bad-state.md"
  sed -i 's/Repository state before packet: clean/Repository state before packet: dirty/' "$TEST_ROOT/bad-state.md"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$TEST_ROOT/bad-state.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Repository State: fail expected=clean actual=dirty"* ]]

  cp "$packet_path" "$TEST_ROOT/bad-readiness.md"
  sed -i 's/"overall": "ready"/"overall": "blocked"/' "$TEST_ROOT/bad-readiness.md"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$TEST_ROOT/bad-readiness.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"V1 Readiness: fail overall=blocked required_not_ready=0"* ]]

  printf '\nrelease packet dirty gate\n' >> "$TEST_ROOT/toolkit/README.md"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet dirty-release --qa-status pass
  [ "$status" -ne 0 ]
  [[ "$output" == *"release packet requires a clean repository"* ]]
  git -C "$TEST_ROOT/toolkit" checkout -- README.md

  git -C "$TEST_ROOT/toolkit" update-ref refs/remotes/origin/main HEAD^
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet unsynced-release --qa-status pass
  [ "$status" -ne 0 ]
  [[ "$output" == *"release packet requires synced upstream state"* ]]
  git -C "$TEST_ROOT/toolkit" update-ref refs/remotes/origin/main HEAD

  run env LAB_ATLAS_VECTOR_BIN="$TEST_ROOT/toolkit/missing-vector" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet not-ready-release --qa-status pass
  [ "$status" -ne 0 ]
  [[ "$output" == *"release packet requires v1 readiness overall=ready"* ]]

  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/release-candidate-gap.txt"
  printf 'release candidate evidence\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start release-candidate-gap demo-node authorized release candidate gap
  [ "$status" -eq 0 ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report release-candidate-gap release-candidate-report
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet release-candidate-gap \
    --operation release-candidate-gap \
    --qa-status pass
  [ "$status" -ne 0 ]
  [[ "$output" == *"release packet requires operation trust chain status=current"* ]]
}

@test "atlas v1 status fails strict on operation evidence and governance gaps" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/v1-artifact.txt"
  late_artifact="$TEST_ROOT/v1-late-artifact.txt"
  printf 'v1 readiness evidence\n' > "$artifact"
  printf 'v1 late evidence\n' > "$late_artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start v1-ledger-gap demo-node authorized v1 ledger check
  [ "$status" -eq 0 ]
  rm "$TEST_ROOT/toolkit/sessions/v1-ledger-gap/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status v1-ledger-gap --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"Ledger"* ]]
  [[ "$output" == *"operation ledger is missing or empty"* ]]
  [[ "$output" == *"Overall: blocked"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start v1-scope-gap demo-node authorized v1 scope check
  [ "$status" -eq 0 ]
  rm "$TEST_ROOT/toolkit/sessions/v1-scope-gap/scope.snapshot.env"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status v1-scope-gap --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"ScopeGuard"* ]]
  [[ "$output" == *"operation scope snapshot is missing"* ]]
  [[ "$output" == *"Overall: blocked"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start v1-evidence-gap demo-node authorized v1 evidence check
  [ "$status" -eq 0 ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence bundle v1-bundle
  [ "$status" -eq 0 ]
  rm "$TEST_ROOT/toolkit/sessions/v1-evidence-gap/evidence-bundles/v1-bundle/manifest.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status v1-evidence-gap --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"Evidence"* ]]
  [[ "$output" == *"latest evidence bundle manifest is missing"* ]]
  [[ "$output" == *"Overall: blocked"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start v1-report-stale demo-node authorized v1 report check
  [ "$status" -eq 0 ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report v1-report-stale v1-report
  [ "$status" -eq 0 ]
  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$late_artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status v1-report-stale --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"Reports"* ]]
  [[ "$output" == *"operation report freshness is stale"* ]]
  [[ "$output" == *"Overall: blocked"* ]]
}

@test "atlas profiles list, show, and snapshot operation scope" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
TAGS='lab web'
OWNER=platform
CREATED_AT=2026-04-23T20:53:16Z
EOF

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" profile list
  [ "$status" -eq 0 ]
  [[ "$output" == *"default"* ]]
  [[ "$output" == *"htb-starting-point"* ]]
  [[ "$output" == *"Hack The Box Starting Point authorized lab profile"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" profile show default
  [ "$status" -eq 0 ]
  [[ "$output" == *"Atlas Profile"* ]]
  [[ "$output" == *"Profile: default"* ]]
  [[ "$output" == *"Bounded authorized reconnaissance"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" profile show htb-starting-point
  [ "$status" -eq 0 ]
  [[ "$output" == *"Profile: htb-starting-point"* ]]
  [[ "$output" == *"Hack The Box Starting Point assessment"* ]]
  [[ "$output" == *"Recommended Workflow"* ]]
  [[ "$output" == *"op recon full-exposure"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start --profile htb-starting-point htb-profile-op demo-node authorized HTB profile
  [ "$status" -eq 0 ]
  [[ "$output" == *"profile: htb-starting-point"* ]]
  grep -q '^SCOPE_PROFILE=htb-starting-point$' "$TEST_ROOT/toolkit/sessions/htb-profile-op/scope.snapshot.env"
  grep -q '^BLOCKED_CAPABILITIES=.*intrusive-validation' "$TEST_ROOT/toolkit/sessions/htb-profile-op/scope.snapshot.env"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op show htb-profile-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Profile: htb-starting-point"* ]]
  [[ "$output" == *"Hack The Box Starting Point assessment"* ]]
  [[ "$output" == *"confirm target reachability through the active HTB lab path"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report htb-profile-op htb-profile-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q 'Hack The Box Starting Point assessment' "$report_path"
  grep -q 'confirm target reachability through the active HTB lab path' "$report_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" profile show missing-profile
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown Atlas profile"* ]]
}

@test "atlas doctor reports runtime health and missing adapters" {
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" doctor

  [ "$status" -eq 0 ]
  [[ "$output" == *"Atlas Doctor"* ]]
  [[ "$output" == *"Core Paths"* ]]
  [[ "$output" == *"Shared Intel"* ]]
  [[ "$output" == *"Atlas Adapters"* ]]
  [[ "$output" == *"wiremap"* ]]
  [[ "$output" == *"vector"* ]]
  [[ "$output" == *"Status: ok"* ]]

  run env LAB_ATLAS_VECTOR_BIN="$TEST_ROOT/toolkit/missing-vector" \
    "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" doctor

  [ "$status" -ne 0 ]
  [[ "$output" == *"vector"* ]]
  [[ "$output" == *"fail"* ]]
  [[ "$output" == *"Status: attention required"* ]]
}

@test "atlas operation keeps target key and stores target address separately" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
TAGS='lab web'
OWNER=platform
CREATED_AT=2026-04-23T20:53:16Z
EOF

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start cutover demo-node runtime smoke

  [ "$status" -eq 0 ]
  [[ "$output" == *"target: demo-node"* ]]
  [[ "$output" == *"address: 10.10.10.10"* ]]
  [[ "$output" == *"scope_status: in-scope"* ]]
  [[ "$output" == *"criticality: high"* ]]
  [[ "$output" == *"tags: lab web"* ]]
  [[ "$output" == *"owner: platform"* ]]
  grep -q '^TARGET=demo-node$' "$TEST_ROOT/toolkit/sessions/cutover/session.env"
  grep -q '^TARGET_ADDRESS=10.10.10.10$' "$TEST_ROOT/toolkit/sessions/cutover/session.env"
  grep -q '^TARGET_SCOPE_STATUS=in-scope$' "$TEST_ROOT/toolkit/sessions/cutover/session.env"
  grep -q '^TARGET_CRITICALITY=high$' "$TEST_ROOT/toolkit/sessions/cutover/session.env"
  grep -q '^TARGET_SCOPE_STATUS=in-scope$' "$TEST_ROOT/toolkit/sessions/cutover/scope.snapshot.env"
  grep -q '^TARGET_CRITICALITY=high$' "$TEST_ROOT/toolkit/sessions/cutover/scope.snapshot.env"
  grep -q '^SCOPE_TARGET=demo-node$' "$TEST_ROOT/toolkit/sessions/cutover/scope.snapshot.env"
  grep -q 'active-recon' "$TEST_ROOT/toolkit/sessions/cutover/scope.snapshot.env"
  jq -e 'select(.event == "op.started" and .op == "cutover" and .target == "demo-node")' \
    "$TEST_ROOT/toolkit/sessions/cutover/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op status cutover
  [ "$status" -eq 0 ]
  [[ "$output" == *"Target: demo-node -> 10.10.10.10"* ]]
  [[ "$output" == *"Target Scope: in-scope"* ]]
  [[ "$output" == *"Target Criticality: high"* ]]
  [[ "$output" == *"Target Owner: platform"* ]]
  [[ "$output" == *"Target Tags: lab web"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op show cutover
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Scope"* ]]
  [[ "$output" == *"Bounded authorized reconnaissance"* ]]
  [[ "$output" == *"Allowed Actions"* ]]
  [[ "$output" == *"Explicitly Out Of Scope"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report cutover cutover-report
  [ "$status" -eq 0 ]
  [[ "$output" == *"operation report written"* ]]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q '^# Atlas Operation Report$' "$report_path"
  grep -q '^## Commands Run$' "$report_path"
  grep -q '^## Artifacts$' "$report_path"
  grep -q 'Target Scope Status: in-scope' "$report_path"
  grep -q 'Target Criticality: high' "$report_path"
  grep -q 'atlas op start cutover demo-node runtime smoke' "$report_path"
  jq -e 'select(.event == "report.generated" and .status == "ok")' \
    "$TEST_ROOT/toolkit/sessions/cutover/ledger.ndjson"
}

@test "atlas scopeguard checks active operation target and records preflight" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start scoped demo-node authorized scope
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" scope status
  [ "$status" -eq 0 ]
  [[ "$output" == *"ScopeGuard"* ]]
  [[ "$output" == *"Allowed: read-only passive-recon active-recon safe-validation"* ]]
  [[ "$output" == *"Blocked: destructive persistence credential-spraying denial-of-service out-of-scope-network"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" scope check active-recon demo-node
  [ "$status" -eq 0 ]
  [[ "$output" == *"scope allowed"* ]]
  [[ "$output" == *"tier: 2"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" scope check active-recon 10.10.10.10
  [ "$status" -eq 0 ]
  [[ "$output" == *"scope allowed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" scope check active-recon other-node
  [ "$status" -ne 0 ]
  [[ "$output" == *"scope refused"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" scope check safe-validation demo-node
  [ "$status" -ne 0 ]
  [[ "$output" == *"approval required"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" approval grant safe-validation bounded validation approved
  [ "$status" -eq 0 ]
  [[ "$output" == *"approval recorded"* ]]
  [[ "$output" == *"tier: 3"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" approval list
  [ "$status" -eq 0 ]
  [[ "$output" == *"safe-validation"* ]]
  [[ "$output" == *"bounded validation approved"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" scope check safe-validation demo-node
  [ "$status" -eq 0 ]
  [[ "$output" == *"scope allowed"* ]]

  jq -e 'select(.event == "scope.preflight" and .status == "allowed" and .capability == "active-recon")' \
    "$TEST_ROOT/toolkit/sessions/scoped/ledger.ndjson"
  jq -e 'select(.event == "scope.preflight" and .status == "denied" and (.detail | contains("other-node")))' \
    "$TEST_ROOT/toolkit/sessions/scoped/ledger.ndjson"
  jq -e 'select(.event == "approval.granted" and .capability == "safe-validation")' \
    "$TEST_ROOT/toolkit/sessions/scoped/ledger.ndjson"
  jq -e 'select(.capability == "safe-validation" and .status == "approved")' \
    "$TEST_ROOT/toolkit/sessions/scoped/approvals.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit scoped
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Audit"* ]]
  [[ "$output" == *"Audit Flags"* ]]
  [[ "$output" == *"denied preflight:"* ]]
  [[ "$output" == *"other-node"* ]]

  cat > "$TEST_ROOT/toolkit/targets/retired-node.env" <<'EOF'
NAME=retired-node
ADDRESS=10.10.10.99
SCOPE_STATUS=out-of-scope
CRITICALITY=low
CREATED_AT=2026-04-23T20:53:16Z
EOF
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start blocked retired-node should fail
  [ "$status" -ne 0 ]
  [[ "$output" == *"marked out-of-scope"* ]]
  [ ! -d "$TEST_ROOT/toolkit/sessions/blocked" ]
}

@test "atlas direct execution routes fail closed or use operation scope" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
TAGS='lab web'
OWNER=platform
CREATED_AT=2026-04-23T20:53:16Z
EOF
  mkdir -p "$TEST_ROOT/toolkit/state/intel"
  cat >> "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/nmap" <<'EOF'
#!/usr/bin/env bash
target="${*: -1}"
printf 'Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-24 00:00 UTC\n'
printf 'Nmap scan report for %s\n' "$target"
printf 'Host is up, received user-set (0.00025s latency).\n'
printf 'PORT   STATE SERVICE REASON  VERSION\n'
printf '22/tcp open  ssh     syn-ack OpenSSH 9.7\n'
printf '\nNmap done: 1 IP address (1 host up) scanned in 0.04 seconds\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/nmap"
  export LAB_VECTOR_NMAP_BIN="$TEST_ROOT/fake-bin/nmap"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" action run validate demo-node "Direct Validate"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no active operation"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" recon workflow run perimeter-sweep demo-node
  [ "$status" -ne 0 ]
  [[ "$output" == *"scoped execution required"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start direct-scope demo-node authorized direct route
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" action candidates other-node
  [ "$status" -ne 0 ]
  [[ "$output" == *"scope refused"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" action run validate demo-node "Direct Validate"
  [ "$status" -ne 0 ]
  [[ "$output" == *"approval required"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" approval grant safe-validation approved direct route validation
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" action run validate demo-node "Direct Validate"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: success"* ]]
  [[ "$output" == *"operation_action_session"* ]]

  jq -e 'select(.event == "tool.completed" and (.detail | contains("legacy-route lane=validate")))' \
    "$TEST_ROOT/toolkit/sessions/direct-scope/ledger.ndjson"
}

@test "atlas validation plans require approval and track execution" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","entity_type":"service","entity_id":"service:demo-node:22/tcp","target":"demo-node","attributes":{"portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl"
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/nmap" <<'EOF'
#!/usr/bin/env bash
target="${*: -1}"
printf 'Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-24 00:00 UTC\n'
printf 'Nmap scan report for %s\n' "$target"
printf 'Host is up, received user-set (0.00025s latency).\n'
printf 'PORT   STATE SERVICE REASON  VERSION\n'
printf '22/tcp open  ssh     syn-ack OpenSSH 9.7\n'
printf '\nNmap done: 1 IP address (1 host up) scanned in 0.04 seconds\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/nmap"
  export LAB_VECTOR_NMAP_BIN="$TEST_ROOT/fake-bin/nmap"
  artifact="$TEST_ROOT/validation-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation list
  [ "$status" -ne 0 ]
  [[ "$output" == *"no active operation"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start --profile htb-starting-point validation-op demo-node authorized validation planning
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation list
  [ "$status" -eq 0 ]
  [[ "$output" == *"no validation plans recorded yet"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan credentials --reason "credential checks are not part of this profile"
  [ "$status" -ne 0 ]
  [[ "$output" == *"validation lane 'credentials' is not allowed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan validate \
    --finding "$finding_id" \
    --evidence "$evidence_id" \
    --reason "confirm observed SSH service"
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation plan recorded"* ]]
  [[ "$output" == *"status: planned"* ]]
  [[ "$output" == *"Lane Plan"* ]]
  plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  plan_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "plan" { print $2; exit }')"
  [ -n "$plan_id" ]
  [ -f "$plan_path" ]
  grep -q 'Lane Plan' "$plan_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation show "$plan_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Validation Plan"* ]]
  [[ "$output" == *"Status: planned"* ]]
  [[ "$output" == *"Finding: $finding_id"* ]]
  [[ "$output" == *"Evidence: $evidence_id"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation run "$plan_id" "Validation Session"
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires approval before run"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation approve "$plan_id" bounded validation approved
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation plan approved"* ]]
  [[ "$output" == *"status: approved"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" approval list
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation_plan=$plan_id bounded validation approved"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation list
  [ "$status" -eq 0 ]
  [[ "$output" == *"$plan_id"* ]]
  [[ "$output" == *"approved"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation run "$plan_id" "Validation Session"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: success"* ]]
  [[ "$output" == *"validation_plan: $plan_id"* ]]
  [[ "$output" == *"validation_status: executed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation show "$plan_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: executed"* ]]
  [[ "$output" == *"Result: success"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding update "$finding_id" \
    --level validated \
    --status validated \
    --validation "$plan_id" \
    --note "confirmed by validation run"
  [ "$status" -eq 0 ]
  [[ "$output" == *"finding updated"* ]]
  [[ "$output" == *"level: validated"* ]]
  [[ "$output" == *"status: validated"* ]]
  [[ "$output" == *"validations: $plan_id"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding show "$finding_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Level: validated"* ]]
  [[ "$output" == *"Status: validated"* ]]
  [[ "$output" == *"Validation Plans: $plan_id"* ]]
  [[ "$output" == *"Latest Note: confirmed by validation run"* ]]
  [[ "$output" == *"History"* ]]
  [[ "$output" == *"recorded"* ]]
  [[ "$output" == *"updated"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op brief
  [ "$status" -eq 0 ]
  [[ "$output" == *"Validation Plans"* ]]
  [[ "$output" == *"$plan_id"* ]]
  [[ "$output" == *"executed"* ]]
  [[ "$output" == *"Latest Finding:"* ]]
  [[ "$output" == *"validated/validated SSH management reachable"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report validation-op validation-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q '## Executive Summary' "$report_path"
  grep -q '## Remediation Priorities' "$report_path"
  grep -q '## Validation Plans' "$report_path"
  grep -q '### Validated' "$report_path"
  grep -q "$plan_id" "$report_path"
  grep -q 'Result: success' "$report_path"
  grep -q 'Validation plans:' "$report_path"
  grep -q 'confirmed by validation run' "$report_path"

  jq -e \
    --arg plan_id "$plan_id" \
    --arg finding_id "$finding_id" \
    --arg evidence_id "$evidence_id" \
    'select(.id == $plan_id and .status == "planned" and .finding == $finding_id and (.evidence | index($evidence_id)))' \
    "$TEST_ROOT/toolkit/sessions/validation-op/validation-plans.ndjson"
  jq -e --arg plan_id "$plan_id" 'select(.id == $plan_id and .status == "approved")' \
    "$TEST_ROOT/toolkit/sessions/validation-op/validation-plans.ndjson"
  jq -e --arg plan_id "$plan_id" 'select(.id == $plan_id and .status == "executed" and .result_status == "success")' \
    "$TEST_ROOT/toolkit/sessions/validation-op/validation-plans.ndjson"
  jq -e --arg plan_id "$plan_id" 'select(.event == "validation.planned" and (.detail | contains($plan_id)))' \
    "$TEST_ROOT/toolkit/sessions/validation-op/ledger.ndjson"
  jq -e --arg plan_id "$plan_id" 'select(.event == "validation.approved" and (.detail | contains($plan_id)))' \
    "$TEST_ROOT/toolkit/sessions/validation-op/ledger.ndjson"
  jq -e --arg plan_id "$plan_id" 'select(.event == "validation.executed" and (.detail | contains($plan_id)))' \
    "$TEST_ROOT/toolkit/sessions/validation-op/ledger.ndjson"
  jq -e --arg finding_id "$finding_id" --arg plan_id "$plan_id" \
    'select(.id == $finding_id and .level == "validated" and .status == "validated" and (.validations | index($plan_id)))' \
    "$TEST_ROOT/toolkit/sessions/validation-op/findings.ndjson"
  jq -e --arg finding_id "$finding_id" 'select(.event == "finding.updated" and (.detail | contains($finding_id)))' \
    "$TEST_ROOT/toolkit/sessions/validation-op/ledger.ndjson"
}

@test "atlas validation retest links evidence and resolves findings" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","entity_type":"service","entity_id":"service:demo-node:22/tcp","target":"demo-node","attributes":{"portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl"
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/nmap" <<'EOF'
#!/usr/bin/env bash
target="${*: -1}"
printf 'Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-24 00:00 UTC\n'
printf 'Nmap scan report for %s\n' "$target"
printf 'Host is up, received user-set (0.00025s latency).\n'
printf 'PORT   STATE SERVICE REASON  VERSION\n'
printf '22/tcp open  ssh     syn-ack OpenSSH 9.7\n'
printf '\nNmap done: 1 IP address (1 host up) scanned in 0.04 seconds\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/nmap"
  export LAB_VECTOR_NMAP_BIN="$TEST_ROOT/fake-bin/nmap"

  artifact="$TEST_ROOT/validation-artifact.txt"
  retest_artifact="$TEST_ROOT/retest-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"
  printf 'ssh no longer reachable after firewall change\n' > "$retest_artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start --profile htb-starting-point retest-op demo-node authorized retest loop
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan validate \
    --finding "$finding_id" \
    --evidence "$evidence_id" \
    --reason "confirm observed SSH service"
  [ "$status" -eq 0 ]
  plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$plan_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation approve "$plan_id" bounded validation approved
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation run "$plan_id" "Validation Session"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding update "$finding_id" \
    --level validated \
    --status validated \
    --validation "$plan_id" \
    --note "confirmed by validation run"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$retest_artifact" --kind retest-output
  [ "$status" -eq 0 ]
  retest_evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$retest_evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation retest "$plan_id" \
    --result resolved \
    --evidence "$retest_evidence_id" \
    --note "remediation confirmed by retest"
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation retest recorded"* ]]
  [[ "$output" == *"result: resolved"* ]]
  [[ "$output" == *"finding: $finding_id"* ]]
  [[ "$output" == *"finding_status: resolved"* ]]
  [[ "$output" == *"$retest_evidence_id"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation show "$plan_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: executed"* ]]
  [[ "$output" == *"Result: success"* ]]
  [[ "$output" == *"Retest Result: resolved"* ]]
  [[ "$output" == *"Retest Note: remediation confirmed by retest"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding show "$finding_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Level: validated"* ]]
  [[ "$output" == *"Status: resolved"* ]]
  [[ "$output" == *"Validation Plans: $plan_id"* ]]
  [[ "$output" == *"$retest_evidence_id"* ]]
  [[ "$output" == *"Latest Note: remediation confirmed by retest"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op brief
  [ "$status" -eq 0 ]
  [[ "$output" == *"Latest Validation: $plan_id validate executed result=resolved"* ]]
  [[ "$output" == *"Latest Finding:"* ]]
  [[ "$output" == *"low/validated/resolved SSH management reachable"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report retest-op retest-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q 'Retest: resolved' "$report_path"
  grep -q 'Retest note: remediation confirmed by retest' "$report_path"
  grep -q 'resolved: SSH management reachable' "$report_path"

  jq -s -e \
    --arg plan_id "$plan_id" \
    --arg finding_id "$finding_id" \
    --arg evidence_id "$evidence_id" \
    --arg retest_evidence_id "$retest_evidence_id" \
    'map(select(.id == $plan_id)) | last | select(.status == "executed" and .finding == $finding_id and .retest_result == "resolved" and (.evidence | index($evidence_id)) and (.evidence | index($retest_evidence_id)))' \
    "$TEST_ROOT/toolkit/sessions/retest-op/validation-plans.ndjson"
  jq -s -e \
    --arg finding_id "$finding_id" \
    --arg plan_id "$plan_id" \
    --arg retest_evidence_id "$retest_evidence_id" \
    'map(select(.id == $finding_id)) | last | select(.level == "validated" and .status == "resolved" and (.validations | index($plan_id)) and (.evidence | index($retest_evidence_id)))' \
    "$TEST_ROOT/toolkit/sessions/retest-op/findings.ndjson"
  jq -e --arg plan_id "$plan_id" 'select(.event == "validation.retested" and (.detail | contains($plan_id)))' \
    "$TEST_ROOT/toolkit/sessions/retest-op/ledger.ndjson"
  jq -e --arg finding_id "$finding_id" 'select(.event == "finding.updated" and (.detail | contains($finding_id)) and (.detail | contains("status=resolved")))' \
    "$TEST_ROOT/toolkit/sessions/retest-op/ledger.ndjson"
}

@test "atlas validation retest still-open promotes finding to validated open" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","entity_type":"service","entity_id":"service:demo-node:22/tcp","target":"demo-node","attributes":{"portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl"
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/nmap" <<'EOF'
#!/usr/bin/env bash
target="${*: -1}"
printf 'Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-24 00:00 UTC\n'
printf 'Nmap scan report for %s\n' "$target"
printf 'Host is up, received user-set (0.00025s latency).\n'
printf 'PORT   STATE SERVICE REASON  VERSION\n'
printf '22/tcp open  ssh     syn-ack OpenSSH 9.7\n'
printf '\nNmap done: 1 IP address (1 host up) scanned in 0.04 seconds\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/nmap"
  export LAB_VECTOR_NMAP_BIN="$TEST_ROOT/fake-bin/nmap"

  artifact="$TEST_ROOT/validation-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start --profile htb-starting-point still-open-op demo-node authorized still-open retest loop
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan validate \
    --finding "$finding_id" \
    --evidence "$evidence_id" \
    --reason "confirm observed SSH service"
  [ "$status" -eq 0 ]
  plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$plan_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation approve "$plan_id" bounded validation approved
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation run "$plan_id" "Validation Session"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation retest "$plan_id" \
    --result still-open \
    --note "finding remains observable after validation"
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation retest recorded"* ]]
  [[ "$output" == *"result: still-open"* ]]
  [[ "$output" == *"finding_status: open"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding show "$finding_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Level: validated"* ]]
  [[ "$output" == *"Status: open"* ]]
  [[ "$output" == *"Validation Plans: $plan_id"* ]]
  [[ "$output" == *"Latest Note: finding remains observable after validation"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report still-open-op still-open-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q 'Findings: 1 total, 0 observed, 0 inferred, 1 validated' "$report_path"
  grep -q '### Validated' "$report_path"
  grep -q 'low / high / open: SSH management reachable' "$report_path"
  grep -q 'Retest: still-open' "$report_path"

  jq -s -e \
    --arg finding_id "$finding_id" \
    --arg plan_id "$plan_id" \
    'map(select(.id == $finding_id)) | last | select(.level == "validated" and .status == "open" and (.validations | index($plan_id)))' \
    "$TEST_ROOT/toolkit/sessions/still-open-op/findings.ndjson"
}

@test "atlas validation supersede links obsolete run to successful replacement" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","entity_type":"service","entity_id":"service:demo-node:22/tcp","target":"demo-node","attributes":{"portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl"
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"
  printf 'fail\n' > "$TEST_ROOT/nmap-mode"
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/nmap" <<'EOF'
#!/usr/bin/env bash
mode="$(cat "$TEST_ROOT/nmap-mode")"
target="${*: -1}"
if [ "$mode" = "fail" ]; then
  printf 'network unavailable in sandbox for %s\n' "$target" >&2
  exit 1
fi
printf 'Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-24 00:00 UTC\n'
printf 'Nmap scan report for %s\n' "$target"
printf 'Host is up, received user-set (0.00025s latency).\n'
printf 'PORT   STATE SERVICE REASON  VERSION\n'
printf '22/tcp open  ssh     syn-ack OpenSSH 9.7\n'
printf '\nNmap done: 1 IP address (1 host up) scanned in 0.04 seconds\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/nmap"
  export LAB_VECTOR_NMAP_BIN="$TEST_ROOT/fake-bin/nmap"

  artifact="$TEST_ROOT/validation-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start --profile htb-starting-point supersede-op demo-node authorized supersession loop
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan validate \
    --finding "$finding_id" \
    --evidence "$evidence_id" \
    --reason "first validation attempt"
  [ "$status" -eq 0 ]
  failed_plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$failed_plan_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation approve "$failed_plan_id" approved failed attempt
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation run "$failed_plan_id" "Failed Validation Session"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: failed"* ]]
  [[ "$output" == *"validation_status: executed"* ]]

  printf 'success\n' > "$TEST_ROOT/nmap-mode"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan validate \
    --finding "$finding_id" \
    --evidence "$evidence_id" \
    --reason "replacement validation attempt"
  [ "$status" -eq 0 ]
  replacement_plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$replacement_plan_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation approve "$replacement_plan_id" approved replacement attempt
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation run "$replacement_plan_id" "Replacement Validation Session"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: success"* ]]
  [[ "$output" == *"validation_status: executed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation supersede "$failed_plan_id" \
    --by "$replacement_plan_id" \
    --reason "first run blocked by sandbox network"
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation plan superseded"* ]]
  [[ "$output" == *"status: superseded"* ]]
  [[ "$output" == *"replacement: $replacement_plan_id"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation show "$failed_plan_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: superseded"* ]]
  [[ "$output" == *"Result: failed"* ]]
  [[ "$output" == *"Superseded By: $replacement_plan_id"* ]]
  [[ "$output" == *"Superseded Reason: first run blocked by sandbox network"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation list
  [ "$status" -eq 0 ]
  [[ "$output" == *"$failed_plan_id"* ]]
  [[ "$output" == *"superseded"* ]]
  [[ "$output" == *"$replacement_plan_id"* ]]
  [[ "$output" == *"executed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report supersede-op supersede-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q "$failed_plan_id / validate / safe-validation / superseded" "$report_path"
  grep -q "Superseded by: $replacement_plan_id" "$report_path"
  grep -q "Superseded reason: first run blocked by sandbox network" "$report_path"

  jq -s -e \
    --arg failed_plan_id "$failed_plan_id" \
    --arg replacement_plan_id "$replacement_plan_id" \
    'map(select(.id == $failed_plan_id)) | last | select(.status == "superseded" and .result_status == "failed" and .superseded_by_plan == $replacement_plan_id)' \
    "$TEST_ROOT/toolkit/sessions/supersede-op/validation-plans.ndjson"
  jq -e --arg failed_plan_id "$failed_plan_id" --arg replacement_plan_id "$replacement_plan_id" \
    'select(.event == "validation.superseded" and (.detail | contains($failed_plan_id)) and (.detail | contains($replacement_plan_id)))' \
    "$TEST_ROOT/toolkit/sessions/supersede-op/ledger.ndjson"
}

@test "atlas operation readiness reports closure blockers and ready state" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/readiness-artifact.txt"
  late_artifact="$TEST_ROOT/readiness-late-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"
  printf 'late closeout screenshot reference\n' > "$late_artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start readiness-op demo-node authorized readiness review
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id" \
    --recommendation "Restrict SSH to the management subnet"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Readiness"* ]]
  [[ "$output" == *"Evidence Records: 1"* ]]
  [[ "$output" == *"Open Findings: 1"* ]]
  [[ "$output" == *"Pending Validation: 0"* ]]
  [[ "$output" == *"Latest Report: none generated yet"* ]]
  [[ "$output" == *"Report Freshness: missing"* ]]
  [[ "$output" == *"Evidence Bundle: none generated yet"* ]]
  [[ "$output" == *"Bundle Freshness: missing"* ]]
  [[ "$output" == *"Latest Handoff: none generated yet"* ]]
  [[ "$output" == *"Handoff Freshness: missing"* ]]
  [[ "$output" == *"Latest Closeout: none generated yet"* ]]
  [[ "$output" == *"Closeout Freshness: missing"* ]]
  [[ "$output" == *"Latest Audit Packet: none generated yet"* ]]
  [[ "$output" == *"Audit Packet Freshness: missing"* ]]
  [[ "$output" == *"Latest Archive Packet: none generated yet"* ]]
  [[ "$output" == *"Archive Packet Freshness: missing"* ]]
  [[ "$output" == *"Close Readiness: attention-required"* ]]
  [[ "$output" == *"Resolve, accept, or retest unresolved findings before closure."* ]]
  [[ "$output" == *"$finding_id"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op close readiness-op
  [ "$status" -ne 0 ]
  [[ "$output" == *"Close Readiness: attention-required"* ]]
  [[ "$output" == *"operation is not ready to close; address readiness items or rerun with --force"* ]]
  grep -q '^STATUS=active$' "$TEST_ROOT/toolkit/sessions/readiness-op/session.env"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding resolve "$finding_id" \
    --evidence "$evidence_id" \
    --note "risk removed before closure"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report readiness-op readiness-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Open Findings: 0"* ]]
  [[ "$output" == *"Pending Validation: 0"* ]]
  [[ "$output" == *"Latest Report:"* ]]
  [[ "$output" == *"$report_path"* ]]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Close Readiness: ready"* ]]
  [[ "$output" == *"Operation is ready to close; generate an evidence bundle if handoff is required."* ]]
  [[ "$output" == *"no unresolved findings remain"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding resolve "$finding_id" \
    --evidence "$evidence_id" \
    --note "owner confirmed closeout evidence"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Open Findings: 0"* ]]
  [[ "$output" == *"Report Freshness: stale"* ]]
  [[ "$output" == *"Latest State Change:"* ]]
  [[ "$output" == *"finding.updated"* ]]
  [[ "$output" == *"Close Readiness: attention-required"* ]]
  [[ "$output" == *"Refresh the operation report before closure."* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op close readiness-op
  [ "$status" -ne 0 ]
  [[ "$output" == *"Report Freshness: stale"* ]]
  [[ "$output" == *"operation is not ready to close; address readiness items or rerun with --force"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report readiness-op readiness-report-fresh
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Close Readiness: ready"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence bundle readiness-bundle
  [ "$status" -eq 0 ]
  bundle_dir="$(printf '%s\n' "$output" | awk -F': ' '$1 == "bundle" { print $2; exit }')"
  manifest_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "manifest" { print $2; exit }')"
  [ -d "$bundle_dir" ]
  [ -f "$manifest_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bundle Freshness: current"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$late_artifact" --kind closeout-note --classification public
  [ "$status" -eq 0 ]
  late_evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$late_evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Report Freshness: stale"* ]]
  [[ "$output" == *"Bundle Freshness: stale"* ]]
  [[ "$output" == *"Latest Evidence Change:"* ]]
  [[ "$output" == *"artifact.created"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report readiness-op readiness-report-post-bundle
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Bundle Freshness: stale"* ]]
  [[ "$output" == *"Close Readiness: ready"* ]]
  [[ "$output" == *"Operation is ready to close; regenerate the evidence bundle if handoff is required."* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op handoff readiness-op readiness-handoff
  [ "$status" -eq 0 ]
  [[ "$output" == *"handoff packet written"* ]]
  handoff_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "handoff" { print $2; exit }')"
  [ -f "$handoff_path" ]
  grep -q '^# Atlas Operation Handoff$' "$handoff_path"
  grep -q 'No raw artifact contents are included' "$handoff_path"
  grep -q 'Close readiness: ready' "$handoff_path"
  grep -q 'Report freshness: current' "$handoff_path"
  grep -q 'Bundle freshness: stale' "$handoff_path"
  grep -q 'Handoff freshness before this packet: missing' "$handoff_path"
  grep -q "$report_path" "$handoff_path"
  grep -q "$bundle_dir" "$handoff_path"
  grep -q "$manifest_path" "$handoff_path"
  grep -q "$finding_id" "$handoff_path"
  grep -q 'Validate recipient and handling requirements' "$handoff_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Latest Handoff:"* ]]
  [[ "$output" == *"$handoff_path"* ]]
  [[ "$output" == *"Handoff Freshness: current"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report readiness-op readiness-report-after-handoff
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Handoff Freshness: stale"* ]]
  [[ "$output" == *"Close Readiness: ready"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op close readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"operation closed"* ]]
  [[ "$output" == *"status: closed"* ]]
  [[ "$output" == *"readiness: ready"* ]]
  [[ "$output" == *"force: 0"* ]]
  grep -q '^STATUS=closed$' "$TEST_ROOT/toolkit/sessions/readiness-op/session.env"
  jq -e 'select(.event == "op.close.readiness" and .status == "ready" and (.detail | contains("readiness=ready")) and (.detail | contains("force=0")))' \
    "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson"
  jq -e --arg handoff_path "$handoff_path" 'select(.event == "handoff.generated" and .detail == $handoff_path)' \
    "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op closeout readiness-op readiness-closeout
  [ "$status" -eq 0 ]
  [[ "$output" == *"closeout manifest written"* ]]
  closeout_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "closeout" { print $2; exit }')"
  [ -f "$closeout_path" ]
  grep -q '^# Atlas Closeout Manifest$' "$closeout_path"
  grep -q 'No raw artifact contents are included' "$closeout_path"
  grep -q 'Operation Status: closed' "$closeout_path"
  grep -q 'Close readiness: ready' "$closeout_path"
  grep -q 'Report freshness: current' "$closeout_path"
  grep -q 'Handoff freshness: stale' "$closeout_path"
  grep -q 'Closeout freshness: current' "$closeout_path"
  grep -q "$report_path" "$closeout_path"
  grep -q "$handoff_path" "$closeout_path"
  grep -q 'Operation ledger: .*events=.*sha256=' "$closeout_path"
  grep -q 'Operation env: .*sha256=' "$closeout_path"
  grep -q 'Scope snapshot: .*sha256=' "$closeout_path"
  grep -q 'Evidence index: .*sha256=' "$closeout_path"
  grep -q 'Finding index: .*sha256=' "$closeout_path"
  jq -e --arg closeout_path "$closeout_path" 'select(.event == "closeout.manifest.generated" and .detail == $closeout_path)' \
    "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Latest Closeout:"* ]]
  [[ "$output" == *"$closeout_path"* ]]
  [[ "$output" == *"Closeout Freshness: current"* ]]

  ledger_events_before="$(wc -l < "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson" | tr -d ' ')"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op verify readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Closeout Verification"* ]]
  [[ "$output" == *"Verification Status: verified"* ]]
  [[ "$output" == *"Latest Report"* ]]
  [[ "$output" == *"Evidence Manifest"* ]]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"verified"* ]]
  [[ "$output" == *"Verification Problems: 0"* ]]
  ledger_events_after="$(wc -l < "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson" | tr -d ' ')"
  [ "$ledger_events_after" = "$ledger_events_before" ]

  printf '\nreport changed after closeout\n' >> "$report_path"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op verify readiness-op "$closeout_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Latest Report"* ]]
  [[ "$output" == *"changed"* ]]
  [[ "$output" == *"Verification Status: attention-required"* ]]
  [[ "$output" == *"Verification Problems: 1"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op handoff readiness-op readiness-handoff-after-closeout
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Handoff Freshness: current"* ]]
  [[ "$output" == *"Closeout Freshness: stale"* ]]

  audit_events_before="$(wc -l < "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson" | tr -d ' ')"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Audit"* ]]
  [[ "$output" == *"Event Counts"* ]]
  [[ "$output" == *"Audit Flags"* ]]
  [[ "$output" == *"Timeline"* ]]
  [[ "$output" == *"handoff.generated"* ]]
  [[ "$output" == *"op.close.readiness"* ]]
  [[ "$output" == *"stale closeout:"* ]]
  [[ "$output" == *"closeout verification: attention-required"* ]]
  audit_events_after="$(wc -l < "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson" | tr -d ' ')"
  [ "$audit_events_after" = "$audit_events_before" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-packet readiness-op readiness-audit
  [ "$status" -eq 0 ]
  [[ "$output" == *"audit packet written"* ]]
  audit_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "audit_packet" { print $2; exit }')"
  [ -f "$audit_packet_path" ]
  grep -q '^# Atlas Operation Audit Packet$' "$audit_packet_path"
  grep -q 'No raw artifact contents are included' "$audit_packet_path"
  grep -q 'Ledger SHA256:' "$audit_packet_path"
  grep -q 'Closeout manifest SHA256:' "$audit_packet_path"
  grep -q 'Closeout verification: attention-required' "$audit_packet_path"
  grep -q 'Audit packet freshness: current' "$audit_packet_path"
  grep -q '## Event Counts' "$audit_packet_path"
  grep -q '## Audit Flags' "$audit_packet_path"
  grep -q '## Timeline' "$audit_packet_path"
  grep -q 'audit.packet.generated' "$audit_packet_path"
  grep -q 'stale closeout:' "$audit_packet_path"
  jq -e --arg audit_packet_path "$audit_packet_path" 'select(.event == "audit.packet.generated" and .detail == $audit_packet_path)' \
    "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Latest Audit Packet:"* ]]
  [[ "$output" == *"$audit_packet_path"* ]]
  [[ "$output" == *"Audit Packet Freshness: current"* ]]

  audit_verify_events_before="$(wc -l < "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson" | tr -d ' ')"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-verify readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Audit Packet Verification"* ]]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"Closeout Manifest"* ]]
  [[ "$output" == *"verified"* ]]
  [[ "$output" == *"Verification Status: verified"* ]]
  [[ "$output" == *"Verification Problems: 0"* ]]
  audit_verify_events_after="$(wc -l < "$TEST_ROOT/toolkit/sessions/readiness-op/ledger.ndjson" | tr -d ' ')"
  [ "$audit_verify_events_after" = "$audit_verify_events_before" ]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op handoff readiness-op readiness-handoff-after-audit-packet
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Audit Packet Freshness: stale"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit readiness-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"stale audit packet:"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-verify readiness-op "$audit_packet_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"changed"* ]]
  [[ "$output" == *"Verification Status: attention-required"* ]]
  [[ "$output" == *"Verification Problems: 1"* ]]

  printf '\ncloseout manifest changed after audit packet\n' >> "$closeout_path"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-verify readiness-op "$audit_packet_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Closeout Manifest"* ]]
  [[ "$output" == *"changed"* ]]
  [[ "$output" == *"Verification Status: attention-required"* ]]
  [[ "$output" == *"Verification Problems: 2"* ]]
}

@test "atlas finding accept records risk ownership and unblocks readiness" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=medium
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/accepted-risk-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start accepted-risk-op demo-node authorized risk acceptance
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id" \
    --recommendation "Restrict SSH to the management subnet"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness accepted-risk-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Open Findings: 1"* ]]
  [[ "$output" == *"Resolve, accept, or retest unresolved findings before closure."* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding accept "$finding_id"
  [ "$status" -ne 0 ]
  [[ "$output" == *"acceptance reason is required"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding accept "$finding_id" \
    --reason "owner accepts residual lab exposure" \
    --owner "Alta" \
    --expires "2999-12-31" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"finding accepted"* ]]
  [[ "$output" == *"status: accepted"* ]]
  [[ "$output" == *"reason: owner accepts residual lab exposure"* ]]
  [[ "$output" == *"owner: Alta"* ]]
  [[ "$output" == *"expires: 2999-12-31"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding update "$finding_id" \
    --note "acceptance reviewed during closeout"
  [ "$status" -eq 0 ]
  [[ "$output" == *"status: accepted"* ]]
  [[ "$output" == *"accepted_reason: owner accepts residual lab exposure"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding show "$finding_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: accepted"* ]]
  [[ "$output" == *"Accepted Reason: owner accepts residual lab exposure"* ]]
  [[ "$output" == *"Accepted Owner: Alta"* ]]
  [[ "$output" == *"Accepted Until: 2999-12-31"* ]]
  [[ "$output" == *"Accepted By:"* ]]
  [[ "$output" == *"Latest Note: acceptance reviewed during closeout"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness accepted-risk-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Open Findings: 0"* ]]
  [[ "$output" == *"Expired Accepted Risks: 0"* ]]
  [[ "$output" == *"no unresolved findings remain"* ]]
  [[ "$output" == *"no expired accepted risks detected"* ]]
  [[ "$output" == *"Report Freshness: missing"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report accepted-risk-op accepted-risk-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q 'Accepted risk: owner accepts residual lab exposure' "$report_path"
  grep -q 'Owner: Alta' "$report_path"
  grep -q 'Accepted until: 2999-12-31' "$report_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness accepted-risk-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Open Findings: 0"* ]]
  [[ "$output" == *"Expired Accepted Risks: 0"* ]]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Close Readiness: ready"* ]]

  jq -s -e \
    --arg finding_id "$finding_id" \
    --arg evidence_id "$evidence_id" \
    'map(select(.id == $finding_id)) | last | select(.status == "accepted" and .accepted_reason == "owner accepts residual lab exposure" and .accepted_owner == "Alta" and .accepted_until == "2999-12-31" and (.evidence | index($evidence_id)))' \
    "$TEST_ROOT/toolkit/sessions/accepted-risk-op/findings.ndjson"
  jq -e --arg finding_id "$finding_id" \
    'select(.event == "finding.accepted" and (.detail | contains($finding_id)) and (.detail | contains("owner accepts residual lab exposure")))' \
    "$TEST_ROOT/toolkit/sessions/accepted-risk-op/ledger.ndjson"
}

@test "atlas expired accepted risks block closure and surface in audit and v1 status" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=medium
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/expired-risk-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start expired-risk-op demo-node authorized expired risk review
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity medium \
    --confidence high \
    --evidence "$evidence_id" \
    --recommendation "Restrict SSH to the management subnet"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review "$finding_id" --reason "premature review"
  [ "$status" -ne 0 ]
  [[ "$output" == *"finding review requires an accepted finding; current status: open"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding accept "$finding_id" \
    --reason "owner accepts residual lab exposure through review date" \
    --owner "Alta" \
    --expires "2026-04-01" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"status: accepted"* ]]
  [[ "$output" == *"expires: 2026-04-01"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review "$finding_id"
  [ "$status" -ne 0 ]
  [[ "$output" == *"review reason is required"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report expired-risk-op expired-risk-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness expired-risk-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Open Findings: 0"* ]]
  [[ "$output" == *"Expired Accepted Risks: 1"* ]]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Close Readiness: attention-required"* ]]
  [[ "$output" == *"Review expired accepted risks before closure."* ]]
  [[ "$output" == *"$finding_id"* ]]
  [[ "$output" == *"expires=2026-04-01"* ]]
  [[ "$output" == *"owner=Alta"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op close expired-risk-op
  [ "$status" -ne 0 ]
  [[ "$output" == *"Expired Accepted Risks: 1"* ]]
  [[ "$output" == *"operation is not ready to close; address readiness items or rerun with --force"* ]]
  grep -q '^STATUS=active$' "$TEST_ROOT/toolkit/sessions/expired-risk-op/session.env"

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit expired-risk-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"expired accepted risk: $finding_id expires=2026-04-01 owner=Alta"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status expired-risk-op --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"Findings"* ]]
  [[ "$output" == *"warning"* ]]
  [[ "$output" == *"operation has expired accepted risks: 1"* ]]
  [[ "$output" == *"Overall: not ready"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op handoff expired-risk-op expired-risk-handoff
  [ "$status" -eq 0 ]
  handoff_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "handoff" { print $2; exit }')"
  [ -f "$handoff_path" ]
  grep -q 'Close readiness: attention-required' "$handoff_path"
  grep -q 'Expired accepted risks: 1' "$handoff_path"

  jq -s -e \
    --arg finding_id "$finding_id" \
    'map(select(.id == $finding_id)) | last | select(.status == "accepted" and .accepted_until == "2026-04-01")' \
    "$TEST_ROOT/toolkit/sessions/expired-risk-op/findings.ndjson"

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review "$finding_id" \
    --reason "owner renewed acceptance after review" \
    --owner "Alta" \
    --expires "2999-12-31" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"finding reviewed"* ]]
  [[ "$output" == *"status: accepted"* ]]
  [[ "$output" == *"reason: owner renewed acceptance after review"* ]]
  [[ "$output" == *"reviewed_by:"* ]]
  [[ "$output" == *"expires: 2999-12-31"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding show "$finding_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: accepted"* ]]
  [[ "$output" == *"Accepted Reason: owner renewed acceptance after review"* ]]
  [[ "$output" == *"Accepted Until: 2999-12-31"* ]]
  [[ "$output" == *"Risk Review Reason: owner renewed acceptance after review"* ]]
  [[ "$output" == *"Risk Reviewed By:"* ]]

  ledger_file="$TEST_ROOT/toolkit/sessions/expired-risk-op/ledger.ndjson"
  tmp_ledger="$TEST_ROOT/expired-risk-ledger.ndjson"
  jq -c '
    if (.event == "report.generated" or .event == "finding.reviewed") then
      .ts = "2026-04-27T10:24:32Z"
    else
      .
    end
  ' "$ledger_file" > "$tmp_ledger"
  mv "$tmp_ledger" "$ledger_file"

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness expired-risk-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Expired Accepted Risks: 0"* ]]
  [[ "$output" == *"Report Freshness: stale"* ]]
  [[ "$output" == *"Latest State Change:"* ]]
  [[ "$output" == *"finding.reviewed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report expired-risk-op expired-risk-reviewed-report
  [ "$status" -eq 0 ]
  reviewed_report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$reviewed_report_path" ]
  grep -q 'Risk review: owner renewed acceptance after review' "$reviewed_report_path"

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness expired-risk-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Expired Accepted Risks: 0"* ]]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Close Readiness: ready"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status expired-risk-op --strict
  [ "$status" -eq 0 ]
  [[ "$output" == *"Findings"* ]]
  [[ "$output" == *"finding lifecycle is implemented and no unresolved findings block this operation"* ]]
  [[ "$output" == *"Overall: ready"* ]]

  jq -s -e \
    --arg finding_id "$finding_id" \
    'map(select(.id == $finding_id)) | last | select(.status == "accepted" and .accepted_until == "2999-12-31" and .review_reason == "owner renewed acceptance after review")' \
    "$TEST_ROOT/toolkit/sessions/expired-risk-op/findings.ndjson"
  jq -e --arg finding_id "$finding_id" \
    'select(.event == "finding.reviewed" and (.detail | contains($finding_id)) and (.detail | contains("owner renewed acceptance after review")))' \
    "$TEST_ROOT/toolkit/sessions/expired-risk-op/ledger.ndjson"
}

@test "atlas finding review-queue classifies accepted risks by review state" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=medium
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/review-queue-artifact.txt"
  printf 'accepted-risk review queue evidence\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start review-queue-op demo-node authorized accepted risk review queue
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "Expired accepted risk" \
    --level observed \
    --severity high \
    --confidence high \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  expired_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$expired_id" ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding accept "$expired_id" \
    --reason "owner accepts expired lab risk" \
    --owner "Alta" \
    --expires "2026-04-01" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "Soon due accepted risk" \
    --level observed \
    --severity medium \
    --confidence high \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  due_soon_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$due_soon_id" ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding accept "$due_soon_id" \
    --reason "owner accepts near-term lab risk" \
    --owner "Alta" \
    --expires "2026-05-10" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "Current accepted risk" \
    --level observed \
    --severity low \
    --confidence medium \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  current_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$current_id" ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding accept "$current_id" \
    --reason "owner accepts long-term lab risk" \
    --owner "Alta" \
    --expires "2999-12-31" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "No expiry accepted risk" \
    --level inferred \
    --severity info \
    --confidence medium \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  no_expiry_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$no_expiry_id" ]
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding accept "$no_expiry_id" \
    --reason "owner accepts lab risk without expiry" \
    --owner "Alta" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness review-queue-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Accepted Risks: 4"* ]]
  [[ "$output" == *"Latest Accepted Risk Review Packet: none generated yet"* ]]
  [[ "$output" == *"Accepted Risk Review Packet Freshness: missing"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit review-queue-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"missing accepted-risk review packet: accepted_risks=4"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review-queue --within 30
  [ "$status" -eq 0 ]
  [[ "$output" == *"Accepted Risk Review Queue"* ]]
  [[ "$output" == *"Today: 2026-04-27"* ]]
  [[ "$output" == *"Review Window: 30 days"* ]]
  [[ "$output" == *"Due By: 2026-05-27"* ]]
  [[ "$output" == *"Expired: 1"* ]]
  [[ "$output" == *"Due Soon: 1"* ]]
  [[ "$output" == *"No Expiry: 1"* ]]
  [[ "$output" == *"Current: 1"* ]]
  [[ "$output" == *"$expired_id"* ]]
  [[ "$output" == *"expired"* ]]
  [[ "$output" == *"$due_soon_id"* ]]
  [[ "$output" == *"due-soon"* ]]
  [[ "$output" == *"$current_id"* ]]
  [[ "$output" == *"current"* ]]
  [[ "$output" == *"$no_expiry_id"* ]]
  [[ "$output" == *"no-expiry"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review-packet queue-review --within 30
  [ "$status" -eq 0 ]
  [[ "$output" == *"accepted-risk review packet written"* ]]
  review_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "review_packet" { print $2; exit }')"
  [ -f "$review_packet_path" ]
  grep -q '^# Atlas Accepted Risk Review Packet$' "$review_packet_path"
  grep -q 'No raw artifact contents are included' "$review_packet_path"
  grep -q 'Review window: 30 days' "$review_packet_path"
  grep -q 'Due by: 2026-05-27' "$review_packet_path"
  grep -q 'Expired: 1' "$review_packet_path"
  grep -q 'Due soon: 1' "$review_packet_path"
  grep -q 'No expiry: 1' "$review_packet_path"
  grep -q 'Current: 1' "$review_packet_path"
  grep -q 'Finding index: .*sha256=' "$review_packet_path"
  grep -q 'Operation ledger: .*events=.*sha256=' "$review_packet_path"
  grep -q "$expired_id" "$review_packet_path"
  grep -q "$due_soon_id" "$review_packet_path"
  grep -q "$current_id" "$review_packet_path"
  grep -q "$no_expiry_id" "$review_packet_path"
  jq -e --arg review_packet_path "$review_packet_path" 'select(.event == "finding.review_packet.generated" and .detail == $review_packet_path)' \
    "$TEST_ROOT/toolkit/sessions/review-queue-op/ledger.ndjson"

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness review-queue-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Accepted Risks: 4"* ]]
  [[ "$output" == *"Latest Accepted Risk Review Packet:"* ]]
  [[ "$output" == *"$review_packet_path"* ]]
  [[ "$output" == *"Accepted Risk Review Packet Freshness: current"* ]]

  review_verify_events_before="$(wc -l < "$TEST_ROOT/toolkit/sessions/review-queue-op/ledger.ndjson" | tr -d ' ')"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review-verify "$review_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Accepted Risk Review Packet Verification"* ]]
  [[ "$output" == *"Finding Index"* ]]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"verified"* ]]
  [[ "$output" == *"Verification Status: verified"* ]]
  [[ "$output" == *"Verification Problems: 0"* ]]
  review_verify_events_after="$(wc -l < "$TEST_ROOT/toolkit/sessions/review-queue-op/ledger.ndjson" | tr -d ' ')"
  [ "$review_verify_events_after" = "$review_verify_events_before" ]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review "$due_soon_id" \
    --reason "owner renewed near-term lab risk" \
    --expires "2999-12-31" \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness review-queue-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Accepted Risk Review Packet Freshness: stale"* ]]
  [[ "$output" == *"Latest Accepted Risk Change:"* ]]
  [[ "$output" == *"finding.reviewed"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit review-queue-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"stale accepted-risk review packet: $review_packet_path"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review-verify "$review_packet_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Finding Index"* ]]
  [[ "$output" == *"changed"* ]]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"Verification Status: attention-required"* ]]

  sleep 1
  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review-packet queue-review --within 30
  [ "$status" -eq 0 ]
  [[ "$output" == *"accepted-risk review packet written"* ]]
  regenerated_review_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "review_packet" { print $2; exit }')"
  [ "$regenerated_review_packet_path" = "$review_packet_path" ]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness review-queue-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Accepted Risk Review Packet Freshness: current"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review-verify "$review_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Verification Status: verified"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive review-queue-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Accepted Risk Review Packet Freshness: current"* ]]
  [[ "$output" == *"Accepted Risk Review Packet Verification: verified"* ]]
  [[ "$output" == *"Latest Accepted Risk Review Packet: $review_packet_path"* ]]

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive-packet review-queue-op review-queue-archive
  [ "$status" -eq 0 ]
  review_archive_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "archive_packet" { print $2; exit }')"
  [ -f "$review_archive_packet_path" ]
  grep -q 'Accepted-risk review packet freshness: current' "$review_archive_packet_path"
  grep -q 'Accepted-risk review packet verification: verified' "$review_archive_packet_path"
  grep -q "$review_packet_path" "$review_archive_packet_path"

  run env ATLAS_TODAY=2026-04-27 "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding review-queue --within nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"review window must be a non-negative integer number of days"* ]]
}

@test "atlas operation archive summarizes final verification state" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/archive-artifact.txt"
  printf 'archive-ready evidence reference\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start archive-op demo-node authorized archive review
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report archive-op archive-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence bundle archive-bundle
  [ "$status" -eq 0 ]
  bundle_dir="$(printf '%s\n' "$output" | awk -F': ' '$1 == "bundle" { print $2; exit }')"
  [ -d "$bundle_dir" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op handoff archive-op archive-handoff
  [ "$status" -eq 0 ]
  handoff_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "handoff" { print $2; exit }')"
  [ -f "$handoff_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op close archive-op
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op closeout archive-op archive-closeout
  [ "$status" -eq 0 ]
  closeout_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "closeout" { print $2; exit }')"
  [ -f "$closeout_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-packet archive-op archive-audit
  [ "$status" -eq 0 ]
  audit_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "audit_packet" { print $2; exit }')"
  [ -f "$audit_packet_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op verify archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"later_allowed_events=1"* ]]
  [[ "$output" == *"Verification Status: verified"* ]]

  archive_events_before="$(wc -l < "$TEST_ROOT/toolkit/sessions/archive-op/ledger.ndjson" | tr -d ' ')"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Archive Snapshot"* ]]
  [[ "$output" == *"Archive Status: incomplete"* ]]
  [[ "$output" == *"Next Archive Step: Generate an archive packet before final archive review."* ]]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Bundle Freshness: current"* ]]
  [[ "$output" == *"Handoff Freshness: current"* ]]
  [[ "$output" == *"Closeout Freshness: current"* ]]
  [[ "$output" == *"Audit Packet Freshness: current"* ]]
  [[ "$output" == *"Archive Packet Freshness: missing"* ]]
  [[ "$output" == *"Closeout Verification: verified"* ]]
  [[ "$output" == *"Audit Packet Verification: verified"* ]]
  [[ "$output" == *"$report_path"* ]]
  [[ "$output" == *"$bundle_dir"* ]]
  [[ "$output" == *"$handoff_path"* ]]
  [[ "$output" == *"$closeout_path"* ]]
  [[ "$output" == *"$audit_packet_path"* ]]
  [[ "$output" == *"Latest Archive Packet: none generated yet"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op trust-chain archive-op --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"Operation Trust Chain"* ]]
  [[ "$output" == *"Trust Chain Status: incomplete"* ]]
  [[ "$output" == *"Next Trust Step: Generate an archive packet before final archive review."* ]]
  [[ "$output" == *"Archive Packet: missing path=none"* ]]
  [[ "$output" == *"Archive Packet: missing packet=-"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op trust-chain archive-op --json --strict
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" |
    jq -e '
      .schema_version == "atlas.operation_trust_chain.v1" and
      .operation.slug == "archive-op" and
      .status == "incomplete" and
      .freshness.archive_packet == "missing" and
      .verification.archive_packet.status == "missing" and
      .v1.overall == "ready"
    '
  archive_events_after="$(wc -l < "$TEST_ROOT/toolkit/sessions/archive-op/ledger.ndjson" | tr -d ' ')"
  [ "$archive_events_after" = "$archive_events_before" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive-packet archive-op archive-final
  [ "$status" -eq 0 ]
  [[ "$output" == *"archive packet written"* ]]
  archive_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "archive_packet" { print $2; exit }')"
  [ -f "$archive_packet_path" ]
  grep -q '^# Atlas Operation Archive Packet$' "$archive_packet_path"
  grep -q 'No raw artifact contents are included' "$archive_packet_path"
  grep -q 'Archive status: current' "$archive_packet_path"
  grep -q 'Archive packet freshness: current' "$archive_packet_path"
  grep -q 'Closeout verification: verified' "$archive_packet_path"
  grep -q 'Audit packet verification: verified' "$archive_packet_path"
  grep -q "$report_path" "$archive_packet_path"
  grep -q "$bundle_dir" "$archive_packet_path"
  grep -q "$handoff_path" "$archive_packet_path"
  grep -q "$closeout_path" "$archive_packet_path"
  grep -q "$audit_packet_path" "$archive_packet_path"
  grep -q "$archive_packet_path" "$archive_packet_path"
  jq -e --arg archive_packet_path "$archive_packet_path" 'select(.event == "archive.packet.generated" and .detail == $archive_packet_path)' \
    "$TEST_ROOT/toolkit/sessions/archive-op/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Archive Status: current"* ]]
  [[ "$output" == *"Audit Packet Freshness: current"* ]]
  [[ "$output" == *"Archive Packet Freshness: current"* ]]
  [[ "$output" == *"Audit Packet Verification: verified"* ]]
  [[ "$output" == *"$archive_packet_path"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-verify archive-op "$audit_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"later_archive_events=1"* ]]
  [[ "$output" == *"Verification Status: verified"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op verify archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"later_allowed_events=2"* ]]
  [[ "$output" == *"Verification Status: verified"* ]]

  archive_verify_events_before="$(wc -l < "$TEST_ROOT/toolkit/sessions/archive-op/ledger.ndjson" | tr -d ' ')"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive-verify archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Archive Packet Verification"* ]]
  [[ "$output" == *"Latest Report"* ]]
  [[ "$output" == *"Evidence Manifest"* ]]
  [[ "$output" == *"Latest Handoff"* ]]
  [[ "$output" == *"Latest Closeout"* ]]
  [[ "$output" == *"Latest Audit Packet"* ]]
  [[ "$output" == *"Operation Ledger"* ]]
  [[ "$output" == *"verified"* ]]
  [[ "$output" == *"Verification Status: verified"* ]]
  [[ "$output" == *"Verification Problems: 0"* ]]
  archive_verify_events_after="$(wc -l < "$TEST_ROOT/toolkit/sessions/archive-op/ledger.ndjson" | tr -d ' ')"
  [ "$archive_verify_events_after" = "$archive_verify_events_before" ]

  trust_events_before="$(wc -l < "$TEST_ROOT/toolkit/sessions/archive-op/ledger.ndjson" | tr -d ' ')"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op trust-chain archive-op --strict
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Trust Chain"* ]]
  [[ "$output" == *"Trust Chain Status: current"* ]]
  [[ "$output" == *"Next Trust Step: Trust chain is current."* ]]
  [[ "$output" == *"V1 Readiness: ready required_not_ready=0"* ]]
  [[ "$output" == *"Archive Packet: current path=$archive_packet_path"* ]]
  [[ "$output" == *"Archive Packet: verified packet=$archive_packet_path"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op trust-chain archive-op --json --strict
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" |
    jq -e --arg archive_packet_path "$archive_packet_path" '
      .schema_version == "atlas.operation_trust_chain.v1" and
      .operation.slug == "archive-op" and
      .status == "current" and
      .next_step == "Trust chain is current." and
      .freshness.archive_packet == "current" and
      .verification.archive_packet.status == "verified" and
      .artifacts.archive_packet == $archive_packet_path and
      .v1.overall == "ready" and
      .v1.required_not_ready == 0 and
      .ledger.events > 0
    '
  trust_events_after="$(wc -l < "$TEST_ROOT/toolkit/sessions/archive-op/ledger.ndjson" | tr -d ' ')"
  [ "$trust_events_after" = "$trust_events_before" ]

  printf '\narchive report changed after packet\n' >> "$report_path"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive-verify archive-op "$archive_packet_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Latest Report"* ]]
  [[ "$output" == *"changed"* ]]
  [[ "$output" == *"Verification Status: attention-required"* ]]
  [[ "$output" == *"Verification Problems: 1"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op trust-chain archive-op --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"Trust Chain Status: attention-required"* ]]
  [[ "$output" == *"Closeout: attention-required manifest=$closeout_path"* ]]
  [[ "$output" == *"Archive Packet: attention-required packet=$archive_packet_path"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-packet archive-op archive-audit-after-archive
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Archive Status: attention-required"* ]]
  [[ "$output" == *"Archive Packet Freshness: stale"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status archive-op --strict
  [ "$status" -ne 0 ]
  [[ "$output" == *"Retention"* ]]
  [[ "$output" == *"archive packet freshness is stale"* ]]
  [[ "$output" == *"Overall: not ready"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"stale archive packet:"* ]]
}

@test "atlas trust lifecycle proves operation-to-release verification chain" {
  make_repo_clean_and_synced

  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-1","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","entity_type":"service","entity_id":"service:demo-node:22/tcp","target":"demo-node","attributes":{"portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl"
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/nmap" <<'EOF'
#!/usr/bin/env bash
target="${*: -1}"
printf 'Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-24 00:00 UTC\n'
printf 'Nmap scan report for %s\n' "$target"
printf 'Host is up, received user-set (0.00025s latency).\n'
printf 'PORT   STATE SERVICE REASON  VERSION\n'
printf '22/tcp open  ssh     syn-ack OpenSSH 9.7\n'
printf '\nNmap done: 1 IP address (1 host up) scanned in 0.04 seconds\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/nmap"
  export LAB_VECTOR_NMAP_BIN="$TEST_ROOT/fake-bin/nmap"

  artifact="$TEST_ROOT/trust-lifecycle-evidence.txt"
  retest_artifact="$TEST_ROOT/trust-lifecycle-retest.txt"
  printf 'ssh reachable from authorized lifecycle proof\n' > "$artifact"
  printf 'ssh exposure resolved in authorized lifecycle proof\n' > "$retest_artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start --profile htb-starting-point trust-lifecycle-op demo-node authorized lifecycle proof
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification public
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id" \
    --recommendation "Restrict SSH to the management subnet"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan validate \
    --finding "$finding_id" \
    --evidence "$evidence_id" \
    --reason "confirm observed SSH service"
  [ "$status" -eq 0 ]
  plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$plan_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation approve "$plan_id" lifecycle validation approved
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation run "$plan_id" "Lifecycle Validation"
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation_status: executed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$retest_artifact" --kind retest-output --classification public
  [ "$status" -eq 0 ]
  retest_evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$retest_evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation retest "$plan_id" \
    --result resolved \
    --evidence "$retest_evidence_id" \
    --note "remediation confirmed in lifecycle proof"
  [ "$status" -eq 0 ]
  [[ "$output" == *"finding_status: resolved"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence bundle trust-lifecycle-bundle
  [ "$status" -eq 0 ]
  bundle_dir="$(printf '%s\n' "$output" | awk -F': ' '$1 == "bundle" { print $2; exit }')"
  manifest_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "manifest" { print $2; exit }')"
  [ -d "$bundle_dir" ]
  [ -f "$manifest_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report trust-lifecycle-op trust-lifecycle-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q 'Retest: resolved' "$report_path"
  grep -q 'remediation confirmed in lifecycle proof' "$report_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op handoff trust-lifecycle-op trust-lifecycle-handoff
  [ "$status" -eq 0 ]
  handoff_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "handoff" { print $2; exit }')"
  [ -f "$handoff_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op readiness trust-lifecycle-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Close Readiness: ready"* ]]
  [[ "$output" == *"Report Freshness: current"* ]]
  [[ "$output" == *"Bundle Freshness: current"* ]]
  [[ "$output" == *"Handoff Freshness: current"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op close trust-lifecycle-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"readiness: ready"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op closeout trust-lifecycle-op trust-lifecycle-closeout
  [ "$status" -eq 0 ]
  closeout_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "closeout" { print $2; exit }')"
  [ -f "$closeout_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op verify trust-lifecycle-op "$closeout_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Verification Status: verified"* ]]
  [[ "$output" == *"Verification Problems: 0"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-packet trust-lifecycle-op trust-lifecycle-audit
  [ "$status" -eq 0 ]
  audit_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "audit_packet" { print $2; exit }')"
  [ -f "$audit_packet_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-verify trust-lifecycle-op "$audit_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Verification Status: verified"* ]]
  [[ "$output" == *"Verification Problems: 0"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive-packet trust-lifecycle-op trust-lifecycle-archive
  [ "$status" -eq 0 ]
  archive_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "archive_packet" { print $2; exit }')"
  [ -f "$archive_packet_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive-verify trust-lifecycle-op "$archive_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Verification Status: verified"* ]]
  [[ "$output" == *"Verification Problems: 0"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive trust-lifecycle-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Archive Status: current"* ]]
  [[ "$output" == *"$report_path"* ]]
  [[ "$output" == *"$bundle_dir"* ]]
  [[ "$output" == *"$handoff_path"* ]]
  [[ "$output" == *"$closeout_path"* ]]
  [[ "$output" == *"$audit_packet_path"* ]]
  [[ "$output" == *"$archive_packet_path"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op trust-chain trust-lifecycle-op --strict
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Trust Chain"* ]]
  [[ "$output" == *"Trust Chain Status: current"* ]]
  [[ "$output" == *"V1 Readiness: ready required_not_ready=0"* ]]
  [[ "$output" == *"Closeout: verified manifest=$closeout_path"* ]]
  [[ "$output" == *"Audit Packet: verified packet=$audit_packet_path"* ]]
  [[ "$output" == *"Archive Packet: verified packet=$archive_packet_path"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" v1 status trust-lifecycle-op --strict
  [ "$status" -eq 0 ]
  [[ "$output" == *"Overall: ready"* ]]
  [[ "$output" == *"Required Not Ready: 0"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet trust-lifecycle-m53-md \
    --operation trust-lifecycle-op \
    --qa-status pass \
    --qa-note "trust lifecycle markdown proof passed"
  [ "$status" -eq 0 ]
  markdown_release_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "release_packet" { print $2; exit }')"
  [ -f "$markdown_release_packet_path" ]
  grep -q 'Trust chain status: current' "$markdown_release_packet_path"
  grep -q 'Operation ledger: .*events=.*sha256=' "$markdown_release_packet_path"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$markdown_release_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Trust Chain: ok status=current replay=current operation=trust-lifecycle-op"* ]]
  [[ "$output" == *"Operation Ledger Replay: ok"* ]]
  [[ "$output" == *"Operation Archive Replay: ok verification=verified"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release packet trust-lifecycle-m36 \
    --json \
    --operation trust-lifecycle-op \
    --qa-status pass \
    --qa-note "trust lifecycle proof passed"
  [ "$status" -eq 0 ]
  release_packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "release_packet_json" { print $2; exit }')"
  [ -f "$release_packet_path" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$release_packet_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Schema: ok atlas.release_trust.v1"* ]]
  [[ "$output" == *"Repository State: ok clean"* ]]
  [[ "$output" == *"Upstream Sync: ok synced"* ]]
  [[ "$output" == *"QA Status: ok pass"* ]]
  [[ "$output" == *"V1 Readiness: ok overall=ready required_not_ready=0"* ]]
  [[ "$output" == *"Operation Trust Chain: ok status=current"* ]]
  [[ "$output" == *"Operation Ledger Replay: ok"* ]]
  [[ "$output" == *"Operation Archive Replay: ok verification=verified"* ]]

  jq -e '
    .schema_version == "atlas.release_trust.v1" and
    .metadata_only == true and
    .qa.status == "pass" and
    .readiness.overall == "ready" and
    .operation_trust_chain.status == "current" and
    .operation_trust_chain.operation.slug == "trust-lifecycle-op" and
    .operation_trust_chain.verification.archive_packet == "verified"
  ' "$release_packet_path"

  printf '\nrelease candidate report changed after release packet\n' >> "$report_path"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$markdown_release_packet_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Operation Trust Chain: fail packet_status=current replay_status=attention-required operation=trust-lifecycle-op"* ]]
  [[ "$output" == *"Operation Archive Replay: fail"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" release verify "$release_packet_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Operation Trust Chain: fail packet_status=current replay_status=attention-required operation=trust-lifecycle-op"* ]]
  [[ "$output" == *"Operation Archive Replay: fail"* ]]
}

@test "atlas operation close can force closure with readiness snapshot" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
CREATED_AT=2026-04-23T20:53:16Z
EOF

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start force-close-op demo-node authorized forced close review
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op close --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"operation closed"* ]]
  [[ "$output" == *"status: closed"* ]]
  [[ "$output" == *"readiness: attention-required"* ]]
  [[ "$output" == *"force: 1"* ]]
  grep -q '^STATUS=closed$' "$TEST_ROOT/toolkit/sessions/force-close-op/session.env"
  jq -e 'select(.event == "op.close.readiness" and .status == "attention-required" and (.detail | contains("readiness=attention-required")) and (.detail | contains("evidence=0")) and (.detail | contains("force=1")))' \
    "$TEST_ROOT/toolkit/sessions/force-close-op/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit force-close-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Audit"* ]]
  [[ "$output" == *"forced close:"* ]]
  [[ "$output" == *"closeout verification: missing"* ]]
}

@test "atlas advisor summarizes operation state and writes AI review packet" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","entity_type":"service","entity_id":"service:demo-node:22/tcp","target":"demo-node","attributes":{"portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl"
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"
  artifact="$TEST_ROOT/advisor-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start advisor-op demo-node authorized advisor
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification internal
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity medium \
    --confidence high \
    --evidence "$evidence_id" \
    --recommendation "Restrict SSH to the management subnet"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan validate \
    --finding "$finding_id" \
    --evidence "$evidence_id" \
    --reason "confirm observed SSH service"
  [ "$status" -eq 0 ]
  plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$plan_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" advisor brief
  [ "$status" -eq 0 ]
  [[ "$output" == *"AI Advisor Brief"* ]]
  [[ "$output" == *"Current State"* ]]
  [[ "$output" == *"AI Handoff Guardrails"* ]]
  [[ "$output" == *"Evidence Redaction: total=1, redacted=0, unredacted=1, non_public=1, review_required=1"* ]]
  [[ "$output" == *"redaction required before external AI handoff"* ]]
  [[ "$output" == *"Priority Findings"* ]]
  [[ "$output" == *"SSH management reachable"* ]]
  [[ "$output" == *"Validation Queue"* ]]
  [[ "$output" == *"$plan_id"* ]]
  [[ "$output" == *"Suggested Operator Moves"* ]]
  [[ "$output" == *"Approve, revise, or retire the planned validation before execution."* ]]
  [[ "$output" == *"Keep execution manual"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" advisor prompt advisor-op advisor-packet
  [ "$status" -eq 0 ]
  [[ "$output" == *"advisor packet written"* ]]
  packet_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "packet" { print $2; exit }')"
  [ -f "$packet_path" ]
  grep -q '^# Atlas AI Advisor Packet$' "$packet_path"
  grep -q 'No raw artifact contents are included' "$packet_path"
  grep -q '^## Redaction Status$' "$packet_path"
  grep -q 'External handoff status: review required' "$packet_path"
  grep -q "$finding_id" "$packet_path"
  grep -q "$plan_id" "$packet_path"
  grep -q '^## Requested Output$' "$packet_path"

  jq -e \
    --arg packet_path "$packet_path" \
    'select(.event == "advisor.packet.generated" and .detail == $packet_path)' \
    "$TEST_ROOT/toolkit/sessions/advisor-op/ledger.ndjson"

  redacted_artifact="$TEST_ROOT/advisor-artifact-redacted.txt"
  printf 'ssh reachable from redacted test node\n' > "$redacted_artifact"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence redact "$evidence_id" "$redacted_artifact" --note "removed operator host detail"
  [ "$status" -eq 0 ]
  [[ "$output" == *"evidence redacted"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" advisor brief
  [ "$status" -eq 0 ]
  [[ "$output" == *"Evidence Redaction: total=1, redacted=1, unredacted=0, non_public=1, review_required=0"* ]]
  [[ "$output" == *"recorded evidence metadata is ready for advisor review"* ]]
}

@test "atlas evidence vault copies, hashes, indexes, and enforces scope" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/artifact.txt"
  printf 'authorized evidence artifact\n' > "$artifact"
  expected_sha="$(sha256sum "$artifact" | awk '{ print $1 }')"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence hash "$artifact"
  [ "$status" -eq 0 ]
  [[ "$output" == *"sha256: $expected_sha"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence list
  [ "$status" -ne 0 ]
  [[ "$output" == *"no active operation"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start evidence-op demo-node authorized evidence
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence list
  [ "$status" -eq 0 ]
  [[ "$output" == *"no evidence recorded yet"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output --classification internal
  [ "$status" -eq 0 ]
  [[ "$output" == *"evidence added"* ]]
  [[ "$output" == *"sha256: $expected_sha"* ]]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  stored_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "path" { print $2; exit }')"
  [ -n "$evidence_id" ]
  [ -f "$stored_path" ]
  [ "$(sha256sum "$stored_path" | awk '{ print $1 }')" = "$expected_sha" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence list
  [ "$status" -eq 0 ]
  [[ "$output" == *"$evidence_id"* ]]
  [[ "$output" == *"scan-output"* ]]
  [[ "$output" == *"$expected_sha"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence show "$evidence_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Evidence Record"* ]]
  [[ "$output" == *"ID: $evidence_id"* ]]
  [[ "$output" == *"SHA256: $expected_sha"* ]]
  [[ "$output" == *"Redacted: false"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence bundle pre-redaction
  [ "$status" -ne 0 ]
  [[ "$output" == *"redaction required before bundling"* ]]

  redacted_artifact="$TEST_ROOT/artifact-redacted.txt"
  printf 'authorized evidence artifact with sensitive fields removed\n' > "$redacted_artifact"
  redacted_sha="$(sha256sum "$redacted_artifact" | awk '{ print $1 }')"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence redact "$evidence_id" "$redacted_artifact" --classification internal --note "removed target-specific detail"
  [ "$status" -eq 0 ]
  [[ "$output" == *"evidence redacted"* ]]
  [[ "$output" == *"id: $evidence_id"* ]]
  [[ "$output" == *"redacted_sha256: $redacted_sha"* ]]
  redacted_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "redacted_path" { print $2; exit }')"
  [ -f "$redacted_path" ]
  [ "$(sha256sum "$redacted_path" | awk '{ print $1 }')" = "$redacted_sha" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence show "$evidence_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Redacted: true"* ]]
  [[ "$output" == *"Redacted SHA256: $redacted_sha"* ]]
  [[ "$output" == *"Redaction Note: removed target-specific detail"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence bundle evidence-review
  [ "$status" -eq 0 ]
  [[ "$output" == *"evidence bundle written"* ]]
  [[ "$output" == *"files: 1"* ]]
  [[ "$output" == *"include_unredacted: 0"* ]]
  bundle_dir="$(printf '%s\n' "$output" | awk -F': ' '$1 == "bundle" { print $2; exit }')"
  manifest_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "manifest" { print $2; exit }')"
  [ -d "$bundle_dir/files" ]
  [ -f "$manifest_path" ]
  bundle_file_rel="$(jq -r --arg evidence_id "$evidence_id" 'select(.id == $evidence_id) | .bundle_path' "$manifest_path")"
  [ -f "$bundle_dir/$bundle_file_rel" ]
  [ "$(sha256sum "$bundle_dir/$bundle_file_rel" | awk '{ print $1 }')" = "$redacted_sha" ]

  jq -e \
    --arg evidence_id "$evidence_id" \
    --arg sha256 "$expected_sha" \
    'select(.id == $evidence_id and .sha256 == $sha256 and .kind == "scan-output" and .target == "demo-node")' \
    "$TEST_ROOT/toolkit/sessions/evidence-op/evidence.ndjson"
  jq -sr \
    --arg evidence_id "$evidence_id" \
    --arg redacted_sha "$redacted_sha" \
    'map(select(.id == $evidence_id)) | last | select(.redacted == true and .redacted_sha256 == $redacted_sha)' \
    "$TEST_ROOT/toolkit/sessions/evidence-op/evidence.ndjson"
  jq -e \
    --arg evidence_id "$evidence_id" \
    --arg redacted_sha "$redacted_sha" \
    'select(.id == $evidence_id and .included_as == "redacted" and .bundled_sha256 == $redacted_sha)' \
    "$manifest_path"
  jq -e \
    --arg evidence_id "$evidence_id" \
    'select(.event == "artifact.created" and (.detail | contains($evidence_id)))' \
    "$TEST_ROOT/toolkit/sessions/evidence-op/ledger.ndjson"
  jq -e \
    --arg evidence_id "$evidence_id" \
    'select(.event == "artifact.redacted" and (.detail | contains($evidence_id)))' \
    "$TEST_ROOT/toolkit/sessions/evidence-op/ledger.ndjson"
  jq -e 'select(.event == "evidence.bundle.generated" and (.detail | contains("evidence-review")))' \
    "$TEST_ROOT/toolkit/sessions/evidence-op/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --target other-node --kind scan-output
  [ "$status" -ne 0 ]
  [[ "$output" == *"scope refused"* ]]
}

@test "atlas findings record levels, link evidence, and render into reports" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF
  artifact="$TEST_ROOT/finding-artifact.txt"
  printf 'ssh reachable from authorized test node\n' > "$artifact"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding list
  [ "$status" -ne 0 ]
  [[ "$output" == *"no active operation"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start finding-op demo-node authorized findings
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding list
  [ "$status" -eq 0 ]
  [[ "$output" == *"no findings recorded yet"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" evidence add "$artifact" --kind scan-output
  [ "$status" -eq 0 ]
  evidence_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$evidence_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH management reachable" \
    --level observed \
    --severity low \
    --confidence high \
    --evidence "$evidence_id" \
    --impact "Remote administrative service is reachable" \
    --recommendation "Restrict SSH to the management subnet"
  [ "$status" -eq 0 ]
  [[ "$output" == *"finding added"* ]]
  [[ "$output" == *"level: observed"* ]]
  [[ "$output" == *"severity: low"* ]]
  [[ "$output" == *"confidence: high"* ]]
  [[ "$output" == *"status: open"* ]]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "SSH exposure validated" \
    --level validated \
    --severity low \
    --confidence high \
    --evidence "$evidence_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"status: validated"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding list
  [ "$status" -eq 0 ]
  [[ "$output" == *"$finding_id"* ]]
  [[ "$output" == *"observed"* ]]
  [[ "$output" == *"SSH management reachable"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding show "$finding_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Finding Record"* ]]
  [[ "$output" == *"ID: $finding_id"* ]]
  [[ "$output" == *"Level: observed"* ]]
  [[ "$output" == *"Evidence: $evidence_id"* ]]
  [[ "$output" == *"Recommendation: Restrict SSH to the management subnet"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op brief
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Brief"* ]]
  [[ "$output" == *"Operator Brief"* ]]
  [[ "$output" == *"Evidence: 1"* ]]
  [[ "$output" == *"Findings: 2"* ]]
  [[ "$output" == *"Operation State: evidence=1, findings=2"* ]]
  [[ "$output" == *"Latest Finding:"* ]]
  [[ "$output" == *"low/validated/validated SSH exposure validated"* ]]
  [[ "$output" == *"Operation Evidence"* ]]
  [[ "$output" == *"$evidence_id"* ]]
  [[ "$output" == *"Operation Findings"* ]]
  [[ "$output" == *"SSH management reachable"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op story
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation Story"* ]]
  [[ "$output" == *"Operation Evidence"* ]]
  [[ "$output" == *"Operation Findings"* ]]
  [[ "$output" == *"SSH management reachable"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" target story demo-node
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operator Brief"* ]]
  [[ "$output" == *"Active Operation Evidence"* ]]
  [[ "$output" == *"$evidence_id"* ]]
  [[ "$output" == *"Active Operation Findings"* ]]
  [[ "$output" == *"SSH management reachable"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" target story 10.10.10.10
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operator Brief"* ]]
  [[ "$output" == *"Active Operation Evidence"* ]]
  [[ "$output" == *"$evidence_id"* ]]
  [[ "$output" == *"Active Operation Findings"* ]]
  [[ "$output" == *"SSH management reachable"* ]]

  jq -e \
    --arg finding_id "$finding_id" \
    --arg evidence_id "$evidence_id" \
    'select(.id == $finding_id and .level == "observed" and .severity == "low" and (.evidence | index($evidence_id)))' \
    "$TEST_ROOT/toolkit/sessions/finding-op/findings.ndjson"
  jq -e \
    --arg finding_id "$finding_id" \
    'select(.event == "finding.recorded" and (.detail | contains($finding_id)))' \
    "$TEST_ROOT/toolkit/sessions/finding-op/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "Unknown evidence link" --evidence ev_missing
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown evidence id"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "Out of scope target" --target other-node
  [ "$status" -ne 0 ]
  [[ "$output" == *"scope refused"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report finding-op finding-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q '## Operator Brief' "$report_path"
  grep -q '## Executive Summary' "$report_path"
  grep -q '## Finding Review' "$report_path"
  grep -q '### Observed' "$report_path"
  grep -q '### Validated' "$report_path"
  grep -q '## Remediation Priorities' "$report_path"
  grep -q 'Findings: 2 total, 1 observed, 0 inferred, 1 validated' "$report_path"
  grep -q 'Highest recorded severity: low' "$report_path"
  grep -q 'Latest finding:' "$report_path"
  grep -q 'Restrict SSH to the management subnet' "$report_path"
  grep -q 'SSH management reachable' "$report_path"
  grep -q "$evidence_id" "$report_path"
}

@test "atlas story demo-web-app renders a canned anonymized story" {
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" story demo-web-app

  [ "$status" -eq 0 ]
  [[ "$output" == *"Target Story"* ]]
  [[ "$output" == *"demo-web-app"* ]]
  [[ "$output" == *"built-in demo fixture"* ]]
  [[ "$output" == *"Posture Findings"* ]]
  [[ "$output" == *"missing-security-headers"* ]]
  [[ "$output" == *"Next Actions"* ]]
}

@test "atlas target story combines target record, shared intel, outcomes, and candidates" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
TAGS='lab web'
OWNER=platform
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-25T07:00:00Z","entity_type":"service","entity_id":"service:demo-node:443/tcp","target":"demo-node","attributes":{"portproto":"443/tcp","service":"https","detail":"DPS/2.0.0"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-25T07:00:00Z","source_tool":"wiremap","source_kind":"recon","source_name":"web-stack","source_run_id":"run-1","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-25T07:01:00Z","source_tool":"wiremap","source_kind":"recon","source_name":"web-stack","source_run_id":"run-1","target":"demo-node","observation_type":"web_surface","confidence":"high","value":{"endpoint":"https://demo-node","portproto":"443/tcp","service":"https","detail":"Ascend and Defend Academy"}}
{"observed_at":"2026-04-25T07:01:01Z","source_tool":"wiremap","source_kind":"recon","source_name":"web-stack","source_run_id":"run-1","target":"demo-node","observation_type":"web_surface","confidence":"high","value":{"endpoint":"https://demo-node","portproto":"443/tcp","service":"https","detail":"Ascend and Defend Academy"}}
{"observed_at":"2026-04-25T07:02:00Z","source_tool":"vector","source_kind":"lane","source_name":"posture","source_run_id":"posture-1","target":"demo-node","observation_type":"http_posture_finding","confidence":"medium","value":{"severity":"low","label":"missing-security-headers","url":"https://demo-node/","detail":"X-Frame-Options, Referrer-Policy"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl" <<'EOF'
{"recorded_at":"2026-04-25T07:03:00Z","source_tool":"vector","source_kind":"lane","source_name":"posture","source_run_id":"posture-1","target":"demo-node","backend":"http-posture","status":"success","summary":"1 HTTP posture finding recorded","run_log":"/tmp/posture.log","loot_count":1,"observation_count":2}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" target story demo-node

  [ "$status" -eq 0 ]
  [[ "$output" == *"Target Story"* ]]
  [[ "$output" == *"Operator Brief"* ]]
  [[ "$output" == *"Scope Status: in-scope"* ]]
  [[ "$output" == *"Criticality: high"* ]]
  [[ "$output" == *"Owner: platform"* ]]
  [[ "$output" == *"Tags: lab web"* ]]
  [[ "$output" == *"Surface: host=up, services=1, web=1"* ]]
  [[ "$output" == *"Operation State: no active operation for this target"* ]]
  [[ "$output" == *"Target Record"* ]]
  [[ "$output" == *"Current Surface"* ]]
  [[ "$output" == *"Web Surface"* ]]
  [[ "$output" == *"Action Outcomes"* ]]
  [[ "$output" == *"Posture Findings"* ]]
  [[ "$output" == *"low missing-security-headers https://demo-node/"* ]]
  [[ "$output" == *"Recent Evidence"* ]]
  [[ "$output" == *"Next Actions"* ]]
  [[ "$output" == *"posture"* ]]

  recent="$(
    printf '%s\n' "$output" |
      awk '/Recent Evidence/{capture=1; next}/Next Actions/{capture=0}capture'
  )"
  [ "$(printf '%s\n' "$recent" | grep -c 'web_surface.*https://demo-node')" -eq 1 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" target brief demo-node
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operator Brief"* ]]
  [[ "$output" == *"Scope Status: in-scope"* ]]
  [[ "$output" == *"Criticality: high"* ]]
  [[ "$output" == *"Surface: host=up, services=1, web=1"* ]]
  [[ "$output" == *"Latest Outcome: posture success 1 HTTP posture finding recorded"* ]]
  [[ "$output" == *"Next Step: Start or resume an Atlas operation before recording evidence or validation."* ]]
}

@test "atlas cycle summarizes exposure, findings, validation queue, and candidates" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/toolkit/state/intel"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
SCOPE_STATUS=in-scope
CRITICALITY=high
TAGS='lab web'
OWNER=platform
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-25T07:00:00Z","entity_type":"host","entity_id":"host:demo-node","target":"demo-node","attributes":{"address":"10.10.10.10"}}
{"observed_at":"2026-04-25T07:00:00Z","entity_type":"service","entity_id":"service:demo-node:443/tcp","target":"demo-node","attributes":{"portproto":"443/tcp","service":"https","detail":"DPS/2.0.0"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-25T07:00:00Z","source_tool":"wiremap","source_kind":"recon","source_name":"web-stack","source_run_id":"run-1","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-25T07:01:00Z","source_tool":"wiremap","source_kind":"recon","source_name":"web-stack","source_run_id":"run-1","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"portproto":"443/tcp","service":"https","detail":"DPS/2.0.0"}}
{"observed_at":"2026-04-25T07:01:01Z","source_tool":"wiremap","source_kind":"recon","source_name":"web-stack","source_run_id":"run-1","target":"demo-node","observation_type":"web_surface","confidence":"high","value":{"endpoint":"https://demo-node","portproto":"443/tcp","service":"https","detail":"Ascend and Defend Academy"}}
{"observed_at":"2026-04-25T07:02:00Z","source_tool":"vector","source_kind":"lane","source_name":"posture","source_run_id":"posture-1","target":"demo-node","observation_type":"http_posture_finding","confidence":"medium","value":{"severity":"low","label":"missing-security-headers","url":"https://demo-node/","detail":"X-Frame-Options, Referrer-Policy"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl" <<'EOF'
{"recorded_at":"2026-04-25T07:03:00Z","source_tool":"vector","source_kind":"lane","source_name":"posture","source_run_id":"posture-1","target":"demo-node","backend":"http-posture","status":"success","summary":"1 HTTP posture finding recorded","run_log":"/tmp/posture.log","loot_count":1,"observation_count":2}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start cycle-op demo-node authorized cycle
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" finding add "Missing security headers" \
    --level observed \
    --severity low \
    --source vector \
    --impact "browser-side defense in depth is weaker" \
    --recommendation "set the missing security headers"
  [ "$status" -eq 0 ]
  finding_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$finding_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" cycle demo-node
  [ "$status" -eq 0 ]
  [[ "$output" == *"Atlas Exposure Cycle"* ]]
  [[ "$output" == *"Target: demo-node"* ]]
  [[ "$output" == *"Address: 10.10.10.10"* ]]
  [[ "$output" == *"Operation: cycle-op"* ]]
  [[ "$output" == *"Discover"* ]]
  [[ "$output" == *"Surface: host=up, services=1, web=1, lateral=0"* ]]
  [[ "$output" == *"Latest Outcome: posture success 1 HTTP posture finding recorded"* ]]
  [[ "$output" == *"Assess"* ]]
  [[ "$output" == *"Shared Posture Findings: 1"* ]]
  [[ "$output" == *"Operation Findings: 1"* ]]
  [[ "$output" == *"Findings Needing Validation Plan: 1"* ]]
  [[ "$output" == *"Missing security headers"* ]]
  [[ "$output" == *"Validate"* ]]
  [[ "$output" == *"Validation Plans: planned=0, approved=0, executed=0"* ]]
  [[ "$output" == *"Report"* ]]
  [[ "$output" == *"Evidence: 0"* ]]
  [[ "$output" == *"Next Safe Step: Create a validation plan for the highest-value finding."* ]]
  [[ "$output" == *"Candidate Lanes"* ]]
  [[ "$output" == *"posture"* ]]
  [[ "$output" == *"cycle is read-only"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" validation plan posture \
    --finding "$finding_id" \
    --reason "confirm missing headers"
  [ "$status" -eq 0 ]
  plan_id="$(printf '%s\n' "$output" | awk -F': ' '$1 == "id" { print $2; exit }')"
  [ -n "$plan_id" ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op cycle cycle-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Atlas Exposure Cycle"* ]]
  [[ "$output" == *"Findings Needing Validation Plan: 0"* ]]
  [[ "$output" == *"Validation Plans: planned=1, approved=0, executed=0"* ]]
  [[ "$output" == *"$plan_id"* ]]
  [[ "$output" == *"planned"* ]]
  [[ "$output" == *"confirm missing headers"* ]]
  [[ "$output" == *"Next Safe Step: Approve, revise, or retire the planned validation before execution."* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" cycle
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation: cycle-op"* ]]
  [[ "$output" == *"Validation Plans: planned=1, approved=0, executed=0"* ]]
}
