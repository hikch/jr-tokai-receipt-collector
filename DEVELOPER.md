# 開発者向けドキュメント

## 🏗️ プロジェクト構成

```
ex-receipts-collect/
├── collect.js        # メイン Playwright スクリプト
├── package.json      # Node.js 依存関係
├── run.sh            # collect.js の薄いラッパー
├── .env.example      # 設定テンプレート
├── .env              # 実際の設定（gitignore済み）
├── .session.json     # Playwright セッション保存（gitignore済み）
├── AGENTS.md         # AI エージェント向け仕様
├── README.md         # 利用者向け説明書
├── DEVELOPER.md      # 本ドキュメント
├── docs/
│   └── adr/
│       └── ADR.md    # アーキテクチャ決定記録
└── tmp/              # 一時ファイル（開発用）
```

## 🔧 技術スタック

- **Playwright** - Chromium ブラウザ自動化・PDF保存
- **Node.js** - 実行環境
- **dotenv** - 環境変数管理
- **Bash** - run.sh ラッパー

## 📋 動作フロー

```
1. .env 読み込み・認証情報確認
2. .session.json があれば読み込んでセッション復元
3. LOGIN_URL へアクセス
4. 未ログインなら ID/PW 入力 → ログインボタンクリック
5. 追加認証（SMS等）が必要なら Enter 待機
6. ログイン成功後 .session.json を保存
7. 利用履歴一覧ページを検出
   ↓ ページループ
8.   article 一覧を取得（領収書ボタンを持つ行のみ）
     ↓ 行ループ
9.     「領収書表示」ボタンクリック
10.    宛名を入力（環境変数が設定されている場合）
11.    「印刷」ボタン: JS直接実行で新窓を開く
12.    新窓で page.pdf() により PDF 保存
13.    新窓を閉じる → 1.5秒待機 → 「戻る」ボタン
     ↓ 行ループ終了
14.  次ページリンクがあれば遷移（先頭行変化で確認）
   ↓ ページループ終了
15. browser.close() → process.exit(0)
```

## 🔑 重要な実装メモ

### opacity:0 ボタン
サイトのボタンはすべて `opacity: 0` の `input[type="submit"]` が実体で、
見た目は `div.des` で表示している。Playwright の `click({ force: true })` が必要。

### ファイル名の日付は乗車日
`tr.date` 行には購入日（`.c2`）と乗車日（`.c5`）の両方が存在する。
ファイル名に使用するのは **乗車日（`.c5`）**。

```html
<tr class="date">
  <td class="c2"><label>購入日</label></td>   <!-- 使わない -->
  <td class="c5"><label>乗車日</label></td>   <!-- ファイル名に使用 -->
</tr>
```

### 印刷ボタンの特殊処理
印刷ボタンの onclick は `cfEXPY_checkLoadEnd()` のチェックを含むため、
クリックの代わりに `page.evaluate()` で JS を直接呼び出す:

```js
page.evaluate(() => {
  window.open('/RSV_P/p38/jsp/new_window.html', 'New_Screen');
  cfEXPY_doNoCheckAction('RSWP360AIDP036', 'New_Screen');
})
```

### ページネーション
次ページも同様に JS を直接呼び出す:

```js
page.evaluate(() => cfEXPY_doAction('RSWP360AIDP015'))
```

遷移完了の確認は「先頭 article の innerText が変化したか」で判定。

### networkidle を避ける理由
サイトがバックグラウンドで継続的にネットワーク通信するため
`waitForLoadState('networkidle')` がタイムアウトする。
代わりに `'load'` または `waitForSelector` を使用する。

## 🧪 デバッグ

ページの状態確認が必要な場合、一時的に以下を追加:

```js
await page.screenshot({ path: '/tmp/debug.png' });
require('fs').writeFileSync('/tmp/debug.html', await page.content());
```

## 🗂️ アーキテクチャ決定記録

`docs/adr/ADR.md` を参照。
