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
ln -sfn ~/dotfiles/claude/commands ~/.claude/commands
ln -sfn ~/dotfiles/claude/agents ~/.claude/agents
