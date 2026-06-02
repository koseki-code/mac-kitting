#!/usr/bin/env bash
# 60-chrome.sh - Google Chrome 設定
#
# 内容:
# 1. 既定ブラウザ化（defaultbrowser コマンド）
# 2. Managed Policies（バックグラウンド動作停止・統計送信停止・セーフブラウジング有効・Autofillクレカ無効）
# 3. ManagedBookmarks（パブリック分 + プライベートリポからマージ）
# 4. ExtensionInstallForcelist（CrowdLog カレンダー同期）

set -euo pipefail

readonly WORK_DIR="${HOME}/.mac-kitting/work"
readonly PRIVATE_REPO="${PRIVATE_REPO:-koseki-code/mac-kitting-private}"
readonly PRIVATE_BOOKMARKS_PATH="managed_bookmarks_private.json"

mkdir -p "${WORK_DIR}"

# brew を PATH に通す（単体実行やサブシェルで PATH 未継承のとき用の保険）。
# defaultbrowser / gh / jq はいずれも brew 配下のため、これが無いと全て command not found になる。
if ! command -v brew >/dev/null 2>&1; then
  for _p in /opt/homebrew /usr/local; do
    if [[ -x "${_p}/bin/brew" ]]; then eval "$("${_p}/bin/brew" shellenv)"; break; fi
  done
fi

# ========================
# 1. 既定ブラウザ化
# ========================
echo "▶ Chrome を既定ブラウザに設定"

if command -v defaultbrowser >/dev/null 2>&1; then
  defaultbrowser chrome || echo "WARN: 既定ブラウザの変更に失敗"
elif [[ -x /opt/homebrew/bin/defaultbrowser ]]; then
  /opt/homebrew/bin/defaultbrowser chrome || echo "WARN: 既定ブラウザの変更に失敗"
elif [[ -x /usr/local/bin/defaultbrowser ]]; then
  /usr/local/bin/defaultbrowser chrome || echo "WARN: 既定ブラウザの変更に失敗"
else
  echo "WARN: defaultbrowser コマンドが見つかりません（Brewfileに 'brew \"defaultbrowser\"' を追加してください）"
fi

# ========================
# 2. Managed Policies (要 sudo)
# ========================
echo "▶ Chrome Managed Policies を設定"

# sudo権限のチェック
if [[ "$EUID" -ne 0 ]] && ! sudo -n true 2>/dev/null; then
  echo "WARN: sudo権限なし。Managed Policies はスキップします"
  echo "      後で 'sudo bash 60-chrome.sh' で再実行してください"
  exit 0
fi

# Chrome Managed Policies の plist パス
readonly CHROME_PLIST="/Library/Preferences/com.google.Chrome.plist"

# 基本セキュリティポリシー
sudo defaults write "${CHROME_PLIST%.plist}" BackgroundModeEnabled -bool false
sudo defaults write "${CHROME_PLIST%.plist}" MetricsReportingEnabled -bool false
sudo defaults write "${CHROME_PLIST%.plist}" SafeBrowsingEnabled -bool true
sudo defaults write "${CHROME_PLIST%.plist}" AutofillCreditCardEnabled -bool false

# ========================
# 3. ManagedBookmarks 構築
# ========================
echo "▶ ManagedBookmarks を構築"

# パブリック側ブックマーク（フラット構造）
PUBLIC_BOOKMARKS=$(cat <<'JSON'
[
  {"toplevel_name": "EXCEED 業務リンク"},
  {"name": "Google Workspace", "url": "https://workspace.google.com"},
  {"name": "Google Drive", "url": "https://drive.google.com"},
  {"name": "Google Calendar", "url": "https://calendar.google.com"},
  {"name": "Gemini", "url": "https://gemini.google.com"},
  {"name": "NotebookLM", "url": "https://notebooklm.google.com"},
  {"name": "ANDPAD", "url": "https://andpad.jp"},
  {"name": "MoneyForward", "url": "https://biz.moneyforward.com"},
  {"name": "Amazon ビジネス", "url": "https://www.amazon.co.jp/business"},
  {"name": "Slack", "url": "https://slack.com"}
]
JSON
)
readonly PUBLIC_BOOKMARKS

# プライベート側ブックマークを取得
echo "▶ プライベートリポからブックマーク定義を取得"

