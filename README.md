# EXCEED GROUP Mac キッティング

新規Mac受領時に情シス担当者が実行するキッティング自動化スクリプト。

## 前提

- 対象: macOS 13 (Ventura) 以降
- 実行者: EXCEED GROUP 情シス担当者
- 想定時間: 30分〜60分（アプリインストール時間を含む）
- Jamf Now MDM のエンロール完了後に実行すること
- **キッティング対象アカウントが管理者（Administrator）であること**（Homebrew導入に必須）
- **実行前に `sudo -v` で sudo を一度認証しておくこと**（非対話実行でHomebrewが `Need sudo access` で止まるのを防ぐ）

```bash
# 実行前にこの1行を先に流しておく（パスワードを1回入力）
sudo -v
```

## 実行方法

### 標準（一般職向け）

```bash
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | bash
```

### エンジニア向け（開発ツールを追加）

```bash
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | PROFILE=eng bash
```

### 非対話モード（確認プロンプトをスキップ）

```bash
curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/setup.sh | NON_INTERACTIVE=1 bash
```

## 何をするスクリプトか

| ステップ | 内容 | 所要時間目安 |
|---|---|---|
| 00-precheck | システム情報・ネットワーク・MDM状態の確認 | 30秒 |
| 10-macos-defaults | トラックパッド・キーボード・Finder・Dock等の設定 | 10秒 |
| 20-homebrew | Homebrewのインストール | 3〜5分 |
| 30-apps | Brewfile に従ってアプリ一括インストール | 15〜40分 |
| 60-chrome | Chrome 既定ブラウザ化・ポリシー・ブックマーク | 30秒 |
| 65-rectangle | Rectangle（ウィンドウ管理）の設定 | 30秒 |
| 70-obs | OBS Studio（セミナー録画用）のインストールと録画設定配置 | 2〜5分 |
| 80-dock-login | 常駐アプリ（Alfred/Clipy/AppCleaner/PDFgear/OBS/RunCat）の初回起動・ログイン項目登録、Dock の不要アプリ削除と業務アプリ配置 | 1分 |
| 99-report | 完了レポート出力 | 即時 |

### OBS Studio について

- 録画設定（シーン・出力・音声トラック分離）はテンプレートを自動配置するため、
  ユーザーの作業は**画面収録・マイク権限をオンにするだけ**。手順は
  [OBS 権限設定手順](./docs/obs-permissions.md) を参照。
- 画面収録・マイク権限の付与は macOS の仕様（TCC/SIP）により自動化不可。
- 設定テンプレートの採取・更新手順は [assets/obs/README.md](./assets/obs/README.md) を参照。

## セキュリティポリシー

このリポジトリは**パブリック**です。以下を厳守してください:

- ❌ シークレット（APIキー、パスワード、トークン）を含めない
- ❌ 社員個人情報を含めない
- ❌ 業務アカウント情報をハードコードしない
- ✅ 設定値・アプリ一覧・公開可能な手順のみ
- ✅ 業務アカウント設定は完了レポートで「手動で行うこと」として誘導

## 失敗時の対処

### スクリプト全体が失敗した

ログを確認:
```bash
ls -lt ~/.mac-kitting/logs/
cat ~/.mac-kitting/logs/setup-YYYYMMDD-HHMMSS.log
```

### 特定モジュールだけ再実行したい

```bash
bash ~/.mac-kitting/work/10-macos-defaults.sh
```

### Homebrew のインストールで止まる

管理者パスワードが要求されている可能性があります。ターミナルを確認してください。

### アプリのインストールで一部失敗

`brew bundle` は失敗しても続行します。完了後に手動で:
```bash
brew bundle --file=~/.mac-kitting/work/Brewfile
```

### Homebrew が `Need sudo access` で止まる

管理者アカウントで、かつ実行前に `sudo -v` を済ませてください（前提を参照）。

### スクリプト更新直後に古い版が実行される（raw CDNキャッシュ）

`raw.githubusercontent.com` は約5分キャッシュされます。更新直後に最新版を確実に使うには、
`REPO_URL` にコミットSHAを指定してキャッシュを回避します:

```bash
SHA=<最新コミットSHA>
curl -fsSL "https://raw.githubusercontent.com/koseki-code/mac-kitting/${SHA}/setup.sh" \
  | REPO_URL="https://raw.githubusercontent.com/koseki-code/mac-kitting/${SHA}" bash
```

## 開発・更新

### スクリプトのテスト

VM や Docker での完全テストは難しいので、**サブの検証用Mac**で実行することを推奨。
通しテストの具体的な手順・検証チェックリストは [TESTING.md](./TESTING.md) を参照。

### 変更フロー

1. ブランチを切る: `git checkout -b feature/xxx`
2. 変更してPR作成
3. 検証Macで `setup.sh` をブランチ指定で実行:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/feature/xxx/setup.sh | bash
   ```
4. mainにマージ

### 設定値の追加・変更

| ファイル | 用途 |
|---|---|
| `lib/10-macos-defaults.sh` | macOSの defaults write 設定 |
| `Brewfile` | 一般職向けアプリ一覧 |
| `Brewfile.eng` | エンジニア向けアプリ一覧 |

## 関連ドキュメント

- [プリンタ設定手順書](./docs/printer-setup/README.md) — Fujifilm Apeos プリンタの手動セットアップ手順（本スクリプトの範囲外）
- [OBS 権限設定手順](./docs/obs-permissions.md) — 画面収録・マイク権限の手動許可手順と録画のはじめかた

## ライセンス

社内利用限定。
