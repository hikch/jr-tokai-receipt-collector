-- 次ボタンテスト用スクリプト

on run
  try
    tell application "Safari"
      tell front document
        set testJS to "
        (() => {
          // pagination.jsのclickNextPage関数をテスト
          var nextButton = document.querySelector('a[name=\"b3\"]');
          if (nextButton) {
            var onclickCode = nextButton.getAttribute('onclick');
            try {
              // return false;を除去してeval実行
              var cleanCode = onclickCode.replace(/;?\\s*return\\s+false;?\\s*$/, '');
              eval(cleanCode);
              return 'NextPage executed: ' + cleanCode;
            } catch (e) {
              return 'NextPage failed: ' + e.message;
            }
          }
          return 'NextButton not found';
        })()
        "
        
        set result to (do JavaScript testJS)
        do shell script "echo 'Next button test result: '" & quoted form of (result as string)
        
      end tell
    end tell
  on error errMsg
    do shell script "echo 'Error: " & errMsg & "'"
  end try
end run