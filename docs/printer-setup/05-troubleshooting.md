# 05. プリンタ設定のトラブルシューティング

## ping は通るが印刷できない

### 確認1: プリンタキューが「Idle」になっているか

```bash
lpstat -p "Yamagata_Office_MFP"
```

- `Idle` → OK（印刷待機中）
- `Disabled` → 何らかの理由で無効化されている。次のコマンドで再有効化:
  ```bash
  cupsenable "Yamagata_Office_MFP"
  ```
- `Stopped, rejecting jobs` → 拒否状態。次で復帰:
  ```bash
  cupsaccept "Yamagata_Office_MFP"
  cupsenable "Yamagata_Office_MFP"
  ```

### 確認2: 残留ジョブの削除

過去のエラージョブが詰まって以降が止まることがある:

```bash
# 残ジョブ確認
lpstat -W not-completed

# 全削除
cancel -a "Yamagata_Office_MFP"
```

### 確認3: CUPS ログを見る

```bash
sudo tail -f /var/log/cups/error_log
```

別ターミナルで印刷を試して、リアルタイムでエラー内容を確認。

---

## PPDが見つからない・選択肢に出ない

### 状況: 03-printer-add.md の `-P` で指定したPPDパスが Error: not found

```bash
# 該当ファイルの存在確認
ls -la "/Library/Printers/PPDs/Contents/Resources/" | grep -i apeos
```

ファイル名のスペースや大文字小文字に注意。
コマンドに渡すときは必ずダブルクォートで囲む。

### 状況: GUIの「ソフトウェアを選択…」に Apeos が出ない

ドライバインストールが完了していない可能性。02-driver-download.md に戻って:
- pkg が正常終了したか
- macOS 再起動が必要なケースがある（特に古いドライバ）

---

## 印刷ジョブが「保留中」のまま動かない

### Apeos の認証ダイアログが裏で待っている

- 認証付き運用の場合、印刷時にユーザーID/パスワードや部門コードの
  ダイアログが画面の裏に隠れていることがある
- Dockのプリンタアイコンをクリックして表示確認

### 解決

- 04-default-settings.md の認証設定を `APAccountInfo=LoginName` 等に変更し、
  毎回ダイアログが出ないようにする

---

## 「プリンタはオフラインです」が出る

### ネットワーク到達性の確認

```bash
ping -c 3 192.168.10.50
nc -zv 192.168.10.50 515   # LPDポート
nc -zv 192.168.10.50 9100  # Socket(RAW)ポート
```

- ping すら通らない → 物理的に同じネットワークにいるか、VPN/WiFi切替確認
- ping通るがポート閉じている → プリンタ本体のサービス設定確認

### CUPS デーモンの再起動

```bash
sudo launchctl stop org.cups.cupsd
sudo launchctl start org.cups.cupsd
```

---

## 「印刷データが壊れている」「文字化け」

### 接続プロトコルが合っていない可能性

- Socket (RAW, port 9100) → 生のPostScript/PCLを送る。ドライバ依存性が強い
- LPD → ヘッダ付きで送る。Apeos標準
- IPP → 認証等の高度な制御が可能

03-printer-add.md の URI を変えて再追加してみる。Apeos は基本 LPD が安全。

### PPD のバージョン違い

ドライバを更新したのに古いプリンタキューが残っていると、PPDの整合が崩れる。
削除して再追加:

```bash
sudo lpadmin -x "Yamagata_Office_MFP"
# その後 03-printer-add.md の手順で再追加
```

---

## macOS アップデート後に印刷できなくなった

### よくあるパターン

- 新しいmacOSバージョン向けのドライバが未配布
- 既存ドライバが新OSと非互換

### 対応

1. Fujifilm 公式サイトで該当 macOS バージョン対応版が出ているか確認
2. 未対応の場合は Fujifilm BI 担当 or 販売店に問い合わせ
3. 暫定でAirPrint対応モデルなら AirPrint で凌ぐ:
   ```bash
   sudo lpadmin -p "Yamagata_Office_MFP_AirPrint" -E \
     -v "ipp://192.168.10.50/ipp/print" \
     -P "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/Generic.ppd" \
     -L "山形本社 1F (AirPrint暫定)" \
     -o printer-is-shared=false
   ```
   → 機能制限あり（両面・ステープル等が使えないことがある）

---

## ICカード認証付きプリンタで認証エラー

### Apeos の IC Card Print 等

- ユーザーごとに「カード番号」と「印刷ジョブ」を紐付ける運用
- Macからの印刷は Mac のログイン名（UNIXユーザー名）でジョブが送信される
- プリンタ側のユーザーマスタにそのユーザー名が登録されていないと弾かれる

### 確認・対応

```bash
# Mac のログイン名（プリンタに送信されるユーザー名）
whoami
```

→ この名前がプリンタ管理者の登録するユーザー一覧と一致しているか確認。
   不一致の場合は人事マスタの命名規則と Mac セットアップ時のユーザー名規則を
   揃える必要がある（ここは情シスの運用ルール設計事項）。

---

## それでも解決しない場合

- Fujifilm BI サポート: 0120-27-4100（販売店契約による）
- 詳細ログを添えて問い合わせ:
  ```bash
  sudo cupsctl --debug-logging
  # 問題再現
  sudo tar czf /tmp/cups-logs.tar.gz /var/log/cups/
  ```
