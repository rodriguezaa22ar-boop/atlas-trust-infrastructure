#!/usr/bin/env bats

setup() {
  export TEST_ROOT
  TEST_ROOT="$(mktemp -d)"
  cp -R "$BATS_TEST_DIRNAME/.." "$TEST_ROOT/toolkit"
  export FAKE_BIN="$TEST_ROOT/fake-bin"
  mkdir -p "$FAKE_BIN"
  chmod +x \
    "$TEST_ROOT/toolkit/bin/intelctl" \
    "$TEST_ROOT/toolkit/bin/labctl" \
    "$TEST_ROOT/toolkit/lib/common.sh" \
    "$TEST_ROOT/toolkit/lib/intel.sh" \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap"
  unset LAB_CONFIG
  export LAB_ROOT="$TEST_ROOT/toolkit"
  export LAB_WIREMAP_RUNS_DIR="$TEST_ROOT/runs"

  cat > "$FAKE_BIN/fake-tshark" <<'EOF'
#!/usr/bin/env bash
command_string=" $* "

case "$command_string" in
  *" -z io,phs "*)
    printf 'Protocol Hierarchy Statistics\n'
    printf 'eth frames:12 bytes:1024\n'
    printf '  ip frames:12 bytes:980\n'
    printf '    tcp frames:9 bytes:760\n'
    printf '      http frames:4 bytes:320\n'
    ;;
  *" -z conv,tcp "*)
    printf 'TCP Conversations\n'
    printf '10.0.0.8:52344 <-> 10.0.0.1:80  12 frames\n'
    ;;
  *" -z conv,udp "*)
    printf 'UDP Conversations\n'
    printf '10.0.0.8:5353 <-> 224.0.0.251:5353  2 frames\n'
    ;;
  *" -V "*)
    printf 'Authorization: Basic dXNlcjpwYXNz\n'
    printf 'Cookie: session=abc123\n'
    ;;
  *"tcp.flags.reset==1"*|*"tcp.analysis.retransmission"*|*"icmp.type==3"*)
    printf '12 0.150000 10.0.0.8 -> 10.0.0.1 TCP [RST]\n'
    printf '13 0.190000 10.0.0.8 -> 10.0.0.1 TCP Retransmission\n'
    ;;
  *)
    printf '1 0.000000 10.0.0.8 -> 10.0.0.1 TCP SYN\n'
    printf '2 0.010000 10.0.0.1 -> 10.0.0.8 TCP SYN, ACK\n'
    printf '3 0.020000 10.0.0.8 -> 10.0.0.1 HTTP GET /login\n'
    ;;
esac
EOF
  chmod +x "$FAKE_BIN/fake-tshark"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "wiremap workflow lists built-in profiles" {
  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" profile list

  [ "$status" -eq 0 ]
  [[ "$output" == *"discover"* ]]
  [[ "$output" == *"admin"* ]]
  [[ "$output" == *"service"* ]]
  [[ "$output" == *"udp-top"* ]]
}

@test "wiremap workflow catalog lists named paths" {
  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" workflow list

  [ "$status" -eq 0 ]
  [[ "$output" == *"perimeter-sweep"* ]]
  [[ "$output" == *"web-stack"* ]]
  [[ "$output" == *"lateral-check"* ]]
}

@test "wiremap workflow can show workflow detail" {
  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" workflow show lateral-check

  [ "$status" -eq 0 ]
  [[ "$output" == *"Workflow Detail"* ]]
  [[ "$output" == *"[LATERAL]"* ]]
  [[ "$output" == *"admin"* ]]
}

@test "wiremap profile can plan a scan with capture context" {
  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" plan fast 192.168.1.10 eth0

  [ "$status" -eq 0 ]
  [[ "$output" == *"profile: fast"* ]]
  [[ "$output" == *"target: 192.168.1.10"* ]]
  [[ "$output" == *"capture_interface: eth0"* ]]
  [[ "$output" == *"scan_command:"* ]]
  [[ "$output" == *"nmap"* ]]
  [[ "$output" == *"capture_command:"* ]]
  [[ "$output" == *"tcpdump"* ]]
}

@test "wiremap resolves target records when planning scan commands" {
  mkdir -p "$TEST_ROOT/toolkit/targets"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF

  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" plan fast demo-node eth0

  [ "$status" -eq 0 ]
  [[ "$output" == *"target: demo-node"* ]]
  [[ "$output" == *"target_address: 10.10.10.10"* ]]
  [[ "$output" == *"scan_command: nmap -Pn -n -T4 -F --reason 10.10.10.10"* ]]
  [[ "$output" == *"capture_filter: host 10.10.10.10"* ]]
}

