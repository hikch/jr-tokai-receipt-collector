-- JR東海セレクタデバッグ用スクリプト

-- JavaScript読み込み
on loadJavaScript(fileName)
  set scriptDir to (do shell script "dirname " & quoted form of ((POSIX path of (path to me)) as string))
  set jsFile to scriptDir & "/" & fileName
  try
    set jsContent to (do shell script "cat " & quoted form of jsFile)
    return {success:true, content:jsContent}
  on error errMsg
    return {success:false, message:"Failed to load " & fileName & ": " & errMsg}
  end try
end loadJavaScript

-- デバッグ実行
on run
  try
    tell application "Safari"
      tell front document
        set debugJS to "
        (() => {
          // 実際に次ページをクリックテスト
          var nextButton = document.querySelector('a[name=\"b3\"]');
          if (nextButton) {
            try {
              eval(nextButton.getAttribute('onclick'));
              return 'NextPage: onclick executed successfully';
            } catch (e) {
              return 'NextPage: onclick failed - ' + e.message;
            }
          }
          return 'NextButton: not found';
        })()
        "
        
        set result to (do JavaScript debugJS)
        do shell script "echo 'Debug result: '" & quoted form of (result as string)
        
      end tell
    end tell
  on error errMsg
    do shell script "echo 'Error: " & errMsg & "'"
  end try
end run