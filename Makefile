.PHONY: all macos arch dotfiles archinstall remount install-common

# 通用配置变量
SSH_OPTIONS = -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
ARCHADDR ?= unset
ARCHPORT ?= 22
ROOT_PASSWORD ?= 123
USER_PASSWORD ?= 123
USERNAME ?= tsingksan

# XDG 配置目录
XDG_CONFIG_HOME ?= $(HOME)/.config

# 系统识别
OS := $(shell uname)

# 颜色定义
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m  # No Color (用于重置颜色)

# 日志输出函数
define log_info
    echo -e "$(GREEN)[INFO]$(NC) $(1)"
endef

define log_warn
    echo -e "$(YELLOW)[WARN]$(NC) $(1)"
endef

define log_error
    echo -e "$(RED)[ERROR]$(NC) $(1)" >&2
endef

# 定义挂载子卷的命令
define MOUNT_SUBVOLS
mount -t btrfs -o compress=zstd,subvol=/@ /dev/nvme0n1p6 /mnt && \
mkdir -p /mnt/{home,boot} && \
mount -t btrfs -o compress=zstd,subvol=/@home /dev/nvme0n1p6 /mnt/home && \
mount /dev/nvme0n1p1 /mnt/boot && \
swapon /dev/nvme0n1p5
endef

# macOS 软件列表
BREW_CASKS := font-fira-code-nerd-font font-fira-mono-nerd-font \
	1password keepassxc maccy snipaste brave-browser \
	chatgpt thunderbird@esr typora visual-studio-code cursor fork \
	insomnium bruno telegram wechat wechatwork localsend ddpm logi-options+ \
	spotify docker appcleaner

BREW_FORMULAE := nvim tmux rustup zig zls go python@3 \
	deno node@22 fastfetch htop

# Arch Linux 软件列表
ARCH_PACMAN := pinentry openssh zsh htop fastfetch neovim \
	ttf-firacode-nerd otf-firamono-nerd docker zig zls go python nodejs-lts-jod \
	handbrake

ARCH_AUR := brave-bin sourcegit-bin bruno-bin visual-studio-code-bin cursor-bin insomnium-bin

# 默认目标
all:
	$(call log_info,"请选择目标: archinstall, macos, arch, dotfiles, remount")

