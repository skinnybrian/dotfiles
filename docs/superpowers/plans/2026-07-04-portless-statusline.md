# portless + statusline 汎用セットアップ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** portless をグローバル導入し、Claude Code の statusline に「いま起動中の dev server の名前付き URL」を表示、CLAUDE.md に運用ルールを追記する。

**Architecture:** portless（v0.15.1）の state（`~/.portless/routes.json` = `[{hostname, port, pid}]`、hostname は TLD 込み FQDN）を statusline.py が直接読む。hostname 導出は portless 本体のロジック（sanitize / scope 除去 / worktree ブランチ最終セグメント prefix）を Python でミラーする。失敗時は常に「表示しない」に倒す。

**Tech Stack:** portless 0.15.1（npm global）、Python 3（statusline.py、標準ライブラリのみ）、bash（検証）

**Spec:** `~/dotfiles/docs/superpowers/specs/2026-07-04-portless-statusline-design.md`

## Global Constraints

- portless は pre-1.0（0.15.1）。statusline 側は routes.json の形式変更・破損で**絶対に例外を漏らさない**（全体 try/except → `''`）
- TLD は `.localhost` 固定（カスタム TLD はスコープ外）
- portless 不在環境（Android Linux 等）では statusline は何も表示しない（routes.json 不在で即 return）
- dotfiles リポジトリには**無関係の未コミット変更が多数ある**。コミットは必ず `git add <明示パス>` + `git commit -- <明示パス>` で対象ファイルだけに絞る
- ファイル削除が必要な場合は `rm` ではなく `trash` を使う
- コミットメッセージ末尾に `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` を付ける
- sudo が必要な手順（CA 信頼・ポート443バインド）は非対話シェルでは実行できない → **ユーザーに `! <command>` で実行してもらう**

## portless 内部仕様（実装の根拠、ソース確認済み）

- state dir: `$PORTLESS_STATE_DIR` または `~/.portless`
- `routes.json`: `[{"hostname": "fix-ui.myapp.localhost", "port": 4123, "pid": 12345}]`（FQDN、TLD 込み）
- `proxy.port`: プレーンテキストの整数。`proxy.tls`: 存在すれば HTTPS（マーカーファイル）
- URL 形式: `{proto}://{hostname}`、proxy ポートがデフォルト（tls=443 / http=80）以外なら `:{port}` 付与
- sanitize 規則: 小文字化 → `[^a-z0-9-]` を `-` に → 連続 `-` を1個に → 先頭末尾の `-` 除去
- base 名の優先順: package.json `"portless"` キー（string または `{name}`）→ portless.json `"name"` → package.json `"name"`（`^@[^/]+/` の npm scope 除去）→ git root の basename。package.json は cwd から上方向に最初に見つかったもの
- worktree prefix: **linked worktree のみ**（`<git root>/.git` がファイル）。ブランチが `main` / `master` / `HEAD` 以外のとき、`branch.split('/')` の**最終セグメント**を sanitize して prefix（`feature/foo` → `foo.myapp.localhost`）。main worktree は feature ブランチ上でも prefix なし

## File Structure

| ファイル | 操作 | 責務 |
| --- | --- | --- |
| `~/dotfiles/claude/statusline.py` | Modify | `portless_url()` 追加 + Line 2 へ 🌐 URL 表示 |
| `~/dotfiles/claude/CLAUDE.md` | Modify | 「ローカル開発サーバー（portless）」セクション追加 |
| npm global | Install | portless 0.15.1 |
| scratchpad `portless-test/` | Create | 検証用フィクスチャ（コミットしない） |

---

### Task 1: 既存の未コミット変更を分離コミット

これから編集する2ファイルに既存の未コミット変更があるため、先に単独コミットして自分の変更と混ざらないようにする。

**Files:**
- Commit only: `~/dotfiles/claude/statusline.py`（既存差分 = worktree 名表示機能、内容確認済み）
- Commit only: `~/dotfiles/claude/CLAUDE.md`（既存差分の内容は Step 2 で確認）

