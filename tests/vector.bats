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
    "$TEST_ROOT/toolkit/tools/vector/bin/vector"
  unset LAB_CONFIG
  export LAB_ROOT="$TEST_ROOT/toolkit"
  export FAKE_BIN="$TEST_ROOT/fake-bin"
  mkdir -p "$TEST_ROOT/toolkit/state/intel" "$FAKE_BIN"

  cat > "$FAKE_BIN/nmap" <<'EOF'
#!/usr/bin/env bash
target="${*: -1}"
args=" $* "
printf 'Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-24 00:00 UTC\n'
printf 'Nmap scan report for %s\n' "$target"
printf 'Host is up, received user-set (0.00025s latency).\n'
printf 'PORT   STATE SERVICE      REASON  VERSION\n'
if [[ "$args" == *"80/tcp"* || "$args" == *"T:80"* ]]; then
  printf '22/tcp  open  ssh          syn-ack OpenSSH 9.7\n'
  printf '80/tcp  open  http         syn-ack nginx 1.25.5\n'
  printf '445/tcp open  microsoft-ds syn-ack Samba 4.19\n'
elif [[ "$args" == *"445/tcp"* || "$args" == *"T:445"* ]]; then
  printf '22/tcp  open  ssh          syn-ack OpenSSH 9.7\n'
  printf '445/tcp open  microsoft-ds syn-ack Samba 4.19\n'
else
  printf '22/tcp  open  ssh          syn-ack OpenSSH 9.7\n'
fi
printf '\nNmap done: 1 IP address (1 host up) scanned in 0.04 seconds\n'
EOF

  cat > "$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
headers=""
body=""
url=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -sk|-skL)
      shift
      ;;
    --max-time)
      shift 2
      ;;
    -D)
      headers="$2"
      shift 2
      ;;
    -o)
      body="$2"
      shift 2
      ;;
    *)
      url="$1"
      shift
      ;;
  esac
done
printf 'HTTP/1.1 200 OK\r\nServer: fake-nginx\r\nContent-Type: text/html\r\n\r\n' > "$headers"
printf '<html><head><title>Admin Portal</title></head><body>%s</body></html>\n' "$url" > "$body"
EOF

  cat > "$FAKE_BIN/msfconsole" <<'EOF'
#!/usr/bin/env bash
command_string=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -q)
      shift
      ;;
    -x)
      command_string="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

printf 'Matching Modules\n'
printf '================\n\n'
printf '   #  Name                                  Disclosure Date  Rank    Check  Description\n'
printf '   -  ----                                  ---------------  ----    -----  -----------\n'

case "$command_string" in
  *"search ssh"*|*"search openssh"*)
    printf '   0  auxiliary/scanner/ssh/ssh_version                      normal  No     SSH Version Scanner\n'
    printf '   1  auxiliary/scanner/ssh/ssh_login                        normal  No     SSH Login Check Scanner\n'
    ;;
  *"search http"*|*"search nginx"*)
    printf '   0  auxiliary/scanner/http/http_version                    normal  No     HTTP Version Detection\n'
    printf '   1  auxiliary/scanner/http/title                           normal  No     HTTP Title Scanner\n'
    printf '   2  auxiliary/scanner/http/robots_txt                      normal  No     HTTP robots.txt Scanner\n'
    ;;
  *"search smb"*|*"search samba"*)
    printf '   0  auxiliary/scanner/smb/smb_version                      normal  No     SMB Version Detection\n'
    printf '   1  auxiliary/scanner/smb/smb_login                        normal  No     SMB Login Check Scanner\n'
    ;;
