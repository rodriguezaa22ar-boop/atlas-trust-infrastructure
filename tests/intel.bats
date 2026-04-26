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
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap"
  unset LAB_CONFIG
  export LAB_ROOT="$TEST_ROOT/toolkit"
  export LAB_WIREMAP_RUNS_DIR="$TEST_ROOT/runs"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "intelctl summary reports shared intel counts and observation types" {
  mkdir -p "$TEST_ROOT/toolkit/state/intel"

  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"perimeter-sweep","target":"10.0.0.8","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"perimeter-sweep","target":"10.0.0.8","observation_type":"service_open","confidence":"high","value":{"portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","entity_type":"host","entity_id":"host:10.0.0.8","target":"10.0.0.8","attributes":{"address":"10.0.0.8"}}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl" <<'EOF'
{"recorded_at":"2026-04-24T00:00:02Z","source_tool":"wiremap","source_name":"perimeter-sweep","target":"10.0.0.8","status":"success","service_count":1,"web_surface_count":0,"lateral_surface_count":1}
EOF
  cat > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","relationship_type":"host-exposes-service","from_entity":"host:10.0.0.8","to_entity":"service:10.0.0.8:22/tcp","target":"10.0.0.8"}
EOF

  run "$TEST_ROOT/toolkit/bin/intelctl" summary

  [ "$status" -eq 0 ]
  [[ "$output" == *"Observations"* ]]
  [[ "$output" == *"Entities"* ]]
  [[ "$output" == *"Outcomes"* ]]
  [[ "$output" == *"Relationships"* ]]
  [[ "$output" == *"host_state"* ]]
  [[ "$output" == *"service_open"* ]]
  [[ "$output" == *"perimeter-sweep"* ]]

  run "$TEST_ROOT/toolkit/bin/intelctl" graph 10.0.0.8
  [ "$status" -eq 0 ]
  [[ "$output" == *"digraph intel"* ]]
  [[ "$output" == *"rankdir=LR"* ]]
  [[ "$output" == *"host:10.0.0.8"* ]]
  [[ "$output" == *"service:10.0.0.8:22/tcp"* ]]
  [[ "$output" == *"host-exposes-service"* ]]

  run "$TEST_ROOT/toolkit/bin/intelctl" graph 10.0.0.8 --format ndjson
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" |
    jq -e 'select(.record_type == "node" and .id == "host:10.0.0.8" and .entity_type == "host")'
  printf '%s\n' "$output" |
    jq -e 'select(.record_type == "edge" and .from == "host:10.0.0.8" and .to == "service:10.0.0.8:22/tcp" and .relationship_type == "host-exposes-service")'

  graph_path="$TEST_ROOT/graph.dot"
  run "$TEST_ROOT/toolkit/bin/intelctl" graph 10.0.0.8 --output "$graph_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"graph export written"* ]]
  [[ "$output" == *"format: dot"* ]]
  [ -f "$graph_path" ]
  grep -q 'host-exposes-service' "$graph_path"
}

@test "intelctl renders web posture observations and vector outcomes with useful detail" {
  mkdir -p "$TEST_ROOT/toolkit/state/intel"

  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:03Z","source_tool":"vector","source_name":"web","target":"demo-node","observation_type":"web_probe","confidence":"medium","value":{"endpoint":"https://demo-node","status_code":"200","server":"DPS/2.0.0","title":"Ascend and Defend Academy"}}
{"observed_at":"2026-04-24T00:00:04Z","source_tool":"vector","source_name":"posture","target":"demo-node","observation_type":"http_posture_finding","confidence":"medium","value":{"severity":"low","label":"missing-security-headers","url":"https://demo-node/","detail":"X-Frame-Options"}}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/entities.jsonl"
  cat > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl" <<'EOF'
{"recorded_at":"2026-04-24T00:00:05Z","source_tool":"vector","source_name":"posture","target":"demo-node","status":"success","backend":"http-posture","summary":"1 HTTP posture finding recorded","loot_count":1,"observation_count":2}
EOF
  : > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl"

  run "$TEST_ROOT/toolkit/bin/intelctl" observations demo-node
  [ "$status" -eq 0 ]
  [[ "$output" == *"https://demo-node status=200 server=DPS/2.0.0 title=Ascend and Defend Academy"* ]]
  [[ "$output" == *"low missing-security-headers https://demo-node/ X-Frame-Options"* ]]

  run "$TEST_ROOT/toolkit/bin/intelctl" outcomes demo-node
  [ "$status" -eq 0 ]
  [[ "$output" == *"backend=http-posture loot=1 observations=2 1 HTTP posture finding recorded"* ]]
}

@test "wiremap workflow publishes shared intel after a run" {
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/fake-nmap" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

if [[ "$*" == *"-sn"* ]]; then
  printf '%s\n' 'Nmap scan report for 10.0.0.7'
  printf '%s\n' 'Host is up'
  exit 0
fi

printf '%s\n' 'Nmap scan report for 10.0.0.7'
printf '%s\n' '22/tcp open  ssh      OpenSSH 9.7'
printf '%s\n' '80/tcp open  http     nginx 1.25.5'
EOF
  chmod +x "$TEST_ROOT/fake-bin/fake-nmap"

  run env PATH="$TEST_ROOT/fake-bin:$PATH" LAB_WIREMAP_UPSTREAM_BIN=fake-nmap \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" workflow run perimeter-sweep 10.0.0.7

  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/toolkit/state/intel/observations.jsonl" ]
  [ -f "$TEST_ROOT/toolkit/state/intel/entities.jsonl" ]
  [ -f "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl" ]
  [ -f "$TEST_ROOT/toolkit/state/intel/relationships.jsonl" ]

  run jq -r '.observation_type' "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
  [ "$status" -eq 0 ]
  [[ "$output" == *"host_state"* ]]
  [[ "$output" == *"service_open"* ]]
  [[ "$output" == *"web_surface"* ]]
  [[ "$output" == *"lateral_surface"* ]]

  run jq -r 'select(.entity_type == "service") | .entity_id' "$TEST_ROOT/toolkit/state/intel/entities.jsonl"
  [ "$status" -eq 0 ]
  [[ "$output" == *"service:10.0.0.7:22/tcp"* ]]
  [[ "$output" == *"service:10.0.0.7:80/tcp"* ]]

  run jq -r '.status + " " + (.service_count|tostring)' "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl"
  [ "$status" -eq 0 ]
  [[ "$output" == *"success 2"* ]]

  run "$TEST_ROOT/toolkit/bin/intelctl" observations 10.0.0.7 service_open
  [ "$status" -eq 0 ]
  [[ "$output" == *"22/tcp ssh OpenSSH 9.7"* ]]
  [[ "$output" == *"80/tcp http nginx 1.25.5"* ]]
}
