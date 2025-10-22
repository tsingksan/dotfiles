#!/usr/bin/env bash
set -euo pipefail # strict error handling

OS="$(uname)"
IS_ARCH="$([ -f /etc/arch-release ] && echo 1 || echo 0)"

main() {
  # 检查必要的环境变量
  if [[ -z "${WEB_DAV_USER:-}" ]] || [[ -z "${WEB_DAV_PASSWORD:-}" ]]; then
    echo "ERROR: please set WEB_DAV_USER and WEB_DAV_PASSWORD environment variables"
    exit 1
  fi

  if [[ "$OS" == "Darwin" ]]; then
    brew install mihomo rclone
  else
    sudo pacman -S --noconfirm rclone
    paru -S --noconfirm mihomo-bin
  fi

  rclone config create webdav webdav \
    url=https://webdav.7897897.xyz/ \
    user="$WEB_DAV_USER" \
    pass="$WEB_DAV_PASSWORD"

  if [[ "$OS" == "Darwin" ]]; then
    target_dir="/opt/homebrew/etc/mihomo"
    rclone copy webdav:mihomo "$target_dir"
    brew tap homebrew/services
    sudo brew services start mihomo
  else
    target_dir="/etc/mihomo"
    rclone copy webdav:mihomo "$target_dir"
    sudo systemctl enable mihomo
    sudo systemctl start mihomo
  fi
}

main
