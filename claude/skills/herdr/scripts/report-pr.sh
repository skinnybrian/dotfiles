#!/bin/sh
# gh pr create 直後に実行する。カレントディレクトリのブランチに紐づくPRを
# herdr pane metadata の $pr トークンとして報告し、サイドバーのagent行に表示する。
set -eu

command -v herdr >/dev/null 2>&1 || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0

pr_number=$(gh pr view --json number -q .number 2>/dev/null || true)

if [ -n "$pr_number" ]; then
  herdr pane report-metadata "$HERDR_PANE_ID" --source herdr-pr-skill --token "pr=PR:#$pr_number"
else
  herdr pane report-metadata "$HERDR_PANE_ID" --source herdr-pr-skill --clear-token pr
fi
