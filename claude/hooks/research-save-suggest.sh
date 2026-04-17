#!/bin/bash
# リサーチ系 Agent 完了時に /save-research を案内するフック
# SubagentStop イベントで発火し、調査結果っぽい出力を検出したら提案する

INPUT=$(cat)

# last_assistant_message を取得
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

# 調査結果のシグナルを検出（複数のキーワードが含まれている場合のみ）
MATCH_COUNT=$(echo "$LAST_MSG" | grep -oiE '調査|ベストプラクティス|推奨|比較|メリット|デメリット|参考|Sources|research|best practices|survey|findings' | sort -fu | wc -l | tr -d ' ')

# 3つ以上のキーワードがマッチした場合のみ提案（誤検出防止）
if [ "$MATCH_COUNT" -ge 3 ]; then
  echo "💾 調査結果が見つかりました！ \`/save-research\` で保存できます。" >&2
fi

exit 0
