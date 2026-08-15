---
name: sync-main
description: PRレビュー中やworktree作業中に「最新のmainを取り込んで」「mainを取り込んでコンフリクト解消して」と頼まれたとき、または作業ブランチをリモートの最新デフォルトブランチに追従させたいときに使う
allowed-tools: Read, Bash, Glob, Grep
---

# Sync Main

引数: $ARGUMENTS（対象ブランチ・worktreeパスの指定があれば使う。なければ現在の作業ディレクトリのブランチ）

## 手順

1. `git status --porcelain` で未コミット変更を確認。何かあれば止めて、stash するかコミットするかユーザーに確認する（マージに巻き込まない）
2. `git fetch origin`
3. デフォルトブランチを検出する。`main` 固定にしない
   ```sh
   DEFAULT_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
   [ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
   ```
4. `git merge origin/$DEFAULT_BRANCH` を実行（ローカルの `main` ではなく `origin/$DEFAULT_BRANCH` を使う。worktree運用ではローカル main が別worktreeにいて古いことがあるため）
   - 既に最新なら "Already up to date" が出て終了。その旨を報告する
   - クリーンにマージできたら結果を報告する
5. コンフリクトが出たら（exit code 1 + `CONFLICT`）
   - `git diff --name-only --diff-filter=U` でコンフリクトファイル一覧を出す
   - 各ファイルの中身を読み、どちらを採用すべきかユーザーと相談しながら解消する（`--ours` / `--theirs` を機械的に全採用しない）
   - 解消したら `git add <ファイル>` → `git commit`（マージコミットメッセージはデフォルトのまま。`--no-verify` は使わない）
   - 迷ったり手に負えない場合は `git merge --abort` で中断し、作業ツリーをきれいな状態に戻せることを伝える

## 注意事項

- push はユーザーが明示的に求めた場合のみ（`/commit` と同じ運用）
- rebase ではなく merge を使う。PRレビュー中は履歴を書き換えるとレビューコメントの対象コミットがズレるため
