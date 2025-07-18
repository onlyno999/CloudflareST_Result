#!/data/data/com.termux/files/usr/bin/bash

# Hosts 檔案位置
MYHOSTS="$HOME/cloudflare_hosts"
NOWIP_FILE="$HOME/nowip_hosts.txt"
CDN_SPEED_TEST="cdnspeedtest"

# IP清單來源
IPV4_LIST_URL="https://raw.githubusercontent.com/onlyno999/CloudflareST_Result/main/ip.txt"
IPV6_LIST_URL="https://raw.githubusercontent.com/onlyno999/CloudflareST_Result/main/ipv6.txt"

echo "CloudflareST Termux 自动测速更新 Hosts 脚本"

# 初始化目前IP記錄檔
init_nowip() {
  if [[ ! -f "$NOWIP_FILE" ]]; then
    echo "首次运行，请输入当前 Cloudflare CDN IP（旧 IP）"

    read -e -p "请输入 IPv4 地址: " NOWIPV4
    if [[ -z "$NOWIPV4" ]]; then
      echo "IPv4 不能为空，退出。"
      exit 1
    fi

    read -e -p "请输入 IPv6 地址: " NOWIPV6
    if [[ -z "$NOWIPV6" ]]; then
      echo "IPv6 不能为空，退出。"
      exit 1
    fi

    echo -e "${NOWIPV4}\n${NOWIPV6}" > "$NOWIP_FILE"
    echo "已保存当前 IP 到 $NOWIP_FILE"
  fi
}

# 根據需求下載 IP 列表
ensure_ip_lists() {
  if [[ "$DO_IPV4" == true && ! -f "ip.txt" ]]; then
    echo "未找到 ip.txt，尝试下载..."
    curl -Lo ip.txt "$IPV4_LIST_URL" || echo "下载 ip.txt 失败，跳过 IPv4 测速。"
  fi

  if [[ "$DO_IPV6" == true && ! -f "ipv6.txt" ]]; then
    echo "未找到 ipv6.txt，尝试下载..."
    curl -Lo ipv6.txt "$IPV6_LIST_URL" || echo "下载 ipv6.txt 失败，跳过 IPv6 测速。"
  fi
}

# 根據用戶選擇測速 & 更新 hosts
update_hosts() {
  NOWIPV4=$(sed -n '1p' "$NOWIP_FILE")
  NOWIPV6=$(sed -n '2p' "$NOWIP_FILE")

  ensure_ip_lists

  cp -f "$MYHOSTS" "$MYHOSTS.bak"

  if [[ "$DO_IPV4" == true ]]; then
    echo -e "\n开始测速 IPv4..."
    $CDN_SPEED_TEST -f "ip.txt" -o "result_hosts_ipv4.txt" -dd -t 1
    if [[ -s "result_hosts_ipv4.txt" ]]; then
      BESTIPV4=$(sed -n '2p' result_hosts_ipv4.txt | awk -F, '{print $1}')
      if [[ -n "$BESTIPV4" ]]; then
        echo -e "替换 IPv4：旧 $NOWIPV4 → 新 $BESTIPV4"
        sed -i "s/\b$NOWIPV4\b/$BESTIPV4/g" "$MYHOSTS"
        sed -i "1s/.*/$BESTIPV4/" "$NOWIP_FILE"
      fi
    else
      echo "IPv4 测速结果为空，跳过 IPv4 更新。"
    fi
  fi

  if [[ "$DO_IPV6" == true ]]; then
    echo -e "\n开始测速 IPv6..."
    $CDN_SPEED_TEST -f "ipv6.txt" -o "result_hosts_ipv6.txt" -dd -t 1
    if [[ -s "result_hosts_ipv6.txt" ]]; then
      BESTIPV6=$(sed -n '2p' result_hosts_ipv6.txt | awk -F, '{print $1}')
      if [[ -n "$BESTIPV6" ]]; then
        echo -e "替换 IPv6：旧 $NOWIPV6 → 新 $BESTIPV6"
        sed -i "s/\b$NOWIPV6\b/$BESTIPV6/g" "$MYHOSTS"
        sed -i "2s/.*/$BESTIPV6/" "$NOWIP_FILE"
      fi
    else
      echo "IPv6 测速结果为空，跳过 IPv6 更新。"
    fi
  fi

  echo -e "\n✅ 更新完成！Hosts 备份文件：$MYHOSTS.bak"
  echo "👉 请根据需要手动配置或重启本地 DNS 服务。"
}

# 選擇模式
show_menu() {
  echo ""
  echo "请选择测速类型："
  echo "1) 仅测速并更新 IPv4"
  echo "2) 仅测速并更新 IPv6"
  echo "3) 同时测速并更新 IPv4 和 IPv6"
  read -p "请输入选项 (1/2/3): " CHOICE

  case "$CHOICE" in
    1)
      DO_IPV4=true
      DO_IPV6=false
      ;;
    2)
      DO_IPV4=false
      DO_IPV6=true
      ;;
    3)
      DO_IPV4=true
      DO_IPV6=true
      ;;
    *)
      echo "无效输入，默认执行同时测速 IPv4 和 IPv6"
      DO_IPV4=true
      DO_IPV6=true
      ;;
  esac
}

main() {
  init_nowip
  show_menu
  update_hosts
}

main "$@"