# Arch Linux 安装
archinstall:
	$(call log_info,"开始安装 Arch Linux...")
	ssh $(SSH_OPTIONS) -p $(ARCHPORT) root@$(ARCHADDR) "\
	set -e; \
	\
	# 停止reflector服务并设置时间同步\
	systemctl stop reflector.service && \
	timedatectl set-ntp true && \
	\
	# 配置中国镜像源\
	echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$$repo/os/\$$arch\nServer = https://mirrors.ustc.edu.cn/archlinux/\$$repo/os/\$$arch' > /etc/pacman.d/mirrorlist.new && \
	cat /etc/pacman.d/mirrorlist >> /etc/pacman.d/mirrorlist.new && \
	mv /etc/pacman.d/mirrorlist.new /etc/pacman.d/mirrorlist && \
	\
	# 格式化和挂载分区\
	echo '正在准备分区...' && \
	mkswap -L swap /dev/nvme0n1p5 && \
	mkfs.btrfs -f -L arch /dev/nvme0n1p6 && \
	mount -t btrfs -o compress=zstd /dev/nvme0n1p6 /mnt && \
	\
	# 创建btrfs子卷\
	echo '创建btrfs子卷...' && \
	btrfs subvolume create /mnt/@ && \
	btrfs subvolume create /mnt/@home && \
	umount /mnt && \
	sleep 1 && \
	\
	# 重新挂载子卷\
	echo '重新挂载子卷...' && \
	$(MOUNT_SUBVOLS) && \
	\
	# 安装基本系统\
	echo '安装基本系统...' && \
	pacman -Sy --noconfirm archlinux-keyring && \
	pacstrap /mnt base base-devel linux linux-firmware btrfs-progs && \
	pacstrap /mnt networkmanager sudo vim && \
	genfstab -U /mnt > /mnt/etc/fstab && \
	\
	# 进入chroot环境配置系统\
	echo '开始系统配置...' && \
	arch-chroot /mnt /bin/bash -c '\
	set -e && \
	\
	# 网络和时区配置\
	echo \"127.0.0.1 localhost\" > /etc/hosts && \
	echo \"::1 localhost\" >> /etc/hosts && \
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	hwclock --systohc && \
	\
	# 语言设置\
	sed -i \"s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/\" /etc/locale.gen && \
	sed -i \"s/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/\" /etc/locale.gen && \
	locale-gen && \
	echo \"LANG=en_US.UTF-8\" > /etc/locale.conf && \
	\
	# 安装和配置引导程序\
	pacman -S --noconfirm grub efibootmgr os-prober && \
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH && \
	sed -i \"s/GRUB_CMDLINE_LINUX_DEFAULT=\\\"loglevel=3 quiet\\\"/GRUB_CMDLINE_LINUX_DEFAULT=\\\"loglevel=5 nowatchdog\\\"/\" /etc/default/grub && \
	grub-mkconfig -o /boot/grub/grub.cfg && \
	\
	# 安装桌面环境\
	pacman -S --noconfirm plasma sddm konsole dolphin ark xorg && \
	pacman -S --noconfirm nvidia && \
	systemctl enable --now sddm NetworkManager && \
	\
	# 创建用户和设置权限\
	echo \"root:$(ROOT_PASSWORD)\" | chpasswd && \
	useradd -m -G wheel -s /bin/bash $(USERNAME) && \
	echo \"$(USERNAME):$(USER_PASSWORD)\" | chpasswd && \
	sed -i \"s/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/\" /etc/sudoers && \
	\
	# 安装常用软件\
	pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra fcitx5-chinese-addons fcitx5-configtool firefox chromium stow git rustup fastfetch && \
	\
	# 配置中文输入法\
	mkdir -p /home/$(USERNAME)/.config/environment.d && \
	echo \"GTK_IM_MODULE=fcitx\" > /home/$(USERNAME)/.config/environment.d/im.conf && \
	echo \"QT_IM_MODULE=fcitx\" >> /home/$(USERNAME)/.config/environment.d/im.conf && \
	echo \"XMODIFIERS=@im=fcitx\" >> /home/$(USERNAME)/.config/environment.d/im.conf && \
	chown -R $(USERNAME):$(USERNAME) /home/$(USERNAME)/.config && \
	\
	# 以用户身份安装rust和AUR助手\
	sudo -u $(USERNAME) bash -c \"rustup default stable && \
		cd /tmp && \
		git clone https://aur.archlinux.org/paru.git && \
		cd paru && \
		makepkg -si --noconfirm && \
		cd .. && \
		rm -rf paru\" && \
	\
	# 使用paru安装其他软件\
	sudo -u $(USERNAME) paru -S --noconfirm mihomo-bin 1password localsend-bin \
	' && \
	\
	# 卸载分区并重启\
	echo '完成安装，准备重启...' && \
	umount -R /mnt && \
	reboot \
	"
	$(call log_info,"安装命令已发送，系统将重启完成安装")

# 单独的重新挂载任务
remount:
	$(call log_info,"重新挂载分区...")
	ssh $(SSH_OPTIONS) -p $(ARCHPORT) root@$(ARCHADDR) "$(MOUNT_SUBVOLS)"
	$(call log_info,"挂载完成")

# macOS 配置
macos:
	$(call log_info,"开始配置 macOS 环境...")
	@if [ "$$EUID" -eq 0 ]; then \
		$(call log_error,"不能以 root 用户运行此脚本"); \
		exit 1; \
	fi

	@if ! command -v brew >/dev/null 2>&1; then \
		$(call log_info,"正在安装 Homebrew..."); \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		eval "$$(/opt/homebrew/bin/brew shellenv)"; \
	fi
	
	$(call log_info,"安装基础工具...")
	@for tool in stow gnupg pinentry-mac mihomo; do \
		if ! brew list $$tool &>/dev/null; then \
			$(call log_info,"安装 $$tool..."); \
			brew install $$tool; \
		else \
			$(call log_info,"$$tool 已安装"); \
		fi \
	done
	
	$(call log_info,"配置 mihomo 服务...")
	@brew tap homebrew/services
	@brew services restart mihomo || brew services start mihomo
	
	$(call log_info,"安装 Cask 应用...")
	@for app in $(BREW_CASKS); do \
		if ! brew list --cask $$app &>/dev/null; then \
			$(call log_info,"安装 $$app..."); \
			brew install --cask $$app || $(call log_warn,"$$app 安装失败，继续..."); \
		else \
			$(call log_info,"$$app 已安装"); \
		fi \
	done
	
	$(call log_info,"安装开发工具...")
	@for tool in $(BREW_FORMULAE); do \
		if ! brew list $$tool &>/dev/null; then \
			$(call log_info,"安装 $$tool..."); \
			brew install $$tool || $(call log_warn,"$$tool 安装失败，继续..."); \
		else \
			$(call log_info,"$$tool 已安装"); \
		fi \
	done
	
	@$(MAKE) dotfiles
	$(call log_info,"macOS 环境配置完成")

