export HISTSIZE=10000        # 内存中的历史条目数
export SAVEHIST=50000        # 持久化存储的历史条目数

setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don\'t record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don\'t record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don\'t write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_NO_STORE             # 不存储 history 命令本身

# https://blog.jasongzy.com/shell-history.html
[ ${BASH_VERSION} ] && PROMPT_COMMAND="mypromptcommand"
[ ${ZSH_VERSION} ] && precmd() { mypromptcommand; }
function mypromptcommand {
    local exit_status=$?
    if [ ${ZSH_VERSION} ]; then
        local number=$(history -1 | awk '{print $1}')
    elif [ ${BASH_VERSION} ]; then
        local number=$(history 1 | awk '{print $1}')
    fi
    # echo $number
    if [ -n "$number" ]; then
        # If the exit status was 127, the command was not found. Let's remove it from history
        if [ $exit_status -eq 127 ] && ([ -z $HISTLASTENTRY ] || [ $HISTLASTENTRY -lt $number ]); then
            local RED='\033[0;31m'
            local NC='\033[0m'
            if [ ${ZSH_VERSION} ]; then
                local HISTORY_IGNORE="${(b)$(fc -ln $number $number)}"
                fc -W
                fc -p $HISTFILE $HISTSIZE $SAVEHIST
            elif [ ${BASH_VERSION} ]; then
                local HISTORY_IGNORE=$(history 1 | awk '{print $2}')
                history -d $number
            fi
            echo -e "${RED}Deleted '$HISTORY_IGNORE' from history.${NC}"
        else
            HISTLASTENTRY=$number
        fi
    fi
}
