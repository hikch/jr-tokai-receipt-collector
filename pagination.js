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
  var nextButton = document.querySelector('a[name="b3"]');
  
  if (nextButton) {
    // 方法1: cfEXPY_doAction関数を直接呼び出し
    try {
      if (typeof cfEXPY_doAction === 'function') {
        cfEXPY_doAction('RSWP360AIDP015');
        return "Next page cfEXPY_doAction executed";
      }
    } catch (e) {
      // 失敗時は次の方法を試行
    }
    
    // 方法2: onclickイベントを直接実行
    var onclickCode = nextButton.getAttribute('onclick');
    if (onclickCode) {
      try {
        eval(onclickCode);
        return "Next page onclick executed";
      } catch (e) {
        // eval失敗時は通常のclickを試行
        nextButton.click();
        return "Next page button clicked (fallback)";
      }
    } else {
      nextButton.click();
      return "Next page button clicked";
    }
  } else {
    return "Next page button not found";
  }
}