@test "wiremap workflow can plan a staged run with capture context" {
  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" workflow plan perimeter-sweep 192.168.1.10 eth0

  [ "$status" -eq 0 ]
  [[ "$output" == *"workflow: perimeter-sweep"* ]]
  [[ "$output" == *"workflow_steps: discover,fast,service"* ]]
  [[ "$output" == *"workflow_step_1: discover"* ]]
  [[ "$output" == *"workflow_step_2: fast"* ]]
  [[ "$output" == *"workflow_step_3: service"* ]]
  [[ "$output" == *"workflow_capture_interface: eth0"* ]]
}

@test "wiremap workflow can show profile detail" {
  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" profile show service

  [ "$status" -eq 0 ]
  [[ "$output" == *"Profile Detail"* ]]
  [[ "$output" == *"[FINGERPRINT]"* ]]
  [[ "$output" == *"understand what is actually listening"* ]]
}

@test "wiremap workflow can run a staged path without system nmap" {
  mkdir -p "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/fake-bin/fake-nmap" <<'EOF'
#!/usr/bin/env bash
printf 'fake-nmap %s\n' "$*"
EOF
  chmod +x "$TEST_ROOT/fake-bin/fake-nmap"

  run env PATH="$TEST_ROOT/fake-bin:$PATH" LAB_WIREMAP_UPSTREAM_BIN=fake-nmap \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" workflow run perimeter-sweep 10.0.0.7

  [ "$status" -eq 0 ]
  [[ "$output" == *"workflow run complete"* ]]
  [[ "$output" == *"workflow_run_dir:"* ]]
  [ "$(find "$TEST_ROOT/runs" -type f -name '01-discover.txt' | wc -l | tr -d ' ')" = "1" ]
  [ "$(find "$TEST_ROOT/runs" -type f -name '02-fast.txt' | wc -l | tr -d ' ')" = "1" ]
  [ "$(find "$TEST_ROOT/runs" -type f -name '03-service.txt' | wc -l | tr -d ' ')" = "1" ]
}

@test "wiremap run scans target record address and keeps intel keyed to target name" {
  mkdir -p "$TEST_ROOT/toolkit/targets" "$TEST_ROOT/fake-bin"
  cat > "$TEST_ROOT/toolkit/targets/demo-node.env" <<'EOF'
NAME=demo-node
ADDRESS=10.10.10.10
CREATED_AT=2026-04-23T20:53:16Z
EOF
  cat > "$TEST_ROOT/fake-bin/fake-nmap" <<'EOF'
#!/usr/bin/env bash
printf 'fake-nmap %s\n' "$*"
printf 'Host is up\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/fake-nmap"

  run env PATH="$TEST_ROOT/fake-bin:$PATH" LAB_WIREMAP_UPSTREAM_BIN=fake-nmap \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" run fast demo-node

  [ "$status" -eq 0 ]
  [[ "$output" == *"Address"* ]]
  [[ "$output" == *"10.10.10.10"* ]]
  [[ "$output" == *"fake-nmap -Pn -n -T4 -F --reason 10.10.10.10"* ]]
  grep -q '^TARGET=demo-node$' "$(find "$TEST_ROOT/runs" -type f -name meta.env)"
  grep -q '^TARGET_ADDRESS=10.10.10.10$' "$(find "$TEST_ROOT/runs" -type f -name meta.env)"
  grep -q '"target":"demo-node"' "$TEST_ROOT/toolkit/state/intel/observations.jsonl"
}

@test "wiremap defaults run storage to persistent state directory" {
  mkdir -p "$TEST_ROOT/fake-bin"
  rm -rf "$TEST_ROOT/toolkit/state/wiremap-runs"
  cat > "$TEST_ROOT/toolkit/etc/lab.env" <<EOF
LAB_STATE_DIR=$TEST_ROOT/persist/state
EOF
  cat > "$TEST_ROOT/fake-bin/fake-nmap" <<'EOF'
#!/usr/bin/env bash
printf 'fake-nmap %s\n' "$*"
printf 'Host is up\n'
EOF
  chmod +x "$TEST_ROOT/fake-bin/fake-nmap"

  run env -u LAB_WIREMAP_RUNS_DIR PATH="$TEST_ROOT/fake-bin:$PATH" LAB_WIREMAP_UPSTREAM_BIN=fake-nmap \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" run fast 10.0.0.7

  [ "$status" -eq 0 ]
  [ "$(find "$TEST_ROOT/persist/state/wiremap-runs" -type f -name scan.txt | wc -l | tr -d ' ')" = "1" ]
  [ ! -d "$TEST_ROOT/toolkit/state/wiremap-runs" ]
}

