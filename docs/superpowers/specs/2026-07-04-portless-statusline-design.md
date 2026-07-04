# portless + Claude Code statusline 汎用セットアップ 設計

日付: 2026-07-04
ステータス: 設計承認済み

## 背景 / 目的

Claude Code の複数セッション並行開発で、各セッションが立てる dev server が
`localhost:3000` / `localhost:5173` / … とポート番号で散らばり、
「このタブどのセッション？」と迷子になる問題を解消する。

ポート番号を記憶する方式をやめ、**セッション（worktree/ブランチ）名で URL を固定**する：

```
feature-auth.myapp.localhost
bugfix-header.myapp.localhost
main → myapp.localhost
```

ツールは portless（v0.15.1 時点）を採用。portless は git worktree を自動検出し、
linked worktree ではブランチ名をサブドメインとして自動付与する（設定不要）。

## スコープ

- **汎用セットアップ**：特定プロジェクトへの組み込みはしない。
  どのリポジトリでも `portless run` すれば動く状態を作る。
- statusline に **起動中のルートのみ** URL を表示する（停止中のグレー表示はしない）。
- HTTPS デフォルト（ポート 443、ローカル CA をシステム信頼ストアに登録、sudo 1回）。
- OS 起動時サービス化（`portless service install`）はしない（YAGNI、必要時に追加）。

## コンポーネント

### 1. portless 本体

- `npm install -g portless`（要 Node 24+、環境は v25.2.1 で充足）
- 初回 `portless trust` でローカル CA 生成 + システム信頼ストア登録
- proxy はアプリ起動時に自動起動（デフォルト HTTPS 443）
- 検証: `portless doctor`

### 2. statusline.py 拡張（`~/dotfiles/claude/statusline.py`）

`portless_url()` 関数を追加し、Line 2（branch 🌳 worktree Model の行）の末尾に
`🌐 https://<hostname>` を表示する。フル URL 表示（Ghostty の URL 検出でクリック可能）。

検出ロジック：

1. `$PORTLESS_STATE_DIR` または `~/.portless` の `routes.json` を読む。
   ファイルが無ければ即 `''` を返す（portless 未導入環境のフォールバック）。
2. 期待 hostname を導出。ベース名の優先順は portless 本体と同じ：
   `portless.json` の `name` → `package.json` の `"portless"` キー（string または `{name}`）
   → `package.json` の `name`（npm scope 除去）→ git root のディレクトリ名。
   linked worktree の場合はブランチ名を prefix（`<branch>.<name>`）。
3. `routes.json`（`[{hostname, port, pid}]` 形式）から一致エントリを探し、
   `os.kill(pid, 0)` で pid 生存確認。生きている場合のみ表示（ゴーストルート除外）。
4. URL は state dir の `proxy.port` から組み立て（443 なら `:port` 省略、scheme は https）。
   TLD は `.localhost` 前提とする（カスタム TLD 運用は本設計のスコープ外）。
5. 関数全体を try/except で包む。routes.json の形式変更・破損時は「表示されないだけ」
   に倒し、statusline 本体は壊さない。

エッジケース：

- モノレポで複数ルート該当 → プロジェクト名一致の 1 件のみ表示（複数表示は YAGNI）
- `feature/foo` のようにブランチ名に `/` を含む場合のサブドメイン変換規則は、
  実装時に portless が実際に生成する hostname を確認して同じ規則をミラーする
- routes.json 破損 / pre-1.0 の形式変更 → 非表示
- pid 死亡のゴーストルート → 非表示（掃除は `portless prune`）

### 3. グローバル CLAUDE.md 運用ルール（`~/dotfiles/claude/CLAUDE.md`）

「ローカル開発サーバー」セクションを追加：

- web プロジェクトの dev server は `portless run` 経由で起動する
  （ブランチ名が自動でサブドメインになり、URL が statusline に表示される）
- portless 未インストール環境（Android Linux 等）では従来通り起動する
- ゴミルートが残った場合は `portless prune` で掃除する

これにより Claude Code のエージェント自身が dev server を立てるときも
名前付き URL に統一される。

## テスト / 検証

1. scratchpad に最小 npm プロジェクト（`dev` script あり）を作成し、
   `portless run` → `https://<name>.localhost` の疎通を確認
2. 同プロジェクトを git repo 化し linked worktree を作成、
   ブランチ prefix 付き URL（`<branch>.<name>.localhost`）を確認
3. statusline.py にモック JSON を stdin で流し、3 パターンの出力を確認：
   起動中（URL 表示）/ 停止中（非表示）/ portless 不在（非表示）

## 成果物と配置

| 成果物 | 場所 | 管理 |
| --- | --- | --- |
| portless 本体 | npm global | 手動インストール |
| statusline.py 変更 | `~/dotfiles/claude/statusline.py` | dotfiles にコミット |
| CLAUDE.md 追記 | `~/dotfiles/claude/CLAUDE.md` | dotfiles にコミット |
| 本設計書 | `~/dotfiles/docs/superpowers/specs/` | dotfiles にコミット |

## 参考

- portless README（v0.15.1、routes.json / state dir / worktree 検出の仕様）
- 電通総研テックブログ「Claude Codeのworktreeとportlessで並行開発できる環境を作る」
  （構成の原型。当時と違い現行 portless は worktree 対応が内蔵）