**Interfaces:**
- Produces: クリーンな作業ベース（以降のタスクは編集対象ファイルに自分の差分だけを持つ）

- [x] **Step 1: statusline.py の既存差分を単独コミット**

```bash
git -C ~/dotfiles add claude/statusline.py
git -C ~/dotfiles commit -m "feat(statusline): worktree 名表示と project_dir ベースのディレクトリ表示を追加

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" -- claude/statusline.py
```

Expected: `1 file changed` のみ（他ファイルが混ざっていないこと）

- [x] **Step 2: claude/CLAUDE.md の既存差分を単独コミット**

既存差分の内容は確認済み：口調・応答スタイルの詳細化（避けるべきパターン節の追加）、PR 作成ルールの追加、`@RTK.md` include の追加。

```bash
git -C ~/dotfiles add claude/CLAUDE.md
git -C ~/dotfiles commit -m "docs: 口調スタイル詳細化・PR作成ルール・RTK.md include を追加

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" -- claude/CLAUDE.md
```

Expected: `1 file changed` のみ

- [x] **Step 3: 対象2ファイルがクリーンなことを確認**

```bash
git -C ~/dotfiles status --short claude/statusline.py claude/CLAUDE.md
```

Expected: 出力なし

---

### Task 2: portless インストールと初期セットアップ

**Files:**
- npm global に portless 0.15.1

**Interfaces:**
- Produces: `portless` CLI（PATH 上）、`~/.portless/` state dir、信頼済みローカル CA、443 で待ち受ける proxy

- [x] **Step 1: グローバルインストール**

```bash
npm install -g portless
portless --version
```

Expected: `0.15.1`（またはそれ以降）

- [x] **Step 2: [USER ACTION] CA 信頼と proxy 起動（sudo 対話が必要）**

非対話シェルでは sudo できないため、ユーザーに以下をそのまま実行してもらう（Claude Code のプロンプトで `!` プレフィックス）：

```
! portless trust
! portless proxy start
```

Expected: CA がシステム信頼ストアに登録され、proxy が 443 で起動する

- [x] **Step 3: ヘルスチェック**

```bash
portless doctor
```

Expected: Node / state dir / proxy / CA trust / DNS の全項目がパス（LAN モード関連の警告は無視してよい）

---

### Task 3: statusline.py に portless_url() を追加

**Files:**
- Modify: `~/dotfiles/claude/statusline.py`（= `~/.claude/statusline.py` の symlink 実体）
- Test: bash フィクスチャ（scratchpad、コミットしない）

**Interfaces:**
- Consumes: portless state（`routes.json` / `proxy.port` / `proxy.tls`）
- Produces: `portless_url(cwd, branch, branch_is_symbolic) -> str`（起動中ルートの URL、なければ `''`）。Line 2 末尾に `🌐 {url}` を表示

- [x] **Step 1: 失敗するテスト（フィクスチャで URL が出ないことを確認）**

```bash
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
FIX=$SCRATCH/portless-test
mkdir -p $FIX/state $FIX/proj
printf '[{"hostname":"test-app.localhost","port":4123,"pid":%d}]' $$ > $FIX/state/routes.json
echo 443 > $FIX/state/proxy.port
touch $FIX/state/proxy.tls
echo '{"name":"test-app"}' > $FIX/proj/package.json
echo "{\"workspace\":{\"current_dir\":\"$FIX/proj\"},\"model\":{\"display_name\":\"Test\"}}" \
  | PORTLESS_STATE_DIR=$FIX/state ~/.claude/statusline.py
```

Expected: 出力に `🌐` が**含まれない**（未実装のため）

- [x] **Step 2: portless_url() を実装**

`statusline.py` の変更は3箇所。

(a) 先頭の import に `re` を追加：

```python
import json, sys, os, re, subprocess
```

(b) `format_tokens()` の直後（`# --- Data extraction ---` の前）に関数を追加：

