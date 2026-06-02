# 実機テスト手順書

`setup.sh` を本番キッティングで使う前に、検証用Macで一度通しテストするための手順。
VM では macOS 設定の検証が難しいため、**実機（サブ機 or 消去可能なMac）** で行う。

## 0. 事前準備（重要）

このスクリプトは多数の `defaults` を**上書き**する。必ず以下のいずれかで実施すること:

- **推奨**: 新規 or 「すべてのコンテンツと設定を消去」直後のMac（＝本来のキッティング対象状態）
- 代替: 設定が消えても困らないサブ機

> ⚠ 普段使いのMacで試すと、トラックパッド速度やFinder設定などが書き換わる。検証機を使うこと。

前提:
- macOS 13 (Ventura) 以降
- Jamf Now のエンロールは検証では未済でもOK（MDM担当領域には触れないため）

---

## 1. まず「設定スクリプト単体」を手元で確認（フル実行前の安全確認）

いきなり `curl | bash` せず、設定部分だけ先に目視＆実行して挙動を見る。

```bash
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/lib/10-macos-defaults.sh -o /tmp/10.sh
less /tmp/10.sh        # 何を書き換えるか目視
bash /tmp/10.sh        # 設定だけ適用（Homebrew/アプリ導入はしない）
```

sudo を求められず最後まで流れ、`⚠ sudo権限なし: ...スキップ` が出れば**選択肢A（sudo方針）の挙動が正常**。

---

## 2. 設定が効いたか検証（チェックリスト）

`10.sh` 実行後、以下を確認（期待値を併記）:

```bash
defaults read -g com.apple.trackpad.scaling          # → 3  （トラックパッド速度Max）
defaults read -g com.apple.mouse.scaling             # → 3  （マウス速度Max）
defaults read -g com.apple.swipescrolldirection      # → 1  （スクロール方向 mac標準/ナチュラル）
defaults read NSGlobalDomain KeyRepeat               # → 2  （キーリピート最速）
defaults -currentHost read com.apple.screensaver idleTime   # → 300（5分）
defaults read com.apple.screensaver askForPassword   # → 1  （即パスワード）
defaults read com.apple.menuextra.clock DateFormat   # → yyyy/MM/dd(EEE)  HH:mm:ss
defaults read com.apple.finder AppleShowAllFiles     # → 1  （隠しファイル表示）
defaults read com.apple.dock autohide                # → 1  （Dock自動非表示）
defaults read com.apple.dock magnification           # → 1  （Dock拡大効果ON）
defaults read com.apple.dock mru-spaces              # → 0  （自動並び替え無効）
defaults read com.apple.controlcenter BatteryShowPercentage  # → 1  （バッテリー％表示）
defaults read NSGlobalDomain com.apple.mouse.tapBehavior     # → 1  （タップでクリック）

# ライトモード = キーが存在しない状態が正解（下はエラーになればOK）
defaults read -g AppleInterfaceStyle 2>&1            # → "does not exist" ならライト固定OK
```

見た目の確認:
- メニューバー時計が `2026/06/01(Mon) 14:30:05` 形式
- Dock が自動で隠れる
- Finder で隠しファイルが見える

※ トラックパッド速度・キーリピートは**再ログイン後に完全反映**される（スライダー値が変わっていればOK）。

### チェックリスト

- [ ] トラックパッド/マウス速度 Max
- [ ] スクロール方向 mac標準（ナチュラル）
- [ ] タップでクリック ON
- [ ] バッテリー％表示 / Dock拡大効果
- [ ] キーリピート最速
- [ ] スクリーンセーバー5分 + 即パスワード
- [ ] メニュー時計の曜日・秒表示
- [ ] Finder 隠しファイル表示
- [ ] Dock 自動非表示
- [ ] ライトモード固定

---

## 3. フル実行（一般職プロファイル）

設定が問題なければ本番同等のフル実行。
**前提**: 管理者アカウントであること＋実行前に `sudo -v` を済ませること（Homebrew導入に必要）。

```bash
# 管理者か確認
id -Gn | tr ' ' '\n' | grep -qx admin && echo "✅ 管理者" || echo "❌ 非管理者（昇格 or 別アカウントへ）"

# sudo を事前認証（パスワードを1回入力）
sudo -v

# フル実行
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | bash
```

確認ポイント:
- プリチェック（システム情報・GitHub到達・MDM）が表示される
- `上記の環境でセットアップを開始してよいですか? [y/N]` で **y** → 続行
- Homebrew インストール（**管理者パスワードを求められる** → 入力）
- `brew bundle` でアプリ導入（15〜40分）
- 完了レポートが表示され `~/.mac-kitting/logs/report-*.txt` に保存される

導入結果の検証:
```bash
brew list --cask          # google-chrome, slack, zoom, google-japanese-ime ... が並ぶ
brew list --formula       # git, gh, jq, wget
cat ~/.mac-kitting/logs/setup-*.log    # 全工程のログ
```

### チェックリスト

- [ ] プリチェックが正常表示
- [ ] 確認プロンプトで中断/続行が機能
- [ ] Homebrew 導入成功
- [ ] Brewfile のアプリが導入された（`brew list --cask` に google-chrome / rectangle 等が並ぶ）
- [ ] 完了レポートが出力・保存された

