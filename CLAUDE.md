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
| `.uim` | `~/.uim` | uim (日本語入力) |
| `claude/` | `~/.claude/` | Claude Code (CLAUDE.md, settings, commands, agents) |

## デザイン方針

- カラーテーマは **Gruvbox Dark Hard** で統一（Vim, Neovim, Ghostty）

## 編集時の注意

- ファイルはシンボリックリンク経由で即反映される。変更後にコピーやデプロイは不要
- `claude/CLAUDE.md` はグローバル設定（`~/.claude/CLAUDE.md`）として使われる。このファイル（リポジトリルートの `CLAUDE.md`）はプロジェクト固有の設定
- 新しいツールの設定を追加する場合は `setup.sh` にリンク作成を追記すること
- `claude/` 配下は symlink 戦略が2種類混在する：個別ファイル（`CLAUDE.md`, `settings.json`, `statusline-command.sh`）と、ディレクトリごと（`commands/`, `agents/`）。詳細は `setup.sh` 参照。`~/.claude/` 直下に新規ファイルを追加する場合は `setup.sh` への追記が必要
- `settings.local.json`（シークレット情報）は `~/.claude/` に直接配置する。リポジトリには含めない
- hookスクリプト（`~/.claude/hooks/`）はリポジトリ管理外。変更はコミットに含まれない

## キー入力に関する制約・知見

- **Karabiner-Elements** で `Ctrl-p/n/b/f` が矢印キー（Emacs風カーソル移動）に変換されている。multiplexer の prefix や bind に使うと届かないので避ける
- **Ctrl+Space は Raycast に占有**されているので multiplexer の prefix にできない
- **tmux prefix は `Alt+Space`** を採用（Karabiner / Raycast / Emacs 風キーバインドと衝突しない）
- **Ctrl+H = ASCII Backspace (0x08)** 問題: Ctrl-h はターミナルで物理的に Backspace と同じバイトを送信する。tmux + Neovim 統合で Ctrl-h を pane 移動に使うには3層対応が必要：
  1. **Ghostty**: `keybind = ctrl+h=csi:104;5u` で CSI u シーケンス送信
  2. **tmux**: `set -s extended-keys on` + `set -as terminal-features 'xterm*:extkeys'` で受信側を有効化
  3. **Neovim**: `<C-h>` バインドに加えて `<BS>` も同じ smart-splits 関数に紐付け（フォールバック）
- **Neovim ↔ tmux ペイン移動**: `mrjones2014/smart-splits.nvim` + tmux の vim 検出パススルー (`is_vim` シェルチェック) で実現。Zellij の `swaits/zellij-nav.nvim` 構成より安定
