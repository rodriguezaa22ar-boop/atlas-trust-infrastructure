#!/usr/bin/env bash

atlas_receipt_require_hash_tool() {
  command -v sha256sum >/dev/null 2>&1 || fail "command not found: sha256sum"
}

atlas_receipt_event_hash_json() {
  local json="$1"

  intel_require_jq
  atlas_receipt_require_hash_tool
  printf '%s\n' "$json" | jq -cS 'del(.event_hash, .receipt_hash)' | sha256sum | awk '{ print $1 }'
}

atlas_receipt_receipt_hash_json() {
  local json="$1"

  intel_require_jq
  atlas_receipt_require_hash_tool
  printf '%s\n' "$json" | jq -cS 'del(.receipt_hash)' | sha256sum | awk '{ print $1 }'
}

atlas_receipt_read_json() {
  local input="$1"

  if [ "$input" = "-" ]; then
    cat
    return 0
  fi

  [ -f "$input" ] || fail "missing receipt: $input"
  cat -- "$input"
}

atlas_receipt_forbidden_content_paths() {
  local receipt_json="$1"

  printf '%s\n' "$receipt_json" | jq -r '
    def pathstr($p): $p | map(tostring) | join(".");
    def bad_key: test("^(raw_artifact|raw_artifacts|raw_body|artifact_body|artifact_content|raw_payload|payload|request_body|response_body|secret|token|password|passwd|api_key|authorization|cookie|session|private_key|credential)$"; "i");
    def bad_value: test("password=|passwd=|api_key=|secret=|token=|authorization:|bearer[[:space:]]|set-cookie:|BEGIN RSA|BEGIN OPENSSH|session=|cookie="; "i");
    (
      [
        paths as $p
        | select(($p | length) > 0)
        | select((($p[-1] | type) == "string") and (($p[-1] | tostring) | bad_key))
        | pathstr($p)
      ] +
      [
        paths(scalars) as $p
        | select(((getpath($p) | type) == "string") and (getpath($p) | bad_value))
        | pathstr($p)
      ]
    ) | unique | .[]
  ' 2>/dev/null || true
}

