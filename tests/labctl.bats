#!/usr/bin/env bats

setup() {
  export TEST_ROOT
  TEST_ROOT="$(mktemp -d)"
  cp -R "$BATS_TEST_DIRNAME/.." "$TEST_ROOT/toolkit"
  rm -rf \
    "$TEST_ROOT/toolkit/releases" \
    "$TEST_ROOT/toolkit/state" \
    "$TEST_ROOT/toolkit/targets" \
    "$TEST_ROOT/toolkit/sessions" \
    "$TEST_ROOT/toolkit/reports" \
    "$TEST_ROOT/toolkit/logs"
  chmod +x \
    "$TEST_ROOT/toolkit/bin/intelctl" \
    "$TEST_ROOT/toolkit/bin/labctl" \
    "$TEST_ROOT/toolkit/lib/common.sh" \
    "$TEST_ROOT/toolkit/lib/intel.sh"
  unset LAB_CONFIG
  export LAB_ROOT="$TEST_ROOT/toolkit"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "labctl status reports builder role" {
  run "$TEST_ROOT/toolkit/bin/labctl" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"role: builder"* ]]
  [[ "$output" == *"runtime_target: local-usb"* ]]
  [[ "$output" == *"releases: 0"* ]]
}

@test "labctl can create a target and list it" {
  run "$TEST_ROOT/toolkit/bin/labctl" target add test-demo 10.0.0.5 edge
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/bin/labctl" target list
  [ "$status" -eq 0 ]
  [[ "$output" == *"test-demo"* ]]
  [[ "$output" == *"10.0.0.5"* ]]
}

@test "labctl can open a session and scaffold a tool" {
  run "$TEST_ROOT/toolkit/bin/labctl" session open test-sprint local-usb
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/toolkit/sessions/test-sprint/session.env" ]

  run "$TEST_ROOT/toolkit/bin/labctl" tool new test-packet-parse "parse command output"
  [ "$status" -eq 0 ]
  [ -x "$TEST_ROOT/toolkit/tools/test-packet-parse/bin/test-packet-parse" ]
}

@test "labctl can distill a command without cloning it" {
  run "$TEST_ROOT/toolkit/bin/labctl" tool distill test-sed-shape sed --help
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/toolkit/tools/test-sed-shape/intel/help.txt" ]
  [ -f "$TEST_ROOT/toolkit/tools/test-sed-shape/intel/version.txt" ]
  [ -x "$TEST_ROOT/toolkit/tools/test-sed-shape/bin/test-sed-shape" ]

  run "$TEST_ROOT/toolkit/bin/labctl" tool run test-sed-shape intel
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* || "$output" == *"usage:"* ]]
}

@test "labctl can build a lean release with selected tools only" {
  run "$TEST_ROOT/toolkit/bin/labctl" tool new test-collector "collect reduced outputs"
  [ "$status" -eq 0 ]
  chmod -x "$TEST_ROOT/toolkit/tools/test-collector/bin/test-collector"

  run "$TEST_ROOT/toolkit/bin/labctl" release build test-runtime test-collector
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/toolkit/releases/test-runtime/manifest.env" ]
  [ -x "$TEST_ROOT/toolkit/releases/test-runtime/native/bin/intelctl" ]
  [ -x "$TEST_ROOT/toolkit/releases/test-runtime/native/bin/labctl" ]
  [ -x "$TEST_ROOT/toolkit/releases/test-runtime/native/bin/test-collector" ]
  [ -f "$TEST_ROOT/toolkit/releases/test-runtime/native/lib/intel.sh" ]
  [ -x "$TEST_ROOT/toolkit/releases/test-runtime/native/tools/test-collector/bin/test-collector" ]
  [ ! -e "$TEST_ROOT/toolkit/releases/test-runtime/native/tests" ]
  [ ! -e "$TEST_ROOT/toolkit/releases/test-runtime/native/sessions/test-sprint" ]

  run "$TEST_ROOT/toolkit/releases/test-runtime/native/bin/test-collector" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"usage:"* ]]

  run "$TEST_ROOT/toolkit/bin/labctl" release inspect test-runtime
  [ "$status" -eq 0 ]
  [[ "$output" == *"RELEASE_NAME=test-runtime"* ]]
  [[ "$output" == *"TOOL_COUNT=1"* ]]
}

