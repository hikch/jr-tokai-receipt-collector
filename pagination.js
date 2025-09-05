// ページネーション関連のJavaScript関数 (ES5互換)

// 総行数取得
function getTotalRowCount() {
  var ROW_SELECTOR = "form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article";
  return document.querySelectorAll(ROW_SELECTOR).length;
}

// ページネーション確認
function checkPagination() {
  var nextButton = document.querySelector('a[name="b3"]') ||
                  document.querySelector('input[type="submit"][value="次へ"]') ||
                  document.querySelector('button[value="次へ"]');
  
  var prevButton = document.querySelector('a[name="b2"]') ||
                  document.querySelector('input[type="submit"][value="前へ"]') ||
                  document.querySelector('button[value="前へ"]');
  
  return {
    hasNext: !!nextButton,
    hasPrev: !!prevButton,
    nextEnabled: !!nextButton,
    prevEnabled: !!prevButton
  };
}

// 次ページボタンクリック
function clickNextPage() {
  console.log("=== clickNextPage() 開始 ===");
  
  var nextButton = document.querySelector('a[name="b3"]');
  console.log("次ボタン検索結果:", nextButton);
  
  if (nextButton) {
    console.log("次ボタンHTML:", nextButton.outerHTML);
    console.log("onclick属性:", nextButton.getAttribute('onclick'));
    
    // cfEXPY_doAction関数の存在確認
    console.log("cfEXPY_doAction関数の型:", typeof cfEXPY_doAction);
    console.log("cfEXPY_doAction関数:", cfEXPY_doAction);
    
    // 方法1: cfEXPY_doAction関数を直接呼び出し（固定値RSWP360AIDP015を使用）
    try {
      if (typeof cfEXPY_doAction === 'function') {
        console.log("cfEXPY_doAction('RSWP360AIDP015') 実行中...");
        cfEXPY_doAction('RSWP360AIDP015');
        console.log("cfEXPY_doAction('RSWP360AIDP015') 実行完了");
        return "Next page executed: cfEXPY_doAction('RSWP360AIDP015')";
      }
    } catch (e) {
      console.error("cfEXPY_doAction実行エラー:", e);
      return "cfEXPY_doAction failed: " + e.message;
    }
    
    // cfEXPY_doAction関数が存在しない場合のフォールバック
    console.error("cfEXPY_doAction関数が見つかりません");
    return "cfEXPY_doAction function not found";
    
  } else {
    console.error("次ボタン(a[name='b3'])が見つかりません");
    
    // 代替セレクタでも検索してみる
    var alternativeButtons = document.querySelectorAll('a[href="#"]');
    console.log("代替検索結果 a[href='#']:", alternativeButtons.length + "個");
    for (var i = 0; i < alternativeButtons.length; i++) {
      console.log("代替ボタン" + i + ":", alternativeButtons[i].outerHTML);
    }
    
    return "Next page button not found";
  }
}