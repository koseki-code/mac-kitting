#!/usr/bin/env bash
# 70-obs.sh - OBS Studio セットアップ（セミナー録画用）
#
# 内容:
# 1. OBS Studio のインストール（Homebrew Cask）
# 2. 録画設定テンプレート（プロファイル・シーンコレクション）の配置
#    - リポジトリの assets/obs/obs-studio/ を tarball 経由で取得して
#      ~/Library/Application Support/obs-studio/ に配置する
#    - テンプレート未格納の場合は警告のみ出してスキップする
# 3. 画面収録・マイク権限の手動許可の案内表示
#
# 注意: 画面収録・マイク権限（TCC）の付与は macOS のセキュリティ仕様により
#       スクリプトでは自動化できません。詳細は docs/obs-permissions.md を参照。
#       OBS は必須ソフトではないため、このモジュールはエラーでも exit 0 で
#       抜けてキッティング全体を止めません。

set -euo pipefail

readonly REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/koseki-code/mac-kitting/main}"
readonly WORK_DIR="${HOME}/.mac-kitting/work"
readonly OBS_APP="/Applications/OBS.app"
# テンプレート取得元 tarball（REPO_URL のブランチ/SHA 指定に追従する。上書き可）
# 例: https://codeload.github.com/koseki-code/mac-kitting/tar.gz/main
OBS_ASSETS_TARBALL="${OBS_ASSETS_TARBALL:-}"

# ========================
# 実行ユーザーの判定（FR-04）
# ========================
# sudo 実行時は $HOME が /var/root を指すため、必ず貸与先ユーザーの
# ホームディレクトリを解決してから配置する。
TARGET_USER="$(whoami)"
TARGET_HOME="${HOME}"
RUNNING_AS_ROOT=0

if [[ "$EUID" -eq 0 ]]; then
  RUNNING_AS_ROOT=1
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="${SUDO_USER}"
    TARGET_HOME="$(dscl . -read "/Users/${TARGET_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
    if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
      TARGET_HOME="/Users/${TARGET_USER}"
    fi
    echo "sudo 実行を検出: 配置先ユーザーを ${TARGET_USER} (${TARGET_HOME}) に切り替えます"
  else
    echo "WARN: root 実行ですが貸与先ユーザーを特定できません（SUDO_USER 未設定）"
    echo "      設定テンプレートの配置をスキップします。貸与先ユーザーで再実行してください:"
    echo "      bash ~/.mac-kitting/work/70-obs.sh"
    exit 0
  fi
fi

readonly OBS_CONFIG_DIR="${TARGET_HOME}/Library/Application Support/obs-studio"

# ========================
# brew を PATH に通す（単体実行やサブシェルで PATH 未継承のとき用の保険）
# ========================
if ! command -v brew >/dev/null 2>&1; then
  for _p in /opt/homebrew /usr/local; do
    if [[ -x "${_p}/bin/brew" ]]; then eval "$("${_p}/bin/brew" shellenv)"; break; fi
  done
fi

# ========================
# 1. OBS Studio のインストール（FR-01）
# ========================
echo "▶ OBS Studio のインストール"

if [[ -d "${OBS_APP}" ]]; then
  echo "OBS Studio は既にインストール済み（${OBS_APP}）。インストールをスキップします"
elif ! command -v brew >/dev/null 2>&1; then
  echo "WARN: Homebrew が見つかりません。OBS のインストールをスキップします"
  echo "      20-homebrew.sh が成功しているか確認してください"
  exit 0
else
  if [[ "$RUNNING_AS_ROOT" -eq 1 ]]; then
    # brew は root 実行を拒否するため、貸与先ユーザーとして実行する
    if ! sudo -u "${TARGET_USER}" -H brew install --cask obs; then
      echo "WARN: OBS のインストールに失敗しました。OBS は必須ソフトではないため続行します"
      exit 0
    fi
  else
    if ! brew install --cask obs; then
      echo "WARN: OBS のインストールに失敗しました。OBS は必須ソフトではないため続行します"
      exit 0
    fi
  fi
  echo "OBS Studio をインストールしました"
fi

# ========================
# 2. 設定テンプレートの取得（FR-02）
# ========================
echo "▶ 録画設定テンプレートの取得"

TEMPLATE_SRC=""

# (a) リポジトリのローカルチェックアウトから単体実行された場合はそれを使う
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "${SCRIPT_DIR}/../assets/obs/obs-studio" ]]; then
  TEMPLATE_SRC="$(cd "${SCRIPT_DIR}/../assets/obs/obs-studio" && pwd)"
  echo "ローカルのテンプレートを使用: ${TEMPLATE_SRC}"
