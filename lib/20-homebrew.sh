#!/usr/bin/env bash
# 20-homebrew.sh - Homebrew インストール
set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  echo "Homebrew は既にインストール済み"
  brew --version | head -1
else
  echo "Homebrew をインストールします（管理者パスワードが必要です）"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
brew update --quiet || echo "(brew update は警告が出ても続行)"

echo "Homebrew セットアップ 完了"
