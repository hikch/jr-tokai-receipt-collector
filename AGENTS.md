# AGENTS.md — ex-receipts-collect

## プロジェクト概要

JR東海EX予約サイトから領収書PDFを自動収集するツール。
Playwright (Chromium) でブラウザを操作し、印刷ダイアログを使わずに `page.pdf()` で直接PDF保存する。

## ディレクトリ構成

```
ex-receipts-collect/
  collect.js        # メイン Playwright スクリプト（実装対象）
  package.json      # Node.js 依存関係
  run.sh            # collect.js の薄いラッパー
  .env.example      # 認証情報テンプレート
  README.md         # ユーザー向けドキュメント
  DEVELOPER.md      # 開発者向けメモ
  docs/             # 追加ドキュメント
  test/             # テスト
```

## 実装仕様: collect.js

### ログイン
- URL: `https://shinkansen1.jr-central.co.jp/RSV_P/index.htm`
- 会員ID入力: `input[placeholder*="数字10桁"]`
- パスワード入力: `input[type="password"]`
- ログインボタン: `button:has-text("ログイン")`

### ページ検出
- 利用履歴ページ判定: `form.history.history-index.history-index-corp` の存在確認
- ログイン後に利用履歴ページが見つからない場合はユーザーに案内して待機

### 行セレクター（領収書対象行）
```
form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article
```

### 各行の処理フロー
1. `input[type="submit"][value="領収書表示"]` をクリック
2. `waitForLoadState('networkidle')` でページ遷移待機
3. 宛名入力（環境変数が設定されている場合）:
   - 1行目: `input[name="i1"]`
   - 2行目: `input[name="i2"]`
4. `input[value="印刷"]` クリック → `context.waitForEvent('page')` で新タブ取得
5. 新タブで `page.pdf({ path, format:'A4', printBackground:true })` で直接保存
6. ファイル名生成: 新タブの `tr.number .c2 label`（お預かり番号）と `tr.date .c5 label`（乗車日）から `YYYY-MM-DD_番号.pdf`
7. 新タブを閉じる
8. `button[name="b2"]` で戻る

### ページネーション
- 次ページリンク存在確認: `a[name="b3"]`
- 次ページ遷移: `page.evaluate(() => cfEXPY_doAction('RSWP360AIDP015'))`
- ページ内容変化を待機してから次ループ

### 環境変数
| 変数名 | 必須 | デフォルト | 説明 |
|--------|------|-----------|------|
| `EX_USER_ID` | ✓ | — | 会員ID（10桁数字） |
| `EX_PASSWORD` | ✓ | — | パスワード |
| `SAVE_DIR` | — | `~/Desktop/Receipts/JRC` | PDF保存先 |
| `RECEIPT_NAME_LINE1` | — | (空) | 宛名1行目 |
| `RECEIPT_NAME_LINE2` | — | (空) | 宛名2行目 |

### 実行モード
- `headless: false`（ユーザーが確認できるよう）

## 技術スタック
- Node.js (ESM or CJS どちらでも可)
- `playwright` パッケージ（`@playwright/test` ではなく `playwright`）
- `dotenv` で `.env` ファイルサポート

## 実行方法
```bash
npm install
npx playwright install chromium
EX_USER_ID=xxxx EX_PASSWORD=xxxx node collect.js
```

または `.env` ファイルを作成して:
```bash
npm install
npx playwright install chromium
node collect.js
```
