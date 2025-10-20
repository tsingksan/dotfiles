.PHONY: all macos arch dotfiles archinstall remount cursor-extensions

# 系统变量
OS := $(shell uname)
IS_ARCH := $(shell [ -f /etc/arch-release ] && echo 1 || echo 0)

# 用户配置
SSH_OPTIONS := -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
ARCHADDR ?= unset
ARCHPORT ?= 22
ROOT_PASSWORD ?= 123
USER_PASSWORD ?= 123
USERNAME ?= tsingksan
XDG_CONFIG_HOME ?= $(HOME)/.config

# 颜色和日志
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m
define log_info
	@printf "$(GREEN)[INFO]$(NC) %s\n" "$(1)"
endef
define log_warn
	@printf "$(YELLOW)[WARN]$(NC) %s\n" "$(1)"
endef
define log_error
	@printf "$(RED)[ERROR]$(NC) %s\n" "$(1)" >&2
endef

# 软件列表
# thunderbird@esr 
BREW_CASKS := font-fira-code-nerd-font font-fira-mono-nerd-font \
	1password maccy snipaste brave-browser keka hammerspoon \
	chatgpt typora visual-studio-code cursor fork \
	insomnium bruno telegram wechat wechatwork localsend ddpm logi-options+ \
	spotify docker appcleaner switchhosts bitwarden

BREW_FORMULAE := nvim tmux rustup zig zls go python@3 \
	deno node@22 fastfetch htop ripgrep rclone neovim

ARCH_PACMAN := pinentry openssh zsh htop fastfetch neovim \
	ttf-firacode-nerd otf-firamono-nerd docker zig zls go python nodejs-lts-jod \
	handbrake

ARCH_AUR := brave-bin visual-studio-code-bin cursor-bin snipaste switchhosts-bin 

# Arch Linux 挂载命令
define MOUNT_SUBVOLS
mount -t btrfs -o compress=zstd,subvol=/@ /dev/nvme0n1p6 /mnt && \
mkdir -p /mnt/{home,boot} && \
mount -t btrfs -o compress=zstd,subvol=/@home /dev/nvme0n1p6 /mnt/home && \
mount /dev/nvme0n1p1 /mnt/boot && \
swapon /dev/nvme0n1p5
endef

# 默认目标
all:
	$(call log_info,"请选择目标: archinstall, macos, arch, dotfiles, remount")

