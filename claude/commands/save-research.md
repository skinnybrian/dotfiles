---
description: 調査結果を Notion / Obsidian に保存する
argument-hint: [トピック名（省略時は会話から自動判定）]
---

# 調査結果の外部保存コマンド

引数: $ARGUMENTS

## 手順

### 1. 保存対象の特定

`05_learning/research/` の最新ファイルを優先。なければ会話中の調査結果（`/research-best-practices`、`/research`、`/consult` 等）を使用。引数あり→トピック名、なし→自動生成。

### 2. 外部サービスへの保存

- **Obsidian**: `mcp__mcp-obsidian` が利用可能なら提案。保存先: `Claude Code Research/`
- **Notion**: `mcp__notionApi` が利用可能なら提案。保存先: 「Best Practice Note」DB（database_id: `3397c078-ee9c-804a-b64f-e4d92b9799d4`）。プロパティ「名前」にタイトル、ページ本文にサマリー。※ `data_source` ID ではなく `database` ID を使うこと
- どちらも利用不可の場合はその旨を報告

## 注意事項

- ソースURLは全収集。Obsidian互換の標準Markdownリンクを使用
