#!/bin/bash
# Claude Codeからブラウザを開くとき、常にGoogle Chromeを使うようにするフック
# PreToolUse (Bash) で open コマンドを検知し、Chrome指定がなければブロックする

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# openコマンドかチェック（パイプやセミコロンの後のopenも検知）
if echo "$COMMAND" | grep -qE '(^|[;&|])[[:space:]]*open[[:space:]]'; then
  # -a "Google Chrome" が含まれているかチェック
  if ! echo "$COMMAND" | grep -q 'Google Chrome'; then
    jq -n '{
      decision: "block",
      reason: "open コマンドには -a \"Google Chrome\" を指定してください。例: open -a \"Google Chrome\" <file/url>"
    }'
    exit 0
  fi
fi

exit 0
