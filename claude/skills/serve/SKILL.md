---
name: serve
description: 開いているプロジェクトの開発サーバを自動判別してバックグラウンドで起動し、アクセスURLを報告する。「devサーバ起動して」「サーバ立ち上げて」「開発サーバ動かして」等の依頼でも使用する
allowed-tools: Read, Bash, Glob, Grep
---

# serve — dev サーバ自動起動

引数: $ARGUMENTS（モノレポで起動対象のアプリ名/サブディレクトリを指定可。省略時はカレントプロジェクト）

## 手順

### 1. 重複起動チェック

- `command -v portless` が通れば `portless list` で対象プロジェクト（worktree 含む）のサーバが起動済みか確認する
- このセッションで起動済みの background task があればそれも確認する
- **起動済みなら URL を報告して終了する。**「再起動して」と明示されたときだけ、`portless list` で対象 app の PID を確認し、**その PID だけ**を kill してから起動し直す。共有リバースプロキシを絶対に巻き込まない（`~/dotfiles/claude/fragments/portless.md` の kill ルール参照）

### 2. 起動コマンドの特定（優先順）

1. **プロジェクトの CLAUDE.md / CLAUDE.local.md / README** に dev サーバの起動方法が書かれていればそれに従う
2. **package.json の scripts** を `dev` → `start` → `serve` の順で探す。パッケージマネージャは lockfile で判定:
   - `pnpm-lock.yaml` → pnpm、`bun.lockb` → bun、`yarn.lock` → yarn、`package-lock.json` → npm
3. **その他の目印**: `Makefile`（dev / serve / run ターゲット）、`docker-compose.yml`（`docker compose up`）、`manage.py`（`python manage.py runserver`）、`Gemfile` + `bin/rails`（`bin/rails server`）など
4. どれでも特定できなければ**ユーザーに質問する**（推測で勝手に起動しない）

**モノレポの場合**（`apps/` `packages/` 等に複数アプリ）: $ARGUMENTS で指定がなければ、どのアプリを起動するかユーザーに確認する。

### 3. 起動前チェック

- Node 系で `node_modules/` が無ければ install を提案してから起動する

### 4. 起動（バックグラウンド）

- **web サーバ + portless あり**: `portless run <コマンド>` で起動する。`dev` script があれば `portless run` だけでよい
- **portless なし**（Android Linux 等）: コマンドをそのまま起動する
- いずれも Bash の `run_in_background: true` で起動する

### 5. 起動確認

- background ログに ready / listening / エラーが出るまで確認する
- 起動失敗したらログを添えて報告する。portless の死にルートが疑われる場合は `portless prune` を提案する

### 6. 報告

- アクセス URL を報告する:
  - portless 経由: `https://<プロジェクト名>.localhost`（linked worktree ならブランチ名の最終セグメントがサブドメイン。statusline の 🌐 にも出る）
  - 直接起動: ログに出たポートから `http://localhost:<ポート>`
- background task のログ確認方法も一言添える
