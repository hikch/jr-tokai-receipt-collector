'use strict';

require('dotenv').config();
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const os = require('os');

// ---- 設定 ----------------------------------------------------------------
const { execSync } = require('child_process');

function fromSafariKeychain() {
  try {
    const out = execSync(
      'security find-internet-password -s "shinkansen1.jr-central.co.jp" -g 2>&1',
      { stdio: ['pipe', 'pipe', 'pipe'] }
    ).toString();
    const account  = out.match(/"acct"<blob>="([^"]+)"/)?.[1] ?? null;
    const password = out.match(/^password: "(.+)"$/m)?.[1] ?? null;
    return { account, password };
  } catch {
    return { account: null, password: null };
  }
}

const _keychain = fromSafariKeychain();
const USER_ID  = process.env.EX_USER_ID  || _keychain.account;
const PASSWORD = process.env.EX_PASSWORD || _keychain.password;
const SAVE_DIR = path.resolve(
  (process.env.SAVE_DIR || '~/Desktop/Receipts/JRC').replace(/^~/, os.homedir())
);
const NAME1 = process.env.RECEIPT_NAME_LINE1 || '';
const NAME2 = process.env.RECEIPT_NAME_LINE2 || '';

const LOGIN_URL   = 'https://shinkansen1.jr-central.co.jp/RSV_P/index.htm';
const SESSION_FILE = path.join(__dirname, '.session.json');
const REQUEST_INTERVAL_MS = parseInt(process.env.REQUEST_INTERVAL_MS || '1500', 10);

// ---- セレクター -----------------------------------------------------------
const SEL = {
  userId:       'input[placeholder*="数字10桁"]',
  password:     'input[type="password"]',
  loginButton:  'input[type="submit"][value="ログイン"]',
  historyForm:  'form.history.history-index.history-index-corp',
  articles:     'form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article',
  showReceipt:  'input[type="submit"][value="領収書表示"]',
  nameInput1:   'input[name="i1"]',
  nameInput2:   'input[name="i2"]',
  printButton:  'input[value="印刷"]',
  backButton:   'button[name="b2"]',
  nextPage:     'a[name="b3"]',
  receiptNum:   'tr.number .c2 label',
  receiptDate:  'tr.date .c5 label',
};

// ---- ユーティリティ -------------------------------------------------------

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

/** 乗車日文字列 "2025年7月26日" → "2025-07-26" */
function parseDate(str) {
  const m = str.match(/(\d{4})年(\d{1,2})月(\d{1,2})日/);
  if (!m) return str.replace(/\s/g, '');
  return `${m[1]}-${String(m[2]).padStart(2, '0')}-${String(m[3]).padStart(2, '0')}`;
}

/** ページ内のarticle一覧を返す（領収書ボタンを持つもののみ） */
async function getReceiptArticles(page) {
  const articles = await page.$$(SEL.articles);
  const result = [];
  for (const art of articles) {
    const btn = await art.$(SEL.showReceipt);
    if (btn) result.push(art);
  }
  return result;
}

// ---- メイン --------------------------------------------------------------

