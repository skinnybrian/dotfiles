source ~/.zplug/init.zsh

fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure

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
alias szsh="source ~/.zshrc"

