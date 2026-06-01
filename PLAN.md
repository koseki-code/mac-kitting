# Mac キッティング自動化 実装計画書

**作成日**: 2026年5月14日
**最終更新**: 2026年6月1日
**担当**: 情シス（小関）
**ステータス**: 実装完了 → 検証フェーズ（実機テスト前）

> **更新メモ (2026-06-01)**: スクリプト一式の実装が完了。セキュリティ系を含む
> macOS設定を「全部入り」で採用し、プリンタ設定は手順書ベースの手動キッティングとして
> 整備した（自動化スコープ外）。本書はその確定内容を反映済み。残るはGitHubリポジトリ作成・
> 実機検証・sudo実行方針の確定・プリンタ拠点調査。

---

## 1. 背景と目的

### 背景

EXCEED GROUP では Jamf Now MDM を導入しているが、**シェルスクリプトの直接配信機能がない**（Jamf Pro と異なり Scripts payload なし）。トラックパッド速度・キーリピート・Finder設定など、ユーザー個別の好みに依存しすぎず初期値として揃えたい設定は MDM では扱いにくい。

Composer + 署名済みパッケージ経由で配信する方法はあるが、Apple Developer Program 契約（年¥14,800）と署名運用が必要で、現状の運用規模（月数台）に対して過剰。

### 目的

- 新規Mac受領時のキッティング所要時間を削減
- 設定の属人化を防ぎ、誰がキッティングしても同じ結果にする
- 設定の変更履歴を git で管理し、変更理由を追跡可能にする

### 非目標

- Jamf Now の代替にはしない（FileVault強制等のセキュリティ系はMDM側で担当）
- 業務アカウント設定の自動化は行わない（パスワードを含むため）

---

## 2. 役割分界

| 責務 | 担当 | 備考 |
|---|---|---|
| FileVault強制 | Jamf Now | セキュリティ |
| 画面ロック | Jamf Now | セキュリティ |
| Wi-Fi設定 | Jamf Now | 全社共通 |
| アプリ制限・機能制限 | Jamf Now | セキュリティ |
| トラックパッド・キーボード | **本スクリプト** | 初期値のみ |
| Finder/Dock設定 | **本スクリプト** | 初期値のみ |
| Homebrew導入 | **本スクリプト** | - |
| 業務アプリ一括導入 | **本スクリプト** | Chrome, Slack, Office 等 |
| Google IME 入力ソース切替 | 手動 | レポートで誘導（自動化は不安定） |
| プリンタ設定 | 手動 | `docs/printer-setup/` 手順書ベース |
| 業務アカウント設定 | 手動 | Google Workspace, Chatwork, ANDPAD |
| iCloud設定 | 手動 | ユーザー判断 |

---

## 3. アーキテクチャ

```
[新規Mac]
  │
  │ 担当者がターミナルで1行実行
  ▼
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | bash
  │
  ▼
[setup.sh] エントリーポイント
  │
  ├──> [lib/00-precheck.sh]  環境確認
  ├──> [lib/10-macos-defaults.sh]  defaults write 一式（セキュリティ系含む全部入り）
  ├──> [lib/20-homebrew.sh]  Homebrew導入
  ├──> [lib/30-apps.sh]  brew bundle 実行
  │      └── PROFILE=general → Brewfile / PROFILE=eng → Brewfile.eng
  └──> [lib/99-report.sh]  完了レポート出力 + 手動作業ガイド

[プリンタ設定]（スクリプト外・手動キッティング）
  └──> docs/printer-setup/  Fujifilm Apeos 系の手順書一式
        01:調査 → 02:ドライバDL → 03:キュー追加 → 04:既定値 → 05:トラブル対処
        + inventory-template.md（拠点別プリンタマスタ）
```

### 採用した macOS 設定（全部入り・10-macos-defaults.sh）

セキュリティ系を含めて初期値を揃える方針を採用:

- **入力デバイス**: トラックパッド/マウス速度 Max、3本指ドラッグ、スクロール方向 Win互換、
  キーリピート最速化、Fnキーをファンクション固定、Caps Lock で英数/かなトグル
- **日本語入力**: Apple純正かな入力のライブ変換オフ（保険）。Google IME への切替は手動（後述）
- **Finder/Dock**: 隠しファイル・拡張子表示、パスバー/ステータスバー、ゴミ箱30日自動削除、
  デスクトップのHDD非表示、Dock自動非表示、ホットコーナー全オフ、Mission Control自動並び替え無効、
  「壁紙クリックでデスクトップ表示」をステージマネージャ使用時のみに
- **セキュリティ**: スクリーンセーバー5分+即時パスワード要求、Siri無効、AirDrop連絡先のみ、
  解析データ送信オフ（要sudo）、ファイル共有/リモートログイン無効（要sudo）、Bluetoothメニュー表示
- **外観/地域**: ライトモード固定、メニュー時計に曜日・秒（`yyyy/MM/dd(EEE) HH:mm:ss`）、日本語ロケール
- **アップデート**: macOS自動DL/自動インストールはオフ（チェックのみ）、App Store自動更新オン

### Google 日本語入力の方針

- Brewfile で `google-japanese-ime` をインストールする
- **入力ソースの追加とApple純正の削除は手動**（cfprefsd 関連で自動化が不安定なため）
- 99-report.sh の完了レポートで手順を明示誘導する

### プリンタ設定の方針（自動化スコープ外）

