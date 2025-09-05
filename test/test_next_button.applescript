(*
  次ボタンテスト専用スクリプト v2
  pagination.jsの次ボタン機能をテスト（詳細ログ付き）
*)

-- ====== JavaScript読み込み ======
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

-- ====== Safari接続確認 ======
on checkSafariConnection()
  tell application "Safari"
    if (count of windows) = 0 then
      return {success:false, message:"Safari has no windows open"}
    end if
    
    tell front document
      set pageURL to URL
      if pageURL does not contain "jr-central.co.jp" then
        return {success:false, message:"Not on JR Central website: " & pageURL}
      end if
      
      return {success:true, message:"Safari connected to JR Central site: " & pageURL}
    end tell
  end tell
end checkSafariConnection

-- ====== 次ボタンテスト実行 ======
on testNextButton()
  try
    -- pagination.js読み込み
    set jsLoad to my loadJavaScript("pagination.js")
    if not (success of jsLoad) then
      return {success:false, message:"Could not load pagination.js: " & (message of jsLoad)}
    end if
    
    tell application "Safari"
      tell front document
        -- JavaScript実行
        do JavaScript (content of jsLoad)
        
        -- コンソールクリア
        do JavaScript "console.clear()"
        do JavaScript "console.log('=== 次ボタンテスト開始 ===')"
        
        -- ページネーション状態確認
        set paginationCheck to (do JavaScript "checkPagination()")
        set hasNext to hasNext of paginationCheck
        
        do JavaScript "console.log('hasNext:', " & hasNext & ")"
        
        if hasNext then
          -- 次ボタンクリック実行
          set nextResult to (do JavaScript "clickNextPage()")
          do JavaScript "console.log('=== 次ボタンテスト完了 ===')"
          
          return {success:true, hasNext:hasNext, result:nextResult}
        else
          do JavaScript "console.log('次ボタンが存在しません')"
          return {success:false, hasNext:hasNext, message:"次ボタンが存在しません"}
        end if
      end tell
    end tell
  on error errMsg
    return {success:false, message:"Test failed: " & errMsg}
  end try
end testNextButton

-- ====== メイン実行 ======
on run
  display notification "次ボタンテスト開始" with title "Test"
  
  -- Safari接続確認
  set safariCheck to my checkSafariConnection()
  if not (success of safariCheck) then
    display alert "Safari Connection Failed" message (message of safariCheck)
    return
  end if
  
  display notification (message of safariCheck) with title "Safari OK"
  
  -- 次ボタンテスト実行
  set testResult to my testNextButton()
  
  if success of testResult then
    if hasNext of testResult then
      set resultMsg to "結果: " & (result of testResult)
      display notification resultMsg with title "Test Success"
    else
      display notification "次ボタンなし（最後のページ）" with title "Test Info"
    end if
  else
    display alert "Test Failed" message (message of testResult)
  end if
  
  -- デバッグ情報の確認を促す
  display notification "Safariの開発者コンソールでログを確認してください" with title "Debug Info"
  
  -- Safari開発者コンソールを開くためのキーボードショートカット案内
  display alert "デバッグ情報" message "Safari > 開発 > JavaScriptコンソールを表示 (⌘+⌥+C) でログを確認できます"
end run