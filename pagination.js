// ページネーション関連のJavaScript関数 (ES5互換)

// 総行数取得
function getTotalRowCount() {
  var ROW_SELECTOR = "form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article";
  return document.querySelectorAll(ROW_SELECTOR).length;
}

// ページネーション確認
function checkPagination() {
  var nextButton = document.querySelector('input[type="submit"][value="次へ"]') ||
                  document.querySelector('button[value="次へ"]') ||
                  document.querySelector('a[href*="next"]');
  
  var prevButton = document.querySelector('input[type="submit"][value="前へ"]') ||
                  document.querySelector('button[value="前へ"]') ||
                  document.querySelector('a[href*="prev"]');
  
  return {
    hasNext: !!nextButton && !nextButton.disabled,
    hasPrev: !!prevButton && !prevButton.disabled,
    nextEnabled: nextButton ? !nextButton.disabled : false,
    prevEnabled: prevButton ? !prevButton.disabled : false
  };
}

// 次ページボタンクリック
function clickNextPage() {
  var nextButton = document.querySelector('input[type="submit"][value="次へ"]') ||
                  document.querySelector('button[value="次へ"]');
  
  if (nextButton && !nextButton.disabled) {
    nextButton.click();
    return "Next page button clicked";
  } else {
    return "Next page button not available";
  }
}