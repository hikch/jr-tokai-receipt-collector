#!/usr/bin/env bash
set -euo pipefail

# 実行ディレクトリをこのファイルの場所に固定
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==== 基本設定（環境変数で上書き可能）====
: "${SAVE_DIR:=$HOME/Desktop/Receipts/JRC}"
: "${RECEIPT_NAME_LINE1:=}"  # 宛名1行目
: "${RECEIPT_NAME_LINE2:=}"  # 宛名2行目

echo "=== JR東海領収書自動収集 ==="
echo "保存先: $SAVE_DIR"
if [ -n "$RECEIPT_NAME_LINE1" ] || [ -n "$RECEIPT_NAME_LINE2" ]; then
  echo "宛名: [$RECEIPT_NAME_LINE1] [$RECEIPT_NAME_LINE2]"
fi
echo "=========================="

export SAVE_DIR RECEIPT_NAME_LINE1 RECEIPT_NAME_LINE2

osascript "$SCRIPT_DIR/jr_receipts_v2.applescript"