PRIVATE_BOOKMARKS_JSON=""
PRIVATE_FETCH_OK=0

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    if PRIVATE_BOOKMARKS_JSON=$(gh api "repos/${PRIVATE_REPO}/contents/${PRIVATE_BOOKMARKS_PATH}" \
         --jq '.content' 2>/dev/null | base64 -d 2>/dev/null); then
      if [[ -n "${PRIVATE_BOOKMARKS_JSON}" ]]; then
        PRIVATE_FETCH_OK=1
        echo "  プライベートブックマーク取得 OK"
      fi
    fi
  else
    echo "  ⚠ gh CLI が認証されていません（'gh auth login' を実行してください）"
  fi
else
  echo "  ⚠ gh CLI 未インストール（Brewfile経由でインストールされるはず）"
fi

# マージ処理（jq が必要）
if [[ "${PRIVATE_FETCH_OK}" -eq 1 ]] && command -v jq >/dev/null 2>&1; then
  # プライベートブックマークを抽出してパブリックとマージ
  MERGED_BOOKMARKS=$(echo "${PRIVATE_BOOKMARKS_JSON}" | jq -c \
    --argjson pub "${PUBLIC_BOOKMARKS}" \
    '$pub + .AdditionalBookmarks')

  if [[ -n "${MERGED_BOOKMARKS}" ]] && [[ "${MERGED_BOOKMARKS}" != "null" ]]; then
    BOOKMARKS_JSON="${MERGED_BOOKMARKS}"
    echo "  パブリック + プライベート をマージしました"
  else
    BOOKMARKS_JSON="${PUBLIC_BOOKMARKS}"
    echo "  ⚠ マージに失敗。パブリックのみで進めます"
  fi
else
  BOOKMARKS_JSON="${PUBLIC_BOOKMARKS}"
  echo "  パブリックのみで進めます"
fi

# Plistに書き込み
TMPFILE=$(mktemp)
echo "${BOOKMARKS_JSON}" > "${TMPFILE}"

# defaults コマンドで配列を書き込むのが難しいため、PlistBuddy を使う
sudo /usr/libexec/PlistBuddy -c "Delete :ManagedBookmarks" "${CHROME_PLIST}" 2>/dev/null || true
sudo /usr/libexec/PlistBuddy -c "Add :ManagedBookmarks array" "${CHROME_PLIST}"

# JSON配列の各要素をループしてPlistBuddyに渡す
echo "${BOOKMARKS_JSON}" | jq -c '.[]' | while IFS= read -r item; do
  # 各要素のキー一覧を取得
  KEYS=$(echo "${item}" | jq -r 'keys[]')

  # 配列に新しい dict を追加
  IDX=$(sudo /usr/libexec/PlistBuddy -c "Print :ManagedBookmarks" "${CHROME_PLIST}" 2>/dev/null \
    | grep -c "Dict {" || true)
  sudo /usr/libexec/PlistBuddy -c "Add :ManagedBookmarks:${IDX} dict" "${CHROME_PLIST}"

  # 各キーの値を追加
  while IFS= read -r key; do
    value=$(echo "${item}" | jq -r ".\"${key}\"")
    sudo /usr/libexec/PlistBuddy -c "Add :ManagedBookmarks:${IDX}:${key} string ${value}" "${CHROME_PLIST}"
  done <<< "${KEYS}"
done

rm -f "${TMPFILE}"

# ========================
# 4. 拡張機能の強制インストール
# ========================
echo "▶ 拡張機能の強制インストール設定"

# ExtensionInstallForcelist
# 形式: 拡張ID;update_url
sudo /usr/libexec/PlistBuddy -c "Delete :ExtensionInstallForcelist" "${CHROME_PLIST}" 2>/dev/null || true
sudo /usr/libexec/PlistBuddy -c "Add :ExtensionInstallForcelist array" "${CHROME_PLIST}"
sudo /usr/libexec/PlistBuddy -c "Add :ExtensionInstallForcelist:0 string aajlpbohkcfpmgeamipkmpllmgjmmmpa;https://clients2.google.com/service/update2/crx" "${CHROME_PLIST}"
echo "  CrowdLog カレンダー同期 を強制インストール対象に追加"

# ========================
# 確認用: 設定内容の表示
# ========================
echo "▶ 設定内容を確認"
echo "--- Chrome Managed Policies ---"
sudo defaults read "${CHROME_PLIST%.plist}" 2>/dev/null | head -40 || echo "(読み込み失敗)"

echo ""
echo "Chrome設定 完了"
echo "※ Chrome を起動すると chrome://policy で設定を確認できます"
echo "※ 既定ブラウザの変更を反映するため、Chromeを一度起動してください"
