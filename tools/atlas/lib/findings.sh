#!/usr/bin/env bash

atlas_findings_index_file() {
  local op_dir="$1"

  printf '%s/findings.ndjson\n' "$op_dir"
}

atlas_findings_dir() {
  local op_dir="$1"

  printf '%s/findings\n' "$op_dir"
}

atlas_findings_next_id() {
  local findings_dir="$1"
  local base
  local candidate
  local index=1

  base="finding_$(date -u +%Y%m%dT%H%M%SZ)"
  candidate="$base"

  while [ -e "$findings_dir/$candidate" ]; do
    index=$((index + 1))
    candidate="$(printf '%s_%02d' "$base" "$index")"
  done

  printf '%s\n' "$candidate"
}

atlas_findings_validate_level() {
  case "$1" in
  observed | inferred | validated)
    return 0
    ;;
  *)
    fail "expected finding level observed, inferred, or validated; got: $1"
    ;;
  esac
}

atlas_findings_validate_severity() {
  case "$1" in
  info | low | medium | high | critical)
    return 0
    ;;
  *)
    fail "expected severity info, low, medium, high, or critical; got: $1"
    ;;
  esac
}

atlas_findings_validate_confidence() {
  case "$1" in
  low | medium | high)
    return 0
    ;;
  *)
    fail "expected confidence low, medium, or high; got: $1"
    ;;
  esac
}

atlas_findings_validate_status() {
  case "$1" in
  open | accepted | resolved | validated)
    return 0
    ;;
  *)
    fail "expected status open, accepted, resolved, or validated; got: $1"
    ;;
  esac
}

atlas_findings_join_unique() {
  local output=""
  local item

  for item in "$@"; do
    [ -n "$item" ] || continue
    case " $output " in
    *" $item "*) ;;
    *)
      output="${output:+$output }$item"
      ;;
    esac
  done

  printf '%s\n' "$output"
}

atlas_findings_evidence_exists() {
  local evidence_id="$1"
  local index_file

  index_file="$(atlas_evidence_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 1

  jq -e \
    --arg evidence_id "$evidence_id" \
    'select(.id == $evidence_id)' \
    "$index_file" >/dev/null
}

atlas_findings_validate_evidence_ids() {
  local evidence_id

  for evidence_id in "$@"; do
    [ -n "$evidence_id" ] || continue
    atlas_findings_evidence_exists "$evidence_id" || fail "unknown evidence id for active operation: $evidence_id"
  done
}

atlas_findings_validation_exists() {
  local validation_id="$1"
  local index_file

  index_file="$(atlas_validation_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 1

  jq -e \
    --arg validation_id "$validation_id" \
    'select(.id == $validation_id)' \
    "$index_file" >/dev/null
}

atlas_findings_validate_validation_ids() {
  local validation_id

  for validation_id in "$@"; do
    [ -n "$validation_id" ] || continue
    atlas_findings_validation_exists "$validation_id" || fail "unknown validation plan id for active operation: $validation_id"
  done
}

atlas_findings_latest_record() {
  local finding_id="$1"
  local index_file

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 1

  jq -sr \
    --arg finding_id "$finding_id" '
      map(select(.id == $finding_id))
      | last // empty
    ' "$index_file"
}

atlas_findings_append_record() {
  local id="$1"
  local target="$2"
  local title="$3"
  local level="$4"
  local severity="$5"
  local confidence="$6"
  local status="$7"
  local source="$8"
  local impact="$9"
  local recommendation="${10}"
  shift 10
  local evidence_ids=("$@")
  local evidence_text
  local index_file

  intel_require_jq

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  : >>"$index_file"
  chmod 600 "$index_file" 2>/dev/null || true
  evidence_text="${evidence_ids[*]}"

  jq -cn \
    --arg id "$id" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$target" \
    --arg title "$title" \
    --arg level "$level" \
    --arg severity "$severity" \
    --arg confidence "$confidence" \
    --arg status "$status" \
    --arg source "$source" \
    --arg impact "$impact" \
    --arg recommendation "$recommendation" \
    --arg created_at "$(timestamp)" \
    --arg evidence_text "$evidence_text" \
    '{
      id: $id,
      operation: $operation,
      target: $target,
      title: $title,
      level: $level,
      severity: $severity,
      confidence: $confidence,
      status: $status,
      source: $source,
      impact: $impact,
      recommendation: $recommendation,
      evidence: ($evidence_text | split(" ") | map(select(length > 0))),
      created_at: $created_at
    }' >>"$index_file"
}

