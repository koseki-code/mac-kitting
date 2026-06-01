# 01. 既存Mac からプリンタ情報を吸い出す

新規拠点のキッティングを始める前に、その拠点の **既存のキッティング済みMac1台** から
現状のプリンタ設定を調査する。これにより:

- 拠点に何台プリンタが存在するか
- それぞれのIP・PPD・キュー名
- 既定値の設定内容

が一括で把握できる。

## 必要なもの

- 対象拠点で実際に印刷ができている既存Mac 1台
- 担当者ターミナル操作の権限

## 調査手順

### Step 1: 接続中プリンタの一覧

```bash
lpstat -p -d
```

出力例:
```
printer Yamagata_Office_MFP is idle.  enabled since ...
printer Yamagata_2F_MFP is idle.  enabled since ...
system default destination: Yamagata_Office_MFP
```

→ **プリンタキュー名** と **デフォルトプリンタ** がわかる。

### Step 2: プリンタの接続情報（IP等）

```bash
lpstat -v
```

出力例:
```
device for Yamagata_Office_MFP: lpd://192.168.10.50
device for Yamagata_2F_MFP: socket://192.168.10.51:9100
```

→ **プロトコル**（lpd/ipp/socket等）と **IPアドレス・ポート** がわかる。

### Step 3: 詳細情報（モデル名・PPD）

```bash
system_profiler SPPrintersDataType
```

出力例:
```
Yamagata_Office_MFP:

      Shared: No
      Status: Idle
      Driver Version: 5.2.0
      Default: Yes
      URI: lpd://192.168.10.50
      PPD: FUJIFILM ApeosPro C650
      PPD File Version: 1.0
      PostScript Version: (3017.103) 0
```

→ **モデル名・ドライババージョン・PPDファイル名** がわかる。

### Step 4: 各プリンタの詳細オプション

各プリンタの既定値設定（両面、用紙、認証など）を確認:

```bash
# プリンタ名は Step 1 で取得したものを指定
lpoptions -p Yamagata_Office_MFP -l
```

出力例:
```
PageSize/Page Size: *A4 A3 B4 Letter Legal ...
Duplex/2-Sided Printing: None *DuplexNoTumble DuplexTumble
ColorModel/Color Mode: *RGB Gray
APAccountInfo/Account Info: *None LoginName ...
```

→ `*` が付いているのが現在の既定値。EXCEED 既存運用の設定が見える。

### Step 5: 一括取得スクリプト

上記を一発で集めるスクリプト:

```bash
cat <<'SCRIPT' > /tmp/printer-inventory.sh
#!/bin/bash
HOST=$(hostname)
DATE=$(date +%Y%m%d-%H%M%S)
OUT="${HOME}/Desktop/printer-inventory-${HOST}-${DATE}.txt"

{
  echo "=== Printer Inventory ==="
  echo "Host : ${HOST}"
  echo "Date : $(date)"
  echo "User : $(whoami)"
  echo "macOS: $(sw_vers -productVersion)"
  echo ""
  echo "--- lpstat -p -d ---"
  lpstat -p -d
  echo ""
  echo "--- lpstat -v ---"
  lpstat -v
  echo ""
  echo "--- system_profiler SPPrintersDataType ---"
  system_profiler SPPrintersDataType
  echo ""
  echo "--- 各プリンタの詳細オプション ---"
  for p in $(lpstat -p | awk '/^printer/ {print $2}'); do
    echo ""
    echo ">>> ${p}"
    lpoptions -p "${p}" -l
    echo ""
    echo ">>> ${p} (current defaults)"
    lpoptions -p "${p}"
  done
  echo ""
  echo "--- インストール済みPPD ---"
  ls /Library/Printers/PPDs/Contents/Resources/ 2>/dev/null | grep -iE "fuji|apeos|xerox" || echo "(該当なし)"
} > "${OUT}"

echo "結果を保存しました: ${OUT}"
SCRIPT
bash /tmp/printer-inventory.sh
```

### Step 6: 結果の保存と展開

調査結果ファイル（デスクトップに出力される）を:

1. 情シス管理の Google Drive にアップロード
2. `inventory-template.md` を埋める材料として使用

## 拠点をまたぐ調査の進め方

1. 山形拠点: 既存Mac 1台で実施
2. 宮城拠点: 既存Mac 1台で実施
3. 福島拠点: 既存Mac 1台で実施

各拠点の出力を比較し、共通項と差異を `inventory-template.md` に整理する。

## 注意

- 同じ拠点でも、Macによってインストールされているプリンタが違うことがある
  （個人が後から追加しているケース）
- 「正しい構成」が何かを決めるのは情シス。複数Macの調査結果を見比べて判断する
- 退職者Macの情報は除外する
