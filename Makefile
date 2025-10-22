.PHONY: all
.PHONY: install-pkg-macos install-pkg-arch setup-dotfiles
.PHONY: enable-mihomo code-link-cursor archinstall remount

export XDG_CONFIG_HOME := $(HOME)/.config

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
SCRIPTS_DIR := $(CURDIR)/scripts

# Arch Linux 分区配置
ROOT_DEVICE ?= /dev/nvme0n1p6
SWAP_DEVICE ?= /dev/nvme0n1p5
BOOT_DEVICE ?= /dev/nvme0n1p1

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

# ============================================================================
# 软件包列表
# ============================================================================

# macOS Homebrew Casks
BREW_CASKS := \
	font-fira-code-nerd-font font-fira-mono-nerd-font \
	1password maccy snipaste brave-browser keka hammerspoon \
	chatgpt typora visual-studio-code cursor fork \
	insomnium bruno telegram wechat wechatwork localsend ddpm logi-options+ \
	spotify docker appcleaner switchhosts bitwarden

# macOS Homebrew Formulae
BREW_FORMULAE := \
	stow gnupg pinentry-mac mihomo \
	neovim rustup zig zls go python@3 \
	deno node@22 fastfetch htop ripgrep

# Arch Linux Pacman 包
ARCH_PACMAN := \
	pinentry openssh zsh htop fastfetch neovim \
	ttf-firacode-nerd otf-firamono-nerd docker zig zls go python nodejs-lts-jod \
	handbrake stow git ripgrep

# Arch Linux AUR 包
ARCH_AUR := \
	brave-bin visual-studio-code-bin cursor-bin snipaste switchhosts-bin 

# ============================================================================
# 辅助脚本路径
# ============================================================================

INSTALL_ARCH_SCRIPT := $(SCRIPTS_DIR)/install-arch.sh
REMOUNT_ARCH_SCRIPT := $(SCRIPTS_DIR)/remount-arch.sh
SETUP_DOTFILES_SCRIPT := $(SCRIPTS_DIR)/setup-dotfiles.sh
SETUP_MIHOMO_SCRIPT := $(SCRIPTS_DIR)/setup-mihomo.sh


enable-mihomo:
	$(call log_info,"enable mihomo...")
	@bash $(SETUP_MIHOMO_SCRIPT)
	$(call log_info,"enable mihomo done")

install-pkg-macos:
	$(call log_info,"开始配置 macOS 环境...")
	@if [ "$$EUID" -eq 0 ]; then \
		$(call log_error,"不能以 root 用户运行此脚本"); \
		exit 1; \
	fi

	@if ! command -v brew >/dev/null 2>&1; then \
		$(call log_info,"正在安装 Homebrew..."); \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		eval "$$(/opt/homebrew/bin/brew shellenv)"; \
	else \
		$(call log_info,"Homebrew 已安装"); \
	fi
	
	$(call log_info,"安装 Homebrew Formulae...")
	@for tool in $(BREW_FORMULAE); do \
		if ! brew list $$tool &>/dev/null; then \
			$(call log_info,"安装 $$tool..."); \
			brew install $$tool || $(call log_warn,"$$tool 安装失败"); \
		fi \
	done
	
	$(call log_info,"安装 Homebrew Casks...")
	@for app in $(BREW_CASKS); do \
		if ! brew list --cask $$app &>/dev/null; then \
			$(call log_info,"安装 $$app..."); \
			brew install --cask $$app || $(call log_warn,"$$app 安装失败"); \
		fi \
	done
	
	$(call log_info,"macOS 环境配置完成")

install-pkg-arch:
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


setup-dotfiles:
	$(call log_info,"setup dotfiles...")
	@bash $(SETUP_DOTFILES_SCRIPT)
	$(call log_info,"setup dotfiles done")

