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

zinit light-mode for \
    OMZ::lib/key-bindings.zsh \
    OMZ::lib/history.zsh

zinit ice id-as"zsh-history-manager-plugin"
zinit snippet ~/.config/zsh/plugins/zsh-history-manager.plugin.zsh 

zinit light-mode as"command" from"gh-r" \
    atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
    atpull"%atclone" src"init.zsh" \
    for starship/starship

zinit wait lucid for \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-completions \
    nix-community/nix-zsh-completions

zinit wait"0" lucid for \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/completion.zsh \
    OMZ::lib/theme-and-appearance.zsh \
    OMZ::lib/directories.zsh

zinit ice wait"0" lucid id-as"OMZ::lib/brew.plugin.zsh"
zinit snippet ~/.config/zsh/plugins/brew.plugin.zsh

zinit wait'1' lucid from"gh-r" as"program" for junegunn/fzf
zinit wait'1' lucid for OMZ::plugins/fzf
zinit wait'1' lucid for Aloxaf/fzf-tab
zinit wait'1' lucid svn id-as"z" for agkozak/zsh-z

zinit wait"2" lucid for \
    OMZ::plugins/git \
    OMZ::plugins/git-commit \
    OMZ::plugins/gpg-agent \
    wfxr/forgit

# zinit wait"3" lucid for decayofmind/zsh-fast-alias-tips
zinit wait"3" lucid for MichaelAquilina/zsh-you-should-use
zinit wait"3" lucid id-as"pnpm-shell-completion" \
    atload"
        zicompinit
        zicdreplay
        if [[ -s ${ZSH_COMPDUMP} && (! -s ${ZSH_COMPDUMP}.zwc || ${ZSH_COMPDUMP} -nt ${ZSH_COMPDUMP}.zwc) ]]; then
            zcompile ${ZSH_COMPDUMP}
        fi
    " \
    atclone"./zplug.zsh" \
    atpull"%atclone" \
    for g-plane/pnpm-shell-completion

# zinit wait"3" lucid for OMZ::plugins/1password