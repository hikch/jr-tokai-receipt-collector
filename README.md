# JR東海領収書自動収集

JR東海のWebサイトから領収書PDFを自動収集するAppleScriptツール。

## 使用方法

1. Safariで[JR東海利用履歴一覧ページ](https://jr-central.co.jp)にアクセス
2. スクリプト実行：
   ```bash
   ./run.sh
   # または
   osascript jr_receipts_v2.applescript
   ```

## 動作フロー

1. **一覧画面** → 「領収書表示」ボタンクリック → **領収書表示画面**
2. **領収書表示画面** → 「印刷」ボタンクリック → **領収書画面**（新タブ）
3. **領収書画面** → PDF保存（ファイルメニュー経由）
4. タブ閉じ → 「戻る」ボタンで**一覧画面**に戻る

## 設定

環境変数で設定可能：
- `SAVE_DIR`: 保存先ディレクトリ（デフォルト: `~/Desktop/Receipts/JRC`）
- `DRY_RUN`: プレビューモード（`true`で実行なし）

## 必要な設定

Safari > Develop > Allow JavaScript from Apple Events を有効化