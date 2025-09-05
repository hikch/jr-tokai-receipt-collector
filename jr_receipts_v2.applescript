(*
  JR東海領収書一括保存 v2 - 関数分離版
  Safari + AppleScript for 一覧→領収書PDF自動保存
*)

-- ====== 環境変数取得 ======
on getenv(k, def)
  try
    set v to system attribute k
    if v is missing value or v = "" then return def
    return v
  on error
    return def
  end try
end getenv

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
      
      return {success:true, message:"Safari connected to JR Central site"}
    end tell
  end tell
end checkSafariConnection

-- ====== 履歴一覧ページ確認 ======
on checkHistoryPage()
  try
    tell application "Safari"
      tell front document
        set hasHistoryForm to (do JavaScript "document.querySelector('form.history') !== null")
        set articlesCount to (do JavaScript "document.querySelectorAll('article').length")
        set receiptButtonsCount to (do JavaScript "document.querySelectorAll('input[value*=\"領収書\"]').length")
        
        if not hasHistoryForm then
          return {success:false, message:"History form not found - please navigate to 利用履歴一覧"}
        end if
        
        return {success:true, articlesCount:articlesCount, receiptButtonsCount:receiptButtonsCount}
      end tell
    end tell
  on error errMsg
    return {success:false, message:"JavaScript error: " & errMsg & " (Enable 'Allow JavaScript from Apple Events' in Safari > Develop menu)"}
  end try
end checkHistoryPage

-- ====== 行データ取得テスト ======
on getRowData(rowIndex)
  set ROW_SELECTOR to "form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article"
  set DATE_SELECTOR to "table:nth-of-type(1) td:nth-of-type(2)"
  set SUMMARY_SELECTOR to "table:nth-of-type(2) td:nth-of-type(2)"
  
  try
    tell application "Safari"
      tell front document
        set jsCode to "
        (() => {
          const articles = document.querySelectorAll('" & ROW_SELECTOR & "');
          if (" & rowIndex & " >= articles.length) return null;
          const row = articles[" & rowIndex & "];
          const dateEl = row.querySelector('" & DATE_SELECTOR & "');
          const summaryEl = row.querySelector('" & SUMMARY_SELECTOR & "');
          return {
            date: dateEl ? dateEl.textContent.trim() : '',
            summary: summaryEl ? summaryEl.textContent.trim() : '',
            hasReceiptButton: !!row.querySelector('input[value*=\"領収書\"]')
          };
        })()
        "
        
        set result to (do JavaScript jsCode)
        return {success:true, data:result}
      end tell
    end tell
  on error errMsg
    return {success:false, message:"Row data error: " & errMsg}
  end try
end getRowData


-- ====== 領収書ボタンクリック ======
on clickReceiptButton(rowIndex)
  set ROW_SELECTOR to "form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article"
  set RECEIPT_SELECTOR to "input[type=\"submit\"][value=\"領収書表示\"]"
  
  try
    tell application "Safari"
      tell front document
        set clickJS to "
        (() => {
          const articles = document.querySelectorAll('" & ROW_SELECTOR & "');
          if (" & rowIndex & " >= articles.length) return 'Row not found';
          
          const row = articles[" & rowIndex & "];
          const button = row.querySelector('" & RECEIPT_SELECTOR & "');
          
          if (!button) return 'Receipt button not found';
          
          // クリック実行
          button.click();
          return 'Receipt button clicked';
        })();
        "
        
        set result to (do JavaScript clickJS)
        return {success:true, message:result}
      end tell
    end tell
  on error errMsg
    return {success:false, message:"Click failed: " & errMsg}
  end try
end clickReceiptButton

-- ====== ページ遷移待機（同じタブ） ======
on waitForPageTransition()
  tell application "Safari"
    tell front document
      -- ページの読み込み完了を待機
      repeat with i from 1 to 20
        delay 0.5
        try
          set readyState to (do JavaScript "document.readyState")
          if readyState is "complete" then
            return {success:true, message:"Page transition completed"}
          end if
        on error
          -- JavaScript実行エラーは無視して続行
        end try
      end repeat
      
      return {success:false, message:"Timeout: Page transition not completed"}
    end tell
  end tell
