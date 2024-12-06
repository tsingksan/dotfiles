#!/bin/zsh

# Load performance profiling module
# zmodload zsh/zprof

# 加载各个模块配置
source "$HOME/.config/zsh/xdg_dirs.zsh"
source "$HOME/.config/zsh/proxy.zsh"
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/completion.zsh"
source "$HOME/.config/zsh/zinit.zsh"
source "$HOME/.config/zsh/os_specific.zsh"

source "$HOME/.config/zsh/plugins/zsh-history-manager.plugin.zsh"

setup_directory_navigation() {
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
