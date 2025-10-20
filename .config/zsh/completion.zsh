#!/bin/zsh

export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# if [ ! -f "$XDG_DATA_HOME/zinit/completions/_docker" ] && command -v docker &>/dev/null; then
#     docker completion zsh >"$XDG_DATA_HOME/zinit/completions/_docker"
# fi

zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*:*:git:*' matcher-list ''

# 如果只想对 git 分支补全区分大小写，可以更具体地设置
# zstyle ':completion:*:*:git-checkout:*:*:branches' case-sensitive true
# zstyle ':completion:*:*:git-merge:*:*:branches' case-sensitive true
# zstyle ':completion:*:*:git-rebase:*:*:branches' case-sensitive true
# zstyle ':completion:*:*:git-branch:*:*' case-sensitive true
# zstyle ':fzf-tab:*' fzf-opt \
#     '--border --preview-window=right:60%:hidden --bind=?:toggle-preview'
# zstyle ':completion:*:*:ls:*:files' command "fd --type f --hidden --exclude .git"
# zstyle ':completion:*:*:ls:*:directory' command "fd --type d --exclude .git"
# zstyle ':fzf-tab:complete:(cat|ls|cd|less|vim|nvim|rm|nano):*' fzf-preview \
#     '([ -d "$realpath" ] && tree -C "$realpath") || cat "$realpath"'

# Smart completion initialization
autoload -Uz compinit

if [[ -n "$ZSH_COMPDUMP" ]]; then
#     local today dump_modified

#     if [[ "$OSTYPE" == "darwin"* ]]; then
#         dump_modified=$(stat -f "%Sm" -t "%j" "$ZSH_COMPDUMP" 2>/dev/null)
#         today=$(date "+%j")
#     else
#         dump_modified=$(stat -c "%Y" "$ZSH_COMPDUMP" 2>/dev/null)
#         today=$(date -d "now" "+%s")
#     fi

#     # Regenerate completion if older than 7 days
#     if [[ -f "$ZSH_COMPDUMP" && ($(($today - $dump_modified)) -lt 7) ]]; then
#         compinit -d "$ZSH_COMPDUMP"
#     else
        compinit -C -d "$ZSH_COMPDUMP"
#     fi
# else
#     compinit -d "$ZSH_COMPDUMP"
fi
