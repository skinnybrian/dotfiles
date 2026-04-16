---
name: commit
description: 変更をコミットする
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

# Commit

引数: $ARGUMENTS

## 手順

1. `git status` + `git diff` で変更確認（`.env` やシークレットファイルは除外）
2. `git log --oneline -5` でコミットメッセージのスタイルを確認
3. 引数にメッセージがあればそれを使用、なければ変更内容から生成。ユーザーに提示して確認
4. 確認後、対象ファイルを `git add`（ファイル名明示、`git add .` は避ける）してコミット（`Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` を含める）

## 注意事項

- コミットメッセージは「なぜ」を重視し簡潔に（1-2文）
- pre-commit hook 失敗時は修正して新規コミット（`--amend` は使わない）
- プッシュはユーザーが明示的に求めた場合のみ