esac
EOF

  chmod +x "$FAKE_BIN/nmap" "$FAKE_BIN/curl" "$FAKE_BIN/msfconsole"
  export LAB_VECTOR_NMAP_BIN="$FAKE_BIN/nmap"
  export LAB_VECTOR_CURL_BIN="$FAKE_BIN/curl"
  export LAB_VECTOR_MSFCONSOLE_BIN="$FAKE_BIN/msfconsole"

  cat > "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:10.0.0.8:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
{"observed_at":"2026-04-24T00:00:02Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:10.0.0.8:80/tcp","portproto":"80/tcp","service":"http","detail":"nginx 1.25.5"}}
{"observed_at":"2026-04-24T00:00:03Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:10.0.0.8:445/tcp","portproto":"445/tcp","service":"microsoft-ds","detail":""}}
{"observed_at":"2026-04-24T00:00:04Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","observation_type":"web_surface","confidence":"medium","value":{"service_entity_id":"service:10.0.0.8:80/tcp","endpoint":"http://10.0.0.8:80","portproto":"80/tcp","service":"http","detail":"nginx 1.25.5"}}
{"observed_at":"2026-04-24T00:00:05Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","observation_type":"lateral_surface","confidence":"medium","value":{"service_entity_id":"service:10.0.0.8:22/tcp","label":"remote-admin","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
{"observed_at":"2026-04-24T00:00:06Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","observation_type":"lateral_surface","confidence":"medium","value":{"service_entity_id":"service:10.0.0.8:445/tcp","label":"windows-surface","portproto":"445/tcp","service":"microsoft-ds","detail":""}}
EOF

  cat > "$TEST_ROOT/toolkit/state/intel/entities.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","entity_type":"host","entity_id":"host:10.0.0.8","target":"10.0.0.8","attributes":{"address":"10.0.0.8"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","entity_type":"service","entity_id":"service:10.0.0.8:22/tcp","target":"10.0.0.8","attributes":{"target":"10.0.0.8","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
{"observed_at":"2026-04-24T00:00:02Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","entity_type":"service","entity_id":"service:10.0.0.8:80/tcp","target":"10.0.0.8","attributes":{"target":"10.0.0.8","portproto":"80/tcp","service":"http","detail":"nginx 1.25.5"}}
{"observed_at":"2026-04-24T00:00:03Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","entity_type":"service","entity_id":"service:10.0.0.8:445/tcp","target":"10.0.0.8","attributes":{"target":"10.0.0.8","portproto":"445/tcp","service":"microsoft-ds","detail":""}}
EOF

  cat > "$TEST_ROOT/toolkit/state/intel/outcomes.jsonl" <<'EOF'
{"recorded_at":"2026-04-24T00:00:07Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","target":"10.0.0.8","status":"success","host_state":"up","service_count":3,"web_surface_count":1,"lateral_surface_count":2}
EOF

  cat > "$TEST_ROOT/toolkit/state/intel/relationships.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"perimeter-sweep","source_run_id":"run-1","relationship_type":"host-exposes-service","from_entity":"host:10.0.0.8","to_entity":"service:10.0.0.8:22/tcp","target":"10.0.0.8"}
EOF
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "vector lists action lanes and backends" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" lanes

  [ "$status" -eq 0 ]
  [[ "$output" == *"validate"* ]]
  [[ "$output" == *"credentials"* ]]
  [[ "$output" == *"lateral"* ]]
  [[ "$output" == *"[WEB]"* ]]
  [[ "$output" == *"[POSTURE]"* ]]
  [[ "$output" == *"service-refresh"* ]]
  [[ "$output" == *"http-posture"* ]]
  [[ "$output" == *"msf-module-scout"* ]]
}

@test "vector target summary reads shared intel and shows vector history" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" target summary 10.0.0.8

  [ "$status" -eq 0 ]
  [[ "$output" == *"Target Summary"* ]]
  [[ "$output" == *"Host State"* ]]
  [[ "$output" == *"Services"* ]]
  [[ "$output" == *"Vector Successes"* ]]
  [[ "$output" == *"22/tcp"* ]]
  [[ "$output" == *"80/tcp"* ]]
  [[ "$output" == *"445/tcp"* ]]
}

@test "vector ranks candidates from shared intel" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" candidates 10.0.0.8

  [ "$status" -eq 0 ]
  [[ "$output" == *"Ranked Candidates"* ]]
  [[ "$output" == *"[1] [LATERAL] lateral"* ]]
  [[ "$output" == *"[2] [CREDENTIALS] credentials"* ]]
  [[ "$output" == *"[3] [WEB] web"* ]]
  [[ "$output" == *"movement-oriented surface(s) observed"* ]]
}

@test "vector plan explains lane evidence and backend" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" plan lateral 10.0.0.8

  [ "$status" -eq 0 ]
  [[ "$output" == *"Lane Plan"* ]]
  [[ "$output" == *"movement-oriented surface(s) observed"* ]]
  [[ "$output" == *"remote-admin"* ]]
  [[ "$output" == *"windows-surface"* ]]
  [[ "$output" == *"Backend"* ]]
  [[ "$output" == *"movement-scout"* ]]
}

