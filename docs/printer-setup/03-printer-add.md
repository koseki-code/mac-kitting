# 03. プリンタキュー追加

ドライバインストール後、プリンタを Mac に「キュー」として登録する。
GUI と CLI の2通りがあるが、**CLI が推奨**（速い・記録が残る・ミスが減る）。

## 前提

- ドライバ（PPD）が `/Library/Printers/PPDs/Contents/Resources/` に配置済み
- プリンタのIPアドレスがわかっている（`inventory-template.md` 参照）
- Macが社内ネットワークに接続済み（プリンタにping応答すること）

```bash
# 接続確認
ping -c 3 192.168.10.50
```

---

## 方法A: CLI で追加（推奨）

### コマンド例: 山形オフィス1F複合機

```bash
sudo lpadmin \
  -p "Yamagata_Office_MFP" \
  -E \
  -v "lpd://192.168.10.50" \
  -P "/Library/Printers/PPDs/Contents/Resources/FUJIFILM ApeosPro C650.ppd" \
  -L "山形本社 1F" \
  -D "山形本社1F複合機" \
  -o printer-is-shared=false
```

### パラメータの意味

| オプション | 意味 |
|---|---|
| `-p` | プリンタキュー名（システム内部での識別子。半角英数とアンダースコアのみ推奨） |
| `-E` | 追加と同時に有効化（Enable） |
| `-v` | デバイスURI（接続情報） |
| `-P` | PPDファイルへのフルパス |
| `-L` | 設置場所（Locationフィールド） |
| `-D` | 表示名（印刷ダイアログで見える名前） |
| `-o printer-is-shared=false` | 他Macとの共有を無効（業務Macでは必須） |

### URIの書き方

| プロトコル | URI | 用途 |
|---|---|---|
| LPD | `lpd://IP_ADDRESS` | 最も一般的、Apeos標準 |
| Socket (RAW) | `socket://IP_ADDRESS:9100` | 高速だが認証なし |
| IPP | `ipp://IP_ADDRESS/ipp/print` | 認証等を使う場合 |
| IPPS | `ipps://IP_ADDRESS/ipp/print` | 暗号化通信 |

→ EXCEED 既存運用が何を使っているかは `01-investigation.md` の `lpstat -v` 結果で確認。

### PPDパスの調べ方

```bash
ls /Library/Printers/PPDs/Contents/Resources/ | grep -i apeos
```

ファイル名にスペースが含まれることが多いので、コマンドではダブルクォートで囲む。

### 追加後の確認

```bash
# 登録されたか
lpstat -p "Yamagata_Office_MFP"

# 設定内容
lpoptions -p "Yamagata_Office_MFP"

# デフォルトプリンタにする場合
lpoptions -d "Yamagata_Office_MFP"
```

---

## 方法B: GUI で追加

CLIに不慣れな担当者向け、または初期検証で使用。

1. システム設定 > プリンタとスキャナを開く
2. 右上の「プリンタ、スキャナ、またはファクスを追加…」をクリック
3. 「IP」タブを選択
4. 以下を入力:
   - アドレス: `192.168.10.50`
   - プロトコル: `Line Printer Daemon - LPD`
   - キュー: (空欄でOK)
   - 名前: `Yamagata_Office_MFP`
   - 場所: `山形本社 1F`
   - ドライバ: 「ソフトウェアを選択…」から `FUJIFILM ApeosPro C650` を選択
5. 「追加」をクリック
6. オプション設定画面が出たら、両面ユニット・大容量給紙トレイ等の有無を確認

---

## 拠点別 一括追加スクリプトの例

調査が終わって `inventory-template.md` が埋まったら、拠点ごとにこのテンプレートを使う:

```bash
#!/bin/bash
# add-printers-yamagata.sh - 山形本社のプリンタを一括追加
set -e

PPD_BASE="/Library/Printers/PPDs/Contents/Resources"

# 山形本社 1F
sudo lpadmin -p "Yamagata_Office_1F_MFP" -E \
  -v "lpd://192.168.10.50" \
  -P "${PPD_BASE}/FUJIFILM ApeosPro C650.ppd" \
  -L "山形本社 1F" \
  -D "山形本社1F複合機" \
  -o printer-is-shared=false

# 山形本社 2F
sudo lpadmin -p "Yamagata_Office_2F_MFP" -E \
  -v "lpd://192.168.10.51" \
  -P "${PPD_BASE}/FUJIFILM ApeosPro C650.ppd" \
  -L "山形本社 2F" \
  -D "山形本社2F複合機" \
  -o printer-is-shared=false

# デフォルトプリンタは1F
lpoptions -d "Yamagata_Office_1F_MFP"

echo "山形本社プリンタの追加完了"
lpstat -p -d
```

このスクリプトを `scripts/add-printers-{location}.sh` として保管しておくと、
次回キッティング時にコピペで使える。

---

## 削除手順（やり直したいとき）

```bash
# 一覧
lpstat -p

# 削除
sudo lpadmin -x "Yamagata_Office_MFP"
```
