#!/bin/sh

if [ "$(uname)" = "Darwin" ]; then
    # printf "%bSetting up for %bMacos Darwin%b\n" "${BLUE}" "${RED}" "${NC}"

    printf "%bIntsalling utils and app %b\n" "${BLUE}" "${NC}"
    brew install neofetch mise htop
    brew install --cask 1password appcleaner brave-browser chatgpt cursor firefox fork kitty maccy rectangle snipaste spotify telegram visual-studio-code wechat

elif [ "$(uname -o)" = "GNU/Linux" ]; then
    if [ -f /etc/arch-release ]; then
        # sudo pacman -S 
        echo '需要下载的'
    fi
fi