@test "vector elevates credentials when wiremap publishes packet auth hints" {
  cat >> "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:08Z","source_tool":"wiremap","source_kind":"capture","source_name":"credential_hint","source_run_id":"run-1","target":"10.0.0.8","observation_type":"credential_hint","confidence":"medium","value":{"label":"basic-auth","evidence":"Authorization: Basic dXNlcjpwYXNz"}}
{"observed_at":"2026-04-24T00:00:09Z","source_tool":"wiremap","source_kind":"capture","source_name":"capture_anomaly","source_run_id":"run-1","target":"10.0.0.8","observation_type":"capture_anomaly","confidence":"medium","value":{"label":"reset","evidence":"12 0.150000 10.0.0.8 -> 10.0.0.1 TCP [RST]"}}
EOF

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" candidates 10.0.0.8

  [ "$status" -eq 0 ]
  [[ "$output" == *"credential hint(s) from capture"* ]]
  [[ "$output" == *"capture anomaly hint(s) observed"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" plan credentials 10.0.0.8
  [ "$status" -eq 0 ]
  [[ "$output" == *"Authorization: Basic"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" target summary 10.0.0.8
  [ "$status" -eq 0 ]
  [[ "$output" == *"Credential Hints"* ]]
  [[ "$output" == *"Capture Anomalies"* ]]
}

@test "vector run validate records outcome and session artifacts" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" run validate 10.0.0.8 "Validate Session"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Vector Run"* ]]
  [[ "$output" == *"Status: success"* ]]
  [[ "$output" == *"3 service(s) refreshed for validation"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" outcomes 10.0.0.8
  [ "$status" -eq 0 ]
  [[ "$output" == *"validate"* ]]
  [[ "$output" == *"success"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" session list
  [ "$status" -eq 0 ]
  [[ "$output" == *"validate-session"* ]]
  [[ "$output" == *"service-refresh"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" session show validate-session
  [ "$status" -eq 0 ]
  [[ "$output" == *"Vector Session"* ]]
  [[ "$output" == *"validate-session"* ]]
  [[ "$output" == *"validate-services.tsv"* ]]

  run cat "$TEST_ROOT/toolkit/sessions/validate-session/notes/validate-command.txt"
  [ "$status" -eq 0 ]
  [[ "$output" == *"T:22"* ]]
  [[ "$output" == *"T:80"* ]]
  [[ "$output" == *"T:445"* ]]
  [[ "$output" != *"/tcp"* ]]
}

@test "vector nmap refresh resolves target records for action runs" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat >> "$TEST_ROOT/toolkit/state/intel/observations.jsonl" <<'EOF'
{"observed_at":"2026-04-24T00:00:00Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"host_state","confidence":"high","value":{"state":"up"}}
{"observed_at":"2026-04-24T00:00:01Z","source_tool":"wiremap","source_name":"fast","source_run_id":"run-2","target":"demo-node","observation_type":"service_open","confidence":"high","value":{"service_entity_id":"service:demo-node:22/tcp","portproto":"22/tcp","service":"ssh","detail":"OpenSSH 9.7"}}
EOF

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" run validate demo-node "Demo Validate"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: success"* ]]

  run cat "$TEST_ROOT/toolkit/sessions/demo-validate/notes/validate-command.txt"
  [ "$status" -eq 0 ]
  [[ "$output" == *"10.10.10.10"* ]]
  [[ "$output" != *" demo-node"* ]]
  grep -q '"target":"demo-node"' "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
}

@test "vector run web records probe intel and loot" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" run web 10.0.0.8 "Web Session"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: success"* ]]
  [[ "$output" == *"1 web endpoint(s) probed successfully"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" target web 10.0.0.8
  [ "$status" -eq 0 ]
  [[ "$output" == *"Admin Portal"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" loot list web-session
  [ "$status" -eq 0 ]
  [[ "$output" == *"loot/web-probes.tsv"* ]]
}

@test "vector run posture records HTTP posture routes and findings" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" run posture 10.0.0.8 "Posture Session"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: success"* ]]
  [[ "$output" == *"HTTP posture probe(s)"* ]]
  [[ "$output" == *"review finding(s)"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" loot list posture-session
  [ "$status" -eq 0 ]
  [[ "$output" == *"loot/posture-routes.tsv"* ]]
  [[ "$output" == *"loot/posture-findings.tsv"* ]]

  run cat "$TEST_ROOT/toolkit/sessions/posture-session/loot/posture-findings.tsv"
  [ "$status" -eq 0 ]
  [[ "$output" == *"missing-security-headers"* ]]
  [[ "$output" == *"login-admin-route-review"* ]]

  grep -q '"observation_type":"http_posture"' "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
  grep -q '"observation_type":"http_posture_finding"' "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
}

@test "vector run research emits module candidates" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" run research 10.0.0.8 "Research Session"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: success"* ]]
  [[ "$output" == *"7 module candidate(s) derived"* ]]
  [[ "$output" == *"metasploit-backed"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" loot list research-session
  [ "$status" -eq 0 ]
  [[ "$output" == *"loot/module-candidates.tsv"* ]]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" session show research-session
  [ "$status" -eq 0 ]
  [[ "$output" == *"research-msf.txt"* ]]
}

@test "vector candidate history reflects prior successful run" {
  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" run lateral 10.0.0.8 "Lateral Session"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/tools/vector/bin/vector" candidates 10.0.0.8
  [ "$status" -eq 0 ]
  [[ "$output" == *"history: 1 prior success"* ]]
}
