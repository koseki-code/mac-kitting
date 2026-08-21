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
    brew bundle check --file="${HOME}/.mac-kitting/work/Brewfile" --verbose 2>/dev/null \
      | grep -E '^\s*→' | sed 's/^/  /' || true
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

  【3】Rectangle にアクセシビリティ権限を許可 ★必須
    └ Rectangle 起動時のダイアログで「システム設定を開く」をクリック
    │  または: システム設定 > プライバシーとセキュリティ > アクセシビリティ
    └ リストから「Rectangle」を見つけてトグルをオン → 認証パスワードを入力
    └ Ctrl+Option+矢印キー でウィンドウが移動することを確認
       （権限が無いとスナップ／ショートカットが一切効かない）

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
    └ Microsoft 365 ライセンス認証（Office を使う場合）

  【7】iCloud アカウント設定
    └ 業務用Apple IDを使用する場合のみログイン
    └ 「iCloud Drive > デスクトップと書類フォルダ」は必ずオフのまま
       （業務ファイルがiCloudに同期される事故を防ぐ）

  【8】Time Machine バックアップ設定（必要に応じて）

EOF
} | tee "$REPORT_FILE"

echo ""
echo "レポートを保存: ${REPORT_FILE}"
