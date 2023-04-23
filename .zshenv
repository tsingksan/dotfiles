# ~/.zshenv

# 基本语言设置
export LANG=en_US.UTF-8

# 添加默认编辑器
export EDITOR=nvim

# Oh My Zsh 路径
export ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh"

# Rust 镜像服务器
export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"

# 优先使用 XDG 目录
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"