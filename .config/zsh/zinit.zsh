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
zinit lucid for OMZP::starship

zinit wait'0a' lucid for \
    atload"zicompinit; zicdreplay" OMZP::fzf \
    id-as"fzf-tab" Aloxaf/fzf-tab \
    \id-as"fast-syntax-highlighting" \
    \atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting

zinit wait'0b' lucid for \
    \atinit"zstyle ':completion:*' menu select" \
    \id-as"z" agkozak/zsh-z

zinit wait'1a' lucid for \
    OMZP::git \
    OMZP::git-commit \
    OMZP::gpg-agent \
    id-as"forgit" wfxr/forgit

zinit wait'1b' lucid for \
    OMZP::1password \
    atload"mise activate zsh &>/dev/null" OMZP::mise

zinit wait'1c' lucid for \
    \id-as"pnpm-shell-completion" \
    \nocompile"#!/*" \
    \atload"zpcdreplay" \
    \atclone"./zplug.zsh" \
    \atpull"%atclone" g-plane/pnpm-shell-completion \
    id-as"alias-tips" djui/alias-tips \
    https://github.com/tsingksan/dotfiles/blob/main/.config/zsh/plugins/zsh-history-manager.plugin.zsh \
