#!/bin/zsh

declare -x -A ZINIT
ZINIT[HOME_DIR]="${XDG_DATA_HOME}/zinit"
ZINIT[BIN_DIR]="${ZINIT[HOME_DIR]}/zinit.git"
ZINIT[ZCOMPDUMP_PATH]="${ZSH_COMPDUMP}"

# Automatic Zinit installation
if [[ ! -d "${ZINIT[BIN_DIR]}" ]]; then
    print-P "%F{green}🚀 Installing Zinit...%f"
    mkdir -p "$(dirname "${ZINIT[BIN_DIR]}")"
    git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT[BIN_DIR]}"
    print-P "%F{blue}✅ Zinit Installation Complete%f"
fi

source "${ZINIT[BIN_DIR]}/zinit.zsh"
mkdir -p "$HOME/.cache/zinit/completions"

# Plugin Loading
zinit lucid for \
    OMZ::lib/key-bindings.zsh \
        light-mode \
        as"command" from"gh-r" \
        atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
        atpull"%atclone" src"init.zsh" \
    starship/starship \
        light-mode \
        id-as"fast-syntax-highlighting" \
        atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting

# Fuzzy Finder and Navigation

zinit wait'0a' lucid for \
    OMZ::lib/history.zsh \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/completion.zsh \
    OMZ::lib/theme-and-appearance.zsh

zinit wait'0b' lucid for \
        light-mode \
        from"gh-r" as"program" \
        atload"zicompinit; zicdreplay" \
    junegunn/fzf \
    OMZ::plugins/fzf \
        id-as"fzf-tab" \
    Aloxaf/fzf-tab \
        svn \
        id-as"z" \
        atinit"zstyle ':completion:*' menu select" \
    agkozak/zsh-z

# Git and Development Tools
zinit wait'1a' lucid for \
    OMZ::plugins/git \
    OMZ::plugins/git-commit \
    OMZ::plugins/gpg-agent \
        atload"mise activate zsh &>/dev/null" \
    OMZ::plugins/mise \
        id-as"forgit" \
    wfxr/forgit

# Utility Plugins
zinit wait'1b' lucid for \
    OMZ::plugins/1password \
        id-as"pnpm-shell-completion" \
        nocompile"#!/*" \
        atload"zpcdreplay" \
        atclone"./zplug.zsh" \
        atpull"%atclone" \
    g-plane/pnpm-shell-completion \
        id-as"alias-tips" \
    djui/alias-tips
zinit ice wait'1b' lucid
zinit snippet "$HOME/.config/zsh/plugins/zsh-history-manager.plugin.zsh"