end waitForPageTransition

-- ====== 新規タブ待機（印刷ボタン用） ======
on waitForNewTabFromPrint()
  tell application "Safari"
    set originalTabCount to count of tabs of front window
    
    -- 新規タブが開くまで待機（印刷ダイアログより先にチェック）
    repeat with i from 1 to 20
      delay 0.5
      try
        set currentTabCount to count of tabs of front window
        if currentTabCount > originalTabCount then
          -- 新規タブを前面化
          set current tab of front window to last tab of front window
          delay 1
          
          -- 印刷ダイアログが表示される場合があるのでキャンセル
          tell application "Safari" to activate
          delay 0.5
          tell application "System Events"
            try
              keystroke "." using command down
            on error
              -- ダイアログがない場合は無視
            end try
          end tell
          delay 1
          
          return {success:true, message:"New receipt tab detected and activated"}
        end if
      on error
        -- タブカウントエラーは無視して続行
      end try
    end repeat
    
    return {success:false, message:"Timeout: New receipt tab not detected"}
  end tell
end waitForNewTabFromPrint

-- ====== 印刷ボタンクリック（領収書表示画面→領収書画面） ======
on clickPrintButton()
  try
    tell application "Safari"
      tell front document
        set printJS to "
        (() => {
          const printButton = document.querySelector('input[type=\"button\"][value=\"印刷\"]') ||
                             document.querySelector('input[type=\"submit\"][value=\"印刷\"]') ||
                             document.querySelector('button[value=\"印刷\"]') ||
                             document.querySelector('input[value=\"印刷\"]');
          
          if (printButton) {
            printButton.click();
            return 'Print button clicked successfully';
          } else {
            return 'Print button not found';
          }
        })();
        "
        
        set result to (do JavaScript printJS)
        return {success:true, message:result}
      end tell
    end tell
  on error errMsg
    return {success:false, message:"Print button click failed: " & errMsg}
  end try
end clickPrintButton

-- ====== 文字列分割 ======
on splitString(theString, theDelimiter)
  set AppleScript's text item delimiters to theDelimiter
  set theArray to every text item of theString
  set AppleScript's text item delimiters to ""
  return theArray
end splitString

-- ====== 日付正規化（YYYY-MM-DD形式） ======
on normalizeDate(dateText)
  try
    set normalizedDate to do shell script "/bin/echo " & quoted form of dateText & " | /usr/bin/sed -E 's/年/\\-/g; s/月/\\-/g; s/日//g; s/[^0-9\\-]//g'"
    
    -- YYYY-MM-DD形式に整形
    set dateParts to my splitString(normalizedDate, "-")
    if (count of dateParts) >= 3 then
      set yearPart to item 1 of dateParts
      set monthPart to text -2 thru -1 of ("0" & (item 2 of dateParts))
      set dayPart to text -2 thru -1 of ("0" & (item 3 of dateParts))
      return yearPart & "-" & monthPart & "-" & dayPart
    else
      return "2025-01-01"
    end if
  on error
    return "2025-01-01"
  end try
end normalizeDate

-- ====== ファイル名サニタイズ ======
on sanitizeFileName(text)
  try
    set sanitized to do shell script "/bin/echo " & quoted form of text & " | /usr/bin/sed -E 's/[\\/:*?\"<>|]/_/g; s/[[:space:]]+/_/g; s/_+/_/g'"
    if length of sanitized > 50 then
      set sanitized to text 1 thru 50 of sanitized
    end if
    return sanitized
  on error
    return "receipt"
  end try
end sanitizeFileName

-- ====== PDF保存用ファイル名生成 ======
on generateFileName(dateText, summaryText)
  set normalizedDate to my normalizeDate(dateText)
  set sanitizedSummary to my sanitizeFileName(summaryText)
  return normalizedDate & "_" & sanitizedSummary & ".pdf"
end generateFileName

