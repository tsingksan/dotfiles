export EDITOR="nvim"
export GNUPGHOME="$HOME/.gnupg"
export LANG="en_US.UTF-8"
export PAGER="less -FiSwX"
export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
path=(
    "$HOME/.local/share/npm/bin"
    "$HOME/.local/share/pnpm"
    "$HOME/.local/share/go/bin"
    $path
)
if [[ -z "$SSH_AUTH_SOCK" ]]; then
  export SSH_AUTH_SOCK=$$(gpgconf --list-dirs agent-ssh-socket);
fi


if [[ "$(uname)" = "Darwin" ]]; then
    path=(
        /opt/homebrew/bin
        /opt/homebrew/sbin
        /usr/local/bin
        /opt/homebrew/Cellar/rustup/1.27.1_1/bin
        /opt/homebrew/opt/ruby/bin
        /opt/homebrew/opt/postgresql@17/bin
        $path
    )
fi

if [[ "$(uname -o)" = "GNU/Linux" ]]; then
    # export PATH="$PATH${PATH:+:}/opt/homebrew/bin/"
fi