> ⚠ **既知バグの回帰確認（2026-06-02 修正）**: 以前、brew が後続モジュールの PATH に
> 引き継がれず `30-apps.sh` が何もインストールせず「完了」していた。フル実行後に
> `brew list --cask` が空でないこと、ログに `brew を PATH に追加` が出ることを必ず確認する。

---

## ★ B-1 Chrome / B-2 Rectangle の検証（追加分）

`30-apps.sh` で Chrome / Rectangle / defaultbrowser / gh / jq が入った後に
`60-chrome.sh` → `65-rectangle.sh` が走る。フル実行後に以下を確認する。

### B-1 Chrome

実行中の想定挙動:
- 🪟 `defaultbrowser chrome` 実行時に macOS が既定ブラウザ変更ダイアログを出すことがある → **「Chromeを使用」をクリック**
- `mac-kitting-private` 未作成のため `gh api` は404 → ログに `パブリックのみで進めます`（**これが正常**）

Chrome を起動し `chrome://policy` を開く:

| ポリシー | 期待値 |
|---|---|
| BackgroundModeEnabled | false |
| MetricsReportingEnabled | false |
| SafeBrowsingEnabled | true |
| AutofillCreditCardEnabled | false |
| ManagedBookmarks | 「EXCEED 業務リンク」配下に Workspace/Drive/Calendar/Gemini/ANDPAD 等10件 |
| ExtensionInstallForcelist | `aajlpbohkcfpmgeamipkmpllmgjmmmpa`（CrowdLog） |

```bash
sudo defaults read com.google.Chrome 2>/dev/null | grep -E "BackgroundMode|SafeBrowsing|Autofill"
```

- [ ] 既定ブラウザが Chrome（システム設定 > デスクトップとDock > 既定のWebブラウザ）
- [ ] ブックマークバーに「EXCEED 業務リンク」フォルダ
- [ ] `chrome://extensions` に CrowdLog が自動インストール（数秒〜数十秒）
- [ ] （sudo未認証時）`WARN: sudo権限なし...スキップ` が出る → `sudo bash ~/.mac-kitting/work/60-chrome.sh` で再実行

### B-2 Rectangle

```bash
defaults read com.knollsoft.Rectangle launchOnLogin     # → 1
defaults read com.knollsoft.Rectangle windowSnapping    # → 1
```

- [ ] メニューバーに Rectangle アイコン
- [ ] **アクセシビリティ権限を手動付与**（完了レポート【3】）: システム設定 > プライバシーとセキュリティ > アクセシビリティ で Rectangle をオン
- [ ] 権限付与後、**Ctrl+Option+矢印** でウィンドウが左右半分にスナップ
- [ ] マウスで画面端へドラッグしてスナップ

---

## 4. エンジニアプロファイルの確認

別の検証機（または同機で再実行）で:

```bash
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | PROFILE=eng bash
```

- [ ] ログに `使用するBrewfile: Brewfile.eng` が出る
- [ ] `brew list --cask` に `visual-studio-code` `cursor` `iterm2` `docker` 等が追加される

---

## 5. sudo（選択肢A）の挙動確認

```bash
# (a) sudoキャッシュなし → スキップ＋警告が出るのが正解
sudo -k                                    # sudoキャッシュをクリア
bash /tmp/10.sh 2>&1 | grep -A2 "ネットワークサービス"
#   → "⚠ sudo権限なし: ...スキップ" と手動コマンド案内が出ればOK

# (b) 手動で残り2項目を適用（完了レポートの【3】通り）
sudo systemsetup -setremotelogin off
sudo launchctl disable system/com.apple.smbd
sudo systemsetup -getremotelogin          # → Remote Login: Off
```

- [ ] sudoなしでスキップ＋手動案内が出る
- [ ] 手動コマンドでリモートログイン Off になる

---

## 6. 未検証項目：Caps Lock トグル

`TISRomajiKeyEnabled` / `TISKanaKeyEnabled` が実機で効くかを確認する（PLAN.md §4.5）:

1. 再ログイン（または再起動）
2. 入力ソースに日本語（ローマ字）または Google IME を追加
3. **Caps Lock キー単独押し**で「英数 ⇄ かな」が切り替わるか確認
4. 効かない場合 → システム設定 > キーボード > キーボードショートカット、または Google IME 側設定が必要。
   結果を PLAN.md §4.5 に反映して PR する。

- [ ] Caps Lock で英数/かな切替ができる（できない場合は所見をPLANに追記）

---

## 7. 切り戻し（検証機を元に戻したい場合）

```bash
# 導入アプリの一括削除（必要なら）
brew bundle --file=~/.mac-kitting/work/Brewfile cleanup --force
# 作業ディレクトリ削除
rm -rf ~/.mac-kitting
```

設定値（defaults）を完全に戻すのは手間なので、**検証機は最後に「すべてのコンテンツと設定を消去」で初期化**するのが確実。

---

## テスト結果の記録

テストで判明した不具合・想定と違った挙動は Issue または PR で記録し、`PLAN.md` の該当箇所に反映する。
特に手順6（Caps Lock）の結果は §4.5 の未決定事項を確定させる材料になる。