-- ====== 戻るボタンクリック ======
on clickBackButton()
  try
    tell application "Safari"
      tell front document
        set backJS to "
        (() => {
          const backButton = document.querySelector('button[name=\"b2\"]') ||
                            document.querySelector('button.designed[name=\"b2\"]') ||
                            document.querySelector('button[rel=\"but-1\"]');
          
          if (backButton) {
            backButton.click();
            return 'Back button clicked successfully';
          } else {
            return 'Back button not found';
          }
        })();
        "
        
        set result to (do JavaScript backJS)
        return {success:true, message:result}
      end tell
    end tell
  on error errMsg
    return {success:false, message:"Back button failed: " & errMsg}
  end try
end clickBackButton

-- ====== 領収書画面からデータ取得 ======
on getReceiptData()
  try
    set jsLoad to my loadJavaScript("receipt_data.js")
    if not (success of jsLoad) then
      return {success:false, message:"Could not load receipt_data.js"}
    end if
    
    tell application "Safari"
      tell front document
        do JavaScript (content of jsLoad)
        set result to (do JavaScript "getReceiptData()")
        return {success:true, data:result}
      end tell
    end tell
  on error errMsg
    return {success:false, message:"Receipt data error: " & errMsg}
  end try
end getReceiptData

-- ====== PDF保存機能（動的ファイル名生成） ======
on saveReceiptAsPDF(saveDir)
  try
    -- 保存ディレクトリ作成
    do shell script "/bin/mkdir -p " & quoted form of saveDir
    
    -- 印刷ダイアログをキャンセル（⌘+.）
    tell application "Safari" to activate
    delay 0.5
    tell application "System Events"
      keystroke "." using command down
    end tell
    delay 1
    
    -- 印刷ダイアログキャンセル後に領収書画面からデータを取得してファイル名生成
    set receiptData to my getReceiptData()
    if not (success of receiptData) then
      return {success:false, message:"Failed to get receipt data: " & (message of receiptData)}
    end if
    
    set dataObj to data of receiptData
    set depositNumber to depositNumber of dataObj
    set rideDate to rideDate of dataObj
    
    -- ファイル名生成
    set normalizedDate to my normalizeDate(rideDate)
    set fileName to normalizedDate & "_" & depositNumber & ".pdf"
    
    -- ファイルメニューからPDF書き出し
    tell application "System Events"
      tell process "Safari"
        click menu bar item "ファイル" of menu bar 1
        delay 1
        try
          click menu item "PDFとして書き出す..." of menu of menu bar item "ファイル" of menu bar 1
        on error
          try
            click menu item "PDFとして書き出す…" of menu of menu bar item "ファイル" of menu bar 1
          on error
            click menu item "PDFとして書き出す" of menu of menu bar item "ファイル" of menu bar 1
          end try
        end try
        delay 2
      end tell
    end tell
    
    -- 保存ダイアログが表示されるまで待機
    delay 2
    
    -- ファイル保存ダイアログでファイル名と保存先を設定
    tell application "System Events"
      tell process "Safari"
        -- ファイル名フィールドに入力
        try
          set value of text field 1 of sheet 1 of window 1 to fileName
        on error
          -- 別の方法でファイル名を設定
          keystroke "a" using command down
          delay 0.2
          keystroke fileName
        end try
        
        -- 保存先移動（⌘+Shift+G でフォルダ指定）
        delay 0.5
        keystroke "g" using {command down, shift down}
        delay 1
        
        -- 英数モード切り替え
        tell application "Safari" to activate
        delay 0.5
        key code 102
        delay 0.5
        keystroke saveDir
        delay 1
        keystroke return
        delay 2
        
        -- 保存実行
        keystroke return
        delay 2
        
        -- 既存ファイル置き換え確認ダイアログが出た場合（待機ループで対応）
        set replaced to false
        repeat with i from 1 to 10 -- 最大5秒待機 (10 * 0.5s)
          try
            -- 診断ログから判明した正確な階層を指定
            if exists button "置き換え" of sheet 1 of sheet 1 of window 1 then
              click button "置き換え" of sheet 1 of sheet 1 of window 1
              set replaced to true
              delay 1
              exit repeat
            end if
          on error errMsg
            -- 念のためのフォールバック
            try
              if exists button "置き換え" of window 1 then
                click button "置き換え" of window 1
                set replaced to true
                delay 1
                exit repeat
              end if
            end try
          end try
          delay 0.5
        end repeat
        
      end tell
    end tell
    
    return {success:true, message:"PDF saved as " & fileName, fileName:fileName}
    
  on error errMsg
    return {success:false, message:"PDF save failed: " & errMsg}
  end try