```python
def portless_url(cwd, branch, branch_is_symbolic):
    """起動中の portless ルートの URL を返す。なければ ''（失敗も常に ''）。"""
    try:
        state_dir = os.environ.get('PORTLESS_STATE_DIR') or os.path.expanduser('~/.portless')
        routes_path = os.path.join(state_dir, 'routes.json')
        if not cwd or not os.path.isfile(routes_path):
            return ''
        with open(routes_path) as f:
            routes = json.load(f)
        if not isinstance(routes, list) or not routes:
            return ''

        def sanitize(name):
            s = re.sub(r'[^a-z0-9-]', '-', name.lower())
            s = re.sub(r'-{2,}', '-', s)
            return s.strip('-')

        # base 名の導出（portless 本体と同じ優先順）
        pkg_portless = pkg_name = pl_name = git_root = ''
        d = cwd
        while True:
            if not (pkg_name or pkg_portless):
                try:
                    with open(os.path.join(d, 'package.json')) as f:
                        pkg = json.load(f)
                    p = pkg.get('portless')
                    if isinstance(p, str):
                        pkg_portless = p
                    elif isinstance(p, dict) and isinstance(p.get('name'), str):
                        pkg_portless = p['name']
                    if isinstance(pkg.get('name'), str):
                        pkg_name = re.sub(r'^@[^/]+/', '', pkg['name'])
                except (OSError, ValueError):
                    pass
            if not pl_name:
                try:
                    with open(os.path.join(d, 'portless.json')) as f:
                        pl = json.load(f)
                    if isinstance(pl.get('name'), str):
                        pl_name = pl['name']
                except (OSError, ValueError):
                    pass
            if not git_root and os.path.exists(os.path.join(d, '.git')):
                git_root = d
            parent = os.path.dirname(d)
            if parent == d:
                break
            d = parent
        base = ''
        for cand in (pkg_portless, pl_name, pkg_name,
                     os.path.basename(git_root) if git_root else ''):
            if cand and sanitize(cand):
                base = sanitize(cand)
                break
        if not base:
            return ''

        # linked worktree のみブランチ最終セグメントを prefix（portless と同じ規則）
        prefix = ''
        if git_root and os.path.isfile(os.path.join(git_root, '.git')):
            if branch_is_symbolic and branch not in ('main', 'master', 'HEAD'):
                prefix = sanitize(branch.split('/')[-1])
        effective = f'{prefix}.{base}' if prefix else base
        hostname = f'{effective}.localhost'

        for r in routes:
            if not isinstance(r, dict) or r.get('hostname') != hostname:
                continue
            try:
                os.kill(int(r['pid']), 0)
            except (ProcessLookupError, ValueError, TypeError, OverflowError, KeyError):
                return ''
            except PermissionError:
                pass  # 生存しているが別ユーザー
            tls = os.path.isfile(os.path.join(state_dir, 'proxy.tls'))
            port = 443 if tls else 80
            try:
                with open(os.path.join(state_dir, 'proxy.port')) as f:
                    port = int(f.read().strip())
            except (OSError, ValueError):
                pass
            proto = 'https' if tls else 'http'
            if port == (443 if tls else 80):
                return f'{proto}://{hostname}'
            return f'{proto}://{hostname}:{port}'
        return ''
    except Exception:
        return ''
```

(c) 既存の branch 取得コードで symbolic-ref 成功を記録し、Line 2 に URL を追加。

branch 取得部（`# Git branch` ブロック）を次のように変更（`branch_is_symbolic` の追加のみ、ロジックは不変）：

```python
# Git branch
branch = ''
branch_is_symbolic = False
if cwd:
    try:
        result = subprocess.run(
            ['git', '-C', cwd, 'symbolic-ref', '--short', 'HEAD'],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode == 0:
            branch = result.stdout.strip()
            branch_is_symbolic = True
        else:
            result = subprocess.run(
                ['git', '-C', cwd, 'rev-parse', '--short', 'HEAD'],
                capture_output=True, text=True, timeout=2
            )
            if result.returncode == 0:
                branch = result.stdout.strip()
    except (subprocess.TimeoutExpired, OSError):
        pass
```

