---
name: research-best-practices
description: 外部のベストプラクティスや他者の解決方法を調査・提案
disable-model-invocation: true
allowed-tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch
---

# ベストプラクティス調査

引数: $ARGUMENTS

## 事前準備

トピックが曖昧すぎる場合（単語1つだけ等）や広すぎる場合（「セキュリティ」「パフォーマンス」等）は、ユーザーに具体的な文脈・目的・スコープを確認してから調査を開始する。

プロジェクトディレクトリ内にいる場合は、package.json、requirements.txt、go.mod、Cargo.toml等を読んで技術スタックを特定する。特定した技術スタック名を各Agentの検索クエリに追加して精度を上げる。

## Phase 1: 並列エージェント検索（必須）

**必ず1つのメッセージで3つのAgentを同時に起動すること。** 順次実行は不可。

各エージェントのプロンプトは [references/agent-prompts.md](references/agent-prompts.md) を参照。

- **Agent 1: 実践知識エージェント** — ブログ、公式ドキュメント、チュートリアルから実践的なベストプラクティスを調査
- **Agent 2: OSSエコシステムエージェント** — GitHub リポジトリ、ライブラリ比較、実装例を調査
- **Agent 3: 学術・技術論文エージェント** — arXiv、ACM DL 等から関連論文を調査

## Phase 2: 統合・深掘り分析

3つのエージェントの結果を統合し、以下を分析する:

- 複数ソースで共通して推奨されているパターン（コンセンサス）
- ソース間で意見が分かれているポイント（論争点）
- 理論（学術知見）と実践（ブログ・OSS）のギャップ
- 必要に応じてWebFetchで追加の詳細取得

## Phase 3: 構造化出力

出力テンプレートは [templates/research-output.md](templates/research-output.md) を参照。

日本語で結果を報告してください。

## Phase 4: ローカルファイルへの自動保存

Phase 3 の出力完了後、以下の手順で調査結果をローカルファイルに自動保存する。

### 4-1. 保存先の決定

- 保存ディレクトリ: `05_learning/research/`（プロジェクトルートからの相対パス）
- ディレクトリが存在しない場合は `mkdir -p` で作成する
- ファイル名: `YYYY-MM-DD_<topic-slug>.md`
  - topic-slug は $ARGUMENTS から生成（日本語はローマ字またはそのまま使用、スペースはハイフンに変換）
  - 同名ファイルが既に存在する場合はユーザーに確認（上書き or 連番付与）

### 4-2. テンプレートに従いコンテンツを構造化

保存テンプレートは [templates/research-output.md](templates/research-output.md) の「ローカル保存テンプレート」セクションを参照し、Write ツールでファイルを作成する。

### 4-3. 保存完了の報告と追加保存の案内

ファイル作成後、保存先パスをユーザーに報告する。その後、以下を案内する:

> Notion や Obsidian にも保存するには `/save-research` を実行してください。
