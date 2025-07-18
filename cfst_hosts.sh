#!/data/data/com.termux/files/usr/bin/bash

# === 設定 ===
remote_exec_url="https://github.xxxxxxxx.nyc.mn/onlyno999/CloudflareST_Result/main/CloudflareST"
exec_dir=~/cfst
exec_bin="${exec_dir}/CloudflareST"
result_file="${exec_dir}/result_hosts.txt"
nowip_file="${exec_dir}/nowip_hosts.txt"
iplist_url="https://raw.githubusercontent.com/onlyno999/CloudflareST_Result/main/ip.txt"
iplist_file="${exec_dir}/ip.txt"
pushplus="你的PushPlus token"
test_count=20
test_url="https://www.gstatic.com/generate_204"  # ✅ 新增：指定测速地址，防止默认失效

# === 初始化 ===
mkdir -p "$exec_dir"
cd "$exec_dir" || exit 1

# === 下載主程序 ===
if [[ ! -f "$exec_bin" ]]; then
  echo "📥 下載 CloudflareST 主程序..."
  curl -L -o "$exec_bin" "$remote_exec_url"
  chmod +x "$exec_bin"
else
  echo "✅ 主程序已存在，跳過下載。"
fi

# === 下載 IP 列表 ===
echo "📥 下載 ip.txt..."
curl -s -A "Mozilla/5.0" -o "$iplist_file" "$iplist_url"
if [[ ! -s "$iplist_file" ]]; then
  echo "❌ ip.txt 下載失敗或為空，退出。"
  exit 1
fi

# === 執行測速 ===
echo "🚀 開始測速..."
"$exec_bin" -f "$iplist_file" -n "$test_count" -o "$result_file" -url "$test_url"

if [[ ! -s "$result_file" ]]; then
  echo "❌ 測速失敗或結果為空，退出。"
  exit 1
fi

# === 提取測速結果 ===
BESTIP=$(sed -n '2p' "$result_file" | awk -F, '{print $1}')
Average=$(sed -n '2p' "$result_file" | awk -F, '{print $5}')
speed=$(sed -n '2p' "$result_file" | awk -F, '{print $6}')
Packet=$(sed -n '2p' "$result_file" | awk -F, '{print $4}')
OLDIP=$(cat "$nowip_file" 2>/dev/null || echo "無")

echo "$BESTIP" > "$nowip_file"

# === 顯示結果 ===
echo -e "\n📡 舊 IP：$OLDIP"
echo -e "✅ 新 IP：$BESTIP"
echo -e "⏱️ 平均延遲：${Average} ms"
echo -e "📶 下載速度：${speed} MB/s"
echo -e "❗ 丟包率：${Packet} %"

# === 發送推送通知 ===
echo "📤 發送推送通知..."
curl -s -o /dev/null --data "token=${pushplus}&title=Cloudflare IP 更新成功&content=舊 IP：${OLDIP}<br>新 IP：${BESTIP}<br>平均延遲：${Average} ms<br>下載速度：${speed} MB/s<br>丟包率：${Packet} %<br>時間：$(date +'%Y-%m-%d %H:%M:%S')&template=html" http://www.pushplus.plus/send

# === 清理 ===
rm -f "$result_file"
echo "✅ 完成！"
