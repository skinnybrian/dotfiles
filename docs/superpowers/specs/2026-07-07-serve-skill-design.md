# /serve スキル設計

日付: 2026-07-07
ステータス: 承認済み

## 目的

プロジェクトの開発サーバ起動を毎回自然文で指示する手間をなくす。`/serve` と打つ（または「devサーバ起動して」と言う）だけで、開いているプロジェクトに適した dev サーバをバックグラウンドで起動し、アクセス URL を報告する。

## 要件

- **起動方式**: バックグラウンド起動（`run_in_background`）+ URL 報告。ログは Claude が追跡でき、エラー時に即対応できる
- **対応範囲**: 検出ロジックは汎用の「探索手順」として記述し、具体例は web プロジェクト中心。Node 以外（Python・Rails・docker-compose 等）も手順に従えば自然に拾える
- **発動条件**: `/serve` の明示呼び出しに加え、「devサーバ起動して」等の自然文でも発動する（`disable-model-invocation` を付けない）
- **portless 統合**: web プロジェクトでは `portless run` 経由で起動する既存ルール（`~/dotfiles/claude/fragments/portless.md`）に従う

## 非要件（YAGNI）

- 検出スクリプト（detect.sh 等）の同梱はしない。判断はすべて Claude が SKILL.md の手順に従って行う
- フレームワーク別の網羅的なコマンド表は持たない
- サーバの停止・再起動専用のサブコマンドは作らない（自然文で依頼されたら portless.md のルールに従って対応）

## アーキテクチャ

**SKILL.md 手順書方式（A案）**: `~/dotfiles/claude/skills/serve/SKILL.md` の1ファイルのみ。symlink 経由で `~/.claude/skills/serve/` として見える（md-to-pdf 等と同じ配置ルール）。

### frontmatter

```yaml
---
name: serve
description: 開いているプロジェクトの開発サーバを自動判別してバックグラウンドで起動し、アクセスURLを報告する。「devサーバ起動して」「サーバ立ち上げて」「開発サーバ動かして」等の依頼でも使用する
allowed-tools: Read, Bash, Glob, Grep
---
```

## 手順フロー

1. **重複起動チェック** — `portless list`（コマンドがあれば）と既存の background task を確認。同じプロジェクトのサーバが起動済みなら URL を報告して終了する。明示的に「再起動して」と言われた場合のみ、portless.md のルール（`portless list` で PID 確認 → その PID だけ kill）に従って再起動する
2. **起動コマンド特定** — 以下の優先順で探索する:
   1. プロジェクトの CLAUDE.md / CLAUDE.local.md / README に dev サーバ起動方法の記載があればそれに従う
   2. `package.json` の scripts を `dev` → `start` → `serve` の順で探す。パッケージマネージャは lockfile で判定する（pnpm-lock.yaml→pnpm、bun.lockb→bun、yarn.lock→yarn、package-lock.json→npm）
   3. その他の目印: Makefile の dev/serve ターゲット、docker-compose.yml、manage.py（Django）、Gemfile + bin/rails 等
   4. 特定できなければユーザーに質問する
3. **portless ラップ** — web サーバかつ `command -v portless` が通る環境なら `portless run` 経由で起動する（`dev` script があれば `portless run` だけでよい）。URL は `https://<プロジェクト名>.localhost`（linked worktree ではブランチ名がサブドメインになる）。portless 未インストール環境ではそのまま起動する
4. **バックグラウンド起動** — Bash の `run_in_background` で起動する
5. **起動確認** — ログに ready / listening / エラーが出るまで確認する
6. **報告** — アクセス URL とログの確認方法を報告する

## エッジケース

- **モノレポ**: ルート直下に `apps/` `packages/` 等の複数アプリがある場合、どれを起動するかユーザーに確認する
- **依存未インストール**: node_modules が存在しない場合は install を提案してから起動する
- **起動失敗**: エラーログを添えて報告する。portless の死にルートが残っていれば `portless prune` で掃除する
- **kill 時の注意**: 共有リバースプロキシを巻き込まない（portless.md の該当ルールをスキル内で参照する）

## テスト

実プロジェクトで `/serve` を実行し、検出 → portless 経由起動 → URL 報告まで通しで動作確認する。自然文（「devサーバ起動して」）での発動も確認する。
