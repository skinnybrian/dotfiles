---
description: トピックやGitHub issueを調査
argument-hint: [topic-or-url]
---

# Research コマンド

引数: $ARGUMENTS

## 処理フロー

- **GitHub issue URL** (`https://github.com/.../issues/...`): GitHub MCP で詳細取得（タイトル/説明/コメント/ラベル/ステータス）、関連コードを特定、内容を要約して対応方法を提案
- **それ以外**: プロジェクト内の関連ファイル・実装・ドキュメントを検索・調査し、結果をまとめて報告

調査結果の報告後:
> この調査結果を保存するには `/save-research` を実行してください。
