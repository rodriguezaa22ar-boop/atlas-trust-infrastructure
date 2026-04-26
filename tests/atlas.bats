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
  [[ "$output" == *"atlas evidence redact <id> <redacted-path>"* ]]
  [[ "$output" == *"atlas evidence bundle [bundle-name]"* ]]
  [[ "$output" == *"atlas finding add <title> [--level observed|inferred|validated]"* ]]
  [[ "$output" == *"atlas finding update <id> [--level level] [--status status]"* ]]
  [[ "$output" == *"atlas finding resolve <id> [--evidence id] [--validation id]"* ]]
  [[ "$output" == *"atlas validation plan <lane> [--finding id] [--evidence id]"* ]]
  [[ "$output" == *"atlas validation retest <id> --result resolved|still-open"* ]]
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
  [[ "$output" == *"atlas op close [name] [--force]"* ]]
  [[ "$output" == *"atlas target brief <target>"* ]]
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

  printf '\narchive report changed after packet\n' >> "$report_path"
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive-verify archive-op "$archive_packet_path"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Latest Report"* ]]
  [[ "$output" == *"changed"* ]]
  [[ "$output" == *"Verification Status: attention-required"* ]]
  [[ "$output" == *"Verification Problems: 1"* ]]

  sleep 1
  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit-packet archive-op archive-audit-after-archive
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op archive archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"Archive Status: attention-required"* ]]
  [[ "$output" == *"Archive Packet Freshness: stale"* ]]

  run "$TEST_ROOT/toolkit/tools/atlas/bin/atlas" op audit archive-op
  [ "$status" -eq 0 ]
  [[ "$output" == *"stale archive packet:"* ]]
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
