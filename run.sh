#!/usr/bin/env bash
set -euo pipefail

# 実行ディレクトリをこのファイルの場所に固定
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==== 基本設定（環境変数で上書き可能）====
: "${SAVE_DIR:=$HOME/Desktop/Receipts/JRC}"
: "${PROCESS_ALL:=true}"  # デフォルトで全件処理

echo "=== JR東海領収書自動収集 ==="
echo "保存先: $SAVE_DIR"
echo "全件処理: $PROCESS_ALL"
echo "=========================="

export SAVE_DIR PROCESS_ALL

osascript "$SCRIPT_DIR/jr_receipts_v2.applescript"
