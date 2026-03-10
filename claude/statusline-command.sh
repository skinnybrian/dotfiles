#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')

# Session slug from transcript JSONL
session_slug=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  session_slug=$(head -5 "$transcript" | jq -r 'select(.slug) | .slug // empty' 2>/dev/null | head -1)
fi

# Shorten home directory to ~
home="$HOME"
short_cwd=$(echo "$cwd" | sed "s|^$home|~|")

# Git branch (skip optional locks)
branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c core.fsmonitor=false rev-parse --short HEAD 2>/dev/null)
fi

# Build the status line
line=""

# Line 1: Directory + Session slug
if [ -n "$session_slug" ]; then
  line="${short_cwd}  🔆 ${session_slug}"
else
  line="${short_cwd}"
fi

# Line 2: Git branch, model, progress bar, tokens
line2=""

if [ -n "$branch" ]; then
  line2="${branch}"
fi

# Model and context usage with progress bar
if [ -n "$model" ]; then
  if [ -n "$line2" ]; then
    line2="${line2}  ${model}"
  else
    line2="${model}"
  fi
fi

if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  # Build a 10-segment progress bar using block characters
  filled=$(( used_int / 10 ))
  empty=$(( 10 - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do
    bar="${bar}█"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}░"
    i=$(( i + 1 ))
  done
  line2="${line2}  [${bar}] ${used_int}%"
fi

# Session token usage
if [ -n "$total_in" ] && [ -n "$total_out" ]; then
  total=$(( total_in + total_out ))
  if [ "$total" -ge 1000000 ]; then
    tok=$(awk "BEGIN { printf \"%.1fM\", $total / 1000000 }")
  elif [ "$total" -ge 1000 ]; then
    tok=$(awk "BEGIN { printf \"%.1fk\", $total / 1000 }")
  else
    tok="${total}"
  fi
  line2="${line2}  tokens:${tok}"
fi

# Combine lines
if [ -n "$line2" ]; then
  printf "%s\n%s" "$line" "$line2"
else
  printf "%s" "$line"
fi
