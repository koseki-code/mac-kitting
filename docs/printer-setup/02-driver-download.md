# 02. Fujifilm Apeos ドライバの入手

## 入手元

Fujifilm Business Innovation の公式サポートサイトからダウンロードする:

- 公式URL: https://www.fujifilm.com/fb/download
- 機種別にmacOS対応ドライバが配布されている

### ダウンロード手順

1. 上記サイトで機種名（例: `Apeos C5570`）を入力
2. OSを「Mac OS」で絞り込み
3. 自社で使用している macOS バージョンと一致するドライバを選択
4. プリンタドライバ（PPD含む）の `.dmg` ファイルをダウンロード

### 機種とドライバの対応表

`inventory-template.md` を参照し、拠点・機種ごとに必要なドライバをリストアップ。
ドライバ名の例:

| 機種 | ドライバ名（例） |
|---|---|
| Apeos C5570 | FUJIFILM_Print_Driver_for_Mac_OS_X_v*.dmg |
| Apeos C2570 | FUJIFILM_Print_Driver_for_Mac_OS_X_v*.dmg |
| ApeosPort 等 | （要確認） |

※ Fujifilm のドライバは **複数機種を1つのインストーラで提供** していることが多い。
   インストール後、追加するプリンタのモデルに応じたPPDが自動で選ばれる。

## ドライバの保管方針

### 推奨: 社内共有ドライブに保管

毎回 Fujifilm サイトからダウンロードすると:
- URLが変わって動かなくなる
- バージョン管理ができない
- 検証済みでない最新版を誤って使う

を防ぐため、**情シス管理の Google Drive 共有フォルダ** にダウンロード済みドライバを保管:

```
共有ドライブ/情シス/Mac-Kitting/printer-drivers/
├── README.md                        # ドライバの来歴メモ
├── current/                         # 現在の標準ドライバ
│   └── FUJIFILM_Print_Driver_macOS_v6.2.0.dmg
└── archive/                         # 過去版（ロールバック用）
    └── FUJIFILM_Print_Driver_macOS_v6.1.0.dmg
```

`current/README.md` の内容例:
```
# Fujifilm Mac Driver

- 現行版: v6.2.0
- 入手日: 2026/03/15
- 入手元: https://www.fujifilm.com/fb/download/.../
- 検証Mac: 山形オフィス 検証機 (macOS 14.4)
- 検証日: 2026/03/20
- 動作確認機種: Apeos C5570, Apeos C2570
```

## ドライバのインストール手順

### Step 1: dmg をマウント

Finder で `.dmg` をダブルクリック、または:

```bash
hdiutil attach ~/Downloads/FUJIFILM_Print_Driver_macOS_v6.2.0.dmg
```

### Step 2: pkg を実行

マウントされたディスク内の `.pkg` をダブルクリックしてインストーラを起動。
管理者パスワードが求められる。

ターミナルから:
```bash
sudo installer -pkg "/Volumes/FUJIFILM Print Driver/FujifilmPrintDriver.pkg" -target /
```

### Step 3: dmg をアンマウント

```bash
hdiutil detach "/Volumes/FUJIFILM Print Driver"
```

### Step 4: 確認

```bash
ls /Library/Printers/PPDs/Contents/Resources/ | grep -iE "fuji|apeos"
```

出力にPPDファイルが並べば成功。

## ライセンスと再配布について

⚠ Fujifilm のドライバを社外公開URL（GCSパブリックバケット等）に置く場合、
Fujifilm の利用規約上、再配布が許されているか必ず確認すること。

社内Google Drive（情シス限定アクセス）への保管は通常問題ないが、
将来GCS公開バケットでの配信に変える場合は事前確認が必須。
