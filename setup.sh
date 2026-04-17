#!/bin/sh
mkdir -p ~/.config

ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/.vimrc ~/.vimrc
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.uim ~/.uim
ln -sfn ~/dotfiles/nvim ~/.config/nvim
ln -sfn ~/dotfiles/ghostty ~/.config/ghostty
ln -sfn ~/dotfiles/zellij ~/.config/zellij

# Claude Code
mkdir -p ~/.claude
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
ln -sf ~/dotfiles/claude/statusline-command.sh ~/.claude/statusline-command.sh
ln -sf ~/dotfiles/claude/statusline.py ~/.claude/statusline.py
ln -sfn ~/dotfiles/claude/commands ~/.claude/commands
ln -sfn ~/dotfiles/claude/agents ~/.claude/agents
ln -sfn ~/dotfiles/claude/skills ~/.claude/skills

# Claude Code hooks（スクリプトのみ個別 symlink。.env やログは環境固有のため ~/.claude/hooks/ に直接配置）
mkdir -p ~/.claude/hooks
# 廃止されたフックの symlink を掃除
rm -f ~/.claude/hooks/tmux-bell.sh
ln -sf ~/dotfiles/claude/hooks/chrome-open.sh ~/.claude/hooks/chrome-open.sh
ln -sf ~/dotfiles/claude/hooks/discord-notify.sh ~/.claude/hooks/discord-notify.sh
ln -sf ~/dotfiles/claude/hooks/research-save-suggest.sh ~/.claude/hooks/research-save-suggest.sh
