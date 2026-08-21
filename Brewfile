# EXCEED GROUP 標準 Brewfile（一般職向け）
#
# 使い方: brew bundle --file=Brewfile

# ========================
# CLI ツール
# ========================
brew "git"
brew "wget"
brew "jq"
brew "gh"            # GitHub CLI（情シス操作で必須）
brew "defaultbrowser" # 既定ブラウザの自動切り替え（60-chrome.sh で使用）
brew "dockutil"       # Dock の並び替え・不要アプリ削除（80-dock-login.sh で使用）

# ========================
# 業務アプリ
# ========================
cask "google-chrome"
cask "chrome-remote-desktop-host" # Chrome リモートデスクトップ（ホスト側 pkg。要 sudo）
cask "google-japanese-ime"
cask "slack"
cask "zoom"
cask "typeless"            # AI音声入力（初回起動時にマイク・アクセシビリティ権限が必要）
cask "claude"              # Claude デスクトップアプリ（Anthropic 公式）
cask "chatgpt"             # ChatGPT デスクトップアプリ（OpenAI 公式）

# ========================
# Microsoft 製品（Office / Teams）は標準では導入しない。必要な端末のみ手動:
#   brew install --cask microsoft-office microsoft-teams
# ========================

# ========================
# ユーティリティ
# ========================
cask "the-unarchiver"      # ZIP/RAR等の展開
cask "appcleaner"          # アプリの完全削除
cask "rectangle"           # ウィンドウ管理（無料）
cask "clipy"               # クリップボード履歴（無料）
cask "alfred"              # ランチャー（無料。Powerpackは有料オプション）

# ========================
# フォント
# ========================
cask "font-noto-sans-cjk-jp"
cask "font-noto-serif-cjk-jp"

# ========================
# Mac App Store アプリ（mas-cli が必要）
# ========================
# brew "mas"
# mas "LINE", id: 539883307
