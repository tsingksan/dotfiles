#!/bin/zsh

# Load performance profiling module
zmodload zsh/zprof

# 加载各个模块配置
source "$HOME/.config/zsh/xdg_dirs.zsh"
source "$HOME/.config/zsh/proxy.zsh"
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/completion.zsh"
source "$HOME/.config/zsh/zinit.zsh"
source "$HOME/.config/zsh/os_specific.zsh"

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

main() {
    setup_directory_navigation
}

# Launch the configuration
main