Line 2 構築部（`# --- Line 2: ... ---` ブロック）の `line2 = '  '.join(parts2)` の**直前**に追加：

```python
url = portless_url(cwd, branch, branch_is_symbolic)
if url:
    parts2.append(f'\U0001f310 {url}')
```

- [x] **Step 3: テスト再実行（起動中ルート → URL 表示）**

Step 1 と同じコマンドを実行。

Expected: Line 2 に `🌐 https://test-app.localhost` が含まれる

- [x] **Step 4: 死んだ pid → 非表示 を確認**

```bash
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
FIX=$SCRATCH/portless-test
true & DEAD_PID=$!; wait $DEAD_PID
printf '[{"hostname":"test-app.localhost","port":4123,"pid":%d}]' $DEAD_PID > $FIX/state/routes.json
echo "{\"workspace\":{\"current_dir\":\"$FIX/proj\"},\"model\":{\"display_name\":\"Test\"}}" \
  | PORTLESS_STATE_DIR=$FIX/state ~/.claude/statusline.py
```

Expected: 出力に `🌐` が含まれない

- [x] **Step 5: worktree prefix（feature/foo → foo.）を確認**

```bash
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
FIX=$SCRATCH/portless-test
cd $FIX/proj && git init -q && git add -A && git commit -qm init && git branch -m main
git worktree add -q ../proj-wt -b feature/test-ui
printf '[{"hostname":"test-ui.test-app.localhost","port":4123,"pid":%d}]' $$ > $FIX/state/routes.json
echo "{\"workspace\":{\"current_dir\":\"$FIX/proj-wt\"},\"model\":{\"display_name\":\"Test\"}}" \
  | PORTLESS_STATE_DIR=$FIX/state ~/.claude/statusline.py
```

Expected: `🌐 https://test-ui.test-app.localhost` が含まれる（`feature-test-ui` ではなく最終セグメント `test-ui`）

- [x] **Step 6: portless 不在環境フォールバック（state dir なし）を確認**

```bash
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
FIX=$SCRATCH/portless-test
echo "{\"workspace\":{\"current_dir\":\"$FIX/proj\"},\"model\":{\"display_name\":\"Test\"}}" \
  | PORTLESS_STATE_DIR=$FIX/empty-nonexistent ~/.claude/statusline.py
```

Expected: `🌐` なし、statusline は正常出力（例外・トレースバックが出ないこと）

- [x] **Step 7: コミット**

```bash
git -C ~/dotfiles add claude/statusline.py
git -C ~/dotfiles commit -m "feat(statusline): 起動中の portless ルートの URL を表示

routes.json を直接読み、portless と同じ hostname 導出規則
（sanitize / scope 除去 / linked worktree のブランチ最終セグメント prefix）
で一致ルートを探す。pid 死亡・形式変更・portless 不在時は非表示に倒す。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" -- claude/statusline.py
```

Expected: `1 file changed`

---

### Task 4: グローバル CLAUDE.md に運用ルール追記

**Files:**
- Modify: `~/dotfiles/claude/CLAUDE.md`

**Interfaces:**
- Produces: Claude Code エージェントが dev server を portless 経由で立てる運用ルール

- [x] **Step 1: セクション追加**

`## MCP サーバー` セクションの**直前**に以下を挿入する：

