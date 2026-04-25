#!/usr/bin/env bash

atlas_report_findings_file() {
  atlas_findings_index_file "$ATLAS_OP_DIR"
}

atlas_report_finding_count_by_level() {
  local level="$1"
  local file

  file="$(atlas_report_findings_file)"
  if [ ! -s "$file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" \
    --arg level "$level" '
      map(select(.target == $target and .level == $level))
      | length
    ' "$file"
}

atlas_report_finding_count_by_severity() {
  local severity="$1"
  local file

  file="$(atlas_report_findings_file)"
  if [ ! -s "$file" ]; then
    printf '0\n'
    return 0
  fi

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" \
    --arg severity "$severity" '
      map(select(.target == $target and .severity == $severity))
      | length
    ' "$file"
}

atlas_report_highest_severity() {
  local file

  file="$(atlas_report_findings_file)"
  if [ ! -s "$file" ]; then
    printf 'none\n'
    return 0
  fi

  jq -sr --arg target "$ATLAS_OP_TARGET" '
    def weight:
      if . == "critical" then 5
      elif . == "high" then 4
      elif . == "medium" then 3
      elif . == "low" then 2
      elif . == "info" then 1
      else 0 end;
    map(select(.target == $target))
    | map(.severity // "info")
    | sort_by(weight)
    | last // "none"
  ' "$file"
}

atlas_report_finding_rows_by_level() {
  local level="$1"
  local file

  file="$(atlas_report_findings_file)"
  [ -s "$file" ] || return 0

  jq -sr \
    --arg target "$ATLAS_OP_TARGET" \
    --arg level "$level" '
      def severity_weight:
        if . == "critical" then 5
        elif . == "high" then 4
        elif . == "medium" then 3
        elif . == "low" then 2
        elif . == "info" then 1
        else 0 end;
      map(select(.target == $target and .level == $level))
      | sort_by([((.severity // "info") | severity_weight), (.created_at // "")])
      | reverse
      | .[]
      | [
          (.id // "?"),
          (.severity // "info"),
          (.confidence // "medium"),
          (.status // "open"),
          (.title // "untitled finding"),
          (.impact // ""),
          (.recommendation // ""),
          ((.evidence // []) | join(", "))
        ]
      | @tsv
    ' "$file"
}

atlas_report_print_finding_level() {
  local level="$1"
  local title="$2"
  local output

  printf '### %s\n\n' "$title"

  output="$(
    atlas_report_finding_rows_by_level "$level" |
      awk -F'\t' '{
        printf "- %s / %s / %s: %s", $2, $3, $4, $5
        if ($6 != "") {
          printf " Impact: %s.", $6
        }
        if ($7 != "") {
          printf " Recommendation: %s.", $7
        }
        if ($8 != "") {
          printf " Evidence: %s.", $8
        }
        printf "\n"
      }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    printf -- '- No %s findings recorded.\n' "$level"
  fi
  printf '\n'
}

atlas_report_executive_summary() {
  local evidence_count
  local finding_count
  local validation_count
  local observed_count
  local inferred_count
  local validated_count
  local highest
  local next_step

  atlas_brief_collect "$ATLAS_OP_TARGET" "1"
  evidence_count="$ATLAS_BRIEF_EVIDENCE_COUNT"
  finding_count="$ATLAS_BRIEF_FINDING_COUNT"
  validation_count="$ATLAS_BRIEF_VALIDATION_COUNT"
  next_step="$ATLAS_BRIEF_NEXT_STEP"

  observed_count="$(atlas_report_finding_count_by_level observed)"
  inferred_count="$(atlas_report_finding_count_by_level inferred)"
  validated_count="$(atlas_report_finding_count_by_level validated)"
  highest="$(atlas_report_highest_severity)"

  printf 'This report summarizes the authorized Atlas operation "%s" for "%s".\n\n' "$ATLAS_OP_NAME" "$ATLAS_OP_TARGET"
  printf -- '- Evidence records: %s\n' "$evidence_count"
  printf -- '- Findings: %s total, %s observed, %s inferred, %s validated\n' "$finding_count" "$observed_count" "$inferred_count" "$validated_count"
  printf -- '- Validation plans: %s\n' "$validation_count"
  printf -- '- Highest recorded severity: %s\n' "$highest"
  printf -- '- Recommended next step: %s\n' "$next_step"
}

atlas_report_finding_review() {
  atlas_report_print_finding_level observed "Observed"
  atlas_report_print_finding_level inferred "Inferred"
  atlas_report_print_finding_level validated "Validated"
}

atlas_report_remediation_priorities() {
  local file
  local output

  file="$(atlas_report_findings_file)"
  if [ ! -s "$file" ]; then
    printf -- '- No remediation priorities recorded yet.\n'
    return 0
  fi

  output="$(
    jq -sr --arg target "$ATLAS_OP_TARGET" '
      def severity_weight:
        if . == "critical" then 5
        elif . == "high" then 4
        elif . == "medium" then 3
        elif . == "low" then 2
        elif . == "info" then 1
        else 0 end;
      map(select(.target == $target and (.recommendation // "") != ""))
      | sort_by([((.severity // "info") | severity_weight), (.created_at // "")])
      | reverse
      | .[]
      | [
          (.severity // "info"),
          (.title // "untitled finding"),
          (.recommendation // ""),
          ((.evidence // []) | join(", "))
        ]
      | @tsv
    ' "$file" |
      awk -F'\t' '{
        printf "- [%s] %s: %s", $1, $2, $3
        if ($4 != "") {
          printf " Evidence: %s.", $4
        }
        printf "\n"
      }'
  )"

  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  else
    printf -- '- No remediation priorities recorded yet.\n'
  fi
}
