#!/bin/sh
# reference https://github.com/josepharhar/dotfiles
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        true # 命令存在
    else
        false # 命令不存在
    fi
}

printf "%bIntsalling zinit%b\n" "${BLUE}" "${NC}"
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

if [ "$(uname)" = "Darwin" ]; then
    printf "%bSetting up for %bMacos Darwin%b\n" "${BLUE}" "${RED}" "${NC}"

    printf "%bIntsalling brew%b\n" "${BLUE}" "${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    printf "%bIntsalling neovim%b\n" "${BLUE}" "${NC}"
    brew install neovim

    printf "%bIntsalling git%b\n" "${BLUE}" "${NC}"
    brew install git

    printf "%bIntsalling gnupg%b\n" "${BLUE}" "${NC}"
    brew install gnupg

    printf "%bIntsalling pinentry-mac%b\n" "${BLUE}" "${NC}"
    brew install pinentry-mac

    printf "%bIntsalling stow%b\n" "${BLUE}" "${NC}"
    brew install stow

    printf "%bIntsalling fira-code%b\n" "${BLUE}" "${NC}"
    brew install font-fira-code-nerd-font font-fira-mono-nerd-font

elif [ "$(uname -o)" = "GNU/Linux" ]; then
    if [ -f /etc/arch-release ]; then

        printf "%bIntsalling zsh%b\n" "${BLUE}" "${NC}"
        sudo pacman -S zsh && chsh -s "$(which zsh)"

        printf "%bIntsalling neovim%b\n" "${BLUE}" "${NC}"
        sudo pacman -S neovim

        printf "%bIntsalling git%b\n" "${BLUE}" "${NC}"
        sudo pacman -S git

        printf "%bIntsalling pinentry-mac%b\n" "${BLUE}" "${NC}"
        sudo pacman -S pinentry

        printf "%bIntsalling stow%b\n" "${BLUE}" "${NC}"
        sudo pacman -S stow

        printf "%bIntsalling fira-code%b\n" "${BLUE}" "${NC}"
        sudo pacman -S ttf-firacode-nerd otf-firamono-nerd

        installYay() {
            printf "%bIntsalling yay%b\n" "${BLUE}" "${NC}"
            sudo pacman -S --needed base-devel
            git clone https://aur.archlinux.org/yay-bin.git
            cd yay-bin || exit
            makepkg -si
            rm -rf yay-bin
        }
        if ! check_command yay; then
            installYay
        fi
    fi
fi

# XDG_DATA_HOME="$HOME/.local/share"
# printf "%bIntsalling ohmyzsh%b\n" "${BLUE}" "${NC}"
# [ ! -d "$XDG_DATA_HOME/.oh-my-zsh" ] && git clone https://github.com/ohmyzsh/ohmyzsh.git "$XDG_DATA_HOME/oh-my-zsh"

# OMZ_PLUGINS_DIRS="${ZSH_CUSTOM:-$XDG_DATA_HOME/oh-my-zsh/custom}/plugins"
# printf "%bIntsalling plugin fzf-tab %b\n" "${BLUE}" "${NC}"
# [ ! -d "${OMZ_PLUGINS_DIRS}/fzf-tab" ] && git clone https://github.com/Aloxaf/fzf-tab "${OMZ_PLUGINS_DIRS}/fzf-tab"

# printf "%bIntsalling plugin forgit %b\n" "${BLUE}" "${NC}"
# [ ! -d "${OMZ_PLUGINS_DIRS}/forgit" ] && git clone https://github.com/wfxr/forgit.git "${OMZ_PLUGINS_DIRS}/forgit"

# printf "%bIntsalling plugin pnpm-shell-completion %b\n" "${BLUE}" "${NC}"
# [ ! -d "${OMZ_PLUGINS_DIRS}/pnpm-shell-completion" ] && git clone https://github.com/g-plane/pnpm-shell-completion.git "${OMZ_PLUGINS_DIRS}/pnpm-shell-completion"
# git clone https://github.com/zsh-users/zsh-autosuggestions "${OMZ_PLUGINS_DIRS}/zsh-autosuggestions"
# git clone https://github.com/zsh-users/zsh-completions "${OMZ_PLUGINS_DIRS}/zsh-completions"

echo "cloning dotfiles"
XDG_CONFIG_HOME="$HOME"/.config
git clone https://github.com/tsingksan/dotfiles.git "$XDG_CONFIG_HOME"/dotfiles

echo "ln dotfiles"
[ ! -d "$HOME"/.ssh ] && mkdir "$HOME"/.ssh
[ ! -d "$HOME"/.gnupg ] && mkdir "$HOME"/.gnupg

cd "$XDG_CONFIG_HOME/dotfiles" || exit
stow . -t ~
# stow --override --delete -t ~

echo "installing alacritty"
if [ -f "$HOME"/.config/alacritty/alacritty.toml ]; then
    echo "found old config/alacritty/alacritty.toml, backing up to .config/alacritty/alacritty.toml.backup"
    mv "$HOME"/.config/alacritty/alacritty.toml "$HOME"/.config/alacritty/alacritty.toml.backup
fi
if [ "$(uname)" = "Darwin" ]; then
    ln -s "$XDG_CONFIG_HOME"/dotfiles/.config/alacritty/mac.toml "$HOME"/.config/alacritty/alacritty.toml
elif [ "$(uname -o)" = "GNU/Linux" ]; then
    if [ -f /etc/arch-release ]; then
        ln -s "$XDG_CONFIG_HOME"/dotfiles/.config/alacritty/arch.toml "$HOME"/.config/alacritty/alacritty.toml
    fi
fi

chmod +x "$XDG_CONFIG_HOME/dotfiles/bin/pinentry-wrapper"
