#!/usr/bin/env bash
# 00-precheck.sh - 環境チェック
set -euo pipefail

echo "--- システム情報 ---"
echo "macOS バージョン: $(sw_vers -productVersion)"
echo "macOS ビルド    : $(sw_vers -buildVersion)"
echo "アーキテクチャ  : $(uname -m)"
echo "シェル          : $SHELL"
echo "ホスト名        : $(hostname)"
echo "シリアル番号    : $(system_profiler SPHardwareDataType | awk '/Serial Number/ {print $4}')"
echo "ログインユーザー: $(whoami) (UID: $(id -u))"

echo ""
echo "--- ネットワーク ---"
if ping -c 1 -W 2000 github.com > /dev/null 2>&1; then
  echo "GitHub到達: OK"
else
  echo "GitHub到達: NG"
  exit 1
fi

if curl -fsSL --max-time 5 https://brew.sh > /dev/null; then
  echo "Homebrewサイト到達: OK"
else
  echo "Homebrewサイト到達: NG"
fi

echo ""
echo "--- ストレージ ---"
df -h / | awk 'NR==1 || NR==2'

echo ""
echo "--- 既存環境 ---"
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew: 既にインストール済み ($(brew --version | head -1))"
else
  echo "Homebrew: 未インストール"
fi

if [[ -f /Library/Apple/System/Library/CoreServices/MDM/MDMConfigurator.app/Contents/MacOS/MDMConfigurator ]] 2>/dev/null; then
  echo "MDM: 検出"
fi
echo "MDMプロファイル:"
profiles list 2>/dev/null | head -20 || echo "  (取得には権限が必要)"

echo ""
echo "プリチェック完了"