# Arch Linux 安装
archinstall:
	$(call log_info,"开始 Arch Linux 安装...")
	ssh $(SSH_OPTIONS) -p $(ARCHPORT) root@$(ARCHADDR) "\
	set -e; \
	systemctl stop reflector.service && \
	timedatectl set-ntp true && \
	echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$$repo/os/\$$arch\nServer = https://mirrors.ustc.edu.cn/archlinux/\$$repo/os/\$$arch' > /etc/pacman.d/mirrorlist.new && \
	cat /etc/pacman.d/mirrorlist >> /etc/pacman.d/mirrorlist.new && \
	mv /etc/pacman.d/mirrorlist.new /etc/pacman.d/mirrorlist && \
	mkswap -L swap /dev/nvme0n1p5 && \
	mkfs.btrfs -f -L arch /dev/nvme0n1p6 && \
	mount -t btrfs -o compress=zstd /dev/nvme0n1p6 /mnt && \
	btrfs subvolume create /mnt/@ && \
	btrfs subvolume create /mnt/@home && \
	umount /mnt && \
	sleep 1 && \
	$(MOUNT_SUBVOLS) && \
	pacman -Sy --noconfirm archlinux-keyring && \
	pacstrap /mnt base base-devel linux linux-firmware btrfs-progs && \
	pacstrap /mnt networkmanager sudo vim && \
	genfstab -U /mnt > /mnt/etc/fstab && \
	arch-chroot /mnt /bin/bash -c '\
	set -e && \
	echo \"127.0.0.1 localhost\" > /etc/hosts && \
	echo \"::1 localhost\" >> /etc/hosts && \
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	hwclock --systohc && \
	sed -i \"s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/\" /etc/locale.gen && \
	sed -i \"s/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/\" /etc/locale.gen && \
	locale-gen && \
	echo \"LANG=en_US.UTF-8\" > /etc/locale.conf && \
	pacman -S --noconfirm grub efibootmgr os-prober && \
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH && \
	sed -i \"s/GRUB_CMDLINE_LINUX_DEFAULT=\\\"loglevel=3 quiet\\\"/GRUB_CMDLINE_LINUX_DEFAULT=\\\"loglevel=5 nowatchdog\\\"/\" /etc/default/grub && \
	grub-mkconfig -o /boot/grub/grub.cfg && \
	pacman -S --noconfirm plasma sddm konsole dolphin ark xorg && \
	pacman -S --noconfirm nvidia && \
	systemctl enable --now sddm NetworkManager && \
	echo \"root:$(ROOT_PASSWORD)\" | chpasswd && \
	useradd -m -G wheel -s /bin/bash $(USERNAME) && \
	echo \"$(USERNAME):$(USER_PASSWORD)\" | chpasswd && \
	sed -i \"s/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/\" /etc/sudoers && \
	pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra fcitx5-chinese-addons fcitx5-configtool firefox chromium stow git rustup fastfetch && \
	mkdir -p /home/$(USERNAME)/.config/environment.d && \
	echo \"XMODIFIERS=@im=fcitx\" >> /home/$(USERNAME)/.config/environment.d/im.conf && \
	chown -R $(USERNAME):$(USERNAME) /home/$(USERNAME)/.config && \
	sudo -u $(USERNAME) bash -c \"rustup default stable && \
		cd /tmp && \
		git clone https://aur.archlinux.org/paru.git && \
		cd paru && \
		makepkg -si --noconfirm && \
		cd .. && \
		rm -rf paru\" && \
	sudo -u $(USERNAME) paru -S --noconfirm mihomo-bin 1password localsend-bin \
	' && \
	umount -R /mnt && \
	reboot \
	"

# 重新挂载
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
	
	@for tool in stow gnupg pinentry-mac mihomo; do \
		if ! brew list $$tool &>/dev/null; then \
			$(call log_info,"安装 $$tool..."); \
			brew install $$tool; \
		fi \
	done
	
	@brew tap homebrew/services
	@brew services restart mihomo || brew services start mihomo
	
	@for app in $(BREW_CASKS); do \
		if ! brew list --cask $$app &>/dev/null; then \
			$(call log_info,"安装 $$app..."); \
			brew install --cask $$app || $(call log_warn,"$$app 安装失败"); \
		fi \
	done
	
	@for tool in $(BREW_FORMULAE); do \
		if ! brew list $$tool &>/dev/null; then \
			$(call log_info,"安装 $$tool..."); \
			brew install $$tool || $(call log_warn,"$$tool 安装失败"); \
		fi \
	done

# Arch Linux 配置
arch:
	$(call log_info,"开始配置 Arch Linux 环境...")
	@sudo pacman -Syu --noconfirm
	
	@for pkg in $(ARCH_PACMAN); do \
		if ! pacman -Q $$pkg &>/dev/null; then \
			$(call log_info,"安装 $$pkg..."); \
			sudo pacman -S --noconfirm $$pkg || $(call log_warn,"$$pkg 安装失败"); \
		fi \
	done
	
	@if ! command -v paru >/dev/null 2>&1; then \
		$(call log_error,"请先安装 paru AUR 助手"); \
		exit 1; \
	fi

	@for pkg in $(ARCH_AUR); do \
		if ! pacman -Q $$pkg &>/dev/null; then \
			$(call log_info,"安装 $$pkg..."); \
			paru -S --noconfirm $$pkg || $(call log_warn,"$$pkg 安装失败"); \
		fi \
	done

