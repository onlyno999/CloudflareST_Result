#!/data/data/com.termux/files/usr/bin/bash

# 适配 Termux，Hosts 文件路径自定义（默认用用户主目录）
MYHOSTS="$HOME/cloudflare_hosts"

# 存放当前 IP 的文件
NOWIP_FILE="$HOME/nowip_hosts.txt"

# CloudflareST测速工具名称（需放在 PATH 或同目录）
CDN_SPEED_TEST="cdnspeedtest"

echo "CloudflareST Termux 自动测速更新 Hosts 脚本"

# 检查并初始化当前 IP 文件
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

update_hosts() {
  NOWIPV4=$(sed -n '1p' "$NOWIP_FILE")
  NOWIPV6=$(sed -n '2p' "$NOWIP_FILE")

  echo "开始测速 IPv4..."
  $CDN_SPEED_TEST -f "ip.txt" -o "result_hosts_ipv4.txt" -dd -t 1
  if [[ ! -s "result_hosts_ipv4.txt" ]]; then
    echo "IPv4 测速结果为空，跳过 IPv4 更新。"
  else
    BESTIPV4=$(sed -n '2p' result_hosts_ipv4.txt | awk -F, '{print $1}')
  fi

  echo "开始测速 IPv6..."
  $CDN_SPEED_TEST -f "ipv6.txt" -o "result_hosts_ipv6.txt" -dd -t 1
  if [[ ! -s "result_hosts_ipv6.txt" ]]; then
    echo "IPv6 测速结果为空，跳过 IPv6 更新。"
  else
    BESTIPV6=$(sed -n '2p' result_hosts_ipv6.txt | awk -F, '{print $1}')
  fi

  # 备份 hosts 文件
  cp -f "$MYHOSTS" "$MYHOSTS.bak"

  if [[ -n "$BESTIPV4" ]]; then
    echo -e "\n替换 IPv4：旧 $NOWIPV4 → 新 $BESTIPV4"
    sed -i "s/\b$NOWIPV4\b/$BESTIPV4/g" "$MYHOSTS"
    sed -i "1s/.*/$BESTIPV4/" "$NOWIP_FILE"
  fi

  if [[ -n "$BESTIPV6" ]]; then
    echo -e "\n替换 IPv6：旧 $NOWIPV6 → 新 $BESTIPV6"
    sed -i "s/\b$NOWIPV6\b/$BESTIPV6/g" "$MYHOSTS"
    sed -i "2s/.*/$BESTIPV6/" "$NOWIP_FILE"
  fi

  echo -e "\n更新完成！当前 hosts 文件备份为：$MYHOSTS.bak"
  echo "请根据需要手动配置或重启本地 DNS 服务。"
}

main() {
  init_nowip
  update_hosts
}

main "$@"
