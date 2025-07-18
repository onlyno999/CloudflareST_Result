#!/data/data/com.termux/files/usr/bin/bash

# CloudflareST Termux 一鍵 Hosts 測速更新腳本
# 作者：ChatGPT 整合版

set -e

MYHOSTS="$HOME/cloudflare_hosts"
NOWIP_FILE="$HOME/nowip_hosts.txt"
CDN_BIN_URL="https://github.xxxxxxxx.nyc.mn/onlyno999/CloudflareST_Result/main/CloudflareST"
CDN_SPEED_TEST="cdnspeedtest"

echo "📡 CloudflareST Termux 自动测速更新 Hosts 脚本"

# 安裝測速工具
install_cdnspeedtest() {
  if ! command -v $CDN_SPEED_TEST >/dev/null 2>&1; then
    echo "未找到 $CDN_SPEED_TEST，正在自動安裝..."
    curl -Lo cdnspeedtest "$CDN_BIN_URL"
    if [[ -f cdnspeedtest ]]; then
      chmod +x cdnspeedtest
      mv cdnspeedtest "$PREFIX/bin/"
      echo "✅ 測速工具安裝完成：$CDN_SPEED_TEST"
    else
      echo "❌ 下載測速工具失敗，請檢查網路與地址"
      exit 1
    fi
  else
    echo "測速工具 $CDN_SPEED_TEST 已安裝"
  fi
}

# 初始化 IP 文件
init_nowip() {
  if [[ ! -f "$NOWIP_FILE" ]]; then
    echo "首次运行，请输入当前 Cloudflare IP（旧 IP）"
    read -rp "请输入 IPv4 地址: " NOWIPV4
    [[ -z "$NOWIPV4" ]] && { echo "IPv4 不能为空，退出。"; exit 1; }
    read -rp "请输入 IPv6 地址: " NOWIPV6
    [[ -z "$NOWIPV6" ]] && { echo "IPv6 不能为空，退出。"; exit 1; }
    echo -e "${NOWIPV4}\n${NOWIPV6}" > "$NOWIP_FILE"
    echo "✅ 已保存当前 IP 到 $NOWIP_FILE"
  fi
}

# 確保 hosts 文件存在
init_hosts() {
  if [[ ! -f "$MYHOSTS" ]]; then
    echo "⚠️ 未找到 hosts 文件，將自動創建一份"
    cat > "$MYHOSTS" << EOF
# Cloudflare Hosts 示例文件
# IPv4
162.159.36.1 some.cloudflare.domain
# IPv6
2606:4700:4700::1111 some.cloudflare.domain
EOF
    echo "✅ 已建立初始 hosts 文件：$MYHOSTS"
  fi
}

# 下載 ip.txt 和 ipv6.txt
download_ipfiles() {
  local URL_IPV4="https://github.com/onlyno999/CloudflareST_Result/raw/refs/heads/main/ip.txt"
  local URL_IPV6="https://github.com/onlyno999/CloudflareST_Result/raw/refs/heads/main/ipv6.txt"

  if [[ ! -f ip.txt ]]; then
    echo "未找到 ip.txt，嘗試下載..."
    curl -fsSL "$URL_IPV4" -o ip.txt || { echo "下載 ip.txt 失敗"; exit 1; }
  fi

  if [[ ! -f ipv6.txt ]]; then
    echo "未找到 ipv6.txt，嘗試下載..."
    curl -fsSL "$URL_IPV6" -o ipv6.txt || { echo "下載 ipv6.txt 失敗"; exit 1; }
  fi
}

# 速度測試與更新
update_hosts() {
  NOWIPV4=$(sed -n '1p' "$NOWIP_FILE")
  NOWIPV6=$(sed -n '2p' "$NOWIP_FILE")

  # 備份 hosts
  cp -f "$MYHOSTS" "$MYHOSTS.bak"

  if [[ $MEASURE_IPV4 == true ]]; then
    echo "开始测速 IPv4..."
    $CDN_SPEED_TEST -f ip.txt -o result_hosts_ipv4.txt -dd -t 1
    if [[ ! -s result_hosts_ipv4.txt ]]; then
      echo "IPv4 测速结果为空，跳过 IPv4 更新。"
    else
      BESTIPV4=$(sed -n '2p' result_hosts_ipv4.txt | awk -F, '{print $1}')
      if [[ -n "$BESTIPV4" ]]; then
        echo -e "\n替换 IPv4：旧 $NOWIPV4 → 新 $BESTIPV4"
        sed -i "s/\b$NOWIPV4\b/$BESTIPV4/g" "$MYHOSTS"
        sed -i "1s/.*/$BESTIPV4/" "$NOWIP_FILE"
      fi
    fi
  fi

  if [[ $MEASURE_IPV6 == true ]]; then
    echo "开始测速 IPv6..."
    $CDN_SPEED_TEST -f ipv6.txt -o result_hosts_ipv6.txt -dd -t 1
    if [[ ! -s result_hosts_ipv6.txt ]]; then
      echo "IPv6 测速结果为空，跳过 IPv6 更新。"
    else
      BESTIPV6=$(sed -n '2p' result_hosts_ipv6.txt | awk -F, '{print $1}')
      if [[ -n "$BESTIPV6" ]]; then
        echo -e "\n替换 IPv6：旧 $NOWIPV6 → 新 $BESTIPV6"
        sed -i "s/\b$NOWIPV6\b/$BESTIPV6/g" "$MYHOSTS"
        sed -i "2s/.*/$BESTIPV6/" "$NOWIP_FILE"
      fi
    fi
  fi

  echo -e "\n✅ 更新完成！当前 hosts 文件备份为：$MYHOSTS.bak"
  echo "请根据需要手动配置或重启本地 DNS 服务。"
}

# 主流程
main() {
  install_cdnspeedtest
  init_nowip
  init_hosts
  download_ipfiles

  echo
  echo "请选择测速类型："
  echo "1) 仅测 IPv4"
  echo "2) 仅测 IPv6"
  echo "3) 同时测 IPv4 + IPv6"
  read -rp "请输入选项 (1/2/3): " option

  case $option in
    1) MEASURE_IPV4=true; MEASURE_IPV6=false ;;
    2) MEASURE_IPV4=false; MEASURE_IPV6=true ;;
    3) MEASURE_IPV4=true; MEASURE_IPV6=true ;;
    *) echo "无效选项，退出"; exit 1 ;;
  esac

  update_hosts
}

main "$@"
