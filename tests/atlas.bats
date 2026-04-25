#!/usr/bin/env bats

setup() {
  export TEST_ROOT
  TEST_ROOT="$(mktemp -d)"
  cp -R "$BATS_TEST_DIRNAME/.." "$TEST_ROOT/toolkit"
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

@test "atlas help groups target-first workflow and story commands" {
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" help

  [ "$status" -eq 0 ]
  [[ "$output" == *"quick flow:"* ]]
  [[ "$output" == *"atlas doctor"* ]]
  [[ "$output" == *"atlas scope status"* ]]
  [[ "$output" == *"atlas evidence add <path> [--kind kind]"* ]]
  [[ "$output" == *"atlas finding add <title> [--level observed|inferred|validated]"* ]]
  [[ "$output" == *"atlas validation plan <lane> [--finding id] [--evidence id]"* ]]
  [[ "$output" == *"targets:"* ]]
  [[ "$output" == *"operations:"* ]]
  [[ "$output" == *"story views:"* ]]
  [[ "$output" == *"scope:"* ]]
  [[ "$output" == *"validation:"* ]]
  [[ "$output" == *"atlas target story <target>"* ]]
  [[ "$output" == *"atlas story demo-web-app"* ]]
  [[ "$output" == *"atlas op show [name]"* ]]
  [[ "$output" == *"atlas op story [name]"* ]]
  [[ "$output" == *"atlas op report [name] [report-name]"* ]]
}

@test "atlas profiles list, show, and snapshot operation scope" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
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
CREATED_AT=2026-04-23T20:53:16Z
EOF

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op start cutover demo-node runtime smoke

  [ "$status" -eq 0 ]
  [[ "$output" == *"target: demo-node"* ]]
  [[ "$output" == *"address: 10.10.10.10"* ]]
  grep -q '^TARGET=demo-node$' "$TEST_ROOT/toolkit/sessions/cutover/session.env"
  grep -q '^TARGET_ADDRESS=10.10.10.10$' "$TEST_ROOT/toolkit/sessions/cutover/session.env"
  grep -q '^SCOPE_TARGET=demo-node$' "$TEST_ROOT/toolkit/sessions/cutover/scope.snapshot.env"
  grep -q 'active-recon' "$TEST_ROOT/toolkit/sessions/cutover/scope.snapshot.env"
  jq -e 'select(.event == "op.started" and .op == "cutover" and .target == "demo-node")' \
    "$TEST_ROOT/toolkit/sessions/cutover/ledger.ndjson"

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op status cutover
  [ "$status" -eq 0 ]
  [[ "$output" == *"Target: demo-node -> 10.10.10.10"* ]]

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
}

@test "atlas direct execution routes fail closed or use operation scope" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
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

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op brief
  [ "$status" -eq 0 ]
  [[ "$output" == *"Validation Plans"* ]]
  [[ "$output" == *"$plan_id"* ]]
  [[ "$output" == *"executed"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op report validation-op validation-report
  [ "$status" -eq 0 ]
  report_path="$(printf '%s\n' "$output" | awk -F': ' '$1 == "report" { print $2; exit }')"
  [ -f "$report_path" ]
  grep -q '## Validation Plans' "$report_path"
  grep -q "$plan_id" "$report_path"
  grep -q 'Result: success' "$report_path"

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

  jq -e \
    --arg evidence_id "$evidence_id" \
    --arg sha256 "$expected_sha" \
    'select(.id == $evidence_id and .sha256 == $sha256 and .kind == "scan-output" and .target == "demo-node")' \
    "$TEST_ROOT/toolkit/sessions/evidence-op/evidence.ndjson"
  jq -e \
    --arg evidence_id "$evidence_id" \
    'select(.event == "artifact.created" and (.detail | contains($evidence_id)))' \
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
  [[ "$output" == *"Evidence: 1"* ]]
  [[ "$output" == *"Findings: 2"* ]]
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
  [[ "$output" == *"Active Operation Evidence"* ]]
  [[ "$output" == *"$evidence_id"* ]]
  [[ "$output" == *"Active Operation Findings"* ]]
  [[ "$output" == *"SSH management reachable"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" target story 10.10.10.10
  [ "$status" -eq 0 ]
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
}