else
  # (b) リポジトリ tarball をダウンロードして展開する
  #     （モジュールは raw URL から単体取得されるため、assets はここで取得する）
  if [[ -z "${OBS_ASSETS_TARBALL}" ]]; then
    # REPO_URL（例: https://raw.githubusercontent.com/OWNER/REPO/REF）から tarball URL を導出
    _repo_path="${REPO_URL#https://raw.githubusercontent.com/}"
    _owner="$(echo "${_repo_path}" | cut -d/ -f1)"
    _repo="$(echo "${_repo_path}" | cut -d/ -f2)"
    _ref="$(echo "${_repo_path}" | cut -d/ -f3-)"
    OBS_ASSETS_TARBALL="https://codeload.github.com/${_owner}/${_repo}/tar.gz/${_ref}"
  fi

  EXTRACT_DIR="${WORK_DIR}/obs-assets"
  rm -rf "${EXTRACT_DIR}"
  mkdir -p "${EXTRACT_DIR}"

  # ネットワーク不通時は速やかに失敗させる（無限リトライしない）
  if curl -fsSL --connect-timeout 10 --max-time 120 "${OBS_ASSETS_TARBALL}" \
      | tar -xz -C "${EXTRACT_DIR}" 2>/dev/null; then
    TEMPLATE_SRC="$(find "${EXTRACT_DIR}" -maxdepth 4 -type d -path '*/assets/obs/obs-studio' | head -1)"
  else
    echo "WARN: テンプレートのダウンロードに失敗しました: ${OBS_ASSETS_TARBALL}"
  fi
fi

if [[ -z "${TEMPLATE_SRC}" || ! -d "${TEMPLATE_SRC}" ]]; then
  echo "WARN: 設定テンプレート（assets/obs/obs-studio/）が見つかりません"
  echo "      設定配置をスキップします。OBS 本体のみインストールされた状態です"
  echo "      テンプレートの採取・格納手順は assets/obs/README.md を参照してください"
  exit 0
fi

# ========================
# 3. 既存設定の退避と配置（FR-02, FR-03）
# ========================
echo "▶ 録画設定テンプレートの配置"

if [[ -d "${OBS_CONFIG_DIR}" ]]; then
  BACKUP_DIR="${OBS_CONFIG_DIR}.bak.$(date +%Y%m%d%H%M%S)"
  echo "既存の OBS 設定を検出。退避します: ${BACKUP_DIR}"
  mv "${OBS_CONFIG_DIR}" "${BACKUP_DIR}"
fi

mkdir -p "${OBS_CONFIG_DIR}"
cp -R "${TEMPLATE_SRC}/." "${OBS_CONFIG_DIR}/"
echo "配置完了: ${OBS_CONFIG_DIR}"

# 所有者を貸与先ユーザーに揃える（FR-04）
if [[ "$RUNNING_AS_ROOT" -eq 1 ]]; then
  TARGET_GROUP="$(id -gn "${TARGET_USER}")"
  chown -R "${TARGET_USER}:${TARGET_GROUP}" "${OBS_CONFIG_DIR}"
  echo "所有者を設定: ${TARGET_USER}:${TARGET_GROUP}"
fi

# ========================
# 4. 権限設定の案内（FR-05）
# ========================
echo ""
echo "OBS セットアップ 完了"
echo ""
echo "================================================================"
echo " ⚠ 重要: 画面収録・マイク権限の手動許可が必要です"
echo "================================================================"
echo ""
echo "OBS で録画するには、以下の権限付与が必要です。"
echo "この手順は macOS のセキュリティ仕様により自動化できません。"
echo ""
echo "手順（システム設定 > プライバシーとセキュリティ）:"
echo "  1. 「画面収録とシステムオーディオ録音」で OBS をオン"
echo "  2. 「マイク」で OBS をオン（自分の発言も録音する場合）"
echo "  3. 許可後、OBS を再起動する"
echo ""
echo "詳細な手順書: docs/obs-permissions.md"

# 対話端末で実行されている場合のみ、システム設定の該当画面を直接開く
if [[ "${NON_INTERACTIVE:-0}" != "1" && -r /dev/tty && "$RUNNING_AS_ROOT" -eq 0 ]]; then
  echo ""
  echo "▶ システム設定（画面収録）を開きます"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture" || true
fi