# dotfiles 配置
dotfiles:
	$(call log_info,"配置 dotfiles...")
	@mkdir -p "$(XDG_CONFIG_HOME)"

	@if [ ! -d "$(XDG_CONFIG_HOME)/dotfiles" ] || [ -z "$$(ls -A $(XDG_CONFIG_HOME)/dotfiles 2>/dev/null)" ]; then \
		git clone https://github.com/tsingksan/dotfiles.git "$(XDG_CONFIG_HOME)/dotfiles" || exit 1; \
	else \
		git -C "$(XDG_CONFIG_HOME)/dotfiles" pull; \
	fi

	@cd "$(XDG_CONFIG_HOME)/dotfiles" && stow -D . -t ~ && stow . -t ~ || exit 1

	@mkdir -p "$$HOME/.ssh" "$$HOME/.gnupg"
	@chmod 700 "$$HOME/.gnupg"
	@if ! grep -q "^pinentry-program" "$$HOME/.gnupg/gpg-agent.conf" 2>/dev/null; then \
		if [ "$(OS)" = "Darwin" ]; then \
			echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >> "$$HOME/.gnupg/gpg-agent.conf"; \
		elif [ "$(IS_ARCH)" = "1" ]; then \
			echo "pinentry-program /usr/bin/pinentry" >> "$$HOME/.gnupg/gpg-agent.conf"; \
		fi \
	fi


	# @killall gpg-agent 2>/dev/null || true
	# @gpg-agent --daemon --enable-ssh-support

	@gpg-connect-agent reloadagent /bye
	@export GPG_TTY=$$(tty)
	@export SSH_AUTH_SOCK=$$(gpgconf --list-dirs agent-ssh-socket)
	@gpgconf --launch gpg-agent

	@if ssh -T git@github.com 2>/dev/null; then \
		cd "$(XDG_CONFIG_HOME)/dotfiles" && git remote set-url origin git@github.com:tsingksan/dotfiles.git; \
	fi

	@if [ "$(OS)" = "Darwin" ]; then \
		rm -rf "$$HOME/Library/Preferences/konsolerc" "$$HOME/Library/Application Support/konsole"; \
		mkdir -p "$$HOME/Library/Application Support"; \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.config/konsolerc" "$$HOME/Library/Preferences/konsolerc"; \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.local/share/konsole" "$$HOME/Library/Application Support"; \
	fi

	@mkdir -p "$(XDG_CONFIG_HOME)/alacritty"
	@if [ -f "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml" ] && [ ! -L "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml" ]; then \
		mv "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml.backup"; \
	fi
	@if [ "$(OS)" = "Darwin" ]; then \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.config/alacritty/mac.toml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml"; \
	elif [ "$(IS_ARCH)" = "1" ]; then \
		ln -sf "$(XDG_CONFIG_HOME)/dotfiles/.config/alacritty/arch.toml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.toml"; \
	fi

	@mkdir -p "$(XDG_CONFIG_HOME)/mihomo"
	@if [ ! -d "$(XDG_CONFIG_HOME)/mihomo/.git" ]; then \
		git clone git@github.com:tsingksan/Profile.git "$(XDG_CONFIG_HOME)/mihomo" || exit 1; \
	else \
		git -C "$(XDG_CONFIG_HOME)/mihomo" pull; \
	fi

	@if [ "$(OS)" = "Darwin" ]; then \
		sudo mkdir -p "/opt/homebrew/etc/mihomo"; \
		cd "$(XDG_CONFIG_HOME)/mihomo"; \
		stow . -t "/opt/homebrew/etc/mihomo"
	elif [ "$(IS_ARCH)" = "1" ]; then \
		sudo mkdir -p "/etc/mihomo"; \
		cd "$(XDG_CONFIG_HOME)/mihomo"; \
		stow . -t "/etc/mihomo"
	fi

	@if [ "$$(basename $$(grep $${USER}: /etc/passwd | cut -d: -f7))" != "zsh" ]; then \
		chsh -s $$(command -v zsh); \
	fi

	$(call log_info,"dotfiles 配置完成")

# 链接vscode扩展到cursor
cursor-extensions:
	@ln -sf ~/.vscode/extensions ~/.cursor
	$(call log_info,"已链接VSCode扩展到Cursor")
