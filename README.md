# EXCEED GROUP Mac キッティング

新規Mac受領時に情シス担当者が実行するキッティング自動化スクリプト。

## 前提

- 対象: macOS 13 (Ventura) 以降
- 実行者: EXCEED GROUP 情シス担当者
- 想定時間: 30分〜60分（アプリインストール時間を含む）
- Jamf Now MDM のエンロール完了後に実行すること

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
| 99-report | 完了レポート出力 | 即時 |

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

## 開発・更新

### スクリプトのテスト

VM や Docker での完全テストは難しいので、**サブの検証用Mac**で実行することを推奨。

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

## ライセンス

社内利用限定。
