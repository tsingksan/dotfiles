# 确保使用 XDG 规范的路径
[[ -d "${XDG_STATE_HOME}/zsh" ]] || mkdir -p "${XDG_STATE_HOME}/zsh"
HISTFILE="${XDG_STATE_HOME}/zsh/history"

# 扩展历史选项
setopt EXTENDED_HISTORY        # 存储命令的时间戳和持续时间
setopt HIST_EXPIRE_DUPS_FIRST  # 当历史记录已满时，首先删除重复项
setopt HIST_FIND_NO_DUPS       # 搜索历史时不显示重复项
setopt HIST_IGNORE_ALL_DUPS    # 添加新条目时删除旧的重复条目
setopt HIST_IGNORE_DUPS        # 不添加连续的重复条目
setopt HIST_IGNORE_SPACE       # 不保存以空格开头的命令
setopt HIST_REDUCE_BLANKS      # 删除命令中不必要的空白
setopt HIST_SAVE_NO_DUPS       # 不保存重复的命令
# setopt INC_APPEND_HISTORY      #  
# setopt INC_APPEND_HISTORY_TIME #
setopt SHARE_HISTORY           # 在所有打开的 shell 间共享历史记录

# 条件性提示命令设置
[ ${BASH_VERSION} ] && PROMPT_COMMAND="mypromptcommand"
[ ${ZSH_VERSION} ] && precmd() { mypromptcommand; }

# 自定义历史管理函数
function mypromptcommand {
    local exit_status=$?
    local number
    
    # 根据 shell 类型获取最后一个命令的编号
    if [ ${ZSH_VERSION} ]; then
        number=$(history -1 | awk '{print $1}')
    elif [ ${BASH_VERSION} ]; then
        number=$(history 1 | awk '{print $1}')
    fi
    
    # 从历史记录中删除未找到命令的条目
    if [ -n "$number" ]; then
        if [ $exit_status -eq 127 ] && ([ -z $HISTLASTENTRY ] || [ $HISTLASTENTRY -lt $number ]); then
            local RED='\033[0;31m'
            local NC='\033[0m'
            
            local HISTORY_IGNORE
            if [ ${ZSH_VERSION} ]; then
                HISTORY_IGNORE="${(b)$(fc -ln $number $number)}"
                fc -W
                fc -p $HISTFILE $HISTSIZE $SAVEHIST
            elif [ ${BASH_VERSION} ]; then
                HISTORY_IGNORE=$(history 1 | awk '{print $2}')
                history -d $number
            fi
            
            echo -e "${RED}Removed from history: '$HISTORY_IGNORE'。${NC}"
        else
            HISTLASTENTRY=$number
        fi
    fi
}

export HISTORY_IGNORE="(ls|pwd|z *|pnpm *|cd *|.*)"