code-link-cursor:
	$(call log_info,"sync VSCode to Cursor...")
	@ln -sf ~/.vscode/extensions ~/.cursor
	@ln -sf ~/Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Cursor/User
	@ln -sf ~/Library/Application\ Support/Code/User/snippets ~/Library/Application\ Support/Cursor/User
	@ln -sf ~/Library/Application\ Support/Code/User/workspaceStorage ~/Library/Application\ Support/Cursor/User
	@ln -sf ~/Library/Application\ Support/Code/User/globalStorage ~/Library/Application\ Support/Cursor/User
	@ln -sf ~/Library/Application\ Support/Code/User/History ~/Library/Application\ Support/Cursor/User
	$(call log_info,"sync VSCode to Cursor done")

# ============================================================================
# Arch Linux 远程安装
# ============================================================================

archinstall:
	@if [ "$(ARCHADDR)" = "unset" ]; then \
		$(call log_error,"请设置 ARCHADDR 变量，例如: make archinstall ARCHADDR=192.168.1.100"); \
		exit 1; \
	fi
	$(call log_info,"开始 Arch Linux 远程安装...")
	$(call log_info,"目标主机: $(ARCHADDR):$(ARCHPORT)")
	$(call log_info,"分区配置: ROOT=$(ROOT_DEVICE) SWAP=$(SWAP_DEVICE) BOOT=$(BOOT_DEVICE)")
	@cat $(INSTALL_ARCH_SCRIPT) | ssh $(SSH_OPTIONS) -p $(ARCHPORT) root@$(ARCHADDR) \
		"bash -s -- '$(ROOT_DEVICE)' '$(SWAP_DEVICE)' '$(BOOT_DEVICE)' '$(USERNAME)' '$(ROOT_PASSWORD)' '$(USER_PASSWORD)'"

remount:
	@if [ "$(ARCHADDR)" = "unset" ]; then \
		$(call log_error,"请设置 ARCHADDR 变量，例如: make remount ARCHADDR=192.168.1.100"); \
		exit 1; \
	fi
	$(call log_info,"重新挂载 Arch Linux 分区...")
	@cat $(REMOUNT_ARCH_SCRIPT) | ssh $(SSH_OPTIONS) -p $(ARCHPORT) root@$(ARCHADDR) \
		"bash -s -- '$(ROOT_DEVICE)' '$(SWAP_DEVICE)' '$(BOOT_DEVICE)'"
	$(call log_info,"挂载完成")


# ============================================================================
# 主要目标
# ============================================================================

# 默认目标：显示帮助信息
all:
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🚀 Dotfiles 管理系统"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📦 环境配置:"
	@echo "  make install-pkg-macos            - 配置 macOS 环境（Homebrew + 软件）"
	@echo "  make install-pkg-arch             - 配置 Arch Linux 环境（pacman + AUR）"
	@echo "  make setup-dotfiles               - 配置 dotfiles（stow 链接）"
	@echo "  make enable-mihomo                - 配置 mihomo（rclone 配置）"
	@echo ""
	@echo "🐧 Arch Linux 远程安装:"
	@echo "  make archinstall ARCHADDR=<IP>  - 远程安装 Arch Linux"
	@echo "  make remount ARCHADDR=<IP>      - 重新挂载分区"
	@echo ""
	@echo "🔧 开发工具:"
	@echo "  make code-link-cursor - 链接 VSCode 扩展到 Cursor"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "⚙️  当前配置:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  OS              = $(OS)"
	@echo "  USERNAME        = $(USERNAME)"
	@echo "  XDG_CONFIG_HOME = $(XDG_CONFIG_HOME)"
	@echo ""
	@echo "  ARCHADDR        = $(ARCHADDR)"
	@echo "  ARCHPORT        = $(ARCHPORT)"
	@echo "  ROOT_DEVICE     = $(ROOT_DEVICE)"
	@echo "  SWAP_DEVICE     = $(SWAP_DEVICE)"
	@echo "  BOOT_DEVICE     = $(BOOT_DEVICE)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