@test "runtime releases keep mutable state in shared runtime storage" {
  run "$TEST_ROOT/toolkit/bin/labctl" tool new test-shared-tool "shared state probe"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/bin/labctl" release build test-shared-runtime test-shared-tool
  [ "$status" -eq 0 ]

  run env -u LAB_ROOT -u LAB_CONFIG \
    "$TEST_ROOT/toolkit/releases/test-shared-runtime/native/bin/labctl" paths
  [ "$status" -eq 0 ]
  [[ "$output" == *"LAB_PERSIST_DIR=$TEST_ROOT/toolkit/shared"* ]]
  [[ "$output" == *"LAB_TARGETS_DIR=$TEST_ROOT/toolkit/shared/targets"* ]]
  [[ "$output" == *"LAB_SESSIONS_DIR=$TEST_ROOT/toolkit/shared/sessions"* ]]
  [[ "$output" == *"LAB_STATE_DIR=$TEST_ROOT/toolkit/shared/state"* ]]

  run env -u LAB_ROOT -u LAB_CONFIG \
    "$TEST_ROOT/toolkit/releases/test-shared-runtime/native/bin/labctl" target add shared-target 10.9.8.7 persisted
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/toolkit/shared/targets/shared-target.env" ]
  [ ! -f "$TEST_ROOT/toolkit/releases/test-shared-runtime/native/targets/shared-target.env" ]

  run env -u LAB_ROOT -u LAB_CONFIG \
    "$TEST_ROOT/toolkit/releases/test-shared-runtime/native/bin/labctl" session open shared-session shared-target
  [ "$status" -eq 0 ]
  [ -f "$TEST_ROOT/toolkit/shared/sessions/shared-session/session.env" ]
  [ ! -f "$TEST_ROOT/toolkit/releases/test-shared-runtime/native/sessions/shared-session/session.env" ]
}

@test "labctl deploy activate migrates shared state and switches local current" {
  deploy_root="$TEST_ROOT/runtime"

  run "$TEST_ROOT/toolkit/bin/labctl" target add demo-node 10.10.10.10 runtime-node
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/bin/labctl" tool new test-deploy-tool "deploy probe"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/bin/labctl" release build test-deploy-runtime test-deploy-tool
  [ "$status" -eq 0 ]

  mkdir -p \
    "$deploy_root/releases/old/native/state/intel" \
    "$deploy_root/releases/old/native/sessions/old-session" \
    "$deploy_root/releases/old/native/targets" \
    "$deploy_root/releases/old/native/reports" \
    "$deploy_root/releases/old/native/logs"
  printf '{}\n' > "$deploy_root/releases/old/native/state/intel/observations.jsonl"
  printf 'STATUS=old\n' > "$deploy_root/releases/old/native/sessions/old-session/session.env"
  printf 'NAME=old\n' > "$deploy_root/releases/old/native/targets/old.env"
  ln -sfn "$deploy_root/releases/old" "$deploy_root/current"

  run "$TEST_ROOT/toolkit/bin/labctl" deploy activate test-deploy-runtime "$deploy_root"

  [ "$status" -eq 0 ]
  [[ "$output" == *"activated_release: test-deploy-runtime"* ]]
  [[ "$output" == *"runtime_root: $deploy_root"* ]]
  [[ "$output" == *"targets_synced: 1"* ]]
  [ "$(readlink "$deploy_root/current")" = "$deploy_root/releases/test-deploy-runtime" ]
  [ -f "$deploy_root/releases/test-deploy-runtime/native/bin/labctl" ]
  [ -f "$deploy_root/shared/state/intel/observations.jsonl" ]
  [ -f "$deploy_root/shared/sessions/old-session/session.env" ]
  [ -f "$deploy_root/shared/targets/old.env" ]
  [ -f "$deploy_root/shared/targets/demo-node.env" ]
  [ ! -f "$deploy_root/releases/test-deploy-runtime/native/targets/demo-node.env" ]

  run env -u LAB_ROOT -u LAB_CONFIG "$deploy_root/current/native/bin/labctl" paths
  [ "$status" -eq 0 ]
  [[ "$output" == *"LAB_PERSIST_DIR=$deploy_root/shared"* ]]
}

@test "labctl deploy activate supports remote runtime roots" {
  fake_bin="$TEST_ROOT/fake-bin"
  ssh_log="$TEST_ROOT/ssh.log"
  rsync_log="$TEST_ROOT/rsync.log"
  mkdir -p "$fake_bin"

  cat > "$fake_bin/ssh" <<'EOF'
#!/usr/bin/env bash
printf 'ssh %s\n' "$*" >> "$SSH_LOG"
case "$*" in
  *labctl*status*)
    printf 'lab_root: fake\n'
    printf 'role: runtime\n'
    ;;
esac
EOF
  cat > "$fake_bin/rsync" <<'EOF'
#!/usr/bin/env bash
printf 'rsync %s\n' "$*" >> "$RSYNC_LOG"
EOF
  chmod +x "$fake_bin/ssh" "$fake_bin/rsync"

  run "$TEST_ROOT/toolkit/bin/labctl" tool new test-remote-tool "remote deploy probe"
  [ "$status" -eq 0 ]

  run "$TEST_ROOT/toolkit/bin/labctl" release build test-remote-runtime test-remote-tool
  [ "$status" -eq 0 ]

  run env PATH="$fake_bin:$PATH" SSH_LOG="$ssh_log" RSYNC_LOG="$rsync_log" \
    "$TEST_ROOT/toolkit/bin/labctl" deploy activate test-remote-runtime hp:/srv/runtime

  [ "$status" -eq 0 ]
  [[ "$output" == *"activated_release: test-remote-runtime"* ]]
  [[ "$output" == *"runtime_root: hp:/srv/runtime"* ]]
  grep -q 'hp:/srv/runtime/releases/test-remote-runtime/' "$rsync_log"
  grep -q 'hp:/srv/runtime/shared/targets/' "$rsync_log"
  grep -q '/srv/runtime' "$ssh_log"
  grep -q 'labctl' "$ssh_log"
}
