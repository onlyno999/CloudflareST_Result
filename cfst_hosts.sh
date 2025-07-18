#!/data/data/com.termux/files/usr/bin/bash
# --------------------------------------------------------------
# 项目: CloudflareST 自动测速（Termux 版，含自动下载主程序）
# 作者: 修改自 XIU2 项目 + ChatGPT 自适配 Termux
# 环境: Termux (Android)，无需 root，仅测速不改 hosts
# --------------------------------------------------------------

CLOUDFLAREST="./CloudflareST"
NOWIP_FILE="nowip_hosts.txt"
RESULT_FILE="result_hosts.txt"
DOWNLOAD_URL="https://github.com/XIU2/CloudflareSpeedTest/releases/latest/download/CloudflareST_linux_arm"

# 检查并下载 CloudflareST 主程序
_DOWNLOAD_CFST() {
    if [[ ! -f ${CLOUDFLAREST} ]]; then
        echo "🌐 未检测到 CloudflareST，开始自动下载..."
        curl -L -o CloudflareST "${DOWNLOAD_URL}"
        if [[ $? -ne 0 ]]; then
            echo "❌ 下载失败，请检查网络或手动下载。"
            exit 1
        fi
        chmod +x CloudflareST
        echo "✅ CloudflareST 下载并设置完成。"
    else
        echo "✅ 已检测到 CloudflareST，可直接使用。"
    fi
}

# 首次配置当前 IP
_CHECK() {
    while true; do
        if [[ ! -e "${NOWIP_FILE}" ]]; then
            echo -e "📌 脚本将使用 CloudflareST 测速并输出最快 IP。\n⚠️ 默认不修改 /etc/hosts（Termux 无权限）。"
            read -p "请输入当前 hosts 中使用的 Cloudflare IP：" NOWIP
            if [[ -n "${NOWIP}" ]]; then
                echo "${NOWIP}" > "${NOWIP_FILE}"
                break
            else
                echo "❌ IP 不能为空，请重新输入。"
            fi
        else
            break
        fi
    done
}

# 执行测速
_UPDATE() {
    echo -e "\n🚀 开始测速..."
    NOWIP=$(head -1 "${NOWIP_FILE}")

    ${CLOUDFLAREST} -o "${RESULT_FILE}"

    if [[ ! -f "${RESULT_FILE}" ]]; then
        echo "⚠️ 测速失败，未生成结果文件，退出。"
        exit 0
    fi

    BESTIP=$(sed -n "2,1p" "${RESULT_FILE}" | awk -F, '{print $1}')
    if [[ -z "${BESTIP}" ]]; then
        echo "⚠️ 未获取到最佳 IP，退出。"
        exit 0
    fi

    echo "${BESTIP}" > "${NOWIP_FILE}"
    echo -e "\n✅ 测速完成："
    echo "旧 IP: ${NOWIP}"
    echo "新 IP: ${BESTIP}"
    echo -e "\n📌 请手动将 Hosts 中 IP 替换为新 IP（Termux 无 root 无法自动替换）。"
}

# 主逻辑执行
_DOWNLOAD_CFST
_CHECK
_UPDATE
