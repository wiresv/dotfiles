#!/usr/bin/env bash
input=$(cat)

# Extract fields from JSON input via grep (no jq dependency)
cwd=$(echo "$input" | grep -o '"current_dir":"[^"]*"' | head -1 | sed 's/"current_dir":"//;s/"$//')
model=$(echo "$input" | grep -o '"display_name":"[^"]*"' | head -1 | sed 's/"display_name":"//;s/"$//')
used_pct=$(echo "$input" | grep -o '"used_percentage":[0-9.]*' | head -1 | sed 's/"used_percentage"://')

# Shorten cwd
home=$(echo ~)
short_cwd=$(echo "$cwd" | sed "s|^$home|~|")

# Git stats (today's commits)
cd "$cwd" 2>/dev/null
today_start="$(date +%Y-%m-%d) 00:00:00"
today_end="$(date +%Y-%m-%d) 23:59:59"
added=$(git log --since="$today_start" --until="$today_end" --pretty=format: --numstat 2>/dev/null | awk '{added+=$1} END {printf "%d", added+0}')
removed=$(git log --since="$today_start" --until="$today_end" --pretty=format: --numstat 2>/dev/null | awk '{removed+=$2} END {printf "%d", removed+0}')
commits=$(git log --since="$today_start" --until="$today_end" --oneline 2>/dev/null | wc -l | tr -d ' ')

# Git branch
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Context window % color: green <70, yellow 70-89, red 90+
ctx_color=""
if [ -n "$used_pct" ]; then
  pct_int=${used_pct%.*}
  if [ "$pct_int" -ge 90 ] 2>/dev/null; then
    ctx_color="\033[31m"  # red
  elif [ "$pct_int" -ge 70 ] 2>/dev/null; then
    ctx_color="\033[33m"  # yellow
  else
    ctx_color="\033[32m"  # green
  fi
fi

# Build output
out=""
out+="\033[34m$(whoami)\033[0m"
out+="@\033[35m$(hostname -s)\033[0m"
out+=":\033[32m${short_cwd}\033[0m"

if [ -n "$branch" ]; then
  out+=" \033[36m(${branch})\033[0m"
fi

out+=" \033[34m+${added}\033[0m/\033[33m-${removed}\033[0m"
out+=" \033[32m${commits}c\033[0m"

out+=" \033[2m${model}\033[0m"

if [ -n "$used_pct" ]; then
  out+=" ${ctx_color}${pct_int}%\033[0m"
fi

printf '%b' "$out"