```markdown
## ローカル開発サーバー（portless）

- web プロジェクトの dev server は `portless run` 経由で起動する（`dev` script があれば `portless run` だけでよい。例: `portless run npm run dev`）。ポート番号ではなく `https://<プロジェクト名>.localhost` でアクセスする
- linked git worktree ではブランチ名（最終セグメント）が自動でサブドメインになる（例: `https://feature-auth.myapp.localhost`）。起動中の URL は statusline に 🌐 で表示される
- portless 未インストール環境（Android Linux 等）では従来どおり起動する（`command -v portless` で確認）
- 死んだルートが残っていたら `portless prune` で掃除する
```

- [x] **Step 2: symlink 経由で反映されていることを確認**

```bash
grep -A2 "ローカル開発サーバー" ~/.claude/CLAUDE.md | head -3
```

Expected: 追記したセクションが表示される

- [x] **Step 3: コミット**

```bash
git -C ~/dotfiles add claude/CLAUDE.md
git -C ~/dotfiles commit -m "docs: ローカル dev server を portless run 経由で起動する運用ルールを追加

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" -- claude/CLAUDE.md
```

Expected: `1 file changed`

---

### Task 5: E2E 動作確認（実 portless + worktree）

Task 2（proxy 起動済み）と Task 3（statusline 実装）の統合確認。

**Files:**
- Create: scratchpad `mini-app/`（検証用、コミットしない）

**Interfaces:**
- Consumes: `portless` CLI、`portless_url()` 入りの statusline.py

- [x] **Step 1: PORT を尊重する最小アプリを作成**

```bash
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
mkdir -p $SCRATCH/mini-app && cd $SCRATCH/mini-app
cat > server.js <<'EOF'
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req, res) => res.end('mini-app ok\n')).listen(port, () =>
  console.log(`listening on ${port}`));
EOF
cat > package.json <<'EOF'
{"name":"mini-app","scripts":{"dev":"node server.js"}}
EOF
git init -q && git add -A && git commit -qm init && git branch -m main
```

- [x] **Step 2: portless run で起動（バックグラウンド）**

`portless run` を run_in_background で起動し、数秒待ってから疎通確認：

```bash
cd $SCRATCH/mini-app && portless run   # run_in_background: true
```

```bash
sleep 3 && curl -s https://mini-app.localhost
portless list
```

Expected: `mini-app ok` が返り、`portless list` に `mini-app.localhost` が出る

- [x] **Step 3: statusline が実 state で URL を出すことを確認**

```bash
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
echo "{\"workspace\":{\"current_dir\":\"$SCRATCH/mini-app\"},\"model\":{\"display_name\":\"Test\"}}" \
  | ~/.claude/statusline.py
```

Expected: `🌐 https://mini-app.localhost` が含まれる（PORTLESS_STATE_DIR 指定なし = 実 `~/.portless` を読む）

- [x] **Step 4: worktree で prefix 付き URL を確認**

```bash
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
cd $SCRATCH/mini-app && git worktree add -q ../mini-app-wt -b feature/auth
cd $SCRATCH/mini-app-wt && portless run   # run_in_background: true
```

```bash
sleep 3 && curl -s https://auth.mini-app.localhost
SCRATCH=/private/tmp/claude-501/-Users-brian--claude/02b903c5-d7da-4f18-8fe1-a35314ded953/scratchpad
echo "{\"workspace\":{\"current_dir\":\"$SCRATCH/mini-app-wt\"},\"model\":{\"display_name\":\"Test\"}}" \
  | ~/.claude/statusline.py
```

Expected: curl が `mini-app ok`、statusline に `🌐 https://auth.mini-app.localhost`

- [x] **Step 5: クリーンアップ**

バックグラウンドの `portless run` プロセス2つを停止（TaskStop または kill）し、ルートが消えることを確認：

```bash
portless list
```

Expected: mini-app 系のルートが消えている（残っていれば `portless prune`）

- [ ] **Step 6: 実セッションでの最終確認をユーザーに依頼**

ユーザーに web プロジェクトのセッションで `portless run` → statusline の 🌐 表示を目視確認してもらう。

---

## 完了条件

- `portless doctor` 全項目パス
- statusline: 起動中 URL 表示 / 停止中非表示 / portless 不在で無害、の3挙動をフィクスチャと実 E2E の両方で確認済み
- dotfiles に statusline.py と CLAUDE.md の変更が**それぞれ単独コミット**で入っている