atlas_findings_append_update_record() {
  local id="$1"
  local target="$2"
  local title="$3"
  local level="$4"
  local severity="$5"
  local confidence="$6"
  local status="$7"
  local source="$8"
  local impact="$9"
  local recommendation="${10}"
  local created_at="${11}"
  local note="${12}"
  local evidence_text="${13}"
  local validation_text="${14}"
  local accepted_reason="${15:-}"
  local accepted_owner="${16:-}"
  local accepted_until="${17:-}"
  local accepted_at="${18:-}"
  local accepted_by="${19:-}"
  local review_reason="${20:-}"
  local reviewed_at="${21:-}"
  local reviewed_by="${22:-}"
  local index_file

  intel_require_jq

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  : >>"$index_file"
  chmod 600 "$index_file" 2>/dev/null || true

  jq -cn \
    --arg id "$id" \
    --arg operation "$ATLAS_OP_SLUG" \
    --arg target "$target" \
    --arg title "$title" \
    --arg level "$level" \
    --arg severity "$severity" \
    --arg confidence "$confidence" \
    --arg status "$status" \
    --arg source "$source" \
    --arg impact "$impact" \
    --arg recommendation "$recommendation" \
    --arg created_at "$created_at" \
    --arg updated_at "$(timestamp)" \
    --arg note "$note" \
    --arg evidence_text "$evidence_text" \
    --arg validation_text "$validation_text" \
    --arg accepted_reason "$accepted_reason" \
    --arg accepted_owner "$accepted_owner" \
    --arg accepted_until "$accepted_until" \
    --arg accepted_at "$accepted_at" \
    --arg accepted_by "$accepted_by" \
    --arg review_reason "$review_reason" \
    --arg reviewed_at "$reviewed_at" \
    --arg reviewed_by "$reviewed_by" \
    '{
      id: $id,
      operation: $operation,
      target: $target,
      title: $title,
      level: $level,
      severity: $severity,
      confidence: $confidence,
      status: $status,
      source: $source,
      impact: $impact,
      recommendation: $recommendation,
      evidence: ($evidence_text | split(" ") | map(select(length > 0))),
      validations: ($validation_text | split(" ") | map(select(length > 0))),
      created_at: $created_at,
      updated_at: $updated_at,
      event: "updated",
      note: $note
    }
    + (if $accepted_reason != "" then {accepted_reason: $accepted_reason} else {} end)
    + (if $accepted_owner != "" then {accepted_owner: $accepted_owner} else {} end)
    + (if $accepted_until != "" then {accepted_until: $accepted_until} else {} end)
    + (if $accepted_at != "" then {accepted_at: $accepted_at} else {} end)
    + (if $accepted_by != "" then {accepted_by: $accepted_by} else {} end)
    + (if $review_reason != "" then {review_reason: $review_reason} else {} end)
    + (if $reviewed_at != "" then {reviewed_at: $reviewed_at} else {} end)
    + (if $reviewed_by != "" then {reviewed_by: $reviewed_by} else {} end)' >>"$index_file"
}

cmd_finding_add() {
  need_args 1 "$#" "finding add <title> [--level observed|inferred|validated] [--severity severity] [--confidence confidence]"
  local title="$1"
  local target=""
  local level="inferred"
  local severity="info"
  local confidence="medium"
  local status=""
  local source="atlas"
  local impact=""
  local recommendation=""
  local evidence_ids=()
  local findings_root
  local finding_id
  local finding_dir

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --target)
      need_args 2 "$#" "finding add <title> --target <target>"
      target="$2"
      shift 2
      ;;
    --level)
      need_args 2 "$#" "finding add <title> --level <observed|inferred|validated>"
      level="$2"
      shift 2
      ;;
    --severity)
      need_args 2 "$#" "finding add <title> --severity <severity>"
      severity="$2"
      shift 2
      ;;
    --confidence)
      need_args 2 "$#" "finding add <title> --confidence <confidence>"
      confidence="$2"
      shift 2
      ;;
    --status)
      need_args 2 "$#" "finding add <title> --status <status>"
      status="$2"
      shift 2
      ;;
    --source)
      need_args 2 "$#" "finding add <title> --source <source>"
      source="$2"
      shift 2
      ;;
    --impact)
      need_args 2 "$#" "finding add <title> --impact <impact>"
      impact="$2"
      shift 2
      ;;
    --recommendation)
      need_args 2 "$#" "finding add <title> --recommendation <recommendation>"
      recommendation="$2"
      shift 2
      ;;
    --evidence)
      need_args 2 "$#" "finding add <title> --evidence <evidence-id>"
      evidence_ids+=("$2")
      shift 2
      ;;
    *)
      fail "unknown finding add option: $1"
      ;;
    esac
  done

  [ -n "$title" ] || fail "finding title is required"
  atlas_findings_validate_level "$level"
  atlas_findings_validate_severity "$severity"
  atlas_findings_validate_confidence "$confidence"
  if [ -z "$status" ]; then
    if [ "$level" = "validated" ]; then
      status="validated"
    else
      status="open"
    fi
  fi
  atlas_findings_validate_status "$status"

  load_active_operation
  if [ -z "$target" ]; then
    target="$ATLAS_OP_TARGET"
  fi
  atlas_scope_preflight "read-only" "atlas" "$target" "record finding"
  atlas_findings_validate_evidence_ids "${evidence_ids[@]}"

  findings_root="$(atlas_findings_dir "$ATLAS_OP_DIR")"
  mkdir -p "$findings_root"
  chmod 700 "$findings_root" 2>/dev/null || true

  finding_id="$(atlas_findings_next_id "$findings_root")"
  finding_dir="$findings_root/$finding_id"
  mkdir -p "$finding_dir"
  chmod 700 "$finding_dir" 2>/dev/null || true

  atlas_findings_append_record "$finding_id" "$target" "$title" "$level" "$severity" "$confidence" "$status" "$source" "$impact" "$recommendation" "${evidence_ids[@]}"
  atlas_ledger_append_current "finding.recorded" "read-only" "atlas" "ok" "finding=$finding_id level=$level severity=$severity status=$status"

  ui_ok "finding added"
  printf 'id: %s\n' "$finding_id"
  printf 'title: %s\n' "$title"
  printf 'level: %s\n' "$level"
  printf 'severity: %s\n' "$severity"
  printf 'confidence: %s\n' "$confidence"
  printf 'status: %s\n' "$status"
  printf 'target: %s\n' "$target"
  if [ "${#evidence_ids[@]}" -gt 0 ]; then
    printf 'evidence: %s\n' "${evidence_ids[*]}"
  fi
}

