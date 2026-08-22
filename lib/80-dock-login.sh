#!/usr/bin/env bash
# 80-dock-login.sh - 常駐アプリの初回起動・ログイン項目登録・Dock 整理
#
# 内容:
# 1. 常駐させたいアプリを一度起動する（初回起動ダイアログ・権限要求を出させる）
# 2. 同アプリを「ログイン項目」に登録し、次回ログイン以降は自動で開くようにする
# 3. Dock を整理する（Apple 標準の不要アプリを名指しで削除 → 業務アプリを追加。
#    Jamf Now の Web クリップや既存配置はそのまま残す）
#
# 注意:
# - ログイン項目の登録は osascript (System Events) を使う。初回のみ
#   「ターミナルが System Events を制御することを許可」ダイアログが出るので
#   「許可」を押すこと（拒否すると登録されずスキップされる）。
# - PDFgear / RunCat は Jamf Now (MDM) が配布する。キッティング時点で未着なら
#   スキップして案内だけ出す。MDM 配布後に本モジュール単体を再実行すればよい:
#     bash <(curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/lib/80-dock-login.sh)
# - Rectangle のログイン時起動は 65-rectangle.sh が Rectangle 自身の設定で行うため
#   ここでは二重登録しない。
# - 本モジュールは必須ではないため、失敗しても exit 0 で継続する。

set -uo pipefail

# ========================
# 設定（ここを編集すれば構成を変えられる）
# ========================

# ログイン時に自動起動させる常駐アプリ（アプリ名 = /Applications/<名前>.app）
LOGIN_APPS=(
  "Alfred 5"
  "Clipy"
  "AppCleaner"
  "PDFgear"
  "OBS"
  "RunCat"
)

# Dock に並べるアプリ（この順で左から並ぶ。無いものはスキップ）
# ※ Finder とゴミ箱は常に表示されるため指定不要
DOCK_APPS=(
  "/Applications/Google Chrome.app"
  "/Applications/Slack.app"
  "/Applications/zoom.us.app"
  "/Applications/Claude.app"
  "/Applications/ChatGPT.app"
  "/Applications/Typeless.app"
  "/Applications/PDFgear.app"
  "/Applications/OBS.app"
  "/Applications/Alfred 5.app"
  "/Applications/Clipy.app"
  "/Applications/AppCleaner.app"
  "/Applications/Rectangle.app"
  "/Applications/RunCat.app"
  "/System/Applications/System Settings.app"
)

# Dock から削除する Apple 標準アプリ（名指しで消す。ここに無いものは触らない）
# ※ Jamf Now (MDM) が差し込む Web クリップ、「アプリ」(Launchpad)、手動で置いたアプリはそのまま残る
DOCK_REMOVE=(
  "Safari"
  "Messages"
  "Mail"
  "Maps"
  "Photos"
  "FaceTime"
  "Calendar"
  "Contacts"
  "Reminders"
  "Notes"
  "Freeform"
  "TV"
  "Music"
  "News"
  "Podcasts"
  "Keynote"
  "Numbers"
  "Pages"
  "App Store"
  "iPhone Mirroring"
)

# MDM (Jamf Now) 配布アプリ。未着でもエラーにせず案内のみ
MDM_APPS=("PDFgear" "RunCat")

# ========================
# 前提: root 実行は想定しない（ログイン項目・Dock はログインユーザー固有）
# ========================
if [[ "$EUID" -eq 0 ]]; then
  echo "WARN: このモジュールは sudo なしでログインユーザーとして実行してください。スキップします"
  exit 0
fi

# brew を PATH に通す（dockutil 用）
if ! command -v brew >/dev/null 2>&1; then
  for _p in /opt/homebrew /usr/local; do
    if [[ -x "${_p}/bin/brew" ]]; then eval "$("${_p}/bin/brew" shellenv)"; break; fi
  done
fi

app_path() { echo "/Applications/$1.app"; }

is_mdm_app() {
  local a
  for a in "${MDM_APPS[@]}"; do [[ "$a" == "$1" ]] && return 0; done
  return 1
}

# ========================
# 1. 初回起動 + 2. ログイン項目登録
# ========================
echo "▶ 常駐アプリの初回起動とログイン項目登録"
MISSING_APPS=()
for app in "${LOGIN_APPS[@]}"; do
  path="$(app_path "$app")"
  if [[ ! -d "$path" ]]; then
    if is_mdm_app "$app"; then
      echo "  - ${app}: 未インストール（Jamf Now 配布待ち）。配布後に本モジュールを再実行してください"
    else
      echo "  - ${app}: 未インストール。スキップ"
    fi
    MISSING_APPS+=("$app")
    continue
  fi

  # 一度起動して初回ダイアログ・権限要求を出させる（-g: 前面に出さない）
  open -g -a "$path" 2>/dev/null && echo "  - ${app}: 起動" || echo "  - ${app}: 起動に失敗（続行）"

  # ログイン項目に登録（既に登録済みなら何もしない）
  if osascript -e "tell application \"System Events\" to get the name of every login item" 2>/dev/null \
       | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -qx "$app"; then
    echo "      ログイン項目: 登録済み"
  elif osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"${path}\", hidden:false}" >/dev/null 2>&1; then
    echo "      ログイン項目: 登録"
  else
    echo "      WARN: ログイン項目の登録に失敗（System Events の制御許可ダイアログで拒否した可能性）"
    echo "            手動: システム設定 > 一般 > ログイン項目と機能拡張 > 「+」で ${app} を追加"
  fi
done

# ========================
# 3. Dock 整理
# ========================
echo ""
echo "▶ Dock 整理"
if ! command -v dockutil >/dev/null 2>&1; then
  echo "WARN: dockutil が見つかりません（Brewfile の brew \"dockutil\" が未導入）。Dock 整理をスキップします"
else
  # Apple 標準アプリだけを名指しで削除する（--remove all は使わない。
  # MDM の Web クリップまで消えてしまうため）
  for label in "${DOCK_REMOVE[@]}"; do
    if dockutil --find "$label" >/dev/null 2>&1; then
      dockutil --remove "$label" --no-restart >/dev/null 2>&1 \
        && echo "  - 削除: ${label}" \
        || echo "  - WARN: 削除失敗: ${label}"
    fi
  done

  # 業務アプリを追加（既に Dock にあるものはスキップして並びを壊さない）
  for path in "${DOCK_APPS[@]}"; do
    label="$(basename "$path" .app)"
    if [[ ! -d "$path" ]]; then
      echo "  - 未インストールのため省略: ${label}"
      continue
    fi
    if dockutil --find "$label" >/dev/null 2>&1; then
      echo "  - 配置済み: ${label}"
      continue
    fi
    dockutil --add "$path" --no-restart >/dev/null 2>&1 \
      && echo "  - 追加: ${label}" \
      || echo "  - WARN: 追加失敗: ${label}"
  done

  # ダウンロードフォルダ（右側のスタック）が無ければ追加
  if ! dockutil --find "Downloads" >/dev/null 2>&1; then
    dockutil --add "${HOME}/Downloads" --view fan --display stack --section others --no-restart >/dev/null 2>&1 || true
  fi

  killall Dock 2>/dev/null || true
  echo "  - Dock を再起動して反映"
fi

echo ""
if (( ${#MISSING_APPS[@]} > 0 )); then
  echo "※ 未インストールでスキップしたアプリ: ${MISSING_APPS[*]}"
  echo "   インストール後に以下で本モジュールだけ再実行できます:"
  echo "   bash <(curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/lib/80-dock-login.sh)"
fi
echo "常駐アプリ・Dock 設定 完了"
exit 0
