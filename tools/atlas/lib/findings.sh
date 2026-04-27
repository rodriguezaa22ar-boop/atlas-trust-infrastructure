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

atlas_findings_review_queue_print_table() {
  local rows="$1"

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

  atlas_findings_review_queue_print_table "$rows"
}

atlas_findings_review_packet_dir() {
  printf '%s/findings/review-packets\n' "$ATLAS_OP_DIR"
}

atlas_findings_latest_review_packet() {
  local ledger_file

  [ -n "${ATLAS_OP_DIR:-}" ] || return 0
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  [ -s "$ledger_file" ] || return 0

  jq -r '
    select(.event == "finding.review_packet.generated")
    | [.ts, .detail]
    | @tsv
  ' "$ledger_file" | tail -n 1
}

atlas_findings_review_packet_field() {
  local packet_file="$1"
  local field="$2"

  awk -F': ' -v wanted="$field" '$1 == wanted { print $2; exit }' "$packet_file"
}

atlas_findings_review_packet_bullet_value() {
  local packet_file="$1"
  local label="$2"

  awk -F': ' -v prefix="- $label" '$1 == prefix { print $2; exit }' "$packet_file"
}

atlas_findings_review_packet_anchor_line() {
  local packet_file="$1"
  local label="$2"

  awk -v prefix="- $label: " 'index($0, prefix) == 1 { print; exit }' "$packet_file"
}

