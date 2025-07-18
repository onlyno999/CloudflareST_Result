#!/data/data/com.termux/files/usr/bin/bash

MYHOSTS="$HOME/cloudflare_hosts"
NOWIP_FILE="$HOME/nowip_hosts.txt"
CDN_TOOL_PATH="$PREFIX/bin/cdnspeedtest"
CDN_SPEED_TEST="cdnspeedtest"

IPV4_LIST_URL="https://raw.githubusercontent.com/onlyno999/CloudflareST_Result/main/ip.txt"
IPV6_LIST_URL="https://raw.githubusercontent.com/onlyno999/CloudflareST_Result/main/ipv6.txt"
CDN_BIN_URL="https://github.com/XIU2/CloudflareSpeedTest/releases/latest/download/CloudflareST_linux_arm64.zip"

echo "📡 CloudflareST Termux 一鍵 Hosts 測速更新腳本"

# 安裝 cdnspeedtest 工具（CloudflareST）
install_cdnspeedtest() {
  if ! command -v $CDN_SPEED_TEST >/dev/null 2>&1; then
    echo "未找到 cdnspeedtest，正在自動安裝..."
    pkg install -y curl unzip > /dev/null 2>&1
    cd "$HOME"
    curl -LO "$CDN_BIN_URL"
    unzip -o CloudflareST_linux_arm64.zip >/dev/null
    mv CloudflareST_linux_arm64/cdst "$CDN_SPEED_TEST"
    chmod +x "$CDN_SPEED_TEST"
    echo "✅ 測速工具安裝完成：$CDN_SPEED_TEST"
  else
    echo "✅ 測速工具已安裝：$CDN_SPEED_TEST"
  fi
}

# 初始化首次用到的文件
init_files() {
  if [[ ! -f "$NOWIP_FILE" ]]; then
    echo "首次运行，请输入当前 Cloudflare IP（旧 IP）"

    read -e -p "请输入 IPv4 地址: " NOWIPV4
    if [[ -z "$NOWIPV4" ]]; then echo "❌ IPv4 不能为空，退出。"; exit 1; fi

    read -e -p "请输入 IPv6 地址: " NOWIPV6
    if [[ -z "$NOWIPV6" ]]; then echo "❌ IPv6 不能为空，退出。"; exit 1; fi

    echo -e "${NOWIPV4}\n${NOWIPV6}" > "$NOWIP_FILE"
    echo "✅ 已保存当前 IP 到 $NOWIP_FILE"
  fi

  if [[ ! -f "$MYHOSTS" ]]; then
    echo "⚠️ 未找到 hosts 文件，將自動創建一份"
    NOWIPV4=$(sed -n '1p' "$NOWIP_FILE")
    NOWIPV6=$(sed -n '2p' "$NOWIP_FILE")
    cat > "$MYHOSTS" <<EOF
$NOWIPV4 cloudflare-dns.com
$NOWIPV6 cloudflare-dns.com
EOF
    echo "✅ 已建立初始 hosts 文件：$MYHOSTS"
  fi
}

# 選單選擇
show_menu() {
  echo ""
  echo "請選擇测速類型："
  echo "1) 僅測 IPv4"
  echo "2) 僅測 IPv6"
  echo "3) 同時測 IPv4 + IPv6"
  read -p "請輸入選項 (1/2/3): " CHOICE

  case "$CHOICE" in
    1) DO_IPV4=true; DO_IPV6=false ;;
    2) DO_IPV4=false; DO_IPV6=true ;;
    3) DO_IPV4=true; DO_IPV6=true ;;
    *) echo "❗ 無效輸入，預設執行 IPv4 + IPv6"; DO_IPV4=true; DO_IPV6=true ;;
  esac
}

# 下載 IP 清單
ensure_ip_lists() {
  [[ "$DO_IPV4" == true && ! -f "ip.txt" ]] && curl -Lo ip.txt "$IPV4_LIST_URL"
  [[ "$DO_IPV6" == true && ! -f "ipv6.txt" ]] && curl -Lo ipv6.txt "$IPV6_LIST_URL"
}

# 測速 + 更新 hosts
update_hosts() {
  NOWIPV4=$(sed -n '1p' "$NOWIP_FILE")
  NOWIPV6=$(sed -n '2p' "$NOWIP_FILE")

  ensure_ip_lists
  cp -f "$MYHOSTS" "$MYHOSTS.bak"

  if [[ "$DO_IPV4" == true ]]; then
    echo "🌐 開始 IPv4 測速..."
    $CDN_SPEED_TEST -f "ip.txt" -o "result_hosts_ipv4.txt" -dd -t 1
    if [[ -s result_hosts_ipv4.txt ]]; then
      BESTIPV4=$(sed -n '2p' result_hosts_ipv4.txt | awk -F, '{print $1}')
      echo "✅ 最佳 IPv4: $BESTIPV4"
      sed -i "s/\b$NOWIPV4\b/$BESTIPV4/g" "$MYHOSTS"
      sed -i "1s/.*/$BESTIPV4/" "$NOWIP_FILE"
    else
      echo "❌ IPv4 測速失敗或無結果"
    fi
  fi

  if [[ "$DO_IPV6" == true ]]; then
    echo "🌐 開始 IPv6 測速..."
    $CDN_SPEED_TEST -f "ipv6.txt" -o "result_hosts_ipv6.txt" -dd -t 1
    if [[ -s result_hosts_ipv6.txt ]]; then
      BESTIPV6=$(sed -n '2p' result_hosts_ipv6.txt | awk -F, '{print $1}')
      echo "✅ 最佳 IPv6: $BESTIPV6"
      sed -i "s/\b$NOWIPV6\b/$BESTIPV6/g" "$MYHOSTS"
      sed -i "2s/.*/$BESTIPV6/" "$NOWIP_FILE"
    else
      echo "❌ IPv6 測速失敗或無結果"
    fi
  fi

  echo -e "\n✅ Hosts 更新完成！備份為：$MYHOSTS.bak"
  echo "請視情況重新載入 DNS 或重啟對應應用。"
}

main() {
  install_cdnspeedtest
  init_files
  show_menu
  update_hosts
}

main "$@"
