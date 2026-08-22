#!/usr/bin/env bash
# 85-wallpaper.sh - デスクトップ画像（壁紙）の設定
#
# 内容:
# 1. リポジトリの assets/wallpaper/wallpaper.jpg（または .png）を取得して
#    ~/Pictures/EXCEED/ に保存する（キャッシュ掃除で消えない永続パス）
# 2. System Events で全ディスプレイ・全スペースの壁紙に設定する
#
# 注意:
# - 画像が未格納（404）の場合はスキップしてキッティングを止めない
# - 初回のみ「ターミナルが System Events を制御することを許可」ダイアログが出る
#   （80-dock-login.sh で既に許可済みなら出ない）
# - WALLPAPER_URL を指定すると別の画像 URL を使える
# - 本モジュールは必須ではないため、失敗しても exit 0 で継続する

set -uo pipefail

readonly REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/koseki-code/mac-kitting/main}"
readonly DEST_DIR="${HOME}/Pictures/EXCEED"

if [[ "$EUID" -eq 0 ]]; then
  echo "WARN: このモジュールは sudo なしでログインユーザーとして実行してください。スキップします"
  exit 0
fi

echo "▶ デスクトップ画像の設定"
mkdir -p "$DEST_DIR"

# 取得元の決定: WALLPAPER_URL 指定 > assets/wallpaper/wallpaper.jpg > wallpaper.png
DEST=""
if [[ -n "${WALLPAPER_URL:-}" ]]; then
  ext="${WALLPAPER_URL##*.}"
  DEST="${DEST_DIR}/wallpaper.${ext}"
  if ! curl -fsSL "$WALLPAPER_URL" -o "$DEST"; then
    echo "WARN: 壁紙の取得に失敗しました: ${WALLPAPER_URL}。スキップします"
    exit 0
  fi
else
  for name in wallpaper.jpg wallpaper.png; do
    if curl -fsSL "${REPO_URL}/assets/wallpaper/${name}" -o "${DEST_DIR}/${name}" 2>/dev/null; then
      DEST="${DEST_DIR}/${name}"
      break
    fi
    rm -f "${DEST_DIR}/${name}"
  done
  if [[ -z "$DEST" ]]; then
    echo "  壁紙画像が未格納のためスキップ（assets/wallpaper/wallpaper.jpg を追加すると自動適用されます）"
    exit 0
  fi
fi

# 画像として妥当か（0バイトや HTML でないか）を軽く検査
if ! file "$DEST" | grep -qiE 'image|JPEG|PNG'; then
  echo "WARN: 取得したファイルが画像ではありません: ${DEST}。スキップします"
  rm -f "$DEST"
  exit 0
fi
echo "  画像: ${DEST}"

# 全ディスプレイ・全スペースに適用
if osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"${DEST}\"" >/dev/null 2>&1; then
  echo "  全ディスプレイの壁紙に設定しました"
else
  echo "WARN: 壁紙の設定に失敗（System Events の制御許可ダイアログで拒否した可能性）"
  echo "      手動: システム設定 > 壁紙 > 「写真を追加」で ${DEST} を選択"
fi

# 現在表示中以外のスペースにも確実に反映させるため Dock を再起動
killall Dock 2>/dev/null || true

echo "デスクトップ画像 設定 完了"
exit 0