(async () => {
  if (!USER_ID || !PASSWORD) {
    console.error('エラー: 認証情報が見つかりません。');
    console.error('  .env に EX_USER_ID と EX_PASSWORD を設定してください。');
    console.error('  ※ Safari の iCloud キーチェーンには自動アクセスできません。');
    process.exit(1);
  }

  ensureDir(SAVE_DIR);
  console.log(`=== JR東海領収書自動収集 (Playwright版) ===`);
  console.log(`保存先: ${SAVE_DIR}`);
  if (NAME1 || NAME2) console.log(`宛名: [${NAME1}] [${NAME2}]`);
  console.log(`==========================================`);

  const hasSession = fs.existsSync(SESSION_FILE);
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext(
    hasSession ? { storageState: SESSION_FILE } : {}
  );
  const page = await context.newPage();

  // ---- ログイン（セッションがない or 切れている場合）--------------------
  await page.goto(LOGIN_URL, { waitUntil: 'load' });

  const alreadyLoggedIn = await page.$(SEL.historyForm);
  if (!alreadyLoggedIn) {
    console.log(hasSession ? 'セッション切れ。再ログインします...' : 'ログイン中...');
    // ログインページへ移動していない場合はログインURLへ
    if (!page.url().includes('index.htm') && !page.url().includes('login')) {
      await page.goto(LOGIN_URL, { waitUntil: 'load' });
    }
    await page.fill(SEL.userId,   USER_ID);
    await page.fill(SEL.password, PASSWORD);
    await page.click(SEL.loginButton, { force: true });
    await page.waitForLoadState('load');

    // SMS認証などの追加ステップがある場合はユーザーに対応してもらう
    const historyAfterLogin = await page.$(SEL.historyForm);
    if (!historyAfterLogin) {
      console.log('');
      console.log('SMS認証などの追加手順が必要です。');
      console.log('ブラウザで認証を完了し、利用履歴一覧ページを表示してから');
      console.log('Enter キーを押してください...');
      await new Promise(resolve => process.stdin.once('data', resolve));
    }

    // ログイン成功後にクッキーを保存
    await context.storageState({ path: SESSION_FILE });
    console.log('セッションを保存しました。次回からSMS認証をスキップします。');
  } else {
    console.log('保存済みセッションでログイン済みです。');
  }

  // ---- ページごとに処理 --------------------------------------------------
  let pageNum = 1;
  let totalSaved = 0;

  while (true) {
    console.log(`\n--- ページ ${pageNum} を処理中 ---`);

    await page.waitForSelector(SEL.historyForm, { timeout: 30000 });
    const articles = await getReceiptArticles(page);
    console.log(`  領収書対象: ${articles.length} 件`);

    for (let i = 0; i < articles.length; i++) {
      // articlesは参照が古くなるので毎回取り直す
      const freshArticles = await getReceiptArticles(page);
      const article = freshArticles[i];
      if (!article) break;

      const btn = await article.$(SEL.showReceipt);
      if (!btn) continue;

      console.log(`  [${i + 1}/${articles.length}] 領収書表示...`);
      await btn.click({ force: true });
      await page.waitForLoadState('load');

      // 宛名入力
      if (NAME1) {
        const n1 = await page.waitForSelector(SEL.nameInput1, { timeout: 5000 }).catch(() => null);
        if (!n1) throw new Error(`宛名入力欄1 (${SEL.nameInput1}) が見つかりません。宛名なしで処理を続けるには RECEIPT_NAME_LINE1 を空にしてください。`);
        await n1.fill(NAME1);
      }
      if (NAME2) {
        const n2 = await page.waitForSelector(SEL.nameInput2, { timeout: 5000 }).catch(() => null);
        if (!n2) throw new Error(`宛名入力欄2 (${SEL.nameInput2}) が見つかりません。宛名なしで処理を続けるには RECEIPT_NAME_LINE2 を空にしてください。`);
        await n2.fill(NAME2);
      }

      // 印刷ボタン: cfEXPY_checkLoadEnd() チェックを迂回して直接JS実行
      const [receiptPage] = await Promise.all([
        context.waitForEvent('page'),
        page.evaluate(() => {
          window.open('/RSV_P/p38/jsp/new_window.html', 'New_Screen');
          cfEXPY_doNoCheckAction('RSWP360AIDP036', 'New_Screen');
        }),
      ]);
      await receiptPage.waitForLoadState('load');

      // ファイル名生成（取得失敗時は保存中止）
      const numText  = await receiptPage.$eval(SEL.receiptNum,  el => el.textContent.trim()).catch(() => null);
      const dateText = await receiptPage.$eval(SEL.receiptDate, el => el.textContent.trim()).catch(() => null);
      if (!numText || !dateText) {
        await receiptPage.screenshot({ path: path.join(SAVE_DIR, `error_${Date.now()}.png`) });
        throw new Error(`領収書情報の取得に失敗しました（番号: ${numText}, 乗車日: ${dateText}）。エラースクリーンショットを保存しました。`);
      }
      const dateStr  = parseDate(dateText);
      const fileName = `${dateStr}_${numText.replace(/\s/g, '')}.pdf`;
      const filePath = path.join(SAVE_DIR, fileName);

      await receiptPage.pdf({ path: filePath, format: 'A4', printBackground: true });
      console.log(`    保存: ${fileName}`);
      totalSaved++;

      await receiptPage.close();

      // サーバー負荷への配慮
      await page.waitForTimeout(REQUEST_INTERVAL_MS);

      // 利用履歴一覧に戻る
      const backBtn = await page.$(SEL.backButton);
      if (backBtn) {
        await backBtn.click({ force: true });
      } else {
        await page.goBack();
      }
      // 一覧ページが復元されるまで待つ
      await page.waitForSelector(SEL.historyForm, { timeout: 30000 });
    }

    // ---- ページネーション ------------------------------------------------
    const nextLink = await page.$(SEL.nextPage);
    if (!nextLink) break;

    console.log(`  次のページへ...`);
    // 先頭行のテキストを記録してページ変化を確認
    const firstArticles = await getReceiptArticles(page);
    const prevFirstText = firstArticles.length > 0
      ? await firstArticles[0].innerText().catch(() => '')
      : '';
    await page.evaluate(() => cfEXPY_doAction('RSWP360AIDP015'));
    await page.waitForLoadState('networkidle');
    // 先頭行が変化したことを確認（最大15秒）
    const changed = await page.waitForFunction(
      ({ sel, prev }) => {
        const arts = document.querySelectorAll(sel);
        if (arts.length === 0) return true;
        return arts[0].innerText !== prev;
      },
      { sel: SEL.articles, prev: prevFirstText },
      { timeout: 15000 }
    ).catch(() => null);
    if (!changed) throw new Error(`ページ ${pageNum} → ${pageNum + 1} への遷移が確認できませんでした。処理を中止します。`);
    pageNum++;
  }

  console.log(`\n=== 完了: ${totalSaved} 件のPDFを保存しました ===`);
  console.log(`保存先: ${SAVE_DIR}`);

  await browser.close();
  process.exit(0);
})().catch(err => {
  console.error('\n予期しないエラーが発生しました:', err.message);
  process.exit(1);
});
