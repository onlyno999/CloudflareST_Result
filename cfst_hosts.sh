#!/data/data/com.termux/files/usr/bin/bash

# ---------------------
# CloudflareST 自動執行 + 遠程拉取主程序 + 推送更新
# 適用於 Termux 環境
# ---------------------

# === 設定 ===
pushplus="填入你的PushPlus token"
remote_exec_url="https://github.xxxxxxxx.nyc.mn/onlyno999/CloudflareST_Result/main/CloudflareST"
exec_path=~/CloudflareST
nowip_file=~/nowip_hosts.txt
result_file=result_hosts.txt

# === 準備主程序 ===
mkdir -p "$(dirname "$exec_path")"
if [[ ! -f "$exec_path" ]]; then
    echo "📥 下載 CloudflareST 主程序..."
    curl -L -o "$exec_path" "$remote_exec_url"
    chmod +x "$exec_path"
else
    echo "✅ 已存在主程序，跳過下載。"
fi

# === 執行主程序測速 ===
cd "$(dirname "$exec_path")"
echo "🚀 開始執行測速..."
./CloudflareST -o "$result_file"

# === 解析結果 ===
if [[ ! -s "$result_file" ]]; then
    echo "❌ 測速結果為空，終止。"
    exit 1
fi

BESTIP=$(sed -n '2p' "$result_file" | awk -F, '{print $1}')
Average=$(sed -n '2p' "$result_file" | awk -F, '{print $5}')
speed=$(sed -n '2p' "$result_file" | awk -F, '{print $6}')
Packet=$(sed -n '2p' "$result_file" | awk -F, '{print $4}')

if [[ -z "$BESTIP" ]]; then
    echo "❌ 未能獲取 IP。"
    exit 1
fi

OLDIP=$(cat "$nowip_file" 2>/dev/null || echo "無")
echo "$BESTIP" > "$nowip_file"

# === 顯示並推送結果 ===
echo -e "\n✅ 舊 IP：$OLDIP"
echo -e "✅ 新 IP：$BESTIP"
echo -e "✅ 平均延遲：$Average ms"
echo -e "✅ 下載速度：$speed MB/s"
echo -e "✅ 丟包率：$Packet %"

echo "📤 發送推送通知..."
curl -s -o /dev/null --data "token=${pushplus}&title=Cloudflare IP 更新成功&content=舊 IP：${OLDIP}<br>新 IP：${BESTIP}<br>延遲：${Average} ms<br>速度：${speed} MB/s<br>丟包率：${Packet}%<br>時間：$(date +'%Y-%m-%d %H:%M:%S')&template=html" http://www.pushplus.plus/send

# 清除結果檔
rm -f "$result_file"

echo "✅ 完成！"
