---
title: "herdr の公式ベストプラクティスと Claude Code スキル化"
date: 2026-08-13
tags: [herdr, claude-code, skills, terminal-multiplexer, ai-agents, token-efficiency]
command: "/research-best-practices herdrのマニュアルを読み込んだうえで公式ベースの良い使い方をリサーチしつつスキル化"
sources:
  - https://herdr.dev/docs/agents/
  - https://herdr.dev/agent-guide.md
  - https://herdr.dev/docs/agent-skill/
  - https://github.com/herdrdev/herdr
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
---

# herdr の公式ベストプラクティスと Claude Code スキル化

## 調査サマリー

herdr は「エージェント対応 tmux」として設計された terminal workspace manager（`herdrdev/herdr`、約28k★、Rust製、活発にメンテ中）。公式自身が **`herdr --skill` でバイナリのバージョンに一致したエージェント向けスキルを出力する**仕組みを持ち、ドキュメントの陳腐化（drift）問題を配布側で解決している。一方で公式スキルの description は「ユーザーが明示的に Herdr に言及したときのみ使用」という保守設計のため、「自然に pane 並列展開したい」用途には自作の薄いラッパースキルで発火条件と頻出レシピを補うのが最適と判明した。

## アプローチ比較（スキル化の選択肢）

| アプローチ | メリット | デメリット | 採用例 | 推奨度 |
|-----------|---------|-----------|--------|--------|
| 公式スキルをそのまま取り込み（`npx skills add herdrdev/herdr` / `herdr --skill` 保存） | 公式が正、バージョン一致、メンテ不要 | description が保守的すぎて自然文で発火しない。本文に「`herdr <group>` を実行して構文を学べ」とあり、毎回の探索トークンは残る | herdr 公式推奨の運用 | ★★ |
| 薄い自作 SKILL.md（golden path 焼き込み）+ 公式スナップショットを references/ に同梱 | 頻出パス（split→start→prompt→wait→read）はヘルプ参照ゼロで完結。日本語トリガーで自然発火。エッジケースだけ references を読む progressive disclosure | スナップショットの再生成が herdr update 時に必要（1コマンドで済む） | Anthropic 公式の skill best practices が推奨する構成 | ★★★ |
| SKILL.md から毎回 `herdr --skill` を動的実行して読む | 常に最新 | 発火のたびに約1,600語ぶんのトークンを消費し「エコ」の目的に反する | — | ★ |

## herdr 公式ベストプラクティス（一次情報: `herdr --skill` v0.8.0）

### 並列エージェント展開の golden path

1. `test "${HERDR_ENV:-}" = 1` で herdr pane 内であることを確認（外部からの操作は禁止）
2. `herdr pane split --current --direction right --cwd "$PWD" --no-focus` で兄弟 pane 作成 → JSON の `.result.pane.pane_id` を読む（wide なら right、narrow/tall なら down）
3. `herdr agent start <名前> --kind claude --pane <id>` — 既存の idle shell pane が必須。レイアウトは作らない。ready まで待機（デフォルト30秒）
4. `herdr agent prompt <名前> "..." --wait --timeout 120000` — text+Enter をアトミック送信、idle/done/blocked の settled 状態まで待つ
5. `herdr agent read <名前> --source recent-unwrapped --lines 120` で結果読み取り

### 公式明記の落とし穴

- バックグラウンド作業は必ず `--no-focus`。focused pane 依存は他クライアントを誤爆する
- ID（`w1:p1` 形式）は JSON レスポンスから取得。推測・サイドバー順からの導出は禁止。`pane move` 後は新 ID を使う
- 自分が作っていない pane / tab / workspace / session を閉じない
- **`herdr server stop` は全 pane 巻き添え停止のため厳禁**。実験は named session で隔離
- alternate screen 上の出力は scrollback に残らない → `--lines` を増やしても回収不可。フォールバックはファイル出力依頼
- `agent prompt` は非 working 状態から5秒以内に状態変化がないと `agent_prompt_stalled` を返す
- `unknown` 状態は完了の証拠にならない（検出は heuristic）

### 状態モデル

`idle`（入力可能・既読）/ `done`（未読のバックグラウンド完了）/ `blocked`（承認・質問UI検出）/ `working` / `unknown`。CLI read では既読にならず、focus 系操作で既読になる。

## 推奨ベストプラクティス（統合結論）

