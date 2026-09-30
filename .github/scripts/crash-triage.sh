#!/usr/bin/env bash
#
# crash-triage.sh — Triage the crash groups that saw activity since the last run.
#
# For each app, pulls the crash summary, picks the groups seen in the last WINDOW_HOURS, attaches a
# sample trace from each group's newest report, and asks Claude to classify them. What comes back is
# written onto the groups (title, severity, third-party, analysis) and summarised to Telegram.
#
# Ported from Northstar's crash-analysis workflow, minus its auto-fix and issue-filing steps.
#
# Environment:
#   CRASH_ADMIN_SECRET   Backend admin secret (required).
#   ANTHROPIC_API_KEY    Claude API key (required).
#   TELEGRAM_BOT_TOKEN   Optional; without it the summary is only printed.
#   TELEGRAM_CHAT_ID     Optional.
#   CRASH_API_BASE       Defaults to https://api.trybloom.app.
#   WINDOW_HOURS         Defaults to 26 - a daily schedule plus jitter.
#
# Never fails the workflow over a triage problem: a missed day is better than a red run nobody
# reads.

set -uo pipefail

BASE="${CRASH_API_BASE:-https://api.trybloom.app}"
WINDOW_HOURS="${WINDOW_HOURS:-26}"
MODEL="claude-opus-5-5"
TRACE_LINES=60

: "${CRASH_ADMIN_SECRET:?CRASH_ADMIN_SECRET is required}"
: "${ANTHROPIC_API_KEY:?ANTHROPIC_API_KEY is required}"

WORK="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/crash-triage"
mkdir -p "$WORK"

CUTOFF="$(date -u -v-"${WINDOW_HOURS}"H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "-${WINDOW_HOURS} hours" +%Y-%m-%dT%H:%M:%SZ)"

api() {
  curl -sf -H "Authorization: Bearer $CRASH_ADMIN_SECRET" "$@"
}

notify_telegram() {
  local message="$1"
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    echo "[telegram] not configured; message was:"
    echo "$message"
    return
  fi

  local response
  response="$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode chat_id="$TELEGRAM_CHAT_ID" \
    --data-urlencode text="$message" \
    -d disable_web_page_preview=true)"
  if [[ "$(echo "$response" | jq -r '.ok // false')" == "true" ]]; then
    echo "[telegram] sent"
  else
    echo "[telegram] failed: $response"
  fi
}

# The shape Claude has to answer in. Structured outputs guarantee it, so nothing below has to cope
# with prose or a code fence around the JSON.
SCHEMA='{
  "type": "object",
  "additionalProperties": false,
  "required": ["groups"],
  "properties": {
    "groups": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["groupId", "title", "severity", "isThirdParty", "actionable", "analysis", "fixSuggestion"],
        "properties": {
          "groupId": {"type": "string"},
          "title": {"type": "string"},
          "severity": {"type": "string", "enum": ["critical", "high", "medium", "low"]},
          "isThirdParty": {"type": "boolean"},
          "actionable": {"type": "boolean"},
          "analysis": {"type": "string"},
          "fixSuggestion": {"type": "string"}
        }
      }
    }
  }
}'

