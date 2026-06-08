#!/usr/bin/env bash
# trash-guard.sh — PreToolUse(Bash) hook
#
# rm によるファイル削除を検知してブロックし、trash(ゴミ箱)経由の削除を促す。
# 目的: 誤削除時に ~/.Trash から復元できるようにする安全策。
#
# stdin に PreToolUse の JSON が渡る。.tool_input.command を見て rm を判定し、
# 該当すれば permissionDecision=deny を返してツール実行を止め、理由をモデルに伝える。

input="$(cat)"

# Bash の実行コマンド文字列を取得(取得できなければ素通り)
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$cmd" ] && exit 0

# rm をコマンドとして使っているかを判定。
#  pattern1) 行頭 / ; / && / || / | / ( / ` / { の直後の rm
#  pattern2) xargs [flags] rm
# 除外されるもの:
#   - `git rm`        : 直前が英字なので pattern1 にマッチしない(git で復元可)
#   - "rm ..." 文字列 : 直前がクォートなので pattern1 にマッチしない
#   - npm / rmdir 等  : rm が単語の一部 or 後続が英数字なのでマッチしない
if printf '%s' "$cmd" | grep -E -q \
     -e '(^|[;&|(`{]|&&|\|\|)[[:space:]]*rm([^[:alnum:]_]|$)' \
     -e '[[:space:]]xargs([[:space:]]+-[^[:space:]]+)*[[:space:]]+rm([^[:alnum:]_]|$)'; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "【削除は trash を使ってね】rm はブロック中です。誤削除時に ~/.Trash から復元できるよう、削除には `trash <ファイル/ディレクトリ...>` を使ってください。例: `rm -rf dist build` → `trash dist build`(trash はディレクトリも対応・-r/-f 不要、複数指定OK)。trash 非対応の特殊ケース(/tmp 掃除・リモート/コンテナ内など)で本当に rm が必要なときはユーザーに確認してください。"
  }
}
JSON
  exit 0
fi

exit 0
