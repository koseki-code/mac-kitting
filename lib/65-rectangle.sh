#!/usr/bin/env bash
# 65-rectangle.sh - Rectangle ウィンドウ管理ツール設定
#
# 内容:
# - ログイン時自動起動を有効化
# - マウスドラッグで画面端にスナップを有効化
# - メニューバーアイコン表示
# - 自動アップデート確認を有効化
# - ショートカットはデフォルトのまま（Rectangle純正設計を尊重）
#
# 注意: アクセシビリティ権限の付与は macOS のセキュリティ仕様により
#       スクリプトでは自動化できません。完了レポートで誘導します。

set -euo pipefail

readonly RECTANGLE_DOMAIN="com.knollsoft.Rectangle"
readonly RECTANGLE_APP="/Applications/Rectangle.app"

# ========================
# Rectangle インストール確認
# ========================
if [[ ! -d "${RECTANGLE_APP}" ]]; then
  echo "WARN: Rectangle が未インストールです。"
  echo "      Brewfile に 'cask \"rectangle\"' が含まれているか確認してください"
  echo "      スキップします"
  exit 0
fi

echo "Rectangle: $(defaults read "${RECTANGLE_DOMAIN}" rectangleVersion 2>/dev/null || echo "version unknown")"

# ========================
# Rectangle を一度起動して初期 plist を作成
# ========================
# Rectangle は初回起動時に plist を作成するため、未起動状態だと defaults write が無効になる
# バックグラウンドで起動して、すぐに kill する
if ! defaults read "${RECTANGLE_DOMAIN}" >/dev/null 2>&1; then
  echo "▶ Rectangle 初回起動（plist 初期化のため）"
  open -g -a Rectangle
  sleep 3
  osascript -e 'quit app "Rectangle"' >/dev/null 2>&1 || true
  sleep 1
fi

# ========================
# 1. ログイン時自動起動
# ========================
echo "▶ ログイン時自動起動を有効化"
defaults write "${RECTANGLE_DOMAIN}" launchOnLogin -bool true

# ========================
# 2. マウスドラッグで画面端にスナップ
# ========================
echo "▶ ウィンドウスナップ機能を有効化"
defaults write "${RECTANGLE_DOMAIN}" windowSnapping -bool true

# ========================
# 3. メニューバーアイコン表示
# ========================
echo "▶ メニューバーアイコンを表示"
defaults write "${RECTANGLE_DOMAIN}" hideMenubarIcon -bool false

# ========================
# 4. 自動アップデート確認
# ========================
echo "▶ 自動アップデート確認を有効化"
defaults write "${RECTANGLE_DOMAIN}" SUEnableAutomaticChecks -bool true

# ========================
# 5. その他の基本設定（妥当なデフォルト）
# ========================
echo "▶ その他のデフォルト設定"

# ウィンドウ間の隙間（0=隙間なし）
defaults write "${RECTANGLE_DOMAIN}" gapSize -int 0

# 「ほぼ最大化」のサイズ（画面の90%）
defaults write "${RECTANGLE_DOMAIN}" almostMaximizeHeight -float 0.9
defaults write "${RECTANGLE_DOMAIN}" almostMaximizeWidth -float 0.9

# 初回起動時のウィザード表示をスキップ（既に設定済みのため）
defaults write "${RECTANGLE_DOMAIN}" launchOnLoginCompleted -bool true

# ========================
# Rectangle を起動
# ========================
echo "▶ Rectangle を起動"
open -g -a Rectangle

echo ""
echo "Rectangle設定 完了"
echo ""
echo "================================================================"
echo " ⚠ 重要: アクセシビリティ権限の手動許可が必要です"
echo "================================================================"
echo ""
echo "Rectangle が動作するには、アクセシビリティ権限の付与が必要です。"
echo "この手順は macOS のセキュリティ仕様により自動化できません。"
echo ""
echo "手順:"
echo "  1. システム設定 > プライバシーとセキュリティ > アクセシビリティ"
echo "  2. リストから「Rectangle」を見つけてトグルをオン"
echo "  3. 認証パスワードを入力"
echo ""
echo "または Rectangle 起動時に表示されるダイアログから「開く」を選択"
echo "→ 自動的にアクセシビリティ設定画面が開きます"