atlas_receipt_validate_json() {
  local receipt_json="$1"
  local forbidden
  local expected_event_hash
  local expected_receipt_hash
  local receipt_id
  local action
  local event_hash
  local prev_hash
  local receipt_hash
  local evidence_ref_count
  local artifact_ref_count
  local approval_ref_count

  intel_require_jq
  atlas_receipt_require_hash_tool

  printf '%s\n' "$receipt_json" | jq -e . >/dev/null 2>&1 ||
    fail "invalid receipt JSON"

  forbidden="$(atlas_receipt_forbidden_content_paths "$receipt_json")"
  [ -z "$forbidden" ] ||
    fail "receipt contains forbidden raw-content marker: $(printf '%s' "$forbidden" | paste -sd, -)"

  printf '%s\n' "$receipt_json" | jq -e '
    . as $receipt |
    def exact_keys($allowed): (keys_unsorted - $allowed | length == 0);
    def nonempty($key): ($receipt[$key] | type == "string" and length > 0);
    ($receipt | type == "object") and
    ($receipt | exact_keys([
      "schema_version",
      "receipt_id",
      "timestamp",
      "metadata_only",
      "raw_artifacts_embedded",
      "action",
      "actor",
      "subject",
      "evidence_refs",
      "artifact_refs",
      "approval_refs",
      "prev_hash",
      "event_hash",
      "receipt_hash",
      "known_limitations",
      "verifier"
    ])) and
    $receipt.schema_version == "atlas.receipt.v1" and
    nonempty("receipt_id") and
    nonempty("timestamp") and
    $receipt.metadata_only == true and
    $receipt.raw_artifacts_embedded == false and
    nonempty("action") and
    nonempty("actor") and
    ($receipt.subject | type == "object" and exact_keys(["type", "ref"])) and
    ($receipt.subject.type | type == "string" and length > 0) and
    ($receipt.subject.ref | type == "string" and length > 0) and
    ($receipt.evidence_refs | type == "array") and
    all($receipt.evidence_refs[]; type == "string" and length > 0) and
    ($receipt.artifact_refs | type == "array") and
    all($receipt.artifact_refs[]; type == "object" and exact_keys(["path", "sha256"]) and (.path | type == "string" and length > 0) and (.sha256 | test("^[a-f0-9]{64}$"))) and
    ($receipt.approval_refs | type == "array") and
    all($receipt.approval_refs[]; type == "string" and length > 0) and
    (($receipt.prev_hash == null) or ($receipt.prev_hash | test("^[a-f0-9]{64}$"))) and
    ($receipt.event_hash | test("^[a-f0-9]{64}$")) and
    ($receipt.receipt_hash | test("^[a-f0-9]{64}$")) and
    ($receipt.known_limitations | type == "array" and length > 0) and
    all($receipt.known_limitations[]; type == "string" and length > 0) and
    ($receipt.verifier | type == "object" and exact_keys(["name", "schema"])) and
    $receipt.verifier.name == "atlas receipt verify" and
    $receipt.verifier.schema == "schemas/atlas.receipt.v1.schema.json"
  ' >/dev/null || fail "invalid receipt fields"

  event_hash="$(printf '%s\n' "$receipt_json" | jq -r '.event_hash')"
  expected_event_hash="$(atlas_receipt_event_hash_json "$receipt_json")"
  [ "$event_hash" = "$expected_event_hash" ] || fail "receipt event_hash mismatch"

  receipt_hash="$(printf '%s\n' "$receipt_json" | jq -r '.receipt_hash')"
  expected_receipt_hash="$(atlas_receipt_receipt_hash_json "$receipt_json")"
  [ "$receipt_hash" = "$expected_receipt_hash" ] || fail "receipt hash mismatch"

  receipt_id="$(printf '%s\n' "$receipt_json" | jq -r '.receipt_id')"
  action="$(printf '%s\n' "$receipt_json" | jq -r '.action')"
  prev_hash="$(printf '%s\n' "$receipt_json" | jq -r '.prev_hash // "null"')"
  evidence_ref_count="$(printf '%s\n' "$receipt_json" | jq -r '.evidence_refs | length')"
  artifact_ref_count="$(printf '%s\n' "$receipt_json" | jq -r '.artifact_refs | length')"
  approval_ref_count="$(printf '%s\n' "$receipt_json" | jq -r '.approval_refs | length')"

  jq -cn \
    --arg schema_version "atlas.receipt_verify.v1" \
    --arg status "ok" \
    --arg receipt_id "$receipt_id" \
    --arg action "$action" \
    --arg event_hash "$event_hash" \
    --arg prev_hash "$prev_hash" \
    --arg receipt_hash "$receipt_hash" \
    --argjson evidence_ref_count "$evidence_ref_count" \
    --argjson artifact_ref_count "$artifact_ref_count" \
    --argjson approval_ref_count "$approval_ref_count" \
    '{
      schema_version: $schema_version,
      status: $status,
      receipt_id: $receipt_id,
      action: $action,
      event_hash: $event_hash,
      prev_hash: $prev_hash,
      receipt_hash: $receipt_hash,
      evidence_ref_count: $evidence_ref_count,
      artifact_ref_count: $artifact_ref_count,
      approval_ref_count: $approval_ref_count,
      metadata_only: true,
      raw_artifacts_embedded: false
    }'
}

atlas_receipt_default_limitations_json() {
  jq -cn '[
    "Metadata-only proof record; raw artifacts and sensitive contents are not embedded.",
    "Does not prove external artifact availability, human intent, legal compliance, or artifact correctness."
  ]'
}

atlas_receipt_array_json() {
  if [ "$#" -eq 0 ]; then
    jq -cn '[]'
    return 0
  fi

  printf '%s\n' "$@" | jq -R . | jq -s .
}

