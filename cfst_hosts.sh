#!/data/data/com.termux/files/usr/bin/bash

# ----------------------------------------
# CloudflareST 自動下載、執行、IP選優 + 通知（Termux 版本）
# 適用架構：aarch64 Android (Termux)
# 作者：你自己，整合：ChatGPT
# ----------------------------------------

# === 設定 ===
remote_exec_url="https://github.xxxxxxxx.nyc.mn/onlyno999/CloudflareST_Result/main/CloudflareST"  # CloudflareST 遠程地址
exec_dir=~/cfst                                 # 存放資料夾
exec_bin="${exec_dir}/CloudflareST"             # 主程序
result_file="${exec_dir}/result_hosts.txt"      # 測速結果
nowip_file="${exec_dir}/nowip_hosts.txt"        # IP 紀錄
pushplus="你的PushPlus token"                   # 推送 Token
test_count=20                                    # 測速節點數量（依你喜好）

# === 建立資料夾 ===
mkdir -p "$exec_dir"
cd "$exec_dir" || exit 1

# === 下載 CloudflareST 主程序（如不存在）===
if [[ ! -f "$exec_bin" ]]; then
    echo "📥 下載 CloudflareST 主程序中..."
    curl -L -o "$exec_bin" "$remote_exec_url"
    chmod +x "$exec_bin"
else
    echo "✅ 主程序已存在，跳過下載。"
fi

# === 執行 CloudflareST 測速 ===
echo "🚀 開始測速..."
"$exec_bin" -n "$test_count" -o "$result_file"

# === 解析結果 ===
if [[ ! -s "$result_file" ]]; then
    echo "❌ 測速失敗或結果為空"
    exit 1
fi

BESTIP=$(sed -n '2p' "$result_file" | awk -F, '{print $1}')
Average=$(sed -n '2p' "$result_file" | awk -F, '{print $5}')
speed=$(sed -n '2p' "$result_file" | awk -F, '{print $6}')
Packet=$(sed -n '2p' "$result_file" | awk -F, '{print $4}')
OLDIP=$(cat "$nowip_file" 2>/dev/null || echo "無")

# === 寫入新 IP ===
echo "$BESTIP" > "$nowip_file"

# === 顯示資訊 ===
echo -e "\n📡 舊 IP：$OLDIP"
echo -e "✅ 新 IP：$BESTIP"
echo -e "⏱️ 平均延遲：${Average} ms"
echo -e "📶 下載速度：${speed} MB/s"
echo -e "❗ 丟包率：${Packet} %"

# === 發送通知 ===
echo "📤 發送推送通知..."
curl -s -o /dev/null --data "token=${pushplus}&title=Cloudflare IP 更新成功&content=舊 IP：${OLDIP}<br>新 IP：${BESTIP}<br>平均延遲：${Average} ms<br>下載速度：${speed} MB/s<br>丟包率：${Packet} %<br>時間：$(date +'%Y-%m-%d %H:%M:%S')&template=html" http://www.pushplus.plus/send

# === 清理結果檔 ===
rm -f "$result_file"
echo "✅ 完成！"
