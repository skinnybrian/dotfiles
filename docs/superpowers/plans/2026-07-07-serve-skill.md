# /serve スキル実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/serve`（または「devサーバ起動して」等の自然文）で、開いているプロジェクトの dev サーバを自動判別してバックグラウンド起動し、アクセス URL を報告するスキルを作る。

**Architecture:** SKILL.md 手順書方式。検出スクリプトは同梱せず、探索手順（プロジェクト CLAUDE.md → package.json → その他 → 質問）を markdown で記述し、判断は Claude が行う。web プロジェクトは portless 経由で起動する。

**Tech Stack:** Claude Code スキル（SKILL.md のみ）、portless（あれば）

**Spec:** `docs/superpowers/specs/2026-07-07-serve-skill-design.md`

## Global Constraints

- スキル本体は `~/dotfiles/claude/skills/serve/SKILL.md` に置く。`~/.claude/skills` はディレクトリごと `~/dotfiles/claude/skills` への symlink なので、置くだけで `~/.claude/skills/serve/` として見える（symlink 作成作業は不要）
- frontmatter: `name: serve`、`allowed-tools: Read, Bash, Glob, Grep`。**`disable-model-invocation` は付けない**（自然文発動を許可するため）
- スキル本文は日本語で書く（ユーザーの既存スキルと同様）
- ファイル削除が必要な場面では `rm` ではなく `trash` を使う
- コミットメッセージ末尾に `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` を付ける
- テスト用フィクスチャはセッションの scratchpad ディレクトリに作る（`/tmp` 直下は使わない）

---

### Task 1: serve スキル本体（SKILL.md）の作成

**Files:**
- Create: `~/dotfiles/claude/skills/serve/SKILL.md`

**Interfaces:**
- Produces: `~/.claude/skills/serve/SKILL.md`（symlink 経由で見えるスキル定義。Task 2 の検証、Task 3 の CLAUDE.md 追記が依存）

- [ ] **Step 1: SKILL.md を書く**

`~/dotfiles/claude/skills/serve/SKILL.md` を以下の内容で作成する（ディレクトリごと新規作成）:

````markdown
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
- **起動済みなら URL を報告して終了する。**「再起動して」と明示されたときだけ、`portless list` で対象 app の PID を確認し、**その PID だけ**を kill してから起動し直す。共有リバースプロキシを絶対に巻き込まない（グローバル CLAUDE.md の portless ルール参照）

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
````

- [ ] **Step 2: symlink 経由で見えることを確認**

Run: `ls ~/.claude/skills/serve/SKILL.md && head -6 ~/.claude/skills/serve/SKILL.md`
Expected: パスが表示され、frontmatter に `name: serve` と `allowed-tools: Read, Bash, Glob, Grep` が含まれ、`disable-model-invocation` が**含まれない**こと

- [ ] **Step 3: コミット**

```bash
cd ~/dotfiles && git add claude/skills/serve/SKILL.md && git commit -m "feat: /serve スキルを追加（devサーバ自動判別起動）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: フィクスチャによる検出ロジックのドライラン検証

**Files:**
- Create: `<scratchpad>/serve-fixtures/pnpm-web/package.json`
- Create: `<scratchpad>/serve-fixtures/pnpm-web/pnpm-lock.yaml`
- Create: `<scratchpad>/serve-fixtures/claude-md-override/package.json`
- Create: `<scratchpad>/serve-fixtures/claude-md-override/CLAUDE.md`
- Create: `<scratchpad>/serve-fixtures/unknown/main.c`

**Interfaces:**
- Consumes: Task 1 の `~/.claude/skills/serve/SKILL.md`
- Produces: なし（検証のみ。フィクスチャは検証後に残してよい — scratchpad はセッション終了で消える）

- [ ] **Step 1: フィクスチャを作る（= 失敗しうるテストの準備）**

3つのフィクスチャプロジェクトを scratchpad に作成する:

`serve-fixtures/pnpm-web/package.json`:
```json
{
  "name": "pnpm-web",
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  }
}
```

`serve-fixtures/pnpm-web/pnpm-lock.yaml`:
```yaml
lockfileVersion: '9.0'
```

`serve-fixtures/claude-md-override/package.json`:
```json
{
  "name": "claude-md-override",
  "scripts": {
    "dev": "next dev"
  }
}
```

`serve-fixtures/claude-md-override/CLAUDE.md`:
```markdown
## 開発サーバ