cmd_finding_update() {
  need_args 1 "$#" "finding update <id> [--level level] [--status status] [--evidence id] [--validation id] [--note text]"
  local finding_id="$1"
  local level=""
  local severity=""
  local confidence=""
  local status=""
  local title=""
  local impact=""
  local recommendation=""
  local note=""
  local accepted_reason=""
  local accepted_owner=""
  local accepted_until=""
  local accepted_at=""
  local accepted_by=""
  local review_reason=""
  local reviewed_at=""
  local reviewed_by=""
  local evidence_ids=()
  local validation_ids=()
  local record
  local fields=()
  local field
  local operation
  local target
  local current_title
  local current_level
  local current_severity
  local current_confidence
  local current_status
  local source
  local current_impact
  local current_recommendation
  local current_evidence
  local current_validations
  local created_at
  local current_accepted_reason
  local current_accepted_owner
  local current_accepted_until
  local current_accepted_at
  local current_accepted_by
  local current_review_reason
  local current_reviewed_at
  local current_reviewed_by
  local merged_evidence
  local merged_validations

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --title)
      need_args 2 "$#" "finding update <id> --title <title>"
      title="$2"
      shift 2
      ;;
    --level)
      need_args 2 "$#" "finding update <id> --level <observed|inferred|validated>"
      level="$2"
      shift 2
      ;;
    --severity)
      need_args 2 "$#" "finding update <id> --severity <severity>"
      severity="$2"
      shift 2
      ;;
    --confidence)
      need_args 2 "$#" "finding update <id> --confidence <confidence>"
      confidence="$2"
      shift 2
      ;;
    --status)
      need_args 2 "$#" "finding update <id> --status <status>"
      status="$2"
      shift 2
      ;;
    --impact)
      need_args 2 "$#" "finding update <id> --impact <impact>"
      impact="$2"
      shift 2
      ;;
    --recommendation)
      need_args 2 "$#" "finding update <id> --recommendation <recommendation>"
      recommendation="$2"
      shift 2
      ;;
    --evidence)
      need_args 2 "$#" "finding update <id> --evidence <evidence-id>"
      evidence_ids+=("$2")
      shift 2
      ;;
    --validation)
      need_args 2 "$#" "finding update <id> --validation <validation-plan-id>"
      validation_ids+=("$2")
      shift 2
      ;;
    --note)
      need_args 2 "$#" "finding update <id> --note <text>"
      note="$2"
      shift 2
      ;;
    --accepted-reason)
      need_args 2 "$#" "finding update <id> --accepted-reason <text>"
      accepted_reason="$2"
      shift 2
      ;;
    --accepted-owner)
      need_args 2 "$#" "finding update <id> --accepted-owner <owner>"
      accepted_owner="$2"
      shift 2
      ;;
    --accepted-until)
      need_args 2 "$#" "finding update <id> --accepted-until <date>"
      accepted_until="$2"
      shift 2
      ;;
    --accepted-at)
      need_args 2 "$#" "finding update <id> --accepted-at <timestamp>"
      accepted_at="$2"
      shift 2
      ;;
    --accepted-by)
      need_args 2 "$#" "finding update <id> --accepted-by <operator>"
      accepted_by="$2"
      shift 2
      ;;
    --review-reason)
      need_args 2 "$#" "finding update <id> --review-reason <text>"
      review_reason="$2"
      shift 2
      ;;
    --reviewed-at)
      need_args 2 "$#" "finding update <id> --reviewed-at <timestamp>"
      reviewed_at="$2"
      shift 2
      ;;
    --reviewed-by)
      need_args 2 "$#" "finding update <id> --reviewed-by <operator>"
      reviewed_by="$2"
      shift 2
      ;;
    *)
      fail "unknown finding update option: $1"
      ;;
    esac
  done

  load_active_operation
  record="$(atlas_findings_latest_record "$finding_id" || true)"
  [ -n "$record" ] || fail "unknown finding: $finding_id"

  while IFS= read -r field; do
    fields+=("$field")
  done < <(
    printf '%s\n' "$record" |
      jq -r '
        [
          (.operation // ""),
          (.target // ""),
          (.title // ""),
          (.level // "inferred"),
          (.severity // "info"),
          (.confidence // "medium"),
          (.status // "open"),
          (.source // "atlas"),
          (.impact // ""),
          (.recommendation // ""),
          ((.evidence // []) | join(" ")),
          ((.validations // []) | join(" ")),
          (.created_at // ""),
          (.accepted_reason // ""),
          (.accepted_owner // ""),
          (.accepted_until // ""),
          (.accepted_at // ""),
          (.accepted_by // ""),
          (.review_reason // ""),
          (.reviewed_at // ""),
          (.reviewed_by // "")
        ]
        | .[]
      '
  )
  operation="${fields[0]:-}"
  target="${fields[1]:-}"
  current_title="${fields[2]:-}"
  current_level="${fields[3]:-}"
  current_severity="${fields[4]:-}"
  current_confidence="${fields[5]:-}"
  current_status="${fields[6]:-}"
  source="${fields[7]:-}"
  current_impact="${fields[8]:-}"
  current_recommendation="${fields[9]:-}"
  current_evidence="${fields[10]:-}"
  current_validations="${fields[11]:-}"
  created_at="${fields[12]:-}"
  current_accepted_reason="${fields[13]:-}"
  current_accepted_owner="${fields[14]:-}"
  current_accepted_until="${fields[15]:-}"
  current_accepted_at="${fields[16]:-}"
  current_accepted_by="${fields[17]:-}"
  current_review_reason="${fields[18]:-}"
  current_reviewed_at="${fields[19]:-}"
  current_reviewed_by="${fields[20]:-}"
  [ "$operation" = "$ATLAS_OP_SLUG" ] || fail "finding '$finding_id' does not belong to active operation '$ATLAS_OP_SLUG'"

  [ -n "$title" ] || title="$current_title"
  [ -n "$level" ] || level="$current_level"
  [ -n "$severity" ] || severity="$current_severity"
  [ -n "$confidence" ] || confidence="$current_confidence"
  [ -n "$status" ] || status="$current_status"
  [ -n "$impact" ] || impact="$current_impact"
  [ -n "$recommendation" ] || recommendation="$current_recommendation"
  [ -n "$created_at" ] || created_at="$(timestamp)"
  [ -n "$accepted_reason" ] || accepted_reason="$current_accepted_reason"
  [ -n "$accepted_owner" ] || accepted_owner="$current_accepted_owner"
  [ -n "$accepted_until" ] || accepted_until="$current_accepted_until"
  [ -n "$accepted_at" ] || accepted_at="$current_accepted_at"
  [ -n "$accepted_by" ] || accepted_by="$current_accepted_by"
  [ -n "$review_reason" ] || review_reason="$current_review_reason"
  [ -n "$reviewed_at" ] || reviewed_at="$current_reviewed_at"
  [ -n "$reviewed_by" ] || reviewed_by="$current_reviewed_by"

  atlas_findings_validate_level "$level"
  atlas_findings_validate_severity "$severity"
  atlas_findings_validate_confidence "$confidence"
  atlas_findings_validate_status "$status"
  atlas_scope_preflight "read-only" "atlas" "$target" "update finding"
  atlas_findings_validate_evidence_ids "${evidence_ids[@]}"
  atlas_findings_validate_validation_ids "${validation_ids[@]}"

  # shellcheck disable=SC2086
  merged_evidence="$(atlas_findings_join_unique $current_evidence "${evidence_ids[@]}")"
  # shellcheck disable=SC2086
  merged_validations="$(atlas_findings_join_unique $current_validations "${validation_ids[@]}")"

  atlas_findings_append_update_record "$finding_id" "$target" "$title" "$level" "$severity" "$confidence" "$status" "$source" "$impact" "$recommendation" "$created_at" "$note" "$merged_evidence" "$merged_validations" "$accepted_reason" "$accepted_owner" "$accepted_until" "$accepted_at" "$accepted_by" "$review_reason" "$reviewed_at" "$reviewed_by"
  atlas_ledger_append_current "finding.updated" "read-only" "atlas" "ok" "finding=$finding_id level=$level severity=$severity status=$status validations=$merged_validations"

  ui_ok "finding updated"
  printf 'id: %s\n' "$finding_id"
  printf 'title: %s\n' "$title"
  printf 'level: %s\n' "$level"
  printf 'severity: %s\n' "$severity"
  printf 'confidence: %s\n' "$confidence"
  printf 'status: %s\n' "$status"
  printf 'target: %s\n' "$target"
  if [ -n "$merged_evidence" ]; then
    printf 'evidence: %s\n' "$merged_evidence"
  fi
  if [ -n "$merged_validations" ]; then
    printf 'validations: %s\n' "$merged_validations"
  fi
  if [ -n "$accepted_reason" ]; then
    printf 'accepted_reason: %s\n' "$accepted_reason"
  fi
  if [ -n "$accepted_owner" ]; then
    printf 'accepted_owner: %s\n' "$accepted_owner"
  fi
  if [ -n "$accepted_until" ]; then
    printf 'accepted_until: %s\n' "$accepted_until"
  fi
  if [ -n "$accepted_by" ]; then
    printf 'accepted_by: %s\n' "$accepted_by"
  fi
  if [ -n "$review_reason" ]; then
    printf 'review_reason: %s\n' "$review_reason"
  fi
  if [ -n "$reviewed_by" ]; then
    printf 'reviewed_by: %s\n' "$reviewed_by"
  fi
}

cmd_finding_resolve() {
  need_args 1 "$#" "finding resolve <id> [--evidence id] [--validation id] [--note text]"
  local finding_id="$1"

  shift
  cmd_finding_update "$finding_id" --status resolved "$@"
}

cmd_finding_accept() {
  need_args 1 "$#" "finding accept <id> --reason text [--owner owner] [--expires date]"
  local finding_id="$1"
  local reason=""
  local owner=""
  local expires=""
  local accepted_at
  local accepted_by
  local note
  local args=()
  local evidence_ids=()
  local validation_ids=()
  local evidence_id
  local validation_id

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --reason)
      need_args 2 "$#" "finding accept <id> --reason <text>"
      reason="$2"
      shift 2
      ;;
    --owner)
      need_args 2 "$#" "finding accept <id> --owner <owner>"
      owner="$2"
      shift 2
      ;;
    --expires | --until)
      need_args 2 "$#" "finding accept <id> --expires <date>"
      expires="$2"
      shift 2
      ;;
    --evidence)
      need_args 2 "$#" "finding accept <id> --evidence <evidence-id>"
      evidence_ids+=("$2")
      shift 2
      ;;
    --validation)
      need_args 2 "$#" "finding accept <id> --validation <validation-plan-id>"
      validation_ids+=("$2")
      shift 2
      ;;
    *)
      fail "unknown finding accept option: $1"
      ;;
    esac
  done

  [ -n "$reason" ] || fail "acceptance reason is required"

  accepted_at="$(timestamp)"
  accepted_by="$(atlas_approval_operator)"
  note="accepted risk: $reason"
  if [ -n "$owner" ]; then
    note="$note owner=$owner"
  fi
  if [ -n "$expires" ]; then
    note="$note expires=$expires"
  fi

  args=(
    "$finding_id"
    --status accepted
    --note "$note"
    --accepted-reason "$reason"
    --accepted-at "$accepted_at"
    --accepted-by "$accepted_by"
  )
  if [ -n "$owner" ]; then
    args+=(--accepted-owner "$owner")
  fi
  if [ -n "$expires" ]; then
    args+=(--accepted-until "$expires")
  fi
  for evidence_id in "${evidence_ids[@]}"; do
    args+=(--evidence "$evidence_id")
  done
  for validation_id in "${validation_ids[@]}"; do
    args+=(--validation "$validation_id")
  done

  cmd_finding_update "${args[@]}" >/dev/null
  atlas_ledger_append_current "finding.accepted" "read-only" "atlas" "accepted" "finding=$finding_id owner=$owner expires=$expires reason=$reason"

  ui_ok "finding accepted"
  printf 'id: %s\n' "$finding_id"
  printf 'status: accepted\n'
  printf 'reason: %s\n' "$reason"
  printf 'accepted_by: %s\n' "$accepted_by"
  printf 'accepted_at: %s\n' "$accepted_at"
  if [ -n "$owner" ]; then
    printf 'owner: %s\n' "$owner"
  fi
  if [ -n "$expires" ]; then
    printf 'expires: %s\n' "$expires"
  fi
}

cmd_finding_review() {
  need_args 1 "$#" "finding review <id> --reason text [--owner owner] [--expires date]"
  local finding_id="$1"
  local reason=""
  local owner=""
  local expires=""
  local reviewed_at
  local reviewed_by
  local note
  local record
  local current_status
  local args=()
  local evidence_ids=()
  local validation_ids=()
  local evidence_id
  local validation_id

  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --reason)
      need_args 2 "$#" "finding review <id> --reason <text>"
      reason="$2"
      shift 2
      ;;
    --owner)
      need_args 2 "$#" "finding review <id> --owner <owner>"
      owner="$2"
      shift 2
      ;;
    --expires | --until)
      need_args 2 "$#" "finding review <id> --expires <date>"
      expires="$2"
      shift 2
      ;;
    --evidence)
      need_args 2 "$#" "finding review <id> --evidence <evidence-id>"
      evidence_ids+=("$2")
      shift 2
      ;;
    --validation)
      need_args 2 "$#" "finding review <id> --validation <validation-plan-id>"
      validation_ids+=("$2")
      shift 2
      ;;
    *)
      fail "unknown finding review option: $1"
      ;;
    esac
  done

  [ -n "$reason" ] || fail "review reason is required"

  load_active_operation
  record="$(atlas_findings_latest_record "$finding_id" || true)"
  [ -n "$record" ] || fail "unknown finding: $finding_id"
  current_status="$(printf '%s\n' "$record" | jq -r '.status // "open"')"
  [ "$current_status" = "accepted" ] || fail "finding review requires an accepted finding; current status: $current_status"

  reviewed_at="$(timestamp)"
  reviewed_by="$(atlas_approval_operator)"
  note="accepted risk reviewed: $reason"
  if [ -n "$owner" ]; then
    note="$note owner=$owner"
  fi
  if [ -n "$expires" ]; then
    note="$note expires=$expires"
  fi

  args=(
    "$finding_id"
    --status accepted
    --note "$note"
    --accepted-reason "$reason"
    --accepted-at "$reviewed_at"
    --accepted-by "$reviewed_by"
    --review-reason "$reason"
    --reviewed-at "$reviewed_at"
    --reviewed-by "$reviewed_by"
  )
  if [ -n "$owner" ]; then
    args+=(--accepted-owner "$owner")
  fi
  if [ -n "$expires" ]; then
    args+=(--accepted-until "$expires")
  fi
  for evidence_id in "${evidence_ids[@]}"; do
    args+=(--evidence "$evidence_id")
  done
  for validation_id in "${validation_ids[@]}"; do
    args+=(--validation "$validation_id")
  done

  cmd_finding_update "${args[@]}" >/dev/null
  atlas_ledger_append_current "finding.reviewed" "read-only" "atlas" "reviewed" "finding=$finding_id owner=$owner expires=$expires reason=$reason"

  ui_ok "finding reviewed"
  printf 'id: %s\n' "$finding_id"
  printf 'status: accepted\n'
  printf 'reason: %s\n' "$reason"
  printf 'reviewed_by: %s\n' "$reviewed_by"
  printf 'reviewed_at: %s\n' "$reviewed_at"
  if [ -n "$owner" ]; then
    printf 'owner: %s\n' "$owner"
  fi
  if [ -n "$expires" ]; then
    printf 'expires: %s\n' "$expires"
  fi
}

atlas_findings_validate_review_window() {
  local window="$1"

  case "$window" in
  "" | *[!0-9]*)
    fail "review window must be a non-negative integer number of days"
    ;;
  esac
}

atlas_findings_review_due_date() {
  local today="$1"
  local window="$2"

  date -u -d "$today + $window days" +%F 2>/dev/null ||
    fail "could not calculate accepted-risk review window from date '$today'"
}

atlas_findings_review_queue_rows() {
  local target="$1"
  local today="$2"
  local due_by="$3"
  local index_file

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg target "$target" \
    --arg today "$today" \
    --arg due_by "$due_by" '
      def accepted_until_date:
        ((.accepted_until // "") | tostring | if length >= 10 then .[0:10] else . end);
      def review_state:
        if accepted_until_date == "" then "no-expiry"
        elif accepted_until_date < $today then "expired"
        elif accepted_until_date <= $due_by then "due-soon"
        else "current" end;
      def state_weight($state):
        if $state == "expired" then 0
        elif $state == "due-soon" then 1
        elif $state == "no-expiry" then 2
        else 3 end;
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select(
          ($target == "" or .target == $target)
          and ((.status // "open") == "accepted")
        ))
      | sort_by([state_weight(review_state), accepted_until_date, .id])
      | .[]
      | [
          (.id // "?"),
          review_state,
          accepted_until_date,
          (.accepted_owner // ""),
          (.severity // "info"),
          (.level // "inferred"),
          (.title // "untitled finding"),
          (.review_reason // .accepted_reason // "")
        ]
      | @tsv
    ' "$index_file"
}

atlas_findings_review_queue_state_count() {
  local rows="$1"
  local state="$2"

  if [ -z "$rows" ]; then
    printf '0\n'
    return 0
  fi

  printf '%s\n' "$rows" |
    awk -F'\t' -v wanted="$state" '$2 == wanted { count++ } END { print count + 0 }'
}

cmd_finding_review_queue() {
  local window="30"
  local today
  local due_by
  local rows
  local expired_count
  local due_soon_count
  local current_count
  local no_expiry_count

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --within | --window)
      need_args 2 "$#" "finding review-queue --within <days>"
      window="$2"
      shift 2
      ;;
    *)
      fail "unknown finding review-queue option: $1"
      ;;
    esac
  done

  atlas_findings_validate_review_window "$window"
  load_active_operation
  today="$(atlas_readiness_today)"
  due_by="$(atlas_findings_review_due_date "$today" "$window")"
  rows="$(atlas_findings_review_queue_rows "$ATLAS_OP_TARGET" "$today" "$due_by")"
  expired_count="$(atlas_findings_review_queue_state_count "$rows" "expired")"
  due_soon_count="$(atlas_findings_review_queue_state_count "$rows" "due-soon")"
  current_count="$(atlas_findings_review_queue_state_count "$rows" "current")"
  no_expiry_count="$(atlas_findings_review_queue_state_count "$rows" "no-expiry")"

  ui_heading "Accepted Risk Review Queue"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Today" "$today"
  ui_kv "Review Window" "$window days"
  ui_kv "Due By" "$due_by"
  ui_kv "Expired" "$expired_count"
  ui_kv "Due Soon" "$due_soon_count"
  ui_kv "No Expiry" "$no_expiry_count"
  ui_kv "Current" "$current_count"
  ui_rule

  if [ -z "$rows" ]; then
    ui_note "no accepted risks recorded"
    return 0
  fi

  printf '%-24s %-10s %-10s %-12s %-8s %-10s %s\n' "ID" "STATE" "EXPIRES" "OWNER" "SEVERITY" "LEVEL" "TITLE"
  printf '%s\n' "$rows" |
    awk -F'\t' '{
      expires = $3 == "" ? "-" : $3
      owner = $4 == "" ? "-" : $4
      printf "%-24s %-10s %-10s %-12s %-8s %-10s %s", $1, $2, expires, owner, $5, $6, $7
      if ($8 != "") {
        printf " reason=%s", $8
      }
      printf "\n"
    }'
}

cmd_finding_list() {
  local index_file

  load_active_operation
  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"

  ui_heading "Findings"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Target" "$ATLAS_OP_TARGET"
  ui_kv "Store" "$index_file"
  ui_rule

  if [ ! -s "$index_file" ]; then
    ui_note "no findings recorded yet"
    return 0
  fi

  jq -sr '
    reduce .[] as $record ({}; .[$record.id] = $record)
    | [.[]]
    | sort_by(.updated_at // .created_at // "", .id)
    | reverse
    | .[]
    |
    [
      (.id // "?"),
      (.level // "?"),
      (.severity // "?"),
      (.confidence // "?"),
      (.status // "?"),
      (.title // "?")
    ]
    | @tsv
  ' "$index_file" |
    awk -F'\t' '{ printf "%-24s %-10s %-8s %-10s %-10s %s\n", $1, $2, $3, $4, $5, $6 }'
}

cmd_finding_show() {
  need_args 1 "$#" "finding show <id>"
  local finding_id="$1"
  local index_file
  local record
  local fields=()
  local field
  local id
  local operation
  local target
  local title
  local level
  local severity
  local confidence
  local status
  local source
  local impact
  local recommendation
  local evidence
  local validations
  local created_at
  local updated_at
  local note
  local accepted_reason
  local accepted_owner
  local accepted_until
  local accepted_at
  local accepted_by
  local review_reason
  local reviewed_at
  local reviewed_by

  load_active_operation
  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || fail "unknown finding: $finding_id"

  record="$(atlas_findings_latest_record "$finding_id" || true)"
  [ -n "$record" ] || fail "unknown finding: $finding_id"

  while IFS= read -r field; do
    fields+=("$field")
  done < <(
    printf '%s\n' "$record" |
      jq -r '
        [
          (.id // "?"),
          (.operation // "?"),
          (.target // "?"),
          (.title // "?"),
          (.level // "?"),
          (.severity // "?"),
          (.confidence // "?"),
          (.status // "?"),
          (.source // "?"),
          (.impact // ""),
          (.recommendation // ""),
          ((.evidence // []) | join(" ")),
          ((.validations // []) | join(" ")),
          (.created_at // "?"),
          (.updated_at // ""),
          (.note // ""),
          (.accepted_reason // ""),
          (.accepted_owner // ""),
          (.accepted_until // ""),
          (.accepted_at // ""),
          (.accepted_by // ""),
          (.review_reason // ""),
          (.reviewed_at // ""),
          (.reviewed_by // "")
        ]
        | .[]
      '
  )
  id="${fields[0]:-}"
  operation="${fields[1]:-}"
  target="${fields[2]:-}"
  title="${fields[3]:-}"
  level="${fields[4]:-}"
  severity="${fields[5]:-}"
  confidence="${fields[6]:-}"
  status="${fields[7]:-}"
  source="${fields[8]:-}"
  impact="${fields[9]:-}"
  recommendation="${fields[10]:-}"
  evidence="${fields[11]:-}"
  validations="${fields[12]:-}"
  created_at="${fields[13]:-}"
  updated_at="${fields[14]:-}"
  note="${fields[15]:-}"
  accepted_reason="${fields[16]:-}"
  accepted_owner="${fields[17]:-}"
  accepted_until="${fields[18]:-}"
  accepted_at="${fields[19]:-}"
  accepted_by="${fields[20]:-}"
  review_reason="${fields[21]:-}"
  reviewed_at="${fields[22]:-}"
  reviewed_by="${fields[23]:-}"

  ui_heading "Finding Record"
  ui_rule
  ui_kv "ID" "$id"
  ui_kv "Operation" "$operation"
  ui_kv "Target" "$target"
  ui_kv "Title" "$title"
  ui_kv "Level" "$level"
  ui_kv "Severity" "$severity"
  ui_kv "Confidence" "$confidence"
  ui_kv "Status" "$status"
  ui_kv "Source" "$source"
  if [ -n "$impact" ]; then
    ui_kv "Impact" "$impact"
  fi
  if [ -n "$recommendation" ]; then
    ui_kv "Recommendation" "$recommendation"
  fi
  if [ -n "$evidence" ]; then
    ui_kv "Evidence" "$evidence"
  fi
  if [ -n "$validations" ]; then
    ui_kv "Validation Plans" "$validations"
  fi
  if [ -n "$accepted_reason" ]; then
    ui_kv "Accepted Reason" "$accepted_reason"
  fi
  if [ -n "$accepted_owner" ]; then
    ui_kv "Accepted Owner" "$accepted_owner"
  fi
  if [ -n "$accepted_until" ]; then
    ui_kv "Accepted Until" "$accepted_until"
  fi
  if [ -n "$accepted_at" ]; then
    ui_kv "Accepted At" "$accepted_at"
  fi
  if [ -n "$accepted_by" ]; then
    ui_kv "Accepted By" "$accepted_by"
  fi
  if [ -n "$review_reason" ]; then
    ui_kv "Risk Review Reason" "$review_reason"
  fi
  if [ -n "$reviewed_at" ]; then
    ui_kv "Risk Reviewed At" "$reviewed_at"
  fi
  if [ -n "$reviewed_by" ]; then
    ui_kv "Risk Reviewed By" "$reviewed_by"
  fi
  ui_kv "Created" "$created_at"
  if [ -n "$updated_at" ]; then
    ui_kv "Updated" "$updated_at"
  fi
  if [ -n "$note" ]; then
    ui_kv "Latest Note" "$note"
  fi
  ui_rule
  ui_subheading "History"
  jq -r \
    --arg finding_id "$finding_id" '
      select(.id == $finding_id)
      | [
          (.updated_at // .created_at // "?"),
          (.event // "recorded"),
          (.level // "?"),
          (.severity // "?"),
          (.status // "?"),
          ((.evidence // []) | join(",")),
          ((.validations // []) | join(",")),
          (.note // "")
        ]
      | @tsv
    ' "$index_file" |
    awk -F'\t' '{
      evidence = $6 == "" ? "-" : $6
      validations = $7 == "" ? "-" : $7
      note = $8 == "" ? "-" : $8
      printf "%-20s %-10s %-10s %-8s %-10s evidence=%s validations=%s note=%s\n", $1, $2, $3, $4, $5, evidence, validations, note
    }'
}

atlas_findings_report_markdown() {
  local index_file

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf -- '- No reviewed findings recorded yet.\n'
    return 0
  fi

  jq -sr '
    reduce .[] as $record ({}; .[$record.id] = $record)
    | [.[]]
    | sort_by(.updated_at // .created_at // "", .id)
    | .[]
    |
    def evidence_text:
      if ((.evidence // []) | length) > 0 then
        " Evidence: " + ((.evidence // []) | join(", ")) + "."
      else
        ""
      end;
    def validation_text:
      if ((.validations // []) | length) > 0 then
        " Validation plans: " + ((.validations // []) | join(", ")) + "."
      else
        ""
      end;
    def acceptance_text:
      if (.accepted_reason // "") != "" then
        " Accepted risk: " + .accepted_reason + "." +
        (if (.accepted_owner // "") != "" then " Owner: " + .accepted_owner + "." else "" end) +
        (if (.accepted_until // "") != "" then " Accepted until: " + .accepted_until + "." else "" end) +
        (if (.accepted_by // "") != "" then " Accepted by: " + .accepted_by + "." else "" end) +
        (if (.review_reason // "") != "" then " Risk review: " + .review_reason + "." else "" end) +
        (if (.reviewed_by // "") != "" then " Reviewed by: " + .reviewed_by + "." else "" end)
      else
        ""
      end;
    "- " + (.severity // "info") + " / " + (.level // "inferred") + " / " + (.status // "open") + ": " +
    (.title // "untitled finding") +
    (if (.impact // "") != "" then " Impact: " + .impact + "." else "" end) +
    (if (.recommendation // "") != "" then " Recommendation: " + .recommendation + "." else "" end) +
    evidence_text +
    validation_text +
    acceptance_text +
    (if (.note // "") != "" then " Latest note: " + .note + "." else "" end)
  ' "$index_file"
}

atlas_findings_count_for_target() {
  local target="${1:-}"
  local index_file

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  if [ ! -s "$index_file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$target" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select($target == "" or .target == $target))
      | length
    ' "$index_file"
}

atlas_findings_rows_for_target() {
  local target="${1:-}"
  local limit="${2:-8}"
  local index_file

  intel_require_jq

  index_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  [ -s "$index_file" ] || return 0

  jq -sr \
    --arg target "$target" \
    --argjson limit "$limit" '
      reduce .[] as $record ({}; .[$record.id] = $record)
      | [.[]]
      | map(select($target == "" or .target == $target))
      | sort_by(.updated_at // .created_at // "", .id)
      | reverse
      | .[:$limit]
      | .[]
      | [
          (.id // "?"),
          (.level // "?"),
          (.severity // "?"),
          (.status // "?"),
          (.title // "?"),
          ((.evidence // []) | join(","))
        ]
      | @tsv
    ' "$index_file"
}

atlas_findings_print_table_for_target() {
  local target="${1:-}"
  local limit="${2:-8}"
  local empty_note="${3:-no findings recorded yet}"
  local output

  output="$(
    atlas_findings_rows_for_target "$target" "$limit" |
      awk -F'\t' '{
        evidence = $6 == "" ? "-" : $6
        printf "%-24s %-10s %-8s %-10s %-32s %s\n", $1, $2, $3, $4, $5, evidence
      }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    ui_note "$empty_note"
  fi
}
