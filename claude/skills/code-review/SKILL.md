---
name: code-review
description: >
  コードレビューを実行。引数なしでローカル変更をレビュー、PR番号指定でGitHub PRをレビュー。
  チェックリスト駆動で severity ラベリング付き。
  Use when the user asks for code review, reviewing changes, checking code quality,
  or wants feedback on their changes before committing or merging.
argument-hint: "[PR番号 | --staged | --deep]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git *)
  - Bash(gh *)
---

# コードレビュー

引数: $ARGUMENTS

## モード判別

引数を解析して以下のモードを判別する:

- **数字のみ** → PR モード（GitHub PR #番号をレビュー）
- **`--staged`** → ステージ済み変更のみレビュー
- **`--deep`** → 並列エージェントによる深掘りレビュー
- **引数なし or 上記以外** → ローカル変更（git diff HEAD）をレビュー

`--deep` は他のモードと組み合わせ可能（例: `123 --deep`, `--staged --deep`）。

---

## Phase 1: コンテキスト収集

### ローカルモード

1. diff を取得:
   - デフォルト: `git diff HEAD`
   - `--staged`: `git diff --cached`
2. 変更ファイルリストを取得: `git diff --name-only HEAD`（or `--cached`）
3. 変更統計: `git diff --stat HEAD`

### PR モード

1. PR の diff を取得: `gh pr diff <番号>`
2. PR の情報を取得: `gh pr view <番号>`
3. 変更ファイルリスト: `gh pr diff <番号> --name-only`

### 共通

4. 変更ファイルが属するディレクトリの CLAUDE.md があれば読む
5. 変更の規模とスコープを把握する

**レビュー不要の判定**: diff が空、または変更が lockfile / 自動生成コードのみの場合は「レビュー不要」と報告して終了。

---

## Phase 2: 高層レビュー

diff 全体を俯瞰して以下を評価する:

- 変更の意図・目的は明確か
- アーキテクチャ・設計パターンへの影響
- 変更のスコープは適切か（1つの目的に集中しているか）
- テスト戦略（テストが含まれているか、カバレッジは十分か）

---

## Phase 3: 行単位分析（チェックリスト駆動）

[references/checklist.md](references/checklist.md) のチェックリストに沿って、各 diff hunk を分析する。

### 重要なルール

- **変更箇所のみに注目する**。変更前から存在する問題（pre-existing issues）は報告しない
- **linter / formatter / 型チェッカーが検出できる問題は報告しない**（CI で検出される前提）
- **確信度の低い指摘はしない**。根拠を示せない場合は省略する
- diff hunk ごとに具体的な **ファイル名:行番号** を示す
- 各 finding に **修正案（diff 形式のコード例）** を含める

### Severity ラベル

| Severity | 基準 |
|----------|-----|
| 🔴 **blocking** | マージ前に必ず修正すべき。バグ、セキュリティ脆弱性、データ破損、クラッシュ |
| 🟡 **important** | 修正すべきだがマージを止めるほどではない。エラーハンドリング不足、パフォーマンス問題、エッジケース |
| 🔵 **nit** | 改善の余地あり。命名、可読性、スタイル |
| 🟢 **praise** | よくできている点。良い設計判断、適切なテスト、わかりやすいコード |

**praise は最低1件含めること。** 良い点を認識することでレビューのバランスを取る。

---

## Phase 4: サマリー & 判定

[templates/output-format.md](templates/output-format.md) のフォーマットに従って結果を報告する。

### PR モードの追加手順

PR モードの場合、レビュー結果をターミナルに表示した後:
1. GitHub PR にコメントとして投稿するかユーザーに確認する
2. 投稿する場合は `gh pr comment <番号> --body "..."` で投稿する

---

## --deep モード（並列エージェント）

`--deep` が指定された場合、3つの並列エージェントを起動してそれぞれ独立にレビューする。

### エージェント構成

1. **セキュリティ & 堅牢性エージェント**
   - OWASP Top 10 の観点
   - 入力バリデーション
   - 認証・認可
   - エラーハンドリングの堅牢性

2. **ロジック & 正確性エージェント**
   - バグ、ロジックエラー
   - エッジケース、境界値
   - レース条件
   - 状態管理の一貫性

3. **設計 & 保守性エージェント**
   - アーキテクチャへの影響
   - コードの可読性・保守性
   - テスタビリティ
   - CLAUDE.md 準拠

### 集約ルール

- 複数エージェントが同じ問題を指摘した場合 → severity を1段階上げる（例: nit → important）
- 1つのエージェントのみが指摘 → そのまま
- 矛盾する指摘がある場合 → 両方を提示してユーザーに判断を委ねる

各エージェントには diff と変更ファイルリストを渡し、レビューチェックリストの該当セクションを担当させる。
結果は Phase 4 のフォーマットに統合して報告する。
