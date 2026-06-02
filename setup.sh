#!/usr/bin/env bash
#
# EXCEED GROUP - Mac キッティング セットアップスクリプト
#
# 使い方:
#   curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | bash
#
# プロファイル指定:
#   curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | PROFILE=eng bash
#
# 非対話モード:
#   curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | NON_INTERACTIVE=1 bash
#

set -euo pipefail

# ========================
# 設定値
# ========================
# REPO_URL は環境変数で上書き可能（特定コミットSHA/ブランチを指す等。raw CDNキャッシュ回避にも有効）
readonly REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/koseki-code/mac-kitting/main}"
readonly PROFILE="${PROFILE:-general}"            # general | eng
readonly NON_INTERACTIVE="${NON_INTERACTIVE:-0}"  # 1: プロンプトをスキップ
readonly LOG_DIR="${HOME}/.mac-kitting/logs"
LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d-%H%M%S).log"
readonly LOG_FILE
readonly WORK_DIR="${HOME}/.mac-kitting/work"

# ========================
# 色付き出力
# ========================
readonly C_RESET='\033[0m'
readonly C_BLUE='\033[0;34m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_RED='\033[0;31m'
readonly C_BOLD='\033[1m'

log()   { echo -e "${C_BLUE}[INFO]${C_RESET}  $*" | tee -a "$LOG_FILE"; }
ok()    { echo -e "${C_GREEN}[OK]${C_RESET}    $*" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*" | tee -a "$LOG_FILE"; }
err()   { echo -e "${C_RED}[ERR]${C_RESET}   $*" | tee -a "$LOG_FILE" >&2; }
step()  { echo -e "\n${C_BOLD}▶ $*${C_RESET}" | tee -a "$LOG_FILE"; }

# ========================
# 初期化
# ========================
init() {
  mkdir -p "$LOG_DIR" "$WORK_DIR"
  : > "$LOG_FILE"

  cat <<EOF | tee -a "$LOG_FILE"
================================================================
 EXCEED GROUP Mac キッティング セットアップ
 開始時刻 : $(date '+%Y-%m-%d %H:%M:%S')
 プロファイル : ${PROFILE}
 ホスト名 : $(hostname)
 ログイン者 : $(whoami)
 macOS : $(sw_vers -productVersion) ($(uname -m))
 ログファイル : ${LOG_FILE}
================================================================
EOF
}

# ========================
# 確認プロンプト
# ========================
confirm() {
  local prompt="${1:-続行しますか?}"
  if [[ "$NON_INTERACTIVE" == "1" ]]; then
    log "非対話モード: 自動でyesと回答 ($prompt)"
    return 0
  fi
  # `curl ... | bash` では stdin がスクリプト本体に占有されるため、
  # キーボード入力は /dev/tty から直接読む。
  if [[ -r /dev/tty ]]; then
    local response
    read -r -p "$prompt [y/N]: " response < /dev/tty
    [[ "$response" =~ ^[Yy]$ ]]
  else
    warn "対話端末（/dev/tty）が見つかりません。"
    warn "確認をスキップして実行するには NON_INTERACTIVE=1 を付けて再実行してください:"
    warn "  curl -fsSL ${REPO_URL}/setup.sh | NON_INTERACTIVE=1 bash"
    return 1
  fi
}

# ========================
# モジュール実行
# ========================
run_module() {
  local module="$1"
  local url="${REPO_URL}/lib/${module}"
  local local_path="${WORK_DIR}/${module}"

  step "${module} を実行"

  if ! curl -fsSL "$url" -o "$local_path"; then
    err "${module} のダウンロードに失敗: ${url}"
    return 1
  fi

  if bash "$local_path" 2>&1 | tee -a "$LOG_FILE"; then
    ok "${module} 完了"
  else
    err "${module} で失敗。ログ: ${LOG_FILE}"
    return 1
  fi
}

# ========================
# メイン
# ========================
main() {
  init

  step "プリチェック"
  run_module "00-precheck.sh"

  if ! confirm "上記の環境でセットアップを開始してよいですか?"; then
    warn "ユーザーが中断しました"
    exit 0
  fi

  # 順次実行（失敗したら止める）
  # ※ プロファイル（general/eng）の差分は 30-apps.sh の Brewfile 選択で吸収する
  run_module "10-macos-defaults.sh"
  run_module "20-homebrew.sh"

  # 20-homebrew.sh は別プロセスで brew を入れるため、その shellenv は親に伝播しない。
  # ここで親プロセスの PATH に brew を通し、以降の子モジュール(30/60/65)へ継承させる。
  # これをしないと 30-apps.sh で brew が見つからず、何もインストールされない。
  if ! command -v brew >/dev/null 2>&1; then
    for _p in /opt/homebrew /usr/local; do
      if [[ -x "${_p}/bin/brew" ]]; then
        eval "$("${_p}/bin/brew" shellenv)"
        ok "brew を PATH に追加: ${_p}/bin"
        break
      fi
    done
  fi

  run_module "30-apps.sh"

  # B-1: Chrome設定（既定ブラウザ・ポリシー・ブックマーク・拡張機能）
  # ※ 30-apps.sh の後でないと defaultbrowser/gh/jq が未インストールで失敗する
  run_module "60-chrome.sh"

  # B-2: Rectangle設定（ウィンドウ管理・自動起動・スナップ）
  # ※ 30-apps.sh の後でないと Rectangle.app が未インストールでスキップされる
  run_module "65-rectangle.sh"

  run_module "99-report.sh"

  step "セットアップ完了"
  ok "ログ: ${LOG_FILE}"
  ok "再ログインまたは再起動を推奨します（環境設定の完全反映のため）"
}

main "$@"
