#!/bin/bash

# Proxy management functions
proxy() {
    local PROXY_URL="http://127.0.0.1:7890"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    export ALL_PROXY="$PROXY_URL"
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export all_proxy="$PROXY_URL"
    # echo "🌐 Proxy Enabled: $PROXY_URL"
}

noproxy() {
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    unset http_proxy https_proxy all_proxy
    echo "🚫 Proxy Disabled"
}

# Auto-enable proxy if not set
[[ -z "$HTTPS_PROXY" ]] && proxy

# ===== 1. 历史记录增强 =====
# 参考: https://sanctum.geek.nz/arabesque/better-bash-history/
HISTSIZE=10000                  # 历史记录条目数量
HISTFILESIZE=20000              # 历史文件大小
HISTCONTROL=ignoreboth          # 忽略重复命令和空格开头的命令
HISTIGNORE="ls:cd:pwd:exit:clear:history"  # 忽略常用命令
HISTTIMEFORMAT="%F %T "         # 添加时间戳
shopt -s histappend             # 追加而不是覆盖历史文件
PROMPT_COMMAND="history -a"     # 实时保存历史记录

# ===== 2. 按键绑定 =====
# 参考: https://www.gnu.org/software/bash/manual/html_node/Readline-Init-File-Syntax.html
bind '"\e[A": history-search-backward'  # 上箭头搜索历史
bind '"\e[B": history-search-forward'   # 下箭头搜索历史
bind '"\e[1;5C": forward-word'          # Ctrl+Right 向前移动一个词
bind '"\e[1;5D": backward-word'         # Ctrl+Left 向后移动一个词

# ===== 3. 自动补全增强 =====
# 参考: https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# 补全设置
bind "set show-all-if-ambiguous on"     # 显示所有可能的补全
bind "set completion-ignore-case on"    # 忽略大小写
bind "set colored-stats on"             # 彩色显示补全选项

# ===== 4. 目录操作增强 =====
# 参考: https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/directories.zsh
shopt -s autocd      # 允许直接输入目录名进入目录
shopt -s cdspell     # 修正目录名拼写错误

# 目录导航别名
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias md='mkdir -p'
alias rd='rmdir'

# 目录栈
alias d='dirs -v'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'

# ===== 5. FZF 集成 =====
# 参考: https://github.com/junegunn/fzf
# 需要安装: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install

# 加载 FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# FZF 配置
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/\.git/*'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="find . -type d -not -path '*/\.git/*'"

# ===== 常用别名 =====
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -la'
alias grep='grep --color=auto'

# ===== 漂亮的提示符 =====
# 参考: https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
# 在提示符中显示 Git 分支
parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;33m\]$(parse_git_branch)\[\033[00m\]\$ '

# ===== 更健壮的 FZF-Tab 功能 =====
# 修复了之前的 fzf_complete_cd 功能

# 使用 FZF 进行目录完成
_fzf_compgen_path() {
    find . -type f -not -path "*/\.git/*" 2> /dev/null
}

_fzf_compgen_dir() {
    find . -type d -not -path "*/\.git/*" 2> /dev/null
}

# 目录补全的FZF增强版本
_fzf_complete_cd() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local dirs
    
    # 如果有指定基础路径，则从该路径开始搜索；否则从当前目录搜索
    local base_dir="${cur%/*}"
    if [[ "$base_dir" == "$cur" ]]; then
        base_dir="."
    elif [[ -z "$base_dir" ]]; then
        base_dir="/"
    fi
    
    # 使用 find 命令查找目录
    dirs=$(find "$base_dir" -type d -not -path "*/\.git/*" 2>/dev/null | sort)
    
    if [[ -n "$dirs" ]]; then
        # 如果找到目录，使用 fzf 过滤
        local selected
        selected=$(echo "$dirs" | fzf --query="$cur" --select-1 --exit-0)
        if [[ -n "$selected" ]]; then
            # 替换当前单词为选中的目录
            COMPREPLY=("$selected")
        fi
    else
        # 如果没有找到任何目录，则使用默认补全
        COMPREPLY=($(compgen -d -- "$cur"))
    fi
    
    return 0
}

# 注册 cd 命令的补全函数
complete -o nospace -F _fzf_complete_cd cd

# 如果要对其他命令也使用FZF补全，可以类似地添加
# complete -o default -F _fzf_complete_<command> <command>