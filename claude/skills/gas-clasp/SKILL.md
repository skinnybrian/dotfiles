---
name: gas-clasp
description: Use when GAS（Google Apps Script）プロジェクトで clasp コマンド（push / deploy / login / status 等）を実行する前、または .clasp.json / .clasprc.json・Apps Script のアカウント認証・デプロイを扱うとき
---

# GAS / clasp（Apps Script CLI）運用ルール

## Overview

clasp (`@google/clasp` v3) には複数の Google アカウントが名前付き（`-u <名前>`）で登録されている。**アカウントを明示せずに実行すると、エラーになるか、最悪の場合は別 Workspace への誤デプロイになる。**

## 鉄則（2つ）

1. **clasp コマンドには必ず `-u <名前>` を付ける**（例: `clasp -u <名前> push`）。`default` ユーザーは廃止済みのため、`-u` 省略は「default が見つからない」エラーになる。
2. **push / deploy などアカウントに影響する操作の前に、使用アカウントを決定してから実行する:**
   - プロジェクトの CLAUDE.md / AGENTS.md / package.json scripts / CI 設定に使用アカウントが明記されている → それに従い、実行前にどのアカウントを使うか一言報告する
   - 明記がない → 登録済みユーザー名の一覧を提示して**必ずユーザーに確認する**。プロジェクトごとに使うアカウントが異なるため、勝手に決めない

## Quick Reference

| やりたいこと | コマンド |
|---|---|
| 登録済みユーザー名の一覧 | `cat ~/.clasprc.json \| jq '.tokens \| keys'`（`clasp logout` 不要で安全） |
| 名前 → メールアドレスの確認 | `clasp -u <名前> show-authorized-user` |
| push | `clasp -u <名前> push` |
| 認証の追加・上書き | `clasp -u <名前> login` |

## v3 の仕様メモ

- **認証はグローバル**: `~/.clasprc.json`（ホーム直下）に全アカウントが格納され、どのディレクトリからでも有効。プロジェクト直下の `./.clasprc.json` はローカル優先になるが、通常はグローバルのみ運用
- `-u/--user` は**グローバルオプション**（`login` のサブオプションではない）
- アカウントの素性確認は `clasp -u <名前> show-authorized-user` を使う。トークンファイルの直読みで済ませない（安全機構が refresh_token からの access_token 発行をブロックするため、メールアドレス表示はこのコマンドが唯一の手段）
- 再ログイン直後のエントリは `id_token`/`expiry_date` を欠くが、`refresh_token` があれば認証は有効（次回コマンド実行時に自動補完される）

## よくあるミス

| ミス | 結果 / 正しい形 |
|---|---|
| `clasp push`（`-u` なし） | `default` が探されてエラー → `clasp -u <名前> push` |
| アカウント未確認で push / deploy | 別 Workspace への誤デプロイ → 鉄則2の手順でアカウント決定 |
| `.clasprc.json` を直接読んで認証確認 | ブロックされる → `show-authorized-user` を使う |
