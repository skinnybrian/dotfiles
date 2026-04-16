# レビュー出力フォーマット

## レビュー結果のテンプレート

以下のフォーマットに従って結果を報告する。

### サマリー（必須・最初に出力）

```
## コードレビュー結果

**対象**: <ローカル変更 or PR #番号>
**変更ファイル数**: X件 / **変更行数**: +XX / -XX

| Severity | 件数 |
|----------|-----|
| 🔴 blocking | X |
| 🟡 important | X |
| 🔵 nit | X |
| 🟢 praise | X |
```

### Findings（severity 順に出力）

blocking → important → nit → praise の順。同 severity 内はファイル順。

```
### 🔴 blocking: <簡潔な説明（1行）>

**`path/to/file.ts:42-48`**

<問題の説明。なぜ問題なのか、どんな影響があるのかを具体的に>

**修正案:**
\```diff
- 問題のあるコード
+ 修正後のコード
\```
```

```
### 🟢 praise: <良い点の説明（1行）>

**`path/to/file.ts:10-15`**

<なぜ良いのか。他の開発者の参考になるポイント>
```

### 結論（必須・最後に出力）

```
## 結論

<blocking が0件の場合>
blocking な問題は見つかりませんでした。important / nit の指摘を検討してください。

<blocking がある場合>
🔴 blocking な問題が X件 あります。マージ前に対応を推奨します。
```

## PR モード時の追加出力

PR モード時は、結果を GitHub PR コメントとして投稿するかユーザーに確認する。
投稿する場合は `gh pr comment` を使用し、以下の形式でコメントする:

```
### Code Review

Found X issues (Y blocking, Z important):

1. 🔴 <description> — `file:line`
2. 🟡 <description> — `file:line`

---
🤖 Generated with Claude Code
```

## ルール

- praise は最低1件は含める（良い点を認識する）
- blocking がない場合は明示的に「blocking なし」と伝える
- 修正案は実際にそのまま適用できるコードを提示する
- pre-existing issues（変更前から存在する問題）は報告しない
- linter / formatter / 型チェッカーが検出できる問題は報告しない
