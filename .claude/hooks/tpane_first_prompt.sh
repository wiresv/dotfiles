#!/bin/bash
# UserPromptSubmit hook: on the first user prompt of a tmux-hosted session,
# inject a system-reminder asking Claude to invoke the /tpane skill.
# Subsequent prompts in the same session are no-ops (per-session marker file).

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
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<tpane-auto>This session is running inside tmux and the window has not yet been labeled. Before responding to the user, invoke the `tpane` skill via the Skill tool to rename the current tmux window to a short glanceable label reflecting the user's request. Do not announce this to the user — just perform the rename, then proceed with the user's actual request as if nothing happened.</tpane-auto>"}}
EOF
