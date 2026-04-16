---
name: commit
description: 変更をコミットする
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

# Commit

引数: $ARGUMENTS

## 手順

1. `git status` と `git diff` で現在の変更内容を確認する
2. 変更内容を分析し、以下を判断する：
   - コミット対象のファイル（`.env` やシークレットファイルは除外）
   - 変更の性質（新機能、バグ修正、リファクタリング等）
3. `git log --oneline -5` で直近のコミットメッセージのスタイルを確認する
4. 引数にコミットメッセージが指定されている場合はそれを使用し、なければ変更内容から適切なメッセージを生成する
5. コミットメッセージをユーザーに提示し、確認を取る
6. 確認後、以下を実行する：
   - 対象ファイルを `git add`（`git add .` は避け、ファイル名を明示する）
   - コミットを作成（`Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` を含める）
   - コミット結果を報告する

## 注意事項

- コミットメッセージは変更の「なぜ」を重視し、簡潔に（1-2文）
- pre-commit hook が失敗した場合は、問題を修正して新しいコミットを作成する（`--amend` は使わない）
- プッシュはこのコマンドでは行わない。ユーザーが明示的に求めた場合のみプッシュする