@test "wiremap analyze brief builds an operator summary" {
  mkdir -p "$TEST_ROOT/brief-run"
  cat > "$TEST_ROOT/brief-run/meta.env" <<'EOF'
TARGET=10.0.0.10
EOF
  cat > "$TEST_ROOT/brief-run/scan.txt" <<'EOF'
22/tcp open  ssh      OpenSSH 9.7
80/tcp open  http     nginx 1.25.5
445/tcp open  microsoft-ds
EOF

  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" analyze brief "$TEST_ROOT/brief-run"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Operator Brief"* ]]
  [[ "$output" == *"10.0.0.10"* ]]
  [[ "$output" == *"web-facing surface present"* ]]
  [[ "$output" == *"internal admin or movement surface present"* ]]
  [[ "$output" == *"web-stack"* ]]
  [[ "$output" == *"lateral-check"* ]]
}

@test "wiremap analyze services extracts an inventory" {
  mkdir -p "$TEST_ROOT/sample-run"
  cat > "$TEST_ROOT/sample-run/meta.env" <<'EOF'
TARGET=10.0.0.7
EOF
  cat > "$TEST_ROOT/sample-run/scan.txt" <<'EOF'
22/tcp open  ssh      OpenSSH 9.7
80/tcp open  http     nginx 1.25.5
443/tcp open  ssl/http Apache httpd
EOF

  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" analyze services "$TEST_ROOT/sample-run"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Service Inventory"* ]]
  [[ "$output" == *"10.0.0.7"* ]]
  [[ "$output" == *"22/tcp"* ]]
  [[ "$output" == *"ssh"* ]]
  [[ "$output" == *"443/tcp"* ]]
}

@test "wiremap analyze web-focus isolates likely web surfaces" {
  mkdir -p "$TEST_ROOT/web-run"
  cat > "$TEST_ROOT/web-run/meta.env" <<'EOF'
TARGET=10.0.0.8
EOF
  cat > "$TEST_ROOT/web-run/scan.txt" <<'EOF'
22/tcp open  ssh      OpenSSH 9.7
80/tcp open  http     nginx 1.25.5
443/tcp open  ssl/http Apache httpd
EOF

  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" analyze web-focus "$TEST_ROOT/web-run"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Web Focus"* ]]
  [[ "$output" == *"http://10.0.0.8:80"* ]]
  [[ "$output" == *"https://10.0.0.8:443"* ]]
}

@test "wiremap analyze lateral-trace isolates admin movement surfaces" {
  mkdir -p "$TEST_ROOT/lateral-run"
  cat > "$TEST_ROOT/lateral-run/meta.env" <<'EOF'
TARGET=10.0.0.9
EOF
  cat > "$TEST_ROOT/lateral-run/scan.txt" <<'EOF'
22/tcp open  ssh      OpenSSH 9.7
445/tcp open  microsoft-ds
8080/tcp open  http     Jetty
EOF

  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" analyze lateral-trace "$TEST_ROOT/lateral-run"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Lateral Trace"* ]]
  [[ "$output" == *"remote-admin"* ]]
  [[ "$output" == *"windows-surface"* ]]
}

@test "wiremap analyze service-diff compares two runs" {
  mkdir -p "$TEST_ROOT/baseline-run" "$TEST_ROOT/candidate-run"
  cat > "$TEST_ROOT/baseline-run/scan.txt" <<'EOF'
22/tcp open  ssh      OpenSSH 9.7
80/tcp open  http     nginx 1.25.5
EOF
  cat > "$TEST_ROOT/candidate-run/scan.txt" <<'EOF'
22/tcp open  ssh      OpenSSH 9.7
443/tcp open  ssl/http Apache httpd
EOF

  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" analyze service-diff "$TEST_ROOT/baseline-run" "$TEST_ROOT/candidate-run"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Service Diff"* ]]
  [[ "$output" == *"Added"* ]]
  [[ "$output" == *"Removed"* ]]
  [[ "$output" == *"443/tcp"* ]]
  [[ "$output" == *"80/tcp"* ]]
}

