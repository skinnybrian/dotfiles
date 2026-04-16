#!/bin/bash
# Claude Code → Discord 通知スクリプト
# Hook イベント (Stop / Notification) を受け取り Discord Webhook に送信する

INPUT=$(cat)

# .env ファイルから環境変数を読み込む
ENV_FILE="$HOME/.claude/hooks/.env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

# デバッグログ
DEBUG_LOG="$HOME/.claude/hooks/discord-debug.log"
echo "$(date): hook called, event=$(echo "$INPUT" | jq -r '.hook_event_name'), WEBHOOK_URL_SET=$([ -n "$DISCORD_WEBHOOK_URL" ] && echo 'yes' || echo 'no')" >> "$DEBUG_LOG"

# 共通フィールド取得
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
PROJECT=$(basename "$CWD")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
SHORT_SESSION="${SESSION_ID:0:8}"

# Stop hook の無限ループ防止
if [ "$EVENT" = "Stop" ]; then
  if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
    exit 0
  fi
  COLOR=5763719  # 緑
  TITLE="✅ タスクが完了しました"
  LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')
  if [ -n "$LAST_MSG" ]; then
    DESCRIPTION=$(printf "プロジェクト: **%s**\n> %.50s..." "${PROJECT:-Unknown}" "$LAST_MSG")
  else
    DESCRIPTION=$(printf "プロジェクト: **%s**\n作業ディレクトリ: \`%s\`" "${PROJECT:-Unknown}" "$CWD")
  fi
elif [ "$EVENT" = "Notification" ]; then
  NOTIF_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "notification"')
  MSG=$(echo "$INPUT" | jq -r '.message // ""')
  COLOR=16776960  # 黄/ゴールド
  TITLE="⚠️ Claude Code が入力を待っています"
  if [ -n "$MSG" ]; then
    DESCRIPTION=$(printf "プロジェクト: **%s**\n> %.50s" "${PROJECT:-Unknown}" "$MSG")
  else
    DESCRIPTION=$(printf "プロジェクト: **%s**\nタイプ: \`%s\`" "${PROJECT:-Unknown}" "$NOTIF_TYPE")
  fi
else
  exit 0
fi

# DISCORD_WEBHOOK_URL が未設定の場合は終了
if [ -z "$DISCORD_WEBHOOK_URL" ] || [ "$DISCORD_WEBHOOK_URL" = "YOUR_WEBHOOK_URL_HERE" ]; then
  echo "$(date): WARNING: DISCORD_WEBHOOK_URL is not set. Skipping notification." >> "$DEBUG_LOG"
  exit 0
fi

# Discord Webhook 送信
PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg desc "$DESCRIPTION" \
  --argjson color "$COLOR" \
  --arg session "$SHORT_SESSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    embeds: [{
      title: $title,
      description: $desc,
      color: $color,
      footer: { text: ("Session: " + $session) },
      timestamp: $ts
    }]
  }')

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$DISCORD_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
  echo "$(date): SUCCESS: event=$EVENT, status=$HTTP_STATUS" >> "$DEBUG_LOG"
else
  echo "$(date): ERROR: event=$EVENT, status=$HTTP_STATUS, webhook送信失敗" >> "$DEBUG_LOG"
fi

exit 0
