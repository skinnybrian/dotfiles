---
name: herdr
description: Use when herdr セッション内で pane / agent / tab / workspace / worktree を操作するとき、または複数の AI エージェントやコマンドを並列 pane で起動・監視・回収したいとき（「並列でエージェント立てて」「別 pane で走らせて」「herdr で分割して」等の自然文を含む）。herdr コマンドの構文を --help で調べ始める前に必ず読む。
---

# herdr — pane 並列展開の運用ルール

## Overview

herdr はエージェント対応の terminal workspace manager。頻出操作（pane 分割 → エージェント起動 → プロンプト送信 → 完了待ち → 読み取り → 片付け）は**このスキルだけで完結させ、`herdr --help` 群を叩かない**。ここに無い操作のみ [references/official-skill.md](references/official-skill.md) を読み、それでも不明な場合だけ `herdr <グループ名>` を単体実行して調べる。

## 鉄則

1. **最初に `test "${HERDR_ENV:-}" = 1` で herdr pane 内か確認**。herdr 外なら pane / agent 操作は一切行わず（他セッション誤爆防止）、ユーザー自身の端末での `herdr --session <名前>` 起動を案内するに留める
2. **バックグラウンド作業は必ず `--no-focus`**。対象指定は `--current`・明示 pane ID・エージェント名のみ（UI フォーカス依存は他クライアントを誤爆する）
3. **ID（`w1:p1` 形式）は JSON レスポンスから読む**（`.result.pane.pane_id` 等）。推測やサイドバー順からの導出は禁止。`pane move` 後は新 ID を使う
4. **自分が作った pane / tab / workspace 以外を閉じない**
5. **`herdr server stop` は実行しない**（全 pane 巻き添え停止）。実験は `herdr --session <一時名>` で隔離

## Golden path: 並列エージェント展開

```sh
# 1. 兄弟 pane 作成（cwd 維持・フォーカス非奪取）。応答はデフォルトで JSON なので jq で pane_id を拾う
#    方向: 横長 pane は right、縦長・狭い pane は down（迷ったら herdr pane layout --pane "$HERDR_PANE_ID"）
#    --current の代わりに明示 pane ID（例: w6:p1）を位置引数で渡すことも可
pane_id=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')

# 2. エージェント起動（既存の対話シェルプロンプト状態の pane が必須。start は pane を作らない）
#    名前は [a-z][a-z0-9_-]{0,31}・live エージェント間で一意。ネイティブ引数は -- の後ろ
herdr agent start reviewer --kind claude --pane "$pane_id"

# 3. プロンプト送信 + 完了待ち（idle / done / blocked に落ち着くまで。--wait で十分、--until は不要）
herdr agent prompt reviewer "現在の diff をレビューして" --wait --timeout 600000

# 4. 結果読み取り
herdr agent read reviewer --source recent-unwrapped --lines 120

# 5. 片付け（自分が作った pane のみ。agent 専用の stop コマンドは無く、pane close が正規の畳み方）
herdr pane close "$pane_id"
```

**複数並列**: 1〜2 を体数分繰り返し、prompt は **`--wait` を付けずに**全員へ送信してから、`herdr agent wait <名前> --timeout 600000` を1体ずつ実行して回収する（`--wait` 付きで送ると1体ずつの直列実行になる）。`--until` 無しの `agent wait` は `prompt --wait` と同じ settled 状態（idle / done / blocked）まで待つ。

## Golden path: 普通のコマンドを別 pane で実行

```sh
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr pane run <pane_id> "npm test"
herdr pane wait-output <pane_id> --match "Tests passed" --timeout 120000
herdr pane read <pane_id> --source recent-unwrapped --lines 120
```

`wait-output` は既存出力にも即マッチする。`--regex` で Rust 正規表現も可。**wait 系（`pane wait-output` / `agent wait` / `agent prompt --wait`）はいずれも `--timeout` 省略で無期限待ち**になるため、常に `--timeout` を明示する。

## Golden path: PR番号をサイドバーに反映

`gh pr create` した直後に実行すると、そのセッションの agent 行に PR 番号（`$pr` トークン、例: `PR:#123`）が表示される。1session=1PR運用が前提で、マージ/クローズ後の自動掃除はしない（次にこの pane でスクリプトを再実行したときに上書きされる程度）。

```sh
~/dotfiles/claude/skills/herdr/scripts/report-pr.sh
```

内部では `$HERDR_PANE_ID`（鉄則1のチェックが前提）と `gh pr view --json number` からPR番号を取得し、`herdr pane report-metadata` で報告する。herdr未インストール・`HERDR_PANE_ID` 未設定の環境では何もしない。

## Quick Reference

| やりたいこと | コマンド |
|---|---|
| 生きてるエージェント一覧 | `herdr agent list` |
| エージェント状態・詳細 | `herdr agent get <名前>` |
| 入力待ち(blocked)まで待つ | `herdr agent wait <名前> --until blocked --timeout 120000` |
| 対話 UI の操作 | `herdr agent send-keys <名前> esc`（`ctrl+c` 等も可） |
| pane 一覧 | `herdr pane list --workspace "$HERDR_WORKSPACE_ID"` |
| 自分の pane 情報 | `herdr pane current --current` |
| worktree 連携 workspace 作成 | `herdr worktree create --branch <名前>` |
| PR番号をサイドバーに反映 | `~/dotfiles/claude/skills/herdr/scripts/report-pr.sh` |

状態モデル: `working` → `idle`（既読の完了・入力可）/ `done`（未読のバックグラウンド完了）/ `blocked`（承認・質問 UI 検出）/ `unknown`（分類不能。**完了の証拠にならない**）。CLI read では既読にならない。

## よくあるミス

| ミス | 正しい形 |
|---|---|
| `wait-output --match ... <pane_id>`（位置引数が後ろ）や `--match=値` | **位置引数はオプションより前**・等号形式不可: `herdr pane wait-output <pane_id> --match "文字列" --timeout 120000` |
| `pane read --lines N` が空を返す | オプション無しの `herdr pane read <pane_id>` で再試行。それでも取れない完了済み応答は alternate screen 上（scrollback 非保存）→ エージェントに「応答を一時ファイルに書いてパスだけ返す」よう依頼して直接読む（最終手段） |
| `agent prompt` 直後に read | `--wait` を付けて settled まで待つ。非 working 状態からの送信は5秒以内に状態変化がないと `agent_prompt_stalled` |
| `agent start` が pane を作ると想定 | 作らない。split → start の2段階。対象 pane はシェルがフォアグラウンドで何も実行していない状態が必須 |
| 同方向 split の連打 | 幅・高さが使い物にならなくなる。方向を交互にする |
| 並列展開なのに各 prompt に `--wait` | 直列化してしまう。並列時は `--wait` 無しで全員に送信 → 個別に `agent wait` で回収 |
| wait が失敗 / blocked が返った直後に入力を送る | まず `agent get` と `agent read` で状況を確認してから判断する |

## メンテナンス

[references/official-skill.md](references/official-skill.md) は `herdr --skill`（v0.8.0）の全文スナップショット。**herdr update 後に `herdr --skill > references/official-skill.md` を実行して再生成し、先頭のスタンプ行を付け直す**。構文が合わないときはインストール済みバイナリが正。