atlas_receipt_artifact_refs_json() {
  if [ "$#" -eq 0 ]; then
    jq -cn '[]'
    return 0
  fi

  printf '%s\n' "$@" | jq -R '
    capture("^(?<path>.+)=(?<sha256>[a-f0-9]{64})$") |
    {path: .path, sha256: .sha256}
  ' | jq -s .
}

atlas_receipt_write_json() {
  local receipt_id="$1"
  local timestamp_value="$2"
  local action="$3"
  local actor="$4"
  local subject_type="$5"
  local subject_ref="$6"
  local evidence_refs_json="$7"
  local artifact_refs_json="$8"
  local approval_refs_json="$9"
  local prev_hash_json="${10}"
  local limitations_json="${11}"
  local receipt_no_hash
  local event_hash
  local receipt_with_event_hash
  local receipt_hash

  receipt_no_hash="$(
    jq -cn \
      --arg schema_version "atlas.receipt.v1" \
      --arg receipt_id "$receipt_id" \
      --arg timestamp "$timestamp_value" \
      --arg action "$action" \
      --arg actor "$actor" \
      --arg subject_type "$subject_type" \
      --arg subject_ref "$subject_ref" \
      --argjson evidence_refs "$evidence_refs_json" \
      --argjson artifact_refs "$artifact_refs_json" \
      --argjson approval_refs "$approval_refs_json" \
      --argjson prev_hash "$prev_hash_json" \
      --argjson known_limitations "$limitations_json" \
      '{
        schema_version: $schema_version,
        receipt_id: $receipt_id,
        timestamp: $timestamp,
        metadata_only: true,
        raw_artifacts_embedded: false,
        action: $action,
        actor: $actor,
        subject: {
          type: $subject_type,
          ref: $subject_ref
        },
        evidence_refs: $evidence_refs,
        artifact_refs: $artifact_refs,
        approval_refs: $approval_refs,
        prev_hash: $prev_hash,
        known_limitations: $known_limitations,
        verifier: {
          name: "atlas receipt verify",
          schema: "schemas/atlas.receipt.v1.schema.json"
        }
      }'
  )"
  event_hash="$(atlas_receipt_event_hash_json "$receipt_no_hash")"
  receipt_with_event_hash="$(printf '%s\n' "$receipt_no_hash" | jq -S --arg event_hash "$event_hash" '. + {event_hash: $event_hash}')"
  receipt_hash="$(atlas_receipt_receipt_hash_json "$receipt_with_event_hash")"
  printf '%s\n' "$receipt_with_event_hash" | jq -S --arg receipt_hash "$receipt_hash" '. + {receipt_hash: $receipt_hash}'
}

