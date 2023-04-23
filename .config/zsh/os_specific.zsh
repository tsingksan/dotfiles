#!/bin/zsh

setup_macos() {
    export PATH="/opt/homebrew/opt/rustup/bin:/opt/homebrew/opt/postgresql@16/bin:$XDG_DATA_HOME/rbenv/bin:$PATH"

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
    # export PATH="$HOME/.cargo/bin:$PATH"
    export CHROME_EXECUTABLE="/usr/bin/chromium"
    
    alias update='sudo pacman -Syu && yay -Syu'
    alias hh='yarn hardhat'
}

# OS-specific setup
case "$(uname)" in
    Darwin)  setup_macos ;;
    Linux)   [[ -f /etc/arch-release ]] && setup_arch_linux ;;
esac