@test "wiremap capture inspect shows protocol hierarchy and packet sample" {
  mkdir -p "$TEST_ROOT/capture-run"
  cat > "$TEST_ROOT/capture-run/meta.env" <<'EOF'
TARGET=10.0.0.8
EOF
  cat > "$TEST_ROOT/capture-run/scan.txt" <<'EOF'
22/tcp open  ssh      OpenSSH 9.7
80/tcp open  http     nginx 1.25.5
EOF
  : > "$TEST_ROOT/capture-run/capture.pcap"

  run env PATH="$FAKE_BIN:$PATH" LAB_DECODE_BIN=fake-tshark \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" capture inspect "$TEST_ROOT/capture-run"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Capture Inspect"* ]]
  [[ "$output" == *"Protocol Hierarchy"* ]]
  [[ "$output" == *"http frames:4"* ]]
  [[ "$output" == *"Sample Packets"* ]]
  [[ "$output" == *"HTTP GET /login"* ]]
}

@test "wiremap capture streams summarizes tcp and udp conversations" {
  mkdir -p "$TEST_ROOT/capture-streams"
  cat > "$TEST_ROOT/capture-streams/meta.env" <<'EOF'
TARGET=10.0.0.8
EOF
  : > "$TEST_ROOT/capture-streams/capture.pcap"

  run env PATH="$FAKE_BIN:$PATH" LAB_DECODE_BIN=fake-tshark \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" capture streams "$TEST_ROOT/capture-streams"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Capture Streams"* ]]
  [[ "$output" == *"TCP Conversations"* ]]
  [[ "$output" == *"10.0.0.8:52344"* ]]
  [[ "$output" == *"UDP Conversations"* ]]
  [[ "$output" == *"224.0.0.251:5353"* ]]
}

@test "wiremap capture creds surfaces auth hints and publishes shared intel" {
  mkdir -p "$TEST_ROOT/capture-creds"
  cat > "$TEST_ROOT/capture-creds/meta.env" <<'EOF'
TARGET=10.0.0.8
EOF
  : > "$TEST_ROOT/capture-creds/capture.pcap"

  run env PATH="$FAKE_BIN:$PATH" LAB_DECODE_BIN=fake-tshark \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" capture creds "$TEST_ROOT/capture-creds"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Credential Hints"* ]]
  [[ "$output" == *"Authorization: Basic"* ]]
  [[ "$output" == *"published 2 credential_hint"* ]]
  [[ "$(grep -c '\"observation_type\":\"credential_hint\"' "$TEST_ROOT/toolkit/state/intel/observations.jsonl")" -eq 2 ]]
}

@test "wiremap capture anomalies surfaces transport signals and publishes shared intel" {
  mkdir -p "$TEST_ROOT/capture-anomalies"
  cat > "$TEST_ROOT/capture-anomalies/meta.env" <<'EOF'
TARGET=10.0.0.8
EOF
  : > "$TEST_ROOT/capture-anomalies/capture.pcap"

  run env PATH="$FAKE_BIN:$PATH" LAB_DECODE_BIN=fake-tshark \
    "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" capture anomalies "$TEST_ROOT/capture-anomalies"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Capture Anomalies"* ]]
  [[ "$output" == *"[RST]"* ]]
  [[ "$output" == *"Retransmission"* ]]
  [[ "$output" == *"published 2 capture_anomaly"* ]]
  [[ "$(grep -c '\"observation_type\":\"capture_anomaly\"' "$TEST_ROOT/toolkit/state/intel/observations.jsonl")" -eq 2 ]]
}

@test "wiremap workflow can force color output" {
  run env LAB_FORCE_COLOR=1 "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" profile list

  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033['* ]]
  [[ "$output" == *"[DISCOVERY]"* ]]
}

@test "wiremap workflow can prune old run directories" {
  mkdir -p \
    "$TEST_ROOT/runs/2026-04-23T00:00:00Z-fast-oldest" \
    "$TEST_ROOT/runs/2026-04-23T00:00:01Z-fast-middle" \
    "$TEST_ROOT/runs/2026-04-23T00:00:02Z-fast-newest"

  run "$TEST_ROOT/toolkit/tools/wiremap/bin/wiremap" prune 1

  [ "$status" -eq 0 ]
  [[ "$output" == *"pruned: 2"* ]]
  [ ! -d "$TEST_ROOT/runs/2026-04-23T00:00:00Z-fast-oldest" ]
  [ ! -d "$TEST_ROOT/runs/2026-04-23T00:00:01Z-fast-middle" ]
  [ -d "$TEST_ROOT/runs/2026-04-23T00:00:02Z-fast-newest" ]
}
