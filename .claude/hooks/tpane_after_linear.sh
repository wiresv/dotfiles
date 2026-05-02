#!/bin/bash
# PostToolUse hook for Linear MCP issue-fetch tools. After the agent fetches a
# Linear issue, the conversation now has concrete task context — inject a
# system-reminder asking Claude to invoke /tpane with that context. Shares the
# per-session marker with tpane_first_prompt.sh so only one rename happens.

input=$(cat)

[ -z "$TMUX" ] && exit 0

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$session_id" ] && exit 0

marker_dir="${TMPDIR:-/tmp}/claude-tpane-markers"
mkdir -p "$marker_dir" 2>/dev/null || exit 0

find "$marker_dir" -type f -mtime +7 -delete 2>/dev/null

marker="$marker_dir/$session_id"
[ -e "$marker" ] && exit 0
touch "$marker"

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"<tpane-auto>This tmux session has not been labeled yet. You now have concrete Linear issue context from the tool call you just made. Invoke the `tpane` skill via the Skill tool to rename the current tmux window to a short glanceable label reflecting the specific issue (e.g., the issue identifier or a tight description of the work). Do not announce this to the user — just perform the rename, then proceed as if nothing happened.</tpane-auto>"}}
EOF
