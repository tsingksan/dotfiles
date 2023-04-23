#!/bin/zsh

# ╭─────────────────────────────────────────────────────────────────╮
# │                     Zsh Configuration File                       │
# │                   Organized and Optimized Setup                 │
# ╰─────────────────────────────────────────────────────────────────╯

# ┌─────────────────────────────────────────────────────────────────┐
#                       🌐 Global Settings
# └─────────────────────────────────────────────────────────────────┘
export LANG=en_US.UTF-8
export ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh"
export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"

# Load performance profiling module
zmodload zsh/zprof

# ┌─────────────────────────────────────────────────────────────────┐
#                       🌐 Proxy Management 
# └─────────────────────────────────────────────────────────────────┘
# Convenient proxy toggle functions
proxy() {
    local PROXY_URL="http://127.0.0.1:7890"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    export ALL_PROXY="$PROXY_URL"
    # echo "🌐 Proxy Enabled: $PROXY_URL"
}

noproxy() {
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    echo "🚫 Proxy Disabled"
}

# Auto-enable proxy if not set
[[ -z "$HTTPS_PROXY" ]] && proxy

# ┌─────────────────────────────────────────────────────────────────┐
#                    📂 XDG Directory Management
# └─────────────────────────────────────────────────────────────────┘
setup_xdg_dirs() {
    # Standardize config and data directories
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

    # Tool-specific XDG configurations
    export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
    export CARGO_HOME="$XDG_DATA_HOME/cargo"
    export GOPATH="$XDG_DATA_HOME/go"
    export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
    export RBENV_ROOT="$XDG_DATA_HOME/rbenv"
    export BUN_INSTALL="$XDG_DATA_HOME/bun"
    export N_PREFIX="$XDG_DATA_HOME/n"
    export _Z_DATA="$XDG_DATA_HOME/z"
    export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
    alias yarn='yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'
    export PSQLRC="$XDG_CONFIG_HOME/pg/psqlrc"
    export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"
    export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"
    export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"

    export PATH="$XDG_DATA_HOME/npm/bin:$PATH"
}

# ┌─────────────────────────────────────────────────────────────────┐
#                   🔌 Zinit Plugin Management
# └─────────────────────────────────────────────────────────────────┘
setup_zinit() {
    declare -x -A ZINIT
    ZINIT[HOME_DIR]="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
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

    # Plugin Categories
    _load_core_plugins
    _load_essential_tools
    _load_navigation_plugins
    _load_git_tools
    _load_dev_tools
    _load_package_managers
}

# Plugin Loading Functions
_load_core_plugins() {
    zinit lucid for OMZP::starship
}

_load_essential_tools() {
    zinit wait'0a' lucid for \
        atload"zicompinit; zicdreplay" OMZP::fzf \
        id-as"fzf-tab" Aloxaf/fzf-tab \
        \id-as"fast-syntax-highlighting" \
        \atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting
}

_load_navigation_plugins() {
    zinit wait'0b' lucid for \
        \atinit"zstyle ':completion:*' menu select" \
        \id-as"z" agkozak/zsh-z
}

_load_git_tools() {
    zinit wait'1a' lucid for \
        OMZP::git \
        OMZP::git-commit \
        OMZP::gpg-agent \
        id-as"forgit" wfxr/forgit
}

_load_dev_tools() {
    zinit wait'1b' lucid for \
        OMZP::1password \
        atload"mise activate zsh &>/dev/null" OMZP::mise
}

_load_package_managers() {
    zinit wait'1c' lucid for \
        \id-as"pnpm-shell-completion" \
        \nocompile"#!/*" \
        \atload"zpcdreplay" \
        \atclone"./zplug.zsh" \
        \atpull"%atclone" g-plane/pnpm-shell-completion
}

# ┌─────────────────────────────────────────────────────────────────┐
#                   🚀 Directory Navigation Helpers
# └─────────────────────────────────────────────────────────────────┘
setup_directory_navigation() {
    # Quick home navigation
    alias home='cd ~'

    # Multi-level directory up navigation
    for i in {1..5}; do
        alias $(printf '.%.0s' $(seq $i))="cd $(printf '../%.0s' $(seq $i))"
    done

    # Auto list directory contents after cd
    function cd() {
        builtin cd "$@" && ls
    }
}

# ┌─────────────────────────────────────────────────────────────────┐
#                   📋 Shell Completion Configuration
# └─────────────────────────────────────────────────────────────────┘
setup_shell_completion() {
    # History and cache directories
    HISTFILE="$XDG_STATE_HOME/zsh/history"
    mkdir -p "$(dirname "$HISTFILE")"
    mkdir -p "$XDG_CACHE_HOME/zsh"

    # Completion cache and dump configuration
    zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
    export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

    # Smart completion initialization
    autoload -Uz compinit
    _setup_intelligent_completion
}

_setup_intelligent_completion() {
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
}

# ┌─────────────────────────────────────────────────────────────────┐
#                   🖥️ OS-Specific Configurations
# └─────────────────────────────────────────────────────────────────┘
setup_macos() {
    export PATH="/opt/homebrew/opt/rustup/bin:$XDG_DATA_HOME/rbenv/bin:$PATH"

    # Lazy rbenv loading
    _rbenv_lazy_init() {
        unset -f ruby gem irake bundle
        eval "$(rbenv init -)"
    }

    for cmd in ruby gem irake bundle; do
        eval "function $cmd() { _rbenv_lazy_init; $cmd \"\$@\" }"
    done
}

setup_arch_linux() {
    export PATH="$HOME/.cargo/bin:$PATH"
    export CHROME_EXECUTABLE="/usr/bin/chromium"
    
    alias update='sudo pacman -Syu && yay -Syu'
    alias hh='yarn hardhat'
}

# ┌─────────────────────────────────────────────────────────────────┐
#                   🚀 Main Initialization
# └─────────────────────────────────────────────────────────────────┘
main() {
    setup_xdg_dirs
    setup_directory_navigation
    setup_shell_completion
    source "$ZSH/oh-my-zsh.sh"

    # OS-specific setup
    case "$(uname)" in
        Darwin)  setup_macos ;;
        Linux)   [[ -f /etc/arch-release ]] && setup_arch_linux ;;
    esac

    setup_zinit
}

# Launch the configuration
main