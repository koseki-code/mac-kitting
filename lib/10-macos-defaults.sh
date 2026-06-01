#!/usr/bin/env bash
# 10-macos-defaults.sh - macOS 環境設定（完全版）
#
# 参考: https://macos-defaults.com/
# べき等性: defaults write は既存値を上書きするので何度実行しても安全

set -euo pipefail

echo "現在のログインユーザーで実行: $(whoami)"

# ========================
# トラックパッド（速度Max）
# ========================
echo "▶ トラックパッド設定"

# タップでクリックを有効化
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# トラックパッド速度 Max (0.0 ~ 3.0 / 既定 1.0)
defaults write -g com.apple.trackpad.scaling -float 3.0

# 3本指ドラッグを有効化
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# ========================
# マウス（速度Max・スクロール方向はWin互換）
# ========================
echo "▶ マウス設定"

# マウス速度 Max
defaults write -g com.apple.mouse.scaling -float 3.0

# I4: スクロール方向を従来式（Windowsと同じ向き）に
# true=ナチュラル / false=従来（Win互換）
defaults write -g com.apple.swipescrolldirection -bool false

# ========================
# キーボード
# ========================
echo "▶ キーボード設定"

# キーリピート速度（最速: 1, 既定: 6）
defaults write NSGlobalDomain KeyRepeat -int 2
# キーリピート開始までの待ち時間（最短: 10, 既定: 25）
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# 自動大文字化・自動置換系を全部オフ
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Fnキーをファンクションキーとして使う
defaults write -g com.apple.keyboard.fnState -bool true

# I1: Caps Lock で英数/かなトグルを有効化
# ※ これは入力ソースが「日本語(ローマ字)」または Google IME 設定後に効く
defaults write -g TISRomajiKeyEnabled -bool true
defaults write -g TISKanaKeyEnabled -bool true

# ========================
# 日本語入力（ライブ変換オフ）
# ========================
echo "▶ 日本語入力設定"

# Apple純正かな入力のライブ変換をオフ
# ※ Google IMEに切り替え後は無関係。Apple純正が残った場合の保険
defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false

# ========================
# Finder
# ========================
echo "▶ Finder設定"

defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# F1: ゴミ箱を30日後に自動削除
defaults write com.apple.finder FXRemoveOldTrashItems -bool true

# F2: デスクトップにiCloudのファイルを表示しない（業務ファイル流出防止）
# ※ iCloud Drive自体はオフにせず、デスクトップ・書類フォルダの同期だけ抑止
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# ========================
# Dock & デスクトップ
# ========================
echo "▶ Dock & デスクトップ設定"

defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3

# I3: Mission Control の自動並び替えを無効
defaults write com.apple.dock mru-spaces -bool false

# 「壁紙をクリックしてデスクトップを表示」を「ステージマネージャ使用時のみ」に
# false = ステージマネージャ使用時のみ / true = 常に
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# I2: ホットコーナー全部オフ
# wvous-{tl,tr,bl,br}-corner: 1=Mission Control系を無効
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-bl-corner -int 1
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-modifier -int 0

# ========================
# スクリーンショット
# ========================
echo "▶ スクリーンショット設定"

mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ========================
# セキュリティ
# ========================
echo "▶ セキュリティ設定"

# S1: スクリーンセーバー5分起動 + 即座にパスワード要求
defaults -currentHost write com.apple.screensaver idleTime -int 300
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# S2: Siri無効化
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri "VoiceTriggerUserEnabled" -bool false

# S3: 解析データをAppleに送らない
defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false 2>/dev/null || \
  echo "  (AutoSubmit の書き込みは sudo が必要なためスキップ - 手動設定を推奨)"

# S4: AirDrop を「連絡先のみ」に
defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"

# S6: Bluetoothメニューバー表示
defaults -currentHost write com.apple.controlcenter.plist Bluetooth -int 18
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

# ========================
# システム全般（地域・外観）
# ========================
echo "▶ システム全般"

# 言語と地域
defaults write NSGlobalDomain AppleLanguages -array "ja-JP" "en-JP"
defaults write NSGlobalDomain AppleLocale -string "ja_JP"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"

# U1: ライトモード固定（画面共有時の一貫性のため）
# ※ ライトモードは AppleInterfaceStyle キーが存在しない状態。
#    ダークモードが既に設定されている場合に備えてキーを削除する。
defaults delete NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true

# U2: メニューバー時計を「曜日・秒表示」付きに
# yyyy/MM/dd(EEE) HH:mm:ss
defaults write com.apple.menuextra.clock DateFormat -string "yyyy/MM/dd(EEE)  HH:mm:ss"
defaults write com.apple.menuextra.clock FlashDateSeparators -bool false
defaults write com.apple.menuextra.clock IsAnalog -bool false

# ========================
# アップデート
# ========================
echo "▶ アップデート設定"

# A1: macOSの自動DL・自動インストールはオフ（チェックのみ有効）
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false
defaults write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
defaults write com.apple.SoftwareUpdate ConfigDataInstall -bool true   # セキュリティデータは自動DL
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true # 緊急セキュリティは自動

# A2: App Storeアプリの自動アップデートはオン
defaults write com.apple.commerce AutoUpdate -bool true

# ========================
# サービス無効化 (S5: ファイル共有・リモートログイン)
# ========================
echo "▶ ネットワークサービス無効化"
# ※ これらは sudo が必要。スクリプトを sudo 付きで実行する必要あり。
#    通常実行ではエラーで止まらず警告のみ出す。
if [[ "$EUID" -eq 0 ]] || sudo -n true 2>/dev/null; then
  sudo launchctl disable system/com.apple.smbd 2>/dev/null || true
  sudo launchctl disable system/com.apple.AppleFileServer 2>/dev/null || true
  # -f: 「Do you really want to turn remote login off?」の確認プロンプトを抑止。
  #     </dev/null で万一の対話入力待ち（curl|bash でのハング）も防ぐ。
  sudo systemsetup -f -setremotelogin off >/dev/null 2>&1 </dev/null || true
  echo "  ファイル共有・リモートログインを無効化"
else
  echo "  ⚠ sudo権限なし: ファイル共有・リモートログイン無効化はスキップ"
  echo "     後で手動実行してください:"
  echo "       sudo systemsetup -f -setremotelogin off"
  echo "       sudo launchctl disable system/com.apple.smbd"
fi

# ========================
# 設定反映
# ========================
echo "▶ 設定を反映"

for app in "Finder" "Dock" "SystemUIServer" "cfprefsd"; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "macOS設定 完了"
echo "※ トラックパッド速度・キーリピート等は再ログイン後に完全反映されます"
