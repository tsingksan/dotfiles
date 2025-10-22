#!/usr/bin/env bash
# scripts/install-arch.sh - Arch Linux 远程安装脚本
set -e

# 参数
ROOT_DEVICE="${1:?需要 ROOT_DEVICE 参数}"
SWAP_DEVICE="${2:?需要 SWAP_DEVICE 参数}"
BOOT_DEVICE="${3:?需要 BOOT_DEVICE 参数}"
USERNAME="${4:?需要 USERNAME 参数}"
ROOT_PASSWORD="${5:?需要 ROOT_PASSWORD 参数}"
USER_PASSWORD="${6:?需要 USER_PASSWORD 参数}"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_step() {
  printf "${YELLOW}[STEP]${NC} %s\n" "$1"
}

# 挂载分区函数
mount_partitions() {
  local root_dev="$1"
  local swap_dev="$2"
  local boot_dev="$3"
  
  mount -t btrfs -o compress=zstd,subvol=/@ "$root_dev" /mnt
  mkdir -p /mnt/{home,boot}
  mount -t btrfs -o compress=zstd,subvol=/@home "$root_dev" /mnt/home
  mount "$boot_dev" /mnt/boot
  swapon "$swap_dev"
}

# ============================================================================
# 主安装流程
# ============================================================================

log_step "停止 reflector 服务"
systemctl stop reflector.service

log_step "同步系统时间"
timedatectl set-ntp true

log_step "配置镜像源"
cat >/etc/pacman.d/mirrorlist.new <<EOF
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
EOF
cat /etc/pacman.d/mirrorlist >>/etc/pacman.d/mirrorlist.new
mv /etc/pacman.d/mirrorlist.new /etc/pacman.d/mirrorlist

log_step "创建交换分区"
mkswap -L swap "$SWAP_DEVICE"

log_step "格式化 Btrfs 分区"
mkfs.btrfs -f -L arch "$ROOT_DEVICE"

log_step "创建 Btrfs 子卷"
mount -t btrfs -o compress=zstd "$ROOT_DEVICE" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
sleep 1

log_step "挂载分区"
mount_partitions "$ROOT_DEVICE" "$SWAP_DEVICE" "$BOOT_DEVICE"

log_step "更新 keyring"
pacman -Sy --noconfirm archlinux-keyring

log_step "安装基础系统"
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs
pacstrap /mnt networkmanager sudo vim

log_step "生成 fstab"
genfstab -U /mnt >/mnt/etc/fstab

log_step "配置系统（chroot）"
arch-chroot /mnt /bin/bash <<CHROOT_SCRIPT
set -e

# 颜色定义
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    printf "\${GREEN}[INFO]\${NC} %s\n" "\$1"
}

log_info "配置主机名和网络"
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts

log_info "配置时区"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

log_info "配置本地化"
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
sed -i "s/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

log_info "安装引导程序"
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

log_info "安装桌面环境"
pacman -S --noconfirm plasma sddm konsole dolphin ark xorg

log_info "安装显卡驱动"
pacman -S --noconfirm nvidia

log_info "启用服务"
systemctl enable sddm NetworkManager

log_info "配置用户"
echo "root:${ROOT_PASSWORD}" | chpasswd
useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
sed -i 's/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

log_info "安装字体和输入法"
pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra \
    fcitx5-chinese-addons fcitx5-configtool

log_info "安装常用软件"
pacman -S --noconfirm firefox chromium stow git rustup fastfetch

log_info "配置输入法环境"
mkdir -p /home/${USERNAME}/.config/environment.d
echo "XMODIFIERS=@im=fcitx" >> /home/${USERNAME}/.config/environment.d/im.conf
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config

log_info "配置 Rust 环境"
sudo -u ${USERNAME} bash -c "rustup default stable"

log_info "安装 paru AUR 助手"
sudo -u ${USERNAME} bash -c "
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ..
    rm -rf paru
"

log_info "安装 AUR 软件包"
sudo -u ${USERNAME} paru -S --noconfirm mihomo-bin 1password localsend-bin

log_info "系统配置完成"
CHROOT_SCRIPT

log_step "卸载分区"
umount -R /mnt

log_info "安装完成，准备重启..."
reboot
