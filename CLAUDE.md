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
| `.tmux.conf` | `~/.tmux.conf` | tmux |
| `nvim/` | `~/.config/nvim/` | Neovim (Lua設定, lazy.nvim) |
| `ghostty/` | `~/.config/ghostty/` | Ghostty ターミナル |
| `claude/` | `~/.claude/` | Claude Code (CLAUDE.md, settings, commands, agents) |

## デザイン方針

- カラーテーマは **Gruvbox Dark Hard** で統一（Vim, Neovim, Ghostty）

## 編集時の注意

- ファイルはシンボリックリンク経由で即反映される。変更後にコピーやデプロイは不要
- `claude/CLAUDE.md` はグローバル設定（`~/.claude/CLAUDE.md`）として使われる。このファイル（リポジトリルートの `CLAUDE.md`）はプロジェクト固有の設定
- 新しいツールの設定を追加する場合は `setup.sh` にリンク作成を追記すること