cmd_receipt_create() {
  local receipt_id=""
  local timestamp_value=""
  local action=""
  local actor=""
  local subject_type=""
  local subject_ref=""
  local prev_hash=""
  local prev_hash_json="null"
  local out_file=""
  local json=0
  local evidence_refs=()
  local artifact_refs=()
  local approval_refs=()
  local limitations=()
  local evidence_refs_json
  local artifact_refs_json
  local approval_refs_json
  local limitations_json
  local receipt_json

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --receipt-id)
      [ "$#" -ge 2 ] || fail "receipt create requires --receipt-id value"
      receipt_id="$2"
      shift 2
      ;;
    --timestamp)
      [ "$#" -ge 2 ] || fail "receipt create requires --timestamp value"
      timestamp_value="$2"
      shift 2
      ;;
    --action)
      [ "$#" -ge 2 ] || fail "receipt create requires --action value"
      action="$2"
      shift 2
      ;;
    --actor)
      [ "$#" -ge 2 ] || fail "receipt create requires --actor value"
      actor="$2"
      shift 2
      ;;
    --subject-type)
      [ "$#" -ge 2 ] || fail "receipt create requires --subject-type value"
      subject_type="$2"
      shift 2
      ;;
    --subject)
      [ "$#" -ge 2 ] || fail "receipt create requires --subject value"
      subject_ref="$2"
      shift 2
      ;;
    --prev-hash)
      [ "$#" -ge 2 ] || fail "receipt create requires --prev-hash value"
      prev_hash="$2"
      shift 2
      ;;
    --evidence-ref)
      [ "$#" -ge 2 ] || fail "receipt create requires --evidence-ref value"
      evidence_refs+=("$2")
      shift 2
      ;;
    --artifact-ref)
      [ "$#" -ge 2 ] || fail "receipt create requires --artifact-ref path=sha256"
      artifact_refs+=("$2")
      shift 2
      ;;
    --approval-ref)
      [ "$#" -ge 2 ] || fail "receipt create requires --approval-ref value"
      approval_refs+=("$2")
      shift 2
      ;;
    --limitation)
      [ "$#" -ge 2 ] || fail "receipt create requires --limitation value"
      limitations+=("$2")
      shift 2
      ;;
    --out)
      [ "$#" -ge 2 ] || fail "receipt create requires --out value"
      out_file="$2"
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    *)
      fail "unknown receipt create option: $1"
      ;;
    esac
  done

  [ -n "$action" ] || fail "receipt create requires --action"
  [ -n "$actor" ] || fail "receipt create requires --actor"
  [ -n "$subject_type" ] || fail "receipt create requires --subject-type"
  [ -n "$subject_ref" ] || fail "receipt create requires --subject"

  if [ -n "$prev_hash" ]; then
    [[ "$prev_hash" =~ ^[a-f0-9]{64}$ ]] || fail "receipt create requires --prev-hash as 64 lowercase hex characters"
    prev_hash_json="$(jq -cn --arg prev_hash "$prev_hash" '$prev_hash')"
  fi

  receipt_id="${receipt_id:-receipt_$(date -u +%Y%m%dT%H%M%SZ)_$(slugify "$action")}"
  timestamp_value="${timestamp_value:-$(timestamp)}"

  if [ "${#limitations[@]}" -eq 0 ]; then
    limitations_json="$(atlas_receipt_default_limitations_json)"
  else
    limitations_json="$(atlas_receipt_array_json "${limitations[@]}")"
  fi

  evidence_refs_json="$(atlas_receipt_array_json "${evidence_refs[@]}")"
  approval_refs_json="$(atlas_receipt_array_json "${approval_refs[@]}")"
  artifact_refs_json="$(atlas_receipt_artifact_refs_json "${artifact_refs[@]}")" ||
    fail "receipt create requires --artifact-ref values formatted as path=sha256"

  receipt_json="$(
    atlas_receipt_write_json \
      "$receipt_id" \
      "$timestamp_value" \
      "$action" \
      "$actor" \
      "$subject_type" \
      "$subject_ref" \
      "$evidence_refs_json" \
      "$artifact_refs_json" \
      "$approval_refs_json" \
      "$prev_hash_json" \
      "$limitations_json"
  )"
  atlas_receipt_validate_json "$receipt_json" >/dev/null

  if [ -n "$out_file" ]; then
    printf '%s\n' "$receipt_json" >"$out_file"
    chmod 600 "$out_file" 2>/dev/null || true
    if [ "$json" -eq 1 ]; then
      printf '%s\n' "$receipt_json"
    else
      printf 'receipt: %s\n' "$out_file"
    fi
  else
    printf '%s\n' "$receipt_json"
  fi
}

cmd_receipt_verify() {
  need_args 1 "$#" "receipt verify <receipt-file|-> [--json]"
  local input="$1"
  local json=0
  local receipt_json
  local verify_json

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --json)
      json=1
      shift
      ;;
    *)
      fail "unknown receipt verify option: $1"
      ;;
    esac
  done

  receipt_json="$(atlas_receipt_read_json "$input")"
  verify_json="$(atlas_receipt_validate_json "$receipt_json")"

  if [ "$json" -eq 1 ]; then
    printf '%s\n' "$verify_json"
  else
    printf 'receipt: ok\n'
    printf 'This receipt validates as a metadata-only proof record.\n'
    printf 'It does not prove external artifact availability, human intent, legal compliance, or artifact correctness.\n'
  fi
}