dev サーバは必ず `make dev-all`（API とフロント同時起動）で起動すること。`npm run dev` 単体では API が立たず動かない。
```

`serve-fixtures/unknown/main.c`:
```c
int main(void) { return 0; }
```

- [ ] **Step 2: サブエージェントでドライラン実行**

Agent ツール（general-purpose）で、フィクスチャ3つそれぞれについて以下のプロンプトを投げる:

> `~/.claude/skills/serve/SKILL.md` を読んで、その手順に従い `<フィクスチャの絶対パス>` で「devサーバ起動して」と言われた場合を**ドライラン**してください。実際にサーバは起動せず、(1) どのファイルを根拠に (2) どの起動コマンドを (3) portless ラップの有無込みでどう実行するか、または質問が必要ならその内容を報告してください。判定環境は portless インストール済みの macOS とします。

- [ ] **Step 3: 期待結果と照合**

Expected:
- `pnpm-web` → package.json の `dev` script + pnpm-lock.yaml を根拠に、`portless run`（または `portless run pnpm dev` 相当）で起動と回答
- `claude-md-override` → CLAUDE.md の記載を package.json より**優先**して `make dev-all`（portless ラップ）と回答
- `unknown` → 起動方法を特定できないため**ユーザーに質問する**と回答（推測起動しない）

1つでも期待と違ったら SKILL.md の該当手順の文言を直し、そのフィクスチャだけ Step 2 を再実行する。

- [ ] **Step 4: 修正があればコミット**

```bash
cd ~/dotfiles && git status --porcelain claude/skills/serve/ | grep -q . && git add claude/skills/serve/SKILL.md && git commit -m "fix: /serve スキルの検出手順を検証結果に基づき調整

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" || echo "修正なし・コミット不要"
```

---

### Task 3: グローバル CLAUDE.md のスキル一覧に /serve を追記

**Files:**
- Modify: `~/dotfiles/claude/CLAUDE.md`（「### Skills（`skills/`）」セクション）

**Interfaces:**
- Consumes: Task 1 のスキル名 `serve`
- Produces: なし

- [ ] **Step 1: スキル一覧に1行追加**

`~/dotfiles/claude/CLAUDE.md` の「### Skills（`skills/`）」リストの `/md-to-pdf` の行の直後に追加:

```markdown
- `/serve` — プロジェクトの dev サーバを自動判別してバックグラウンド起動し URL を報告（自然文「devサーバ起動して」でも発動）
```

- [ ] **Step 2: 追記を確認**

Run: `grep -n "/serve" ~/dotfiles/claude/CLAUDE.md`
Expected: Skills セクション内に1行ヒット

- [ ] **Step 3: コミット**

注意: `claude/CLAUDE.md` には既存の未コミット変更がある可能性があるため、`git add -p` 等ではなく、追記行だけが今回の差分であることを `git diff claude/CLAUDE.md` で確認してからコミットする。無関係の既存変更が混ざっている場合は、この追記だけを別途ステージする（`git add -p claude/CLAUDE.md` で該当 hunk のみ選択）。

```bash
cd ~/dotfiles && git diff claude/CLAUDE.md
# 追記行のみなら:
git add claude/CLAUDE.md && git commit -m "docs: CLAUDE.md のスキル一覧に /serve を追加

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: 実プロジェクトでの受け入れ確認（ユーザー協力）

**Files:** なし（動作確認のみ）

**Interfaces:**
- Consumes: Task 1〜3 完了済みのスキル一式

- [ ] **Step 1: ユーザーに新しいセッションでの確認を依頼**

スキル一覧はセッション開始時に読み込まれるため、実際の web プロジェクトを開いた**新しい Claude Code セッション**で以下の2つを確認してもらう:

1. `/serve` と打つ → 検出 → portless 経由バックグラウンド起動 → `https://<プロジェクト名>.localhost` の報告まで通ること
2. `/serve` を使わず「devサーバ起動して」と言う → 同じスキルが自然文発動すること

Expected: どちらも重複起動なしで URL 報告まで完了。問題があれば SKILL.md を修正して再確認。