# Arch Linux 配置
arch:
	$(call log_info,"开始配置 Arch Linux 环境...")
	@sudo pacman -Syu --noconfirm
	
	$(call log_info,"安装必要工具...")
	@for pkg in $(ARCH_PACMAN); do \
		if ! pacman -Q $$pkg &>/dev/null; then \
			$(call log_info, "安装 $$pkg..."); \
			sudo pacman -S --noconfirm $$pkg || $(call log_warn, "$$pkg 安装失败，继续..."); \
		else \
			$(call log_info, "$$pkg 已安装"); \
		fi \
	done
	
	$(call log_info,"安装 AUR 应用...")
	@if ! command -v paru >/dev/null 2>&1; then \
		$(call log_error,"请先安装 paru AUR 助手"); \
		exit 1; \
	fi

	@for pkg in $(ARCH_AUR); do \
		if ! pacman -Q $$pkg &>/dev/null; then \
			$(call log_info,"安装 $$pkg..."); \
			paru -S --noconfirm $$pkg || $(call log_warn,"$$pkg 安装失败，继续..."); \
		else \
			$(call log_info,"$$pkg 已安装"); \
		fi \
	done

	@$(MAKE) dotfiles
	$(call log_info,"Arch Linux 环境配置完成")

# dotfiles 配置
dotfiles:
	$(call log_info,"开始配置 dotfiles...")
	@mkdir -p "$(XDG_CONFIG_HOME)"

	@if [ ! -d "$(XDG_CONFIG_HOME)/dotfiles" ] || [ -z "$$(ls -A $(XDG_CONFIG_HOME)/dotfiles 2>/dev/null)" ]; then \
		$(call log_info,"克隆 dotfiles 仓库..."); \
		git clone https://github.com/tsingksan/dotfiles.git "$(XDG_CONFIG_HOME)/dotfiles" || \
		{ $(call log_error,"克隆 dotfiles 失败"); exit 1; }; \
	else \
		$(call log_info,"更新 dotfiles 仓库..."); \
		git -C "$(XDG_CONFIG_HOME)/dotfiles" pull; \
	fi

	@if ! command -v stow >/dev/null 2>&1; then \
		$(call log_error,"请先安装 stow"); \
		exit 1; \
	fi
	
	$(call log_info,"应用 dotfiles 配置...")
	@cd "$(XDG_CONFIG_HOME)/dotfiles" && stow -D . -t ~ && stow . -t ~ || { $(call log_error,"stow 操作失败"); exit 1; }

	$(call log_info,"配置 GPG 和 SSH agent...")
	@mkdir -p "$$HOME/.ssh" "$$HOME/.gnupg"
	@chmod 700 "$$HOME/.gnupg"
	@if ! grep -q "^pinentry-program" "$$HOME/.gnupg/gpg-agent.conf" 2>/dev/null; then \
		if [ "$(OS)" = "Darwin" ]; then \
			echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >> "$$HOME/.gnupg/gpg-agent.conf"; \
			$(call log_info, "已配置 macOS GPG pinentry"); \
		elif [ "$$(uname -o 2>/dev/null)" = "GNU/Linux" ] && [ -f /etc/arch-release ]; then \
			echo "pinentry-program /usr/bin/pinentry" >> "$$HOME/.gnupg/gpg-agent.conf"; \
			$(call log_info, "已配置 Arch Linux GPG pinentry"); \
		fi \
	fi


	# @killall gpg-agent 2>/dev/null || true
	# @gpg-agent --daemon --enable-ssh-support

	$(call log_info,"重启 GPG Agent...")
	@gpg-connect-agent reloadagent /bye
	@export GPG_TTY=$$(tty)
	@export SSH_AUTH_SOCK=$$(gpgconf --list-dirs agent-ssh-socket)
	@gpgconf --launch gpg-agent

	$(call log_info,"检查 GitHub SSH 配置...")
	@if ! ssh -T git@github.com 2>/dev/null; then \
		$(call log_info,"切换 dotfiles 仓库到 SSH 地址..."); \
		cd "$(XDG_CONFIG_HOME)/dotfiles" && git remote set-url origin git@github.com:tsingksan/dotfiles.git; \
	else \
		$(call log_warn,"GitHub SSH 密钥未配置，请先配置 SSH 密钥"); \
	fi

	@if [ "$(OS)" = "Darwin" ]; then \
		$(call log_info,"配置 Konsole \(macOS\)..."); \
		rm -rf "$$HOME/Library/Preferences/konsolerc" "$$HOME/Library/Application Support/konsole"; \
		mkdir -p "$$HOME/Library/Application Support"; \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.config/konsolerc" "$$HOME/Library/Preferences/konsolerc"; \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.local/share/konsole" "$$HOME/Library/Application Support"; \
	fi

	$(call log_info,"配置 Alacritty...")
	@mkdir -p "$(XDG_CONFIG_HOME)/alacritty"
	@if [ -f "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml" ] && [ ! -L "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml" ]; then \
		mv "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml.backup"; \
		$(call log_info,"已备份原有 Alacritty 配置"); \
	fi
	@if [ "$(OS)" = "Darwin" ]; then \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.config/alacritty/mac.toml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml"; \
		$(call log_info,"已应用 macOS Alacritty 配置"); \
	elif [ "$$(uname -o 2>/dev/null)" = "GNU/Linux" ] && [ -f /etc/arch-release ]; then \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.config/alacritty/arch.toml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml"; \
		$(call log_info,"已应用 Arch Linux Alacritty 配置"); \
	fi

	$(call log_info,"配置 mihomo Profile...")
	@mkdir -p "$(XDG_CONFIG_HOME)/profile"
	@if [ ! -d "$(XDG_CONFIG_HOME)/profile/.git" ]; then \
		$(call log_info,"克隆 Profile 仓库..."); \
		git clone git@github.com:tsingksan/Profile.git "$(XDG_CONFIG_HOME)/profile" || \
		{ $(call log_error,"克隆 Profile 仓库失败"); exit 1; }; \
	else \
		$(call log_info,"更新 Profile 仓库..."); \
		git -C "$(XDG_CONFIG_HOME)/profile" pull || $(call log_warn,"更新 Profile 仓库失败"); \
	fi

	@if [ "$(OS)" = "Darwin" ]; then \
		$(call log_info,"配置 mihomo 配置文件 \(macOS\)..."); \
		sudo mkdir -p "/opt/homebrew/etc/mihomo"; \
		sudo ln -sf "$(XDG_CONFIG_HOME)/profile/config.yaml" "/opt/homebrew/etc/mihomo/config.yaml" || \
		{ $(call log_error,"链接 mihomo 配置文件失败"); exit 1; }; \
	elif [ "$$(uname -o 2>/dev/null)" = "GNU/Linux" ] && [ -f /etc/arch-release ]; then \
		$(call log_info,"配置 mihomo 配置文件 \(Arch Linux\)..."); \
		sudo mkdir -p "/etc/mihomo"; \
		sudo ln -sf "$(XDG_CONFIG_HOME)/profile/config.yaml" "/etc/mihomo/config.yaml" || \
		{ $(call log_error,"链接 mihomo 配置文件失败"); exit 1; }; \
	else \
		$(call log_warn,"未识别的操作系统，跳过 mihomo 配置文件链接"); \
	fi

	$(call log_info,"配置 ZSH 为默认 shell...")
	@if [ "$$(basename $$(grep $${USER}: /etc/passwd | cut -d: -f7))" != "zsh" ]; then \
		chsh -s $$(command -v zsh); \
		$(call log_info,"已将 ZSH 设为默认 shell"); \
	else \
		$(call log_info,"ZSH 已是默认 shell"); \
	fi

	$(call log_info,"dotfiles 配置完成")

# 通用安装入口
install-common:
	@if [ "$(OS)" = "Darwin" ]; then \
		$(MAKE) macos; \
	elif [ "$$(uname -o 2>/dev/null)" = "GNU/Linux" ] && [ -f /etc/arch-release ]; then \
		$(MAKE) arch; \
	else \
		$(call log_error,"不支持的操作系统"); \
		exit 1; \
	fi
