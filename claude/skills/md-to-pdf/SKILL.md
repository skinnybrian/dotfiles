---
name: md-to-pdf
description: マークダウンファイルをPDFに変換する
disable-model-invocation: true
allowed-tools: Read, Bash, Glob
---

# Markdown to PDF

引数: $ARGUMENTS

## 概要

Markdownファイルを綺麗な日本語PDF（Noto Sans JP・テーブル・コードブロック整形済み）に変換するスキル。

技術スタック: `marked`（MD→HTML） + 既存 `Google Chrome.app` の `--headless --print-to-pdf`。
**`md-to-pdf`（npm）は使わない**（puppeteer の Chromium DL が遅すぎてハマる）。

## 手順

1. `$ARGUMENTS` から入力Markdownファイルパスを取得（必須）
2. オプション解析（任意）:
   - `--out <path>`: 出力先（デフォルト: `~/Downloads/<basename>.pdf`）
   - `--title <text>`: PDFメタデータタイトル（デフォルト: ファイル名）
3. `~/.claude/skills/md-to-pdf/convert.sh <args>` を実行
4. 出力パスとサイズを報告。共有用途なら「Chromeで開く？」と提案して `open -a "Google Chrome" <pdf>`

## 使い方

```bash
# 基本（~/Downloads/<basename>.pdf に出力）
~/.claude/skills/md-to-pdf/convert.sh minutes/foo.md

# 出力先指定
~/.claude/skills/md-to-pdf/convert.sh minutes/foo.md --out /tmp/foo.pdf

# タイトル指定
~/.claude/skills/md-to-pdf/convert.sh minutes/foo.md --title "議事録：foo"
```

## 出力先デフォルト

共有用途を想定して `~/Downloads/` がデフォルト。リポジトリ内に出したいときは `--out` で明示。

## ファイル構成

- `SKILL.md` — このファイル
- `convert.sh` — 実行スクリプト（エントリポイント）
- `md2html.js` — `marked` 使った MD→HTML 変換
- `style.css` — Noto Sans JP + テーブル/コードブロック用CSS

## 依存

- macOS（`/Applications/Google Chrome.app` が必須）
- Node.js（`mise` 管理でも可）
- `marked` は `~/.cache/md-to-pdf/node_modules/` に初回のみインストール（2回目以降は即実行）

## 注意

- 入力Markdownに外部画像URLがある場合、Chromeのfetch時間が伸びる（`--virtual-time-budget=10000` で10秒上限）
- ヘッダー/フッターは付けない（Chromeのデフォルトはfile://とか出てしまうため `--no-pdf-header-footer`）
- ページ番号が必要なら CSS の `@page` ルールで対応可能（要拡張）
