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
  [[ "$output" == *"targets:"* ]]
  [[ "$output" == *"operations:"* ]]
  [[ "$output" == *"story views:"* ]]
  [[ "$output" == *"atlas target story <target>"* ]]
  [[ "$output" == *"atlas story demo-web-app"* ]]
  [[ "$output" == *"atlas op show [name]"* ]]
  [[ "$output" == *"atlas op story [name]"* ]]
  [[ "$output" == *"atlas op report [name] [report-name]"* ]]
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
