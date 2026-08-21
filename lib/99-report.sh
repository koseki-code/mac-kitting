#!/usr/bin/env bash
# 99-report.sh - 完了レポート
set -euo pipefail

REPORT_FILE="${HOME}/.mac-kitting/logs/report-$(date +%Y%m%d-%H%M%S).txt"
readonly REPORT_FILE

mkdir -p "$(dirname "$REPORT_FILE")"

{
  echo "================================================================"
  echo " EXCEED GROUP Mac キッティング 完了レポート"
  echo " 完了時刻 : $(date '+%Y-%m-%d %H:%M:%S')"
  echo "================================================================"
  echo ""
  echo "▼ システム情報"
  echo "  ホスト名     : $(hostname)"
  echo "  ユーザー     : $(whoami)"
  echo "  macOS        : $(sw_vers -productVersion)"
  echo "  シリアル番号 : $(system_profiler SPHardwareDataType | awk '/Serial Number/ {print $4}')"
  echo ""
  echo "▼ インストール済みアプリ（Brew Cask）"
  brew list --cask 2>/dev/null | sed 's/^/  - /' || echo "  (brew未インストール)"
  echo ""
  echo "▼ インストール済みCLI（Brew Formula）"
  brew list --formula 2>/dev/null | sed 's/^/  - /' || echo "  (brew未インストール)"
  echo ""
  echo "▼ Brewfile 未インストール項目（空なら全て導入済み）"
  if [[ -f "${HOME}/.mac-kitting/work/Brewfile" ]] && command -v brew >/dev/null 2>&1; then
    brew bundle check --file="${HOME}/.mac-kitting/work/Brewfile" --verbose 2>&1 \
      | grep -E '^\s*→' | sed 's/^/  /' || echo "  (なし)"
  else
    echo "  (Brewfile が見つからないため判定不可)"
  fi
  echo ""
  echo "▼ Google 日本語入力"
  if [[ -d "/Library/Input Methods/GoogleJapaneseInput.app" ]]; then
    echo "  インストール: OK"
    if defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -q com.google.inputmethod.Japanese; then
      echo "  入力ソース有効化: OK"
    else
      echo "  入力ソース有効化: 未（下記【2】の手動作業が必要）"
    fi
  else
    echo "  インストール: NG ★ brew install --cask google-japanese-ime を実行してください"
  fi
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "▼ 必ず手動で行う作業（情シス担当者向け）"
  echo "════════════════════════════════════════════════════════════════"
  cat <<'EOF'

  【1】Mac本体を再起動
    └ トラックパッド速度・キーリピート・各種環境設定の完全反映のため

  【2】Google日本語入力をデフォルト IME に設定 ★最重要
    └ システム設定 > キーボード > 入力ソース > 編集
    │  ① 「Google」配下の「ひらがな」「英数」「カタカナ」を追加
    │  ② 「日本語 - ローマ字入力」を削除（Apple純正を消す）
    │  ③ Caps Lockキーで切替できることを確認
    └ Google IME 設定 > 一般 で以下を確認:
       - サジェスト機能のオン/オフ（業務情報送信を嫌う場合はオフ推奨）

  【2'】常駐アプリの起動確認とログイン時自動起動（80-dock-login.sh が自動設定済み）
    └ 対象: Alfred 5 / Clipy / AppCleaner / PDFgear / OBS Studio / Rectangle / RunCat
    └ 各アプリが起動しているか（メニューバー右上のアイコン）を確認し、
       初回ダイアログ（権限許可・チュートリアル）があれば済ませる
    └ システム設定 > 一般 > ログイン項目と機能拡張 の「ログイン時に開く」に
       上記アプリが並んでいることを確認。無ければ「+」から追加
       （スクリプト実行時に「System Events の制御を許可」を拒否すると未登録になる）
    └ PDFgear / RunCat は Jamf Now 配布のため、未着なら配布後に以下を再実行:
         bash <(curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/lib/80-dock-login.sh)
    └ Dock は Apple 標準アプリ（Safari / メッセージ / マップ / 写真 等）を削除し、
       業務アプリ（Chrome / Slack / Zoom / Claude / ChatGPT / Typeless / PDFgear /
       OBS / Alfred / Clipy / AppCleaner / Rectangle / RunCat / システム設定）を追加済み。
       Jamf Now の Web クリップは残る。削除/追加の対象を変えたい場合は
       lib/80-dock-login.sh の DOCK_REMOVE / DOCK_APPS を編集

  【3】Rectangle にアクセシビリティ権限を許可 ★必須
    └ Rectangle 起動時のダイアログで「システム設定を開く」をクリック
    │  または: システム設定 > プライバシーとセキュリティ > アクセシビリティ
    └ リストから「Rectangle」を見つけてトグルをオン → 認証パスワードを入力
    └ Ctrl+Option+矢印キー でウィンドウが移動することを確認
       （権限が無いとスナップ／ショートカットが一切効かない）

  【3'】Typeless（AI音声入力）の初期設定
    └ Typeless を起動してアカウントにログイン
    └ 初回ダイアログで「マイク」と「アクセシビリティ」の権限を許可
       （システム設定 > プライバシーとセキュリティ > マイク / アクセシビリティ）
    └ ショートカット（デフォルト: Fn 長押し）で音声入力できることを確認

  【3''】Chrome リモートデスクトップのリモートアクセス有効化
    └ Chrome で https://remotedesktop.google.com/access を開く（業務 Google アカウント）
    └ 「リモートアクセスの設定」→ ホストは導入済みなので「オンにする」→ PC名・PIN を設定
    └ 求められたら「画面収録」「アクセシビリティ」権限を許可
       （システム設定 > プライバシーとセキュリティ）

  【4】セキュリティ系
    └ FileVault を有効化（システム設定 > プライバシーとセキュリティ）
    └ Jamf Now MDM のエンロール状態を確認
    └ 以下のコマンドを sudo 付きで実行（スクリプトでスキップされた場合）:
         sudo systemsetup -f -setremotelogin off
         sudo launchctl disable system/com.apple.smbd

  【5】解析データ送信オフ（スクリプトで完全に切れない場合）
    └ システム設定 > プライバシーとセキュリティ > 解析と機能向上
       「Macの解析を共有」「アプリ開発者と共有」を全てオフ

  【6】業務アカウントの設定
    └ Google Workspace（Gmail/Calendar/Drive）
    └ Chatwork
    └ Slack
    └ ANDPAD
    └ Microsoft 365 ライセンス認証（Office / Teams を手動導入した場合のみ）

  【7】iCloud アカウント設定
    └ 業務用Apple IDを使用する場合のみログイン
    └ 「iCloud Drive > デスクトップと書類フォルダ」は必ずオフのまま
       （業務ファイルがiCloudに同期される事故を防ぐ）

  【8】Time Machine バックアップ設定（必要に応じて）

EOF
} | tee "$REPORT_FILE"

echo ""
echo "レポートを保存: ${REPORT_FILE}"