拠点（山形/宮城/福島）ごとに構成・ICカード認証・部門コードが異なり、月数台のキッティング頻度では
自動化の費用対効果が低いため、`docs/printer-setup/` の手順書による手動キッティングとする。
将来 構成が揃う/頻度が上がる場合は [調査スクリプト化 → マスタYAML化 → 自動化] の順で段階移行。

### 配信方式

- GitHub **パブリックリポジトリ** (`koseki-code/mac-kitting`)
- `raw.githubusercontent.com` 経由で直接配信
- 認証不要、シークレット非保持

### セキュリティ

- スクリプト本体にシークレットを含めない（パブリック前提）
- 業務アカウント情報は完了レポートで「手動設定すべき項目」として誘導
- `set -euo pipefail` で失敗時は即座に停止
- ログを `~/.mac-kitting/logs/` に保存（調査用）

---

## 4. 実装ロードマップ

### Phase 0: 実装（完了 ✅ 2026-06-01）

- [x] アーキテクチャ/ディレクトリ構成設計
- [x] スクリプト一式の実装（`bash -n` 構文チェック済み）
- [x] Brewfile（一般職向け / エンジニア向け）
- [x] プリンタ設定手順書（docs/printer-setup/ 7ファイル）
- [x] README.md

### Phase 1: リポジトリ準備（1日）

- [ ] `koseki-code/mac-kitting` リポジトリをパブリックで作成（素の `gh repo create`。repo-provisionerは使わない）
- [ ] スクリプト一式をコミット & push
- [ ] GitHub Actions で shellcheck を有効化（任意）

### Phase 2: 検証（3日）

- [ ] 検証用Mac（または vmware/utm の macOS仮想環境）で初回実行テスト
- [ ] 既存設定が上書きされて困ることがないか確認
- [ ] PROFILE=eng の動作確認
- [ ] エラーケースのハンドリング確認（ネットワーク切断、権限不足等）

### Phase 3: 限定運用（1ヶ月）

- [ ] 次のキッティング1〜2台で実運用
- [ ] 担当者の操作感をヒアリング
- [ ] フィードバックを反映

### Phase 4: 本運用（継続）

- [ ] 全キッティングで標準採用
- [ ] 設定変更は Pull Request 経由のみ
- [ ] 月1回、Brewfile の見直し（不要アプリの整理）

---

## 4.5 確定済み / 未決定事項

### 確定済み

- **sudo実行方針 = 選択肢A（2026-06-01 確定）**
  スクリプトは一般ユーザー権限（`curl ... | bash`）で実行する。root必須の2項目
  （S3: 解析データ送信オフ / S5: ファイル共有・リモートログイン無効）は `sudo -n` を試行し、
  権限がなければスキップして警告を出す。完了レポート（99-report.sh）で手動実行を誘導する。
  - 採用理由: S5 は Jamf Now MDM のセキュリティ担当領域と重複する／月数台規模で手動2コマンドの
    コストは小さい／選択肢B（root実行 + `SUDO_USER`振り分け）はバグを生みやすく検証負担が増える。
  - キッティング担当者は完了レポートの【3】【4】に従い、必要なら手動で以下を実行:
    ```bash
    sudo systemsetup -setremotelogin off
    sudo launchctl disable system/com.apple.smbd
    ```

### 未決定事項

| 項目 | 内容 | 対応タイミング |
|---|---|---|
| **Caps Lock トグルの実効性** | `TISRomajiKeyEnabled`/`TISKanaKeyEnabled` が実機で効くか未検証 | 検証Macテスト時に確認 |
| **プリンタ拠点調査** | 山形/宮城/福島の既存Macで `01-investigation.md` を実行し inventory を埋める | 拠点ごとに順次 |

---

## 5. リスクと対処

| リスク | 影響度 | 対処 |
|---|---|---|
| macOS のアップデートで `defaults` キーが変わる | 中 | 検証用Macで先行テスト |
| 既にユーザーがカスタマイズした設定を上書きする | 中 | 初回キッティング時のみ実行のルール |
| GitHub障害で配信できない | 低 | ローカルにスクリプトをダウンロードしておくフォールバック |
| Homebrew がインストール失敗 | 中 | エラーログを残す、手動再実行可能 |
| ユーザー権限と root 権限の混在 | 中 | `defaults` はユーザー、`brew install` は管理者で実行 |

---

## 6. 運用ルール

### 変更プロセス

1. Issue で変更内容を起票
2. Pull Request を作成（必ずブランチを切る）
3. 検証用Macで動作確認（ブランチ指定で実行）
4. レビュー後 main にマージ
5. CHANGELOG.md に記録

### 緊急時の切り戻し

```bash
# 特定コミットの版を実行
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/{コミットSHA}/setup.sh | bash
```

### ログ保管

- ローカルログ: `~/.mac-kitting/logs/` に蓄積
- 必要に応じて Slack DM で情シスチャンネルに送付するフックを後日追加

---

## 7. 拡張余地（将来）

- WorkContextAgent 連携: キッティング完了を Firestore に記録
- Slack 通知: 完了時に情シスチャンネルへ自動通知
- 設定差分検査: 既存キッティング済みMacが期待値とずれていないか定期チェック
- Jamf Now の Composer パッケージ化: スクリプトを `.pkg` で配信する方式へ移行（必要であれば）

---

## 8. 関連リンク

- リポジトリ: `https://github.com/koseki-code/mac-kitting`
- Jamf Now 公式: スクリプト配信なし、Composer 経由のみ
- macOS defaults リファレンス: `https://macos-defaults.com/`
