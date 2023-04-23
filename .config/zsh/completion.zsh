#!/bin/zsh

# History and cache directories
HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
mkdir -p "$XDG_CACHE_HOME/zsh"

# Completion cache and dump configuration
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# Smart completion initialization
autoload -Uz compinit

if [[ -n "$ZSH_COMPDUMP" ]]; then
    local today dump_modified

    if [[ "$OSTYPE" == "darwin"* ]]; then
        dump_modified=$(stat -f "%Sm" -t "%j" "$ZSH_COMPDUMP" 2>/dev/null)
        today=$(date "+%j")
    else
        dump_modified=$(stat -c "%Y" "$ZSH_COMPDUMP" 2>/dev/null)
        today=$(date -d "now" "+%s")
    fi

    # Regenerate completion if older than 7 days
    if [[ -f "$ZSH_COMPDUMP" && ($(($today - $dump_modified)) -lt 7) ]]; then
        compinit -C -d "$ZSH_COMPDUMP"
    else
        compinit -d "$ZSH_COMPDUMP"
    fi
else
    compinit -d "$ZSH_COMPDUMP"
fi