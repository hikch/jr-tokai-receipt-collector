# 開発者向けドキュメント

## 🏗️ プロジェクト構成

```
ex-receipts-collect/
├── jr_receipts_v2.applescript    # メインスクリプト
├── pagination.js                 # ページネーション機能
├── receipt_data.js               # 領収書データ抽出
├── run.sh                        # 実行スクリプト
├── README.md                     # 利用者向け説明書
├── TODO.md                       # タスク管理
├── DEVELOPER.md                  # 本ドキュメント
└── test/
    └── test_next_button.applescript  # 次ボタンテスト
```

## 🔧 技術スタック

- **AppleScript** - Safari自動化とシステム操作
- **JavaScript (ES5)** - Webページ操作とデータ抽出
- **Bash** - 環境変数設定と実行制御

## 📋 動作フロー詳細

### 1. メイン処理 (`jr_receipts_v2.applescript`)

#### 単件処理フロー
```
1. 一覧ページで行データ取得・検証
2. 「領収書表示」ボタンクリック
3. ページ遷移待機
4. 「印刷」ボタンクリック → 新タブで領収書画面
5. 領収書画面でデータ抽出してファイル名生成
6. PDF保存（印刷ダイアログキャンセル → ファイルメニュー）
7. 領収書タブクローズ
8. 「戻る」ボタンで一覧に戻る
```

#### 全件処理フロー（ページネーション対応）
```
repeat (全ページ):
  repeat (現在ページの全行):
    単件処理フロー実行
  end repeat
  
  if hasNext:
    次ページへ移動
    ページ内容変化を監視
    新ページ読み込み完了を待機
  else:
    処理完了
  end if
end repeat
```

### 2. ページネーション (`pagination.js`)

#### 主要関数
- `getTotalRowCount()` - 現在ページの行数取得
- `checkPagination()` - 次/前ボタンの存在確認
- `clickNextPage()` - 次ページボタンクリック

#### 次ページ遷移の仕組み
```javascript
// 固定値でcfEXPY_doAction関数を呼び出し
cfEXPY_doAction('RSWP360AIDP015');
```

### 3. 領収書データ抽出 (`receipt_data.js`)

#### データ取得セレクタ
```javascript
// お預かり番号
'tr.number .c2 label'

// 乗車日  
'tr.date .c5 label'
```

## 🧪 テスト・デバッグ

### テスト実行
```bash
# 次ボタン機能テスト
osascript test/test_next_button.applescript

# 少数件テスト - Web側で期間を短く設定してからスクリプト実行
./run.sh
```

### デバッグ方法

1. **Safari開発者コンソール**
   ```
   ⌘+⌥+C でコンソール開く
   pagination.jsの詳細ログを確認
   ```

2. **AppleScript通知**
   ```
   各処理段階でmacOS通知が表示される
   エラー詳細はダイアログで表示
   ```

3. **ページタイプ確認**
   ```applescript
   -- 現在表示中の画面タイプを判定
   checkCurrentPageType()
   ```

## 📁 ファイル詳細

### `jr_receipts_v2.applescript`

#### 主要関数
- `processSingleReceipt()` - 1件の領収書処理
- `processAllReceipts()` - 全件処理（ページネーション対応）
- `saveReceiptAsPDF()` - PDF保存（動的ファイル名生成）
- `checkCurrentPageType()` - 画面タイプ判定
- `closeCurrentTab()` - 安全なタブクローズ

#### 環境変数
- `SAVE_DIR` - PDF保存先
- `RECEIPT_NAME_LINE1` - 領収書宛名1行目
- `RECEIPT_NAME_LINE2` - 領収書宛名2行目

### ファイル名生成ロジック
```applescript
-- 領収書画面から取得したデータで生成
-- normalizedDate = 乗車日(YYYY-MM-DD形式)
-- depositNumber = お預かり番号
set fileName to normalizedDate & "_" & depositNumber & ".pdf"
-- 例: "2025-07-26_2026.pdf" (2025年7月26日乗車、お預かり番号2026)
```

## 🐛 既知の問題・制限事項

### 1. ページ遷移の検出
- URLが変わらないため、ページ内容の変化で判定
- 最初の行データを比較して遷移完了を検知

### 2. タイミング調整
```applescript
-- 印刷ダイアログキャンセル後の処理順序が重要
delay 1  -- キャンセル処理完了待機
-- データ取得・ファイル名生成
-- PDF書き出し実行
```

### 3. Safari依存
- Apple Events からのJavaScript実行が必須
- Safari固有の動作に依存（他ブラウザ不可）

## 🔄 継続的改善

### パフォーマンス
- `delay` の最適化
- エラーハンドリングの強化
- 並列処理の検討

### 機能追加案
- ~~日付範囲指定フィルタ~~ → EX予約サイトの期間選択機能で代替
- 重複ファイルチェック
- 処理進捗の詳細表示
- 設定ファイルサポート

### 期間選択について
現在は**EX予約サイトの標準機能**を使用：
- サイト上で利用履歴の表示期間を選択
- スクリプトは表示されている期間の全データを処理
- この方式により、サイトのUI変更に対する耐性を確保

### コード品質
- AppleScript関数の分割
- JavaScriptのモジュール化
- エラーメッセージの統一

## 🤝 コントリビューション

1. `feature/*` ブランチで開発
2. テスト実行確認
3. コミットメッセージは従来の形式に準拠
4. プルリクエスト作成

### コミットメッセージ例
```
feat: Add new feature description
fix: Fix specific bug description  
refactor: Refactor component description
docs: Update documentation
test: Add test for specific functionality
```

## 📚 参考資料

- [AppleScript Language Guide](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/)
- [Safari JavaScript Automation](https://developer.apple.com/documentation/safariservices)
- [JR東海EX予約 技術仕様](https://jr-central.co.jp) (非公式)