1. **薄い自作 SKILL.md + 公式スナップショット references/ 同梱**が最適。Anthropic 公式の progressive disclosure 原則（metadata 常駐 ~100 tokens → SKILL.md はトリガー時のみ → references/ は必要時のみ）と herdr 公式の「バイナリが正」の思想を両立できる
2. **description は自作する**。公式の「明示的に Herdr と言及されたときのみ」をコピーすると日常の「並列でエージェント立てて」で発火せず、スキル化の目的が果たせない
3. **`HERDR_ENV=1` ガードは維持**。herdr 外のセッション（tmux 等）では pane 操作をせず、`herdr --session <名前>` での起動案内に留める分岐を入れる
4. **更新運用**: `herdr update` 後に `herdr --skill > references/official-skill.md` で再生成（1行）。バージョンチェック自動化は不要（公式スキル自身が「インストール済みバイナリが構文の正」と宣言しており drift は自己修正される）

## 具体的なアクション

- [x] `claude/skills/herdr/SKILL.md` を新規作成（golden path + 安全ルール + Quick Reference）
- [x] `claude/skills/herdr/references/official-skill.md` に `herdr --skill` 出力を保存（v0.8.0 スタンプ付き）
- [x] `claude/CLAUDE.md` のスキル一覧に `/herdr` を追記
- [ ] herdr update のたびにスナップショット再生成（運用）

## 補足メモ

- `herdr integration install claude` で入る hook（`~/.claude/hooks/herdr-agent-state.sh`、導入済み v7）は**エージェント状態レポート用**で、スキルとは別物。混同しない
- エコシステム: `awesome-herdr` に80以上の周辺プロジェクト（herdr-reviewr 399★、herdr-file-viewer 393★、collie 371★ など）
- herdr 誕生から約105日と若く、破壊的変更リスクあり → スナップショット方式なら追従が容易

## スキル化の検証結果（TDD 式）

superpowers:writing-skills の RED-GREEN-REFACTOR で検証した。

### RED（スキルなし baseline・実機実行）

サブエージェントに「pane 分割 → echo 実行 → 出力読み取り → pane close + agent 起動コマンド列の記述」を実行させた結果:

- **ヘルプ参照 27回**（`--help` 26回 + 構文リトライ中の1回）、約7.7万トークン・28分を消費
- `pane wait-output` の**引数順で3回連続失敗**（位置引数 pane_id をオプションの後ろに置いた・`--match=値` の等号形式を使った）
- `pane read --lines 15` が**空文字列を返す罠**に遭遇（オプション無しで成功）
- 安全ルール（自作 pane のみ close・server stop 回避）は明示指示があったため遵守

### GREEN（スキルあり・記述式）

SKILL.md を読ませた新鮮なサブエージェントに同等タスク + エッジケース4問を出題:

- **ヘルプ参照 0回**で、タスクA/B のコマンド列が全問正しい構文（wait-output の引数順、`--no-focus`、`--cwd "$PWD"`、JSON からの ID 取得、自作 pane のみ close）
- エッジケース（read が空 / `agent_prompt_stalled` / `unknown` 状態の解釈 / HERDR_ENV 未設定時）も全問スキルどおりに正答

### REFACTOR

GREEN テストのエージェントが申告した曖昧点4件（並列時の `--wait` の扱い、pane_id 取得の jq ワンライナー、素の `agent wait` のデフォルト挙動、split への明示 pane ID 指定・agent の畳み方）を SKILL.md に反映し、質問形式の再テスト（4問全問正解・ヘルプ参照0回）で定着を確認した。再テストが指摘した最後の欠落「`agent wait` / `agent prompt --wait` の `--timeout` 省略時の挙動」は `herdr agent wait --help` で「無期限待ち」と確認し、「wait 系は常に `--timeout` を明示する」として反映済み。

## 参考リンク

- https://herdr.dev/docs/agents/ — 公式エージェント統合ドキュメント
- https://herdr.dev/agent-guide.md — エージェント向けガイド（プレーンテキスト版）
- https://herdr.dev/docs/agent-skill/ — 公式スキル配布の説明
- https://github.com/herdrdev/herdr — 本体リポジトリ（約28k★、Apache-2.0）
- https://github.com/yigitkonur/awesome-herdr — エコシステム集
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices — Anthropic 公式 skill best practices
- https://akmatori.com/blog/herdr-agent-multiplexer / https://coles.codes/posts/herding-agents-with-herdr/ — サードパーティ解説
