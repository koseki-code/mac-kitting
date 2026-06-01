#!/usr/bin/env bash
# 30-apps.sh - Brewfile によるアプリ一括インストール
set -euo pipefail

readonly REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/koseki-code/mac-kitting/main}"
readonly PROFILE="${PROFILE:-general}"
readonly BREWFILE_PATH="${HOME}/.mac-kitting/work/Brewfile"

mkdir -p "$(dirname "$BREWFILE_PATH")"

# プロファイルに対応する Brewfile を明示的に選択する
#   general → Brewfile      （標準・一般職向け）
#   eng     → Brewfile.eng  （標準 + 開発ツール）
case "$PROFILE" in
  eng) BREWFILE_REMOTE="Brewfile.eng" ;;
  general) BREWFILE_REMOTE="Brewfile" ;;
  *)
    echo "WARN: 未知のプロファイル '${PROFILE}'。標準Brewfileを使用します"
    BREWFILE_REMOTE="Brewfile"
    ;;
esac

if ! curl -fsSL "${REPO_URL}/${BREWFILE_REMOTE}" -o "$BREWFILE_PATH"; then
  echo "ERROR: Brewfile の取得に失敗しました: ${REPO_URL}/${BREWFILE_REMOTE}" >&2
  exit 1
fi
echo "使用するBrewfile: ${BREWFILE_REMOTE}"

echo ""
echo "--- インストール対象 ---"
cat "$BREWFILE_PATH"
echo "------------------------"
echo ""

brew bundle --file="$BREWFILE_PATH" --no-lock || {
  echo "WARN: 一部アプリのインストールに失敗。ログを確認してください"
}

echo "アプリインストール 完了"
