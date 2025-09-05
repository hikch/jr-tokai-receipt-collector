# ADR Journal

- 2025-09-05: AppleScript+Safari自動化採用。理由: macOSシステムダイアログ制御とPDF保存確実性。却下: Playwright/Selenium。
- 2025-09-05: 外部JavaScript分離採用。理由: メンテナンス性向上とロジック分離。却下: AppleScript内JavaScript埋め込み。
- 2025-09-05: ES5互換JavaScript採用。理由: SafariのAppleScript JavaScript実行環境対応。却下: モダンJavaScript構文。
- 2025-09-05: 領収書画面からの動的ファイル名生成採用。理由: 一覧画面データ不確実性対策。却下: 一覧画面データ使用。
- 2025-09-05: サイト標準期間選択機能使用採用。理由: UI変更耐性とユーザビリティ。却下: 独自日付フィルタ実装。
- 2025-09-05: コンテンツ変化による遷移検出採用。理由: URL不変サイトでの確実なページ遷移判定。却下: URL変化監視。
- 2025-09-05: 固定値cfEXPY_doAction('RSWP360AIDP015')採用。理由: 次ページ機能の確実性。却下: 動的パラメータ抽出。