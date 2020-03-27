source ~/.zplug/init.zsh

fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure

# colors
export LSCOLORS=Exfxcxdxbxegedabagacad
alias ls="ls -G"

# zplug
zplug "zplug/zplug", hook-build:"zplug --self-manage"
zplug "mafredri/zsh-async", from:github
zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme
zplug "zsh-users/zsh-completions"

# anyenv
eval "$(anyenv init -)"

export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"

# nodenv
export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# alias
alias zshrc="vim ~/.zshrc"
alias szsh="source ~/.zshrc"

alias vimrc="vim ~/.vimrc"

alias gst="git status"
alias gaa="git add --all"
alias gb="git branch"
alias gc="git commit -v"
alias gd="git diff"
alias glog="git log --oneline --decorate --graph"
