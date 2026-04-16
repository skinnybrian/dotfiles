---
name: research-best-practices
description: 外部のベストプラクティスや他者の解決方法を調査・提案
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch
---

# ベストプラクティス調査

引数: $ARGUMENTS

## 事前準備

トピックが曖昧/広すぎる場合は具体的な文脈・目的・スコープを確認する。プロジェクト内なら技術スタックを特定しクエリに追加する。

## Phase 1: 並列エージェント検索

**必ず1つのメッセージで3つのAgentを同時に起動すること。** 各エージェントのプロンプトは [references/agent-prompts.md](references/agent-prompts.md) を参照。

- **Agent 1: 実践知識** — ブログ、公式ドキュメント、チュートリアル
- **Agent 2: OSSエコシステム** — GitHub リポジトリ、ライブラリ比較、実装例
- **Agent 3: 学術・技術論文** — arXiv、ACM DL 等

## Phase 2: 統合分析

3結果を統合し、コンセンサス・論争点・理論と実践のギャップを分析。必要に応じて WebFetch で追加取得。

## Phase 3: 構造化出力

出力テンプレートは [templates/research-output.md](templates/research-output.md) を参照。

## Phase 4: ローカル保存

- 保存先: `05_learning/research/YYYY-MM-DD_<topic-slug>.md`（ディレクトリがなければ `mkdir -p`）
- 同名ファイルが存在する場合はユーザーに確認
- テンプレートは [templates/research-output.md](templates/research-output.md) の「ローカル保存テンプレート」を使用
- 保存完了後: 保存先パスを報告し、`/save-research` での外部保存を案内
