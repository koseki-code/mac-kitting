#!/usr/bin/env bash
# 30-apps.sh - Brewfile によるアプリ一括インストール
set -euo pipefail

readonly REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/koseki-code/mac-kitting/main}"
readonly PROFILE="${PROFILE:-general}"
readonly BREWFILE_PATH="${HOME}/.mac-kitting/work/Brewfile"

mkdir -p "$(dirname "$BREWFILE_PATH")"

# brew を PATH に通す（単体実行やサブシェルで PATH 未継承のとき用の保険）。
# これが無いと brew bundle が「command not found」になり、|| で握り潰され空振りする。
if ! command -v brew >/dev/null 2>&1; then
  for _p in /opt/homebrew /usr/local; do
    if [[ -x "${_p}/bin/brew" ]]; then eval "$("${_p}/bin/brew" shellenv)"; break; fi
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "ERROR: brew が見つかりません。20-homebrew.sh が成功しているか確認してください" >&2
  exit 1
fi

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

# ※ `--no-lock` は Homebrew 6.x で廃止され、付けると brew bundle が
#    "Error: invalid option: --no-lock" でヘルプを出して即終了し、
#    Brewfile のアプリが1つも入らない（2026-08-21 の実機キッティングで発生）。
#    Brewfile.lock.json の生成抑止は環境変数で行う。
export HOMEBREW_BUNDLE_NO_LOCK=1
export HOMEBREW_NO_AUTO_UPDATE=1
# Homebrew 6.x の brew bundle は「全項目を fetch → 成功したら一括 install」の動きで、
# 1件でもダウンロードに失敗（配布元の 404 等）すると残り全件が未インストールのまま終わる。
# そのため bundle が失敗したら、1項目ずつ brew install に切り替えて道連れを防ぐ。
if ! brew bundle install --file="$BREWFILE_PATH"; then
  echo ""
  echo "WARN: brew bundle が失敗。1項目ずつ個別インストールに切り替えます"
  FAILED_ITEMS=()

  # ネットワーク不調（Connection reset 等）を吸収するため各項目を最大2回試す。
  # ※ 必ず </dev/null を付ける。brew install（特に ca-certificates の post-install）が
  #    標準入力を読むため、付けないと while read が読んでいる Brewfile の残り行を
  #    brew に食われてループが途中で終わる（2026-08-22 実機で wget の後で停止した）。
  brew_try() {
    local i
    for i in 1 2; do
      if brew "$@" </dev/null; then return 0; fi
      echo "  (失敗 ${i}/2: brew $*)"
      (( i < 2 )) && sleep 10
    done
    return 1
  }

  # Brewfile は fd 3 で読む（標準入力を brew と共有しない）
  while IFS= read -r -u 3 line; do
    line="${line%%#*}"
    kind="$(echo "$line" | awk '{print $1}')"
    name="$(echo "$line" | sed -n 's/^[a-z]* *"\([^"]*\)".*/\1/p')"
    [[ -z "$name" ]] && continue
    case "$kind" in
      brew)
        brew list --formula "$name" >/dev/null 2>&1 && continue
        brew_try install --formula "$name" || FAILED_ITEMS+=("formula:${name}")
        ;;
      cask)
        brew list --cask "$name" >/dev/null 2>&1 && continue
        brew_try install --cask "$name" || FAILED_ITEMS+=("cask:${name}")
        ;;
      tap)
        brew_try tap "$name" || FAILED_ITEMS+=("tap:${name}")
        ;;
    esac
  done 3< "$BREWFILE_PATH"
  if (( ${#FAILED_ITEMS[@]} > 0 )); then
    echo ""
    echo "WARN: 以下はインストールできませんでした（配布元の障害等）:"
    printf '  ✘ %s\n' "${FAILED_ITEMS[@]}"
  fi
fi

# 実際に何が入らなかったかを明示する（WARN だけだと見落とされるため）
echo ""
echo "--- Brewfile 充足チェック ---"
if brew bundle check --file="$BREWFILE_PATH" --verbose; then
  echo "Brewfile の全項目がインストール済みです"
else
  echo "WARN: 上記の項目が未インストールです。以下で個別に再試行してください:"
  echo "      brew bundle install --file=\"$BREWFILE_PATH\""
fi
echo "-----------------------------"

echo "アプリインストール 完了"
