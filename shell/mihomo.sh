#!/bin/sh

install() {
    if [ "$(uname)" = "Darwin" ]; then
        printf "%bIntsalling mihomo%b\n" "${BLUE}" "${NC}"
        brew install mihomo

        echo "cloning dotfiles"
        if [ -d "$HOME"/.config/profile ]; then
            echo "found old profile, backing up to .profile.backup"
            mv "$HOME"/.config/profile "$HOME"/.config/profile.backup
        fi
        git clone git@github.com:tsingksan/Profile.git "$HOME"/.config/profile

        echo "设置开机自启"
        sudo brew services start mihomo
        CONFIG_DIR=$(brew services info mihomo --json | awk -F'"command": "' '/"command":/ {split($2, a, "\""); print a[1]}' | awk '{print $NF}')
        printf "mihomo config dir %s \n restart...\n" "${CONFIG_DIR}"
        ln -s "$HOME"/.config/profile/MihomoPro_icon.yaml "$CONFIG_DIR"/config.yaml
        sudo brew services restart mihomo

    elif [ "$(uname -o)" = "GNU/Linux" ]; then
        if [ -f /etc/arch-release ]; then
            printf "%bIntsalling mihomo%b\n" "${BLUE}" "${NC}"
            yay -S mihomo

            echo "cloning dotfiles"
            if [ -d "$HOME"/.config/profile ]; then
                echo "found old profile, backing up to .profile.backup"
                mv "$HOME"/.config/profile "$HOME"/.config/profile.backup
            fi
            git clone git@github.com:tsingksan/Profile.git "$HOME"/.config/profile

            echo "设置开机自启"
            # 定义变量
            SERVICE_NAME="mihomo"
            SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
            SCRIPT_PATH="/usr/local/bin/start_mihomo.sh"
            MIHOMO_PATH="/path/to/mihomo" # 替换为实际的 Mihomo 路径
            LOG_PATH="/var/log/mihomo.log"
            USER_NAME=$(whoami) # 获取当前用户

            # 检查是否以 root 用户运行
            if [ "$(id -u)" -ne 0 ]; then
                echo "请以 root 用户运行此脚本 (使用 sudo)。"
                exit 1
            fi

            # 创建启动脚本
            echo "创建启动脚本 ${SCRIPT_PATH}..."
            cat <<EOF >"${SCRIPT_PATH}"
#!/bin/bash
# 等待网络稳定
sleep 5
# 切换到 Mihomo 路径
cd ${MIHOMO_PATH}
# 启动程序并重定向日志
nohup ./mihomo > ${LOG_PATH} 2>&1 &
EOF

            # 设置脚本权限
            chmod +x "${SCRIPT_PATH}"

            # 创建 systemd 服务文件
            echo "创建 systemd 服务文件 ${SERVICE_FILE}..."
            cat <<EOF >"${SERVICE_FILE}"
[Unit]
Description=Mihomo Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash ${SCRIPT_PATH}
User=${USER_NAME}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

            # 重新加载 systemd 配置
            echo "重新加载 systemd 配置..."
            systemctl daemon-reload

            # 启动服务
            echo "启动 ${SERVICE_NAME} 服务..."
            systemctl start "${SERVICE_NAME}.service"

            # 设置服务开机自启
            echo "设置 ${SERVICE_NAME} 服务开机自启..."
            systemctl enable "${SERVICE_NAME}.service"

            # 检查服务状态
            echo "服务状态如下："
            systemctl status "${SERVICE_NAME}.service"

            echo "自动化设置完成！"
        fi
    fi
}

set_proxy() {
    networksetup -setwebproxy "Wi-Fi" 127.0.0.1 7890
    networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 7890
    networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 7890

    if curl -o /dev/null -x http://127.0.0.1:7890 https://www.google.com; then
        echo "Connection successful"
    else
        echo "Connection failed"
    fi

}

unset_proxy() {
    networksetup -setwebproxystate "Wi-Fi" off
    networksetup -setsecurewebproxystate "Wi-Fi" off
    networksetup -setsocksfirewallproxystate "Wi-Fi" off
}

if [ "$1" = "set" ]; then
    set_proxy
elif [ "$1" = "unset" ]; then
    unset_proxy
elif [ "$1" = "install" ]; then
    install
else
    echo "Please provide a valid argument: 'set' or 'unset' 'install'."
fi