# Groups worth a look: seen in the window, and either brand new or not yet dealt with. A group
# someone has already marked fixed/unfixable/manual, or pinned on third-party code, only comes back
# if it's new - no re-spamming about a known crash. Groups with no reports left are skipped.
RECENT_FILTER='
  [ .groups[]
    | select(.occurrenceCount > 0)
    | select((.lastSeenAt // "") > $cutoff)
    | select(
        ((.createdAt // "") > $cutoff)
        or (
          (((.fixStatus // "") | IN("unfixable", "manual", "fixed", "pr_open")) | not)
          and (.isThirdParty != true)
        )
      ) ]'

# The report context each group is sent with: the group, plus a sample of its newest report.
ENTRY_FILTER='
  {
    groupId: $group.id,
    currentTitle: $group.title,
    signature: $group.signature,
    occurrences: $group.occurrenceCount,
    affectedVersions: $group.affectedVersions,
    isNew: ($group.analysis == null),
    previousAnalysis: $group.analysis,
    sample: {
      process: $sample.processName,
      source: $sample.source,
      exceptionType: $sample.exceptionType,
      exceptionCode: $sample.exceptionCode,
      terminationReason: $sample.terminationReason,
      osVersion: $sample.osVersion,
      deviceModel: $sample.deviceModel,
      symbolicated: $sample.isSymbolicated,
      trace: (($sample.symbolicatedTrace // $sample.stackTrace // "") | split("\n") | .[0:$lines] | join("\n"))
    }
  }'

# Fallbacks on by default: if a safety classifier declines, the API re-runs the request on its
# recommended fallback model rather than returning nothing.
REQUEST_FILTER='
  {
    model: $model,
    max_tokens: 16000,
    output_config: {effort: "medium", format: {type: "json_schema", schema: $schema}},
    fallbacks: "default",
    messages: [{role: "user", content: $prompt}]
  }'

PATCH_FILTER='
  {
    title: .title,
    severity: .severity,
    isThirdParty: .isThirdParty,
    analysis: (.analysis + (if .fixSuggestion != "" then "\n\nSuggested fix: " + .fixSuggestion else "" end))
  }'

LINES_FILTER='
  .[] as $a
  | ($recent[] | select(.id == $a.groupId)) as $g
  | (if $a.isThirdParty then "📦"
     elif $a.severity == "critical" then "🔴"
     elif $a.severity == "high" then "🟠"
     elif $a.severity == "medium" then "🟡"
     else "⚪" end) as $icon
  | "\n\($icon) \($a.title) (\($a.severity), \($g.occurrenceCount)x, \($g.affectedVersions | join(", ")))\n\($a.analysis)\n\(if $a.actionable then "Fix: " + $a.fixSuggestion else "Not actionable" end)\n"'

MESSAGE=""

for APP in bloom bloom-watch; do
  echo "== $APP"

  if ! SUMMARY="$(api "$BASE/v1/admin/apps/$APP/crashes/summary")"; then
    echo "::warning::Could not fetch the $APP crash summary"
    continue
  fi

  RECENT=$(echo "$SUMMARY" | jq -c --arg cutoff "$CUTOFF" "$RECENT_FILTER")
  COUNT=$(echo "$RECENT" | jq 'length')
  TOTAL=$(echo "$SUMMARY" | jq '.totalReports')
  echo "$COUNT group(s) with activity since $CUTOFF ($TOTAL report(s) all-time)"
  [[ "$COUNT" -eq 0 ]] && continue

  # One sample report per group, so the model sees a stack rather than a signature.
  CONTEXT="[]"
  for GROUP_ID in $(echo "$RECENT" | jq -r '.[].id'); do
    SAMPLE="$(api "$BASE/v1/admin/apps/$APP/crashes/reports?crashGroupID=$GROUP_ID&limit=1" | jq -c '.[0] // {}')"
    GROUP="$(echo "$RECENT" | jq -c --arg id "$GROUP_ID" '.[] | select(.id == $id)')"
    ENTRY="$(jq -n -c --argjson group "$GROUP" --argjson sample "$SAMPLE" --argjson lines "$TRACE_LINES" "$ENTRY_FILTER")"
    CONTEXT="$(echo "$CONTEXT" | jq -c --argjson entry "$ENTRY" '. + [$entry]')"
  done

  PLATFORM="the iOS app and its extensions (widgets, Screen Time extensions)"
  [[ "$APP" == "bloom-watch" ]] && PLATFORM="the watchOS app and its widgets"

  PROMPT="You are triaging crash reports for Bloom, a health and wellness app written in Swift and SwiftUI. These crashes come from ${PLATFORM}. First-party code lives in the Bloom executable and in the frameworks BloomFoundation, BloomUI, CoreHealth, CoreNetwork, DataContainer, ScreenControl and Umbrella; everything else is Apple or third-party (RevenueCat, TelemetryDeck, SFSafeSymbols, and similar).

Each group below has a sample report. Traces may be unsymbolicated - addresses only - when the build's symbols weren't available; say so in the analysis rather than guessing at a cause.

For every group, return:
- title: a short, specific name for the crash (the function and what went wrong), not just the exception type.
- severity: critical (crash on launch or data loss), high (a feature is broken), medium (an edge case), low (rare or cosmetic).
- isThirdParty: true when the fault is in Apple or third-party code rather than Bloom's own.
- actionable: true when a change to Bloom's code could reasonably fix it - force unwraps, index out of range, main-actor or concurrency violations with a clear path, bad state handling. False for OS bugs, memory pressure or watchdog terminations without a clear cause, and third-party SDK faults.
- analysis: two or three sentences on the likely root cause, citing the frame that matters.
- fixSuggestion: what to change if actionable, otherwise an empty string.

Keep groupId exactly as given. Include every group, once.

Groups:
${CONTEXT}"

  REQUEST="$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --argjson schema "$SCHEMA" "$REQUEST_FILTER")"

  RESPONSE="$(curl -s -w "\n%{http_code}" -X POST "https://api.anthropic.com/v1/messages" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "anthropic-beta: server-side-fallback-2026-07-01" \
    -H "content-type: application/json" \
    -d "$REQUEST")"
  HTTP_CODE="$(echo "$RESPONSE" | tail -1)"
  BODY="$(echo "$RESPONSE" | sed '$d')"

  if [[ "$HTTP_CODE" != "200" ]]; then
    echo "::warning::Claude API call failed for $APP (HTTP $HTTP_CODE): $BODY"
    continue
  fi

  STOP_REASON="$(echo "$BODY" | jq -r '.stop_reason')"
  if [[ "$STOP_REASON" != "end_turn" ]]; then
    # "refusal" after the fallback also declined, or "max_tokens" - either way the JSON isn't
    # complete, so there is nothing safe to write back.
    echo "::warning::Claude stopped with $STOP_REASON for $APP; skipping"
    continue
  fi

  ANALYSIS="$(echo "$BODY" | jq -c '[.content[] | select(.type == "text") | .text] | join("") | fromjson | .groups')"
  echo "$ANALYSIS" > "$WORK/$APP-analysis.json"

  # ── Write the triage back onto the groups ──

  for ((i = 0; i < $(echo "$ANALYSIS" | jq 'length'); i++)); do
    ENTRY="$(echo "$ANALYSIS" | jq -c ".[$i]")"
    GROUP_ID="$(echo "$ENTRY" | jq -r '.groupId')"

    # Model output: only PATCH ids that were actually sent.
    if ! echo "$RECENT" | jq -e --arg id "$GROUP_ID" 'any(.[]; .id == $id)' > /dev/null; then
      echo "::warning::Skipping an entry for unknown group '$GROUP_ID'"
      continue
    fi

    PATCH="$(echo "$ENTRY" | jq -c "$PATCH_FILTER")"
    api -o /dev/null -X PATCH -H "Content-Type: application/json" -d "$PATCH" \
      "$BASE/v1/admin/apps/$APP/crashes/groups/$GROUP_ID" \
      || echo "::warning::Failed to update group $GROUP_ID"
  done

  # ── Summarise ──

  MESSAGE+="Bloom crashes - $APP
$COUNT group(s) with new activity ($TOTAL report(s) all-time)
"
  LINES="$(echo "$ANALYSIS" | jq -r --argjson recent "$RECENT" "$LINES_FILTER")"
  MESSAGE+="$LINES"
  MESSAGE+="
"
done

if [[ -n "$MESSAGE" ]]; then
  notify_telegram "$MESSAGE"
else
  echo "Nothing new to report."
fi
