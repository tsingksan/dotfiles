#!/usr/bin/env bash
set -euo pipefail # strict error handling

OS="$(uname)"
IS_ARCH="$([ -f /etc/arch-release ] && echo 1 || echo 0)"

setup_dotfiles_repo() {
  local repo_dir="$XDG_CONFIG_HOME/dotfiles"

  if [[ ! -d "$repo_dir" ]] || [[ -z "$(ls -A "$repo_dir" 2>/dev/null)" ]]; then
    git clone https://github.com/tsingksan/dotfiles.git "$repo_dir"
  else
    git -C "$repo_dir" pull
  fi

  cd "$repo_dir"
  stow -D . -t ~ && stow . -t ~

  local mihomo_dir="$XDG_CONFIG_HOME/mihomo"

  if [[ ! -d "$mihomo_dir/.git" ]]; then
    git clone git@github.com:tsingksan/Profile.git "$mihomo_dir"
  else
    git -C "$mihomo_dir" pull
  fi

  if [ "$OS" = "Darwin" ]; then
    [[ -d "/opt/homebrew/etc/mihomo" ]] && mv "/opt/homebrew/etc/mihomo" "/opt/homebrew/etc/mihomo.bak" 2>/dev/null || true
    sudo mkdir -p "/opt/homebrew/etc/mihomo"
    cd "$mihomo_dir"
    stow . -t "/opt/homebrew/etc/mihomo"
  elif [ "$IS_ARCH" = "1" ]; then
    [[ -d "/etc/mihomo" ]] && sudo mv "/etc/mihomo" "/etc/mihomo.bak" 2>/dev/null || true
    sudo mkdir -p "/etc/mihomo"
    cd "$mihomo_dir"
    sudo stow . -t "/etc/mihomo"
  fi
}

setup_gpg() {
  mkdir -p "$HOME/.ssh" "$HOME/.gnupg"
  chmod 700 "$HOME/.gnupg"

  local gpg_conf="$HOME/.gnupg/gpg-agent.conf"
  if ! grep -q "^pinentry-program" "$gpg_conf" 2>/dev/null; then
    case "$OS" in
    Darwin)
      echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >>"$gpg_conf"
      ;;
    Linux)
      [[ "$IS_ARCH" == "1" ]] &&
        echo "pinentry-program /usr/bin/pinentry" >>"$gpg_conf"
      ;;
    esac
  fi

  # killall gpg-agent 2>/dev/null || true
  # gpg-agent --daemon --enable-ssh-support

  gpg-connect-agent reloadagent /bye
  export GPG_TTY=$(tty)
  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  gpgconf --launch gpg-agent

  if ssh -T git@github.com 2>/dev/null; then
    cd "$XDG_CONFIG_HOME/dotfiles" && git remote set-url origin git@github.com:tsingksan/dotfiles.git
  fi
}

setup_alacritty() {
  local config_dir="$XDG_CONFIG_HOME/alacritty"
  mkdir -p "$config_dir"

  # 备份现有配置（如果不是符号链接）
  if [[ -f "$config_dir/alacritty.toml" ]] && [[ ! -L "$config_dir/alacritty.toml" ]]; then
    mv "$config_dir/alacritty.toml" "$config_dir/alacritty.toml.backup.$(date +%Y%m%d_%H%M%S)"
  fi

  # 创建符号链接
  local source_file="arch.toml"
  [[ "$OS" == "Darwin" ]] && source_file="mac.toml"
  ln -sf "$XDG_CONFIG_HOME/dotfiles/.config/alacritty/$source_file" \
    "$config_dir/alacritty.toml"
}

change_shell() {
  local current_shell=$(basename "$(grep "^${USER}:" /etc/passwd | cut -d: -f7)")
  if [[ "$current_shell" != "zsh" ]]; then
    chsh -s "$(command -v zsh)"
  fi
}

# macOS 特定配置
setup_konsole_macos() {
  if [[ "$OS" == "Darwin" ]]; then
    # 备份现有配置
    [[ -f "$HOME/Library/Preferences/konsolerc" ]] && \
      mv "$HOME/Library/Preferences/konsolerc" "$HOME/Library/Preferences/konsolerc.backup" 2>/dev/null || true
    [[ -d "$HOME/Library/Application Support/konsole" ]] && \
      mv "$HOME/Library/Application Support/konsole" "$HOME/Library/Application Support/konsole.backup" 2>/dev/null || true
    
    mkdir -p "$HOME/Library/Application Support"
    ln -sf "$XDG_CONFIG_HOME/dotfiles/.config/konsolerc" "$HOME/Library/Preferences/konsolerc"
    ln -sf "$XDG_CONFIG_HOME/dotfiles/.local/share/konsole" "$HOME/Library/Application Support/konsole"
  fi
}

# 主流程
main() {
  setup_dotfiles_repo
  setup_gpg
  setup_konsole_macos
  setup_alacritty
  change_shell
}

main
