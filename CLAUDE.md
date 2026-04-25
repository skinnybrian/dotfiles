# dotfiles

個人の設定ファイルを管理するリポジトリ。`setup.sh` でシンボリックリンクを作成し、各ツールの設定を展開する。

## セットアップ

```sh
cd ~/dotfiles
sh setup.sh
```

## リポジトリ構造

| ディレクトリ/ファイル | リンク先 | 対象ツール |
|---|---|---|
| `.zshrc` | `~/.zshrc` | Zsh |
| `.vimrc` | `~/.vimrc` | Vim |
| `.tmux.conf` | `~/.tmux.conf` | tmux（メイン multiplexer、smart-splits.nvim 連携） |
| `nvim/` | `~/.config/nvim/` | Neovim (Lua設定, lazy.nvim) |
| `ghostty/` | `~/.config/ghostty/` | Ghostty ターミナル |
| `zellij/` | `~/.config/zellij/` | Zellij（バックアップとして残置、日常使用は tmux） |
| `.uim` | `~/.uim` | uim（日本語入力、Android Linux 用） |
| `claude/` | `~/.claude/` | Claude Code (CLAUDE.md, settings, skills, commands, agents) |

## デザイン方針

- カラーテーマは **Gruvbox Dark Hard** で統一（Vim, Neovim, Ghostty）

## 編集時の注意

- ファイルはシンボリックリンク経由で即反映される。変更後にコピーやデプロイは不要
- `claude/CLAUDE.md` はグローバル設定（`~/.claude/CLAUDE.md`）として使われる。このファイル（リポジトリルートの `CLAUDE.md`）はプロジェクト固有の設定
- 新しいツールの設定を追加する場合は `setup.sh` にリンク作成を追記すること
- `claude/` 配下は symlink 戦略が2種類混在する：個別ファイル（`CLAUDE.md`, `settings.json`, `statusline-command.sh`, `statusline.py`）と、ディレクトリごと（`skills/`, `commands/`, `agents/`）。詳細は `setup.sh` 参照。`~/.claude/` 直下に新規ファイルを追加する場合は `setup.sh` への追記が必要
- `settings.local.json`（シークレット情報）は `~/.claude/` に直接配置する。リポジトリには含めない
- hookスクリプト（`~/.claude/hooks/`）はリポジトリ管理外。変更はコミットに含まれない

## Android Linux (AVF Debian) セットアップ

Pixel の Linux Terminal（Android Virtualization Framework 上の Debian VM）で日本語入力を有効化する手順。`setup.sh` では自動化していない（apt / locale 周りは環境依存のため手動推奨）。

```sh
sudo apt install locales
sudo sed -i 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
sudo apt install uim-fep uim-mozc
sh ~/dotfiles/setup.sh   # ~/.uim の symlink を張る
uim-fep                  # 起動後 Ctrl+_ で IME トグル
```

## キー入力に関する制約・知見

- **Karabiner-Elements** で `Ctrl-p/n/b/f` が矢印キー（Emacs風カーソル移動）に変換されている。multiplexer の prefix や bind に使うと届かないので避ける
- **Ctrl+Space は Raycast に占有**されているので multiplexer の prefix にできない
- **tmux prefix は `Ctrl+a`** を採用（Screen 由来の定番リバインド）。bash/zsh の行頭移動(`C-a`)と衝突するが、`bind C-a send-prefix` により `C-a` 2連打で生の `C-a` をペインに送信でき、行頭移動も使える
- **Ctrl+H = ASCII Backspace (0x08)** 問題: Ctrl-h はターミナルで物理的に Backspace と同じバイトを送信する。tmux + Neovim 統合で Ctrl-h を pane 移動に使うには3層対応が必要：
  1. **Ghostty**: `keybind = ctrl+h=csi:104;5u` で CSI u シーケンス送信
  2. **tmux**: `set -s extended-keys on` + `set -as terminal-features 'xterm*:extkeys'` で受信側を有効化
  3. **Neovim**: `<C-h>` バインドに加えて `<BS>` も同じ smart-splits 関数に紐付け（フォールバック）
- **Neovim ↔ tmux ペイン移動**: `mrjones2014/smart-splits.nvim` + tmux の vim 検出パススルー (`is_vim` シェルチェック) で実現。Zellij の `swaits/zellij-nav.nvim` 構成より安定
- **Ctrl+_ = uim-fep トグル**（Android Linux / AVF Debian）: `Ctrl+Space` / `Alt+j` が AVF 実機で動作しなかったための選択。`Ctrl+_` は bash/zsh readline の undo と衝突するが、uim-fep 起動中はキーを横取りするため実害なし。uim-fep 未起動のシェルでは Ctrl+_ が undo として効く点に注意
- **Android Linux Terminal の貼り付け**: Ctrl+V は readline の `quoted-insert` に取られているため効かない。**`Ctrl+Shift+V`** が OS クリップボード貼り付け（xterm 系の慣習）。`Shift+Insert` / 長押し Paste も利用可
- **Ghostty Quick Terminal × Karabiner**: Quick Terminal は `NSPanel` 系ウィンドウで macOS の "frontmost application" を切り替えない。Karabiner の `frontmost_application_unless` で Ghostty を除外しても Quick Terminal では効かず、直前のアプリが frontmost のまま判定される。Karabiner の `Ctrl+D → delete_forward` 変換ルールはこの問題で `\E[3~` (Forward Delete CSI) が tmux に届くため削除済（2026-04-25 実施）。同様の `frontmost_application_unless` ベースのアプリ依存リマップは Quick Terminal で意図せず発火するので注意
- **tmux copy-mode の `C-d/C-u`** は `halfpage-down/up` でカーソル移動のみ実行する。画面表示はカーソルが画面端を超えるまで動かない。`prefix [` 突入直後は既に画面最下端のため `C-d` を押しても画面が変わらず「効かないように見える」が仕様。画面そのものをスクロールしたい場合は `J/K` (scroll-down/up 各 1 行) や `C-e/C-y` を copy-mode-vi にバインドする
