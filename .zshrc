# uim-fep がある環境 (= Android Linux / AVF Debian) でのみログインシェルをラップ。
# tmux 内と uim-fep 内からの再入はガードする。
if [[ -z "$UIM_FEP_STARTED" ]] && [[ -z "$TMUX" ]] && command -v uim-fep >/dev/null 2>&1; then
  export UIM_FEP_STARTED=1
  exec uim-fep
fi

# ---- zplug ----
source ~/.zplug/init.zsh

zplug "zplug/zplug", hook-build:"zplug --self-manage"
zplug "mafredri/zsh-async", from:github
zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme
zplug "zsh-users/zsh-completions"

# 未インストールがあれば自動で入れる
if ! zplug check --verbose; then
  zplug install
fi

zplug load

# colors
export LSCOLORS=Exfxcxdxbxegedabagacad
alias ls="ls -G"

# zstyle
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# history-search-end
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# fzf-cdr
alias cdd='fzf-cdr'
function fzf-cdr() {
    target_dir=`cdr -l | sed 's/^[^ ][^ ]*  *//' | fzf`
    target_dir=`echo ${target_dir/\~/$HOME}`
    if [ -n "$target_dir" ]; then
        cd $target_dir
    fi
}

# alias
alias zshrc="vim ~/.zshrc"
alias szsh="source ~/.zshrc"
alias vimrc="vim ~/.vimrc"
alias nvimrc="nvim ~/.config/nvim"
alias tmuxc="vim ~/.tmux.conf"
alias stmux="tmux source ~/.tmux.conf"
alias gst="git status"
alias ga="git add"
alias gaa="git add --all"
alias gb="git branch"
alias gc="git commit -v"
alias gco="git checkout"
alias gcm="git checkout main"
alias gcb="git checkout -b"
alias gd="git diff"
alias gdca="git diff --cached"
alias glog="git log --oneline --decorate --graph"
alias gp="git push"
alias gl="git pull"
alias gfa="git fetch --all"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Claude Code
export PATH="$HOME/.local/bin:$PATH"

# mise
export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$(mise activate zsh)"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/brian/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