end saveReceiptAsPDF

-- ====== 現在の画面タイプ確認 ======
on checkCurrentPageType()
  try
    tell application "Safari"
      tell front document
        set pageURL to URL
        set pageTitle to name
        
        -- 領収書画面の確認
        set hasReceiptTitle to (do JavaScript "document.querySelector('h1') && document.querySelector('h1').textContent.includes('領収書')")
        set hasReceiptTable to (do JavaScript "document.querySelector('tr.number') !== null")
        
        -- 履歴一覧画面の確認  
        set hasHistoryForm to (do JavaScript "document.querySelector('form.history') !== null")
        
        -- 領収書表示画面の確認
        set hasPrintButton to (do JavaScript "document.querySelector('input[value=\"印刷\"]') !== null")
        
        if hasReceiptTitle and hasReceiptTable then
          return {success:true, pageType:"receipt", message:"領収書画面"}
        else if hasHistoryForm then
          return {success:true, pageType:"history", message:"履歴一覧画面"}
        else if hasPrintButton then
          return {success:true, pageType:"receipt_display", message:"領収書表示画面"}
        else
          return {success:true, pageType:"unknown", message:"不明な画面: " & pageTitle}
        end if
      end tell
    end tell
  on error errMsg
    return {success:false, message:"Page check error: " & errMsg}
  end try
end checkCurrentPageType

-- ====== 安全なタブクローズ（画面確認付き） ======
on closeCurrentTab()
  try
    -- 現在の画面タイプを確認
    set pageCheck to my checkCurrentPageType()
    if not (success of pageCheck) then
      return {success:false, message:"Cannot verify current page: " & (message of pageCheck)}
    end if
    
    set currentPageType to pageType of pageCheck
    set pageMessage to message of pageCheck
    
    -- 領収書画面の場合のみタブを閉じる
    if currentPageType is "receipt" then
      tell application "Safari" to activate
      delay 0.5
      tell application "System Events"
        keystroke "w" using command down
      end tell
      delay 1
      return {success:true, message:"Receipt tab closed: " & pageMessage}
    else
      return {success:false, message:"Wrong page type for closing: " & pageMessage}
    end if
    
  on error errMsg
    return {success:false, message:"Failed to close tab: " & errMsg}
  end try
end closeCurrentTab

-- ====== 1件処理の完全ワークフロー ======
on processSingleReceipt(rowIndex, saveDir)
  -- 1. 行データ取得（領収書ボタンの存在確認のみ）
  set rowData to my getRowData(rowIndex)
  if not (success of rowData) then
    return {success:false, message:"Row " & rowIndex & ": " & (message of rowData)}
  end if
  
  set rowInfo to data of rowData
  set hasButton to hasReceiptButton of rowInfo
  
  if not hasButton then
    return {success:false, message:"Row " & rowIndex & ": No receipt button"}
  end if
  
  -- 2. 領収書表示ボタンクリック（同じタブで遷移）
  set receiptClick to my clickReceiptButton(rowIndex)
  if not (success of receiptClick) then
    return {success:false, message:"Receipt click failed: " & (message of receiptClick)}
  end if
  
  -- ページ読み込み待機
  set transitionResult to my waitForPageTransition()
  if not (success of transitionResult) then
    return {success:false, message:"Page transition failed: " & (message of transitionResult)}
  end if
  
  -- 3. 印刷ボタンクリック（別タブで領収書画面へ）
  set printClick to my clickPrintButton()
  if not (success of printClick) then
    return {success:false, message:"Print click failed: " & (message of printClick)}
  end if
  
  -- 新タブで領収書画面が開くのを待機
  delay 3
  
  -- 4. PDF保存処理（領収書画面でファイル名を動的生成）
  set pdfSave to my saveReceiptAsPDF(saveDir)
  if not (success of pdfSave) then
    return {success:false, message:"PDF save failed: " & (message of pdfSave)}
  end if
  
  set fileName to fileName of pdfSave
  
  -- 5. 領収書タブを閉じる
  tell application "Safari" to activate
  delay 0.5
  tell application "System Events"
    keystroke "w" using command down
  end tell
  delay 1
  
  -- 6. 領収書表示画面から一覧に戻る
  set backClick to my clickBackButton()
  if not (success of backClick) then
    return {success:false, message:"Back click failed: " & (message of backClick)}
  end if
  
  delay 2 -- 一覧への遷移待機
  
  return {success:true, message:"Receipt " & rowIndex & " completed: " & fileName}
