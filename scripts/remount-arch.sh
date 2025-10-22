#!/usr/bin/env bash
# scripts/remount-arch.sh - 重新挂载 Arch Linux 分区
set -e

ROOT_DEVICE="${1:?需要 ROOT_DEVICE 参数}"
SWAP_DEVICE="${2:?需要 SWAP_DEVICE 参数}"
BOOT_DEVICE="${3:?需要 BOOT_DEVICE 参数}"

# 颜色定义
GREEN='\033[0;32m'
NC='\033[0m'

printf "${GREEN}[INFO]${NC} 挂载 root 分区...\n"
mount -t btrfs -o compress=zstd,subvol=/@ "$ROOT_DEVICE" /mnt

printf "${GREEN}[INFO]${NC} 创建挂载点...\n"
mkdir -p /mnt/{home,boot}

printf "${GREEN}[INFO]${NC} 挂载 home 分区...\n"
mount -t btrfs -o compress=zstd,subvol=/@home "$ROOT_DEVICE" /mnt/home

printf "${GREEN}[INFO]${NC} 挂载 boot 分区...\n"
mount "$BOOT_DEVICE" /mnt/boot

printf "${GREEN}[INFO]${NC} 启用交换分区...\n"
swapon "$SWAP_DEVICE"

printf "\n${GREEN}挂载信息:${NC}\n"
printf "  Root: %s -> /mnt\n" "$ROOT_DEVICE"
printf "  Home: %s -> /mnt/home\n" "$ROOT_DEVICE"
printf "  Boot: %s -> /mnt/boot\n" "$BOOT_DEVICE"
printf "  Swap: %s\n" "$SWAP_DEVICE"
