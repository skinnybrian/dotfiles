---
description: 調査結果を Notion / Obsidian に保存する
argument-hint: [トピック名（省略時は会話から自動判定）]
---

# 調査結果の外部保存コマンド

引数: $ARGUMENTS

## 手順

### 1. 保存対象の特定

以下の優先順でソースを決定する:

1. **ローカルmdファイルが存在する場合**: `05_learning/research/` 配下の最新の調査結果ファイルを Read ツールで読み込み、その内容を保存対象とする。引数が指定されている場合はファイル名にマッチするものを探す。
2. **ローカルmdファイルがない場合**: 現在の会話を振り返り、保存すべき調査結果を特定する（`/research-best-practices`、`/research`、`/consult` の実行結果、Agent による調査結果等）。

引数が指定されている場合はそれをトピック名とする。省略時はソースの内容からトピック名を自動生成する。

### 2. 外部サービスへの保存

以下の外部サービスへの保存を確認・実行する:

- **Obsidian**: MCP サーバー（mcp__mcp-obsidian）が利用可能な場合、「Obsidian Vault にも保存する？」と提案。保存先は `Claude Code Research/` フォルダ配下。
- **Notion**: MCP サーバー（mcp__notionApi）が利用可能な場合、「Notion にも保存する？」と提案。保存先は「Best Practice Note」DB（database_id: `3397c078-ee9c-804a-b64f-e4d92b9799d4`）。プロパティ「名前」にタイトルを設定し、ページ本文にサマリーを追加する。※ `data_source` ID ではなく `database` ID を使うこと。
- どちらも利用不可の場合は、その旨を報告して終了する。

## 注意事項

- ソース URL は可能な限りすべて収集する
- Obsidian 互換を意識し、wikilinks ではなく標準 Markdown リンクを使う
- 画像や大きなコードブロックがある場合もそのまま含める
