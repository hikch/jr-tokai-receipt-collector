// 領収書画面データ取得用のJavaScript関数 (ES5互換)

// 領収書画面からお預かり番号と乗車日を取得
function getReceiptData() {
  // お預かり番号を取得（領収書画面）
  var depositNumberElement = document.querySelector('tr.number .c2 label');
  var depositNumber = depositNumberElement ? depositNumberElement.textContent.trim() : '';
  
  // 乗車日を取得（領収書画面）
  var rideDateElement = document.querySelector('tr.date .c5 label');
  var rideDate = rideDateElement ? rideDateElement.textContent.trim() : '';
  
  return {
    depositNumber: depositNumber,
    rideDate: rideDate
  };
}