#!/usr/bin/env bash
# 20-homebrew.sh - Homebrew インストール
set -euo pipefail

# ネットワークの一時的な不調で止まらないよう、インストールはリトライする。
# 2026-08-22 の実機で Portable Ruby（ghcr.io）のダウンロードが途中で切れて
# "Failed to install Homebrew Portable Ruby" となりキッティング全体が停止した。
readonly INSTALL_RETRIES=3
readonly RETRY_WAIT=20

brew_ok() {
  # brew コマンドが存在し、かつ Portable Ruby を含めて動作する状態か。
  # 見つかったら同時に PATH も通す（新規セッションでは .zprofile が未読込で
  # `brew` が command not found になるため）。
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]] && "$b" --version >/dev/null 2>&1; then
      eval "$("$b" shellenv)"
      return 0
    fi
  done
  return 1
}

if brew_ok; then
  echo "Homebrew は既にインストール済み"
  brew --version | head -1
else
  echo "Homebrew をインストールします（管理者パスワードが必要です）"
  attempt=1
  until brew_ok; do
    if (( attempt > INSTALL_RETRIES )); then
      echo "ERROR: Homebrew のインストールに ${INSTALL_RETRIES} 回失敗しました。" >&2
      echo "       ネットワーク（特に ghcr.io / github.com への到達）を確認して再実行してください" >&2
      exit 1
    fi
    echo "--- Homebrew インストール試行 ${attempt}/${INSTALL_RETRIES} ---"
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      break
    fi
    # install.sh は brew 本体の配置後に `brew update --force` で Portable Ruby を落とす。
    # ここで切れると brew 本体は残るが動かない状態になるため、update だけやり直す。
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [[ -x "$b" ]]; then
        echo "brew 本体は配置済み。Portable Ruby の取得を再試行します"
        "$b" update --force --quiet && break
      fi
    done || true
    if brew_ok; then break; fi
    attempt=$((attempt + 1))
    echo "WARN: 失敗しました。${RETRY_WAIT} 秒待って再試行します"
    sleep "$RETRY_WAIT"
  done
fi

# PATHを通す（Apple Silicon / Intel 両対応）
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

if [[ -x "${BREW_PREFIX}/bin/brew" ]]; then
  eval "$(${BREW_PREFIX}/bin/brew shellenv)"

  # zshrc に永続化（未追加の場合のみ）
  if ! grep -q "brew shellenv" "${HOME}/.zprofile" 2>/dev/null; then
    echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "${HOME}/.zprofile"
    echo "${HOME}/.zprofile に brew shellenv を追加"
  fi
fi

echo "Homebrew: $(brew --version | head -1)"
# brew update も一時的なネットワーク不調でコケることがあるため最大3回
for i in 1 2 3; do
  brew update --quiet && break
  echo "(brew update 失敗 ${i}/3。再試行します)"
  sleep 10
done || true

echo "Homebrew セットアップ 完了"
