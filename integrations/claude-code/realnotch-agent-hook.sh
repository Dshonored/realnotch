#!/bin/bash
# RealNotch ← Claude Code agent monitor.
# Reads a hook event JSON on stdin and writes/updates a per-session status file
# that the RealNotch app watches. Branches on hook_event_name so one script
# handles every event. Requires jq. Safe/no-op if anything is missing.

DIR="$HOME/Library/Application Support/RealNotch/Agents"
command -v jq >/dev/null 2>&1 || exit 0
mkdir -p "$DIR" || exit 0

input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -z "$sid" ] && exit 0

event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty')
cwd=$(printf '%s' "$input"  | jq -r '.cwd // empty')
ntype=$(printf '%s' "$input" | jq -r '.notification_type // empty')
tool=$(printf '%s' "$input"  | jq -r '.tool_name // empty')
name=$(printf '%s' "$input"  | jq -r '.session_name // empty')
file="$DIR/$sid.json"

case "$event" in
  SessionEnd)
    rm -f "$file"; exit 0 ;;
  Notification)
    case "$ntype" in
      permission_prompt|agent_needs_input|elicitation_dialog)
        status="waiting"; detail="$ntype" ;;
      *)
        status="idle"; detail="waiting for you" ;;
    esac ;;
  Stop)
    status="idle"; detail="done" ;;
  PreToolUse|PostToolUse)
    status="working"; detail="$tool" ;;
  *)
    status="working"; detail="" ;;
esac

jq -n --arg sid "$sid" --arg name "$name" --arg cwd "$cwd" --arg status "$status" --arg detail "$detail" \
  '{session_id:$sid, name:$name, cwd:$cwd, status:$status, detail:$detail, updatedAt: now}' \
  > "$file.tmp" 2>/dev/null && mv "$file.tmp" "$file"
exit 0
