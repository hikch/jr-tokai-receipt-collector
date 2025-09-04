#!/usr/bin/env bash
set -euo pipefail

# 実行ディレクトリをこのファイルの場所に固定
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==== 必要に応じて上書き（環境変数で指定可）====
: "${SAVE_DIR:=$HOME/Desktop/Receipts}"
# EX予約 ご利用履歴一覧 向け既定セレクタ
: "${ROW_SELECTOR:=form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article}"
: "${DATE_SELECTOR:=table:nth-of-type(1) td:nth-of-type(2)}"
: "${SUMMARY_SELECTOR:=table:nth-of-type(2) td:nth-of-type(2)}"
: "${RECEIPT_TEXT:=領収書}"
: "${RECEIPT_SELECTOR:=input[type=\"submit\"][value=\"領収書表示\"]}"

# 追加オプション
: "${LIST_URL:=}"
: "${NEXT_SELECTOR:=a[name=\"b3\"]}"
: "${DATE_FROM:=}"
: "${DATE_TO:=}"
: "${DRY_RUN:=}"

export SAVE_DIR ROW_SELECTOR DATE_SELECTOR SUMMARY_SELECTOR RECEIPT_TEXT RECEIPT_SELECTOR \
  LIST_URL NEXT_SELECTOR DATE_FROM DATE_TO DRY_RUN

osascript "$SCRIPT_DIR/jr_receipts.applescript"