end processSingleReceipt

-- ====== メイン実行 ======
on run
  -- 基本設定
  set saveDir to my getenv("SAVE_DIR", (POSIX path of (path to desktop folder)) & "Receipts/JRC")
  set DRY_RUN to my getenv("DRY_RUN", "false")
  set PROCESS_ALL to my getenv("PROCESS_ALL", "false")
  
  -- 保存ディレクトリ作成
  do shell script "/bin/mkdir -p " & quoted form of saveDir
  
  -- Safari接続確認
  set safariCheck to my checkSafariConnection()
  if not (success of safariCheck) then
    display alert "Safari Connection Failed" message (message of safariCheck)
    return
  end if
  
  -- 履歴ページ確認
  set pageCheck to my checkHistoryPage()
  if not (success of pageCheck) then
    display alert "Page Check Failed" message (message of pageCheck)
    return
  end if
  
  -- 最初の行データをテスト取得
  set rowTest to my getRowData(0)
  if not (success of rowTest) then
    display alert "Row Data Test Failed" message (message of rowTest)
    return
  end if
  
  set rowInfo to data of rowTest
  set dateText to |date| of rowInfo
  set summaryText to summary of rowInfo
  set fileName to my generateFileName(dateText, summaryText)
  
  if PROCESS_ALL = "true" then
    -- 全件処理モード
    if DRY_RUN = "true" then
      display notification "DRY RUN: All rows processing mode" with title "Preview"
      return
    end if
    
    set result to my processAllReceipts(saveDir)
    display notification "All processing completed" with title "Success"
  else
    -- 単件処理モード（従来通り）
    if DRY_RUN = "true" then
      display notification "DRY RUN: " & fileName with title "Preview"
      return
    end if
    
    set result to my processSingleReceipt(0, saveDir)
    if success of result then
      display notification (message of result) with title "Success"
    else
      display alert "Processing Failed" message (message of result)
    end if
  end if
end run

