#!/bin/zsh

setup_macos() {
    export PATH="$PATH"
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