atlas_findings_review_packet_disallowed_later_ledger_events() {
  local ledger_file="$1"
  local expected_events="$2"

  atlas_closeout_numeric_token "$expected_events" || return 1
  tail -n +"$((expected_events + 1))" "$ledger_file" |
    jq -r '
      select(
        ((.event // "") != "finding.review_packet.generated")
        and ((.event // "") != "audit.packet.generated")
        and ((.event // "") != "archive.packet.generated")
      )
      | (.event // "?")
    ' |
    sort -u |
    paste -sd, -
}

atlas_findings_review_packet_ledger_anchor_matches() {
  local ledger_file="$1"
  local expected_events="$2"
  local expected_sha="$3"
  local actual_events
  local actual_sha
  local prefix_sha
  local disallowed_events

  [ -f "$ledger_file" ] || return 1
  atlas_closeout_numeric_token "$expected_events" || return 1

  actual_events="$(atlas_audit_event_count "$ledger_file")"
  actual_sha="$(atlas_evidence_hash_path "$ledger_file")"
  if [ "$actual_events" = "$expected_events" ] && [ "$actual_sha" = "$expected_sha" ]; then
    return 0
  fi

  atlas_closeout_numeric_token "$actual_events" || return 1
  [ "$actual_events" -gt "$expected_events" ] || return 1

  prefix_sha="$(atlas_closeout_ledger_prefix_sha "$ledger_file" "$expected_events")"
  [ "$prefix_sha" = "$expected_sha" ] || return 1

  disallowed_events="$(atlas_findings_review_packet_disallowed_later_ledger_events "$ledger_file" "$expected_events")"
  [ -z "$disallowed_events" ]
}

atlas_findings_write_review_packet() {
  local file="$1"
  local window="$2"
  local today="$3"
  local due_by="$4"
  local rows="$5"
  local findings_file
  local findings_sha="none"
  local ledger_file
  local ledger_events="0"
  local ledger_sha="none"
  local expired_count
  local due_soon_count
  local current_count
  local no_expiry_count

  findings_file="$(atlas_findings_index_file "$ATLAS_OP_DIR")"
  ledger_file="$(atlas_ledger_file "$ATLAS_OP_DIR")"
  if [ -f "$findings_file" ]; then
    findings_sha="$(atlas_evidence_hash_path "$findings_file")"
  fi
  if [ -f "$ledger_file" ]; then
    ledger_events="$(atlas_audit_event_count "$ledger_file")"
    ledger_sha="$(atlas_evidence_hash_path "$ledger_file")"
  fi

  expired_count="$(atlas_findings_review_queue_state_count "$rows" "expired")"
  due_soon_count="$(atlas_findings_review_queue_state_count "$rows" "due-soon")"
  current_count="$(atlas_findings_review_queue_state_count "$rows" "current")"
  no_expiry_count="$(atlas_findings_review_queue_state_count "$rows" "no-expiry")"

  {
    printf '# Atlas Accepted Risk Review Packet\n\n'
    printf 'Generated: %s\n' "$(timestamp)"
    printf 'Operation: %s\n' "$ATLAS_OP_NAME"
    printf 'Operation ID: %s\n' "$ATLAS_OP_SLUG"
    printf 'Operation Status: %s\n' "$ATLAS_OP_STATUS"
    printf 'Target: %s\n' "$ATLAS_OP_TARGET"
    if [ -n "${ATLAS_OP_TARGET_ADDRESS:-}" ] && [ "$ATLAS_OP_TARGET_ADDRESS" != "$ATLAS_OP_TARGET" ]; then
      printf 'Address: %s\n' "$ATLAS_OP_TARGET_ADDRESS"
    fi
    printf '\nNo raw artifact contents are included in this accepted-risk review packet.\n'

    printf '\n## Review Window\n\n'
    printf -- '- Today: %s\n' "$today"
    printf -- '- Review window: %s days\n' "$window"
    printf -- '- Due by: %s\n' "$due_by"

    printf '\n## Queue Counts\n\n'
    printf -- '- Expired: %s\n' "$expired_count"
    printf -- '- Due soon: %s\n' "$due_soon_count"
    printf -- '- No expiry: %s\n' "$no_expiry_count"
    printf -- '- Current: %s\n' "$current_count"

    printf '\n## Anchors\n\n'
    printf -- "- Finding index: \`%s\` sha256=%s\n" "$findings_file" "$findings_sha"
    printf -- "- Operation ledger: \`%s\` events=%s sha256=%s\n" "$ledger_file" "$ledger_events" "$ledger_sha"

    printf '\n## Review Queue\n\n'
    printf '```text\n'
    if [ -n "$rows" ]; then
      atlas_findings_review_queue_print_table "$rows"
    else
      printf 'no accepted risks recorded\n'
    fi
    printf '```\n'
  } >"$file"
}

cmd_finding_review_packet() {
  local packet_name=""
  local packet_slug
  local packet_dir
  local packet_file
  local window="30"
  local today
  local due_by
  local rows

  while [ "$#" -gt 0 ]; do
    case "$1" in
    --within | --window)
      need_args 2 "$#" "finding review-packet [packet-name] [--within days]"
      window="$2"
      shift 2
      ;;
    -*)
      fail "unknown finding review-packet option: $1"
      ;;
    *)
      if [ -n "$packet_name" ]; then
        fail "finding review-packet [packet-name] [--within days]"
      fi
      packet_name="$1"
      shift
      ;;
    esac
  done

  atlas_findings_validate_review_window "$window"
  load_active_operation
  today="$(atlas_readiness_today)"
  due_by="$(atlas_findings_review_due_date "$today" "$window")"
  rows="$(atlas_findings_review_queue_rows "$ATLAS_OP_TARGET" "$today" "$due_by")"

  if [ -z "$packet_name" ]; then
    packet_name="$ATLAS_OP_SLUG-accepted-risk-review"
  fi
  packet_slug="$(slugify "$packet_name")"
  [ -n "$packet_slug" ] || fail "accepted-risk review packet name produced an empty slug"

  packet_dir="$(atlas_findings_review_packet_dir)"
  mkdir -p "$packet_dir"
  chmod 700 "$packet_dir" 2>/dev/null || true
  packet_file="$packet_dir/$packet_slug.md"

  atlas_ledger_append_current "finding.review_packet.generated" "read-only" "atlas" "ok" "$packet_file"
  atlas_findings_write_review_packet "$packet_file" "$window" "$today" "$due_by" "$rows"
  chmod 600 "$packet_file" 2>/dev/null || true
  record_operation_history "$ATLAS_OP_DIR" "finding-review-packet" "$packet_file"

  ui_ok "accepted-risk review packet written"
  printf 'review_packet: %s\n' "$packet_file"
}

atlas_findings_resolve_review_packet() {
  local packet_arg="$1"
  local latest_packet
  local latest_packet_path=""
  local candidate
  local packet_slug

  if [ -z "$packet_arg" ]; then
    latest_packet="$(atlas_findings_latest_review_packet)"
    [ -n "$latest_packet" ] || fail "no accepted-risk review packet recorded for operation '$ATLAS_OP_SLUG'"
    IFS=$'\t' read -r _ latest_packet_path <<<"$latest_packet"
    [ -f "$latest_packet_path" ] || fail "recorded accepted-risk review packet is missing: $latest_packet_path"
    printf '%s\n' "$latest_packet_path"
    return 0
  fi

  if [ -f "$packet_arg" ]; then
    readlink -f "$packet_arg"
    return 0
  fi

  candidate="$(atlas_findings_review_packet_dir)/$packet_arg"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  packet_slug="$(slugify "${packet_arg%.md}")"
  candidate="$(atlas_findings_review_packet_dir)/$packet_slug.md"
  if [ -f "$candidate" ]; then
    readlink -f "$candidate"
    return 0
  fi

  fail "unknown accepted-risk review packet for operation '$ATLAS_OP_SLUG': $packet_arg"
}

atlas_findings_verify_review_packet() {
  local packet_file="$1"
  local packet_operation
  local findings_line
  local findings_file
  local expected_findings_sha
  local actual_findings_sha=""
  local findings_status="verified"
  local ledger_line
  local ledger_file
  local expected_events
  local actual_events=""
  local expected_ledger_sha
  local actual_ledger_sha=""
  local ledger_status="verified"
  local ledger_detail=""
  local disallowed_events=""
  local problems=0
  local status="verified"

  [ -f "$packet_file" ] || fail "accepted-risk review packet is not a file: $packet_file"
  packet_operation="$(atlas_findings_review_packet_field "$packet_file" "Operation ID")"
  [ -n "$packet_operation" ] || fail "accepted-risk review packet is missing Operation ID: $packet_file"
  [ "$packet_operation" = "$ATLAS_OP_SLUG" ] || fail "accepted-risk review packet belongs to '$packet_operation', not '$ATLAS_OP_SLUG'"

  findings_line="$(atlas_findings_review_packet_anchor_line "$packet_file" "Finding index")"
  findings_file="$(atlas_closeout_anchor_path "$findings_line")"
  expected_findings_sha="$(atlas_closeout_anchor_token "$findings_line" "sha256")"
  if [ -z "$findings_file" ] || [ -z "$expected_findings_sha" ]; then
    findings_status="unverifiable"
    problems=$((problems + 1))
  elif [ ! -f "$findings_file" ] && [ "$expected_findings_sha" = "none" ]; then
    actual_findings_sha="none"
  elif [ ! -f "$findings_file" ]; then
    findings_status="missing"
    problems=$((problems + 1))
  else
    actual_findings_sha="$(atlas_evidence_hash_path "$findings_file")"
    if [ "$actual_findings_sha" != "$expected_findings_sha" ]; then
      findings_status="changed"
      problems=$((problems + 1))
    fi
  fi

  ledger_line="$(atlas_findings_review_packet_anchor_line "$packet_file" "Operation ledger")"
  ledger_file="$(atlas_closeout_anchor_path "$ledger_line")"
  expected_events="$(atlas_closeout_anchor_token "$ledger_line" "events")"
  expected_ledger_sha="$(atlas_closeout_anchor_token "$ledger_line" "sha256")"
  if [ -z "$ledger_file" ] || [ -z "$expected_events" ] || [ -z "$expected_ledger_sha" ]; then
    ledger_status="unverifiable"
    problems=$((problems + 1))
  elif [ ! -f "$ledger_file" ]; then
    ledger_status="missing"
    problems=$((problems + 1))
  else
    actual_events="$(atlas_audit_event_count "$ledger_file")"
    actual_ledger_sha="$(atlas_evidence_hash_path "$ledger_file")"
    if [ "$actual_events" = "$expected_events" ] && [ "$actual_ledger_sha" = "$expected_ledger_sha" ]; then
      ledger_detail="events=$actual_events"
    elif atlas_findings_review_packet_ledger_anchor_matches "$ledger_file" "$expected_events" "$expected_ledger_sha"; then
      ledger_detail="events=$actual_events anchored_events=$expected_events later_allowed_events=$((actual_events - expected_events))"
    else
      ledger_status="changed"
      disallowed_events="$(atlas_findings_review_packet_disallowed_later_ledger_events "$ledger_file" "$expected_events" 2>/dev/null || true)"
      ledger_detail="expected_events=$expected_events actual_events=$actual_events expected_sha=$expected_ledger_sha actual_sha=$actual_ledger_sha disallowed_later_events=${disallowed_events:-none}"
      problems=$((problems + 1))
    fi
  fi

  if [ "$problems" -gt 0 ]; then
    status="attention-required"
  fi

  ui_heading "Accepted Risk Review Packet Verification"
  ui_rule
  ui_kv "Operation" "$ATLAS_OP_NAME"
  ui_kv "Packet" "$packet_file"
  ui_rule
  printf '%-20s %-14s %s\n' "ARTIFACT" "STATUS" "DETAIL"
  printf '%-20s %-14s expected_sha=%s actual_sha=%s path=%s\n' \
    "Finding Index" \
    "$findings_status" \
    "${expected_findings_sha:-unknown}" \
    "${actual_findings_sha:-unknown}" \
    "${findings_file:-unknown}"
  printf '%-20s %-14s ledger=%s %s\n' \
    "Operation Ledger" \
    "$ledger_status" \
    "${ledger_file:-unknown}" \
    "${ledger_detail:-expected_events=${expected_events:-unknown} actual_events=${actual_events:-unknown} expected_sha=${expected_ledger_sha:-unknown} actual_sha=${actual_ledger_sha:-unknown}}"
  ui_rule
  ui_kv "Verification Status" "$status"
  ui_kv "Verification Problems" "$problems"

  [ "$problems" -eq 0 ] || return 1
}

cmd_finding_review_verify() {
  local packet_arg=""
  local packet_file

  [ "$#" -le 1 ] || fail "finding review-verify [packet]"

  if [ "$#" -eq 1 ]; then
    packet_arg="$1"
  fi

  load_active_operation
  packet_file="$(atlas_findings_resolve_review_packet "$packet_arg")"
  atlas_findings_verify_review_packet "$packet_file"
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