-- ====== 全件処理用関数（ページネーション対応） ======
on processAllReceipts(saveDir)
  set successCount to 0
  set failureCount to 0
  set totalProcessed to 0
  set currentPage to 1
  
  -- pagination.js読み込み
  try
    set jsLoad to my loadJavaScript("pagination.js")
    if not (success of jsLoad) then
      return {success:false, message:"Could not load pagination.js"}
    end if
  on error errMsg
    return {success:false, message:"Could not load pagination.js: " & errMsg}
  end try
  
  -- 全ページを順次処理
  repeat
    display notification "Processing page " & currentPage with title "Receipt Collection"
    
    try
      tell application "Safari"
        tell front document
          do JavaScript (content of jsLoad)
          
          -- 現在ページの行数取得
          set totalRows to (do JavaScript "getTotalRowCount()")
          
          -- ページネーション状態確認
          set paginationInfo to (do JavaScript "checkPagination()")
          set hasNext to hasNext of paginationInfo
        end tell
      end tell
    on error errMsg
      return {success:false, message:"JavaScript execution failed: " & errMsg}
    end try
    
    -- 現在ページの全行を処理
    repeat with i from 0 to (totalRows - 1)
      set totalProcessed to totalProcessed + 1
      display notification "Processing row " & (i + 1) & "/" & totalRows & " (Page " & currentPage & ", Total " & totalProcessed & ")" with title "Receipt Collection"
      
      set result to my processSingleReceipt(i, saveDir)
      
      if success of result then
        set successCount to successCount + 1
      else
        set failureCount to failureCount + 1
      end if
      
      delay 2
    end repeat
    
    -- 次ページがある場合は次ページに移動
    if hasNext then
      display notification "Moving to next page... (hasNext=" & hasNext & ")" with title "Receipt Collection"
      
      try
        tell application "Safari"
          tell front document
            -- 現在ページの最初の行データを取得（遷移確認用）
            set currentFirstRowData to (do JavaScript "
              (() => {
                const articles = document.querySelectorAll('form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article');
                if (articles.length > 0) {
                  const dateEl = articles[0].querySelector('table:nth-of-type(1) td:nth-of-type(2)');
                  const summaryEl = articles[0].querySelector('table:nth-of-type(2) td:nth-of-type(2)');
                  return {
                    date: dateEl ? dateEl.textContent.trim() : '',
                    summary: summaryEl ? summaryEl.textContent.trim() : ''
                  };
                }
                return null;
              })()
            ")
            
            -- pagination.jsを再読み込み（関数確実に利用可能にする）
            do JavaScript (content of jsLoad)
            
            -- 関数存在確認
            set functionExists to (do JavaScript "typeof clickNextPage === 'function'")
            display notification "clickNextPage function exists: " & functionExists with title "Debug"
            
            if functionExists then
              set nextResult to (do JavaScript "clickNextPage()")
              display notification "clickNextPage result: " & nextResult with title "Debug"
            else
              display notification "ERROR: clickNextPage function not found" with title "Debug"
              return {success:false, message:"clickNextPage function not available", successCount:successCount, failureCount:failureCount}
            end if
            
            -- ページ遷移待機
            delay 5
            
            -- ページ内容の変化を確認（最初の行データで判定）
            repeat with waitCount from 1 to 20
              delay 1
              try
                set newFirstRowData to (do JavaScript "
                  (() => {
                    const articles = document.querySelectorAll('form.history.history-index.history-index-corp #main.history.history-list.history-list-recept .main-contents-wrap > article');
                    if (articles.length > 0) {
                      const dateEl = articles[0].querySelector('table:nth-of-type(1) td:nth-of-type(2)');
                      const summaryEl = articles[0].querySelector('table:nth-of-type(2) td:nth-of-type(2)');
                      return {
                        date: dateEl ? dateEl.textContent.trim() : '',
                        summary: summaryEl ? summaryEl.textContent.trim() : ''
                      };
                    }
                    return null;
                  })()
                ")
                
                -- 行データが変化した場合はページ遷移完了
                if currentFirstRowData is not equal to newFirstRowData then
                  display notification "Page content changed after " & waitCount & " seconds" with title "Debug"
                  exit repeat
                end if
              on error
                -- データ取得失敗は無視
              end try
            end repeat
            
            -- 遷移後のページネーション状態を再確認
            delay 2
            do JavaScript (content of jsLoad)
            set newPaginationInfo to (do JavaScript "checkPagination()")
            set newHasNext to hasNext of newPaginationInfo
            display notification "After move - hasNext: " & newHasNext with title "Debug"
            
          end tell
        end tell
        
        set currentPage to currentPage + 1
        delay 2
        
      on error errMsg
        return {success:false, message:"Page navigation failed: " & errMsg, successCount:successCount, failureCount:failureCount}
      end try
    else
      -- 次ページがない場合は処理完了
      display notification "No next page - processing complete" with title "Receipt Collection"
      exit repeat
    end if
    
  end repeat
  
  return {success:true, message:"All pages processed", successCount:successCount, failureCount:failureCount, totalProcessed:totalProcessed, totalPages:currentPage}
end processAllReceipts