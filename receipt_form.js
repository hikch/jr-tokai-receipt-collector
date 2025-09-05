// 領収書表示画面フォーム入力用のJavaScript関数 (ES5互換)

// 宛名入力関数
function fillReceiptName(line1, line2) {
  console.log("=== fillReceiptName() 開始 ===");
  console.log("line1:", line1);
  console.log("line2:", line2);
  
  var input1 = document.querySelector('input[name="i1"]');
  var input2 = document.querySelector('input[name="i2"]');
  
  console.log("input1 element:", input1);
  console.log("input2 element:", input2);
  
  if (!input1) {
    return "宛名入力欄1 (i1) が見つかりません";
  }
  
  if (!input2) {
    return "宛名入力欄2 (i2) が見つかりません";
  }
  
  try {
    // 1行目入力
    if (line1) {
      input1.value = line1;
      input1.dispatchEvent(new Event('input', { bubbles: true }));
      console.log("line1 入力完了:", line1);
    }
    
    // 2行目入力
    if (line2) {
      input2.value = line2;
      input2.dispatchEvent(new Event('input', { bubbles: true }));
      console.log("line2 入力完了:", line2);
    }
    
    console.log("=== fillReceiptName() 完了 ===");
    return "宛名入力完了: [" + (line1 || "") + "] [" + (line2 || "") + "]";
    
  } catch (e) {
    console.error("宛名入力エラー:", e);
    return "宛名入力エラー: " + e.message;
  }
}