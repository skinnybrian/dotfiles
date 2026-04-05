---
description: トピックやGitHub issueを調査
argument-hint: [topic-or-url]
---

# Research コマンド

引数: $ARGUMENTS

## 処理フロー

引数が GitHub issue URL (https://github.com/.../issues/...) の場合：
1. GitHub MCP を使用して issue の詳細情報を取得
2. タイトル、説明、コメント、ラベル、ステータスを確認
3. 関連するコードやファイルを特定
4. issue の内容を要約し、対応方法を提案

それ以外の文字列が渡された場合：
1. プロジェクト内で関連するファイルを検索
2. コードベースを調査し、関連する実装を特定
3. ドキュメントやコメントを確認
4. 調査結果をまとめて報告

## 実行

上記のフローに従って「$ARGUMENTS」を調査してください。
日本語で結果を報告してください。

調査結果の報告後、保存を案内する:
> この調査結果を保存するには `/save-research` を実行してください。
