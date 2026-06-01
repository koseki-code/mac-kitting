# 04. 既定値（両面・モノクロ等）の設定

プリンタを追加しただけだと、両面印刷・モノクロ・部門コード等の既定値が
ユーザー好みになっておらず、毎回印刷時に変更する必要がある。

ここを情シスで揃えておくことで、ユーザー教育コストが下がる。

## 推奨される既定値（EXCEED 一般想定）

| 設定項目 | 推奨値 | 理由 |
|---|---|---|
| 両面印刷 | 長辺綴じ両面 | 用紙削減・コスト |
| カラーモード | モノクロ | コスト（必要時はユーザーが切替） |
| 用紙サイズ | A4 | 業務標準 |
| 排紙 | 通常 | - |
| ステープル | なし | 必要時はユーザーが選択 |

※ 拠点・部門で運用方針が異なる場合は、`inventory-template.md` に併記。

## 設定方法

### lpoptions コマンドで既定値を設定

CLIから一発で設定:

```bash
# 山形オフィスの複合機を例に
lpoptions -p "Yamagata_Office_MFP" \
  -o Duplex=DuplexNoTumble \
  -o ColorModel=Gray \
  -o PageSize=A4
```

### 利用可能なオプション一覧の確認

```bash
lpoptions -p "Yamagata_Office_MFP" -l
```

出力例:
```
PageSize/Page Size: *A4 A3 B4 Letter Legal ...
Duplex/2-Sided Printing: None *DuplexNoTumble DuplexTumble
ColorModel/Color Mode: *Gray RGB CMYK
APPrinterPreset/Preset: *None ...
```

`*` が付いているのが現在の既定値。

### 各オプションの値

#### Duplex（両面印刷）

| 値 | 意味 |
|---|---|
| `None` | 片面 |
| `DuplexNoTumble` | 両面（長辺綴じ） |
| `DuplexTumble` | 両面（短辺綴じ） |

#### ColorModel（カラーモード）

| 値 | 意味 |
|---|---|
| `Gray` | モノクロ |
| `RGB` / `CMYK` | カラー |

※ Fujifilm ドライバによって値の名前が異なる場合あり。
   `lpoptions -p <name> -l` で正確な値を確認。

#### PageSize（用紙サイズ）

| 値 | 意味 |
|---|---|
| `A4` | A4 |
| `A3` | A3 |
| `B4` | B4 |
| `Letter` | レター |

---

## 部門コード（Apeos 認証）の扱い

Fujifilm Apeos 系では、印刷時に **部門コード** や **ユーザーID/パスワード**
を要求する設定が運用されているケースがある。

### 現状確認

```bash
lpoptions -p "Yamagata_Office_MFP" -l | grep -iE "account|auth|user"
```

オプション例（ドライババージョンで名称が変わる）:
- `APAccountInfo`: 認証情報の取扱い
- `APUserID`: ユーザーIDの保存
- `XRXAccountUserID` 等

### 設定の選択肢

| 方針 | 設定 | メリット | デメリット |
|---|---|---|---|
| A: 認証情報をMacに保存 | `APAccountInfo=LoginName` | 毎回入力不要 | Mac共有時にリスク |
| B: 毎回ダイアログで聞く | `APAccountInfo=PromptUser` | 安全 | ユーザー負担 |
| C: 認証なし運用 | `APAccountInfo=None` | 楽 | 部門集計不可 |

→ **EXCEED の現状はどの方針か** を運用部門（総務・経理）に確認のうえ決定。
   方針を決めたら `inventory-template.md` に明記。

---

## オプション付き lpadmin（プリンタ追加時に既定値も同時設定）

`lpadmin` 実行時に `-o` を複数回つけて、追加と同時に既定値も設定できる:

```bash
sudo lpadmin \
  -p "Yamagata_Office_MFP" \
  -E \
  -v "lpd://192.168.10.50" \
  -P "/Library/Printers/PPDs/Contents/Resources/FUJIFILM ApeosPro C650.ppd" \
  -L "山形本社 1F" \
  -D "山形本社1F複合機" \
  -o printer-is-shared=false \
  -o Duplex=DuplexNoTumble \
  -o ColorModel=Gray \
  -o PageSize=A4
```

03-printer-add.md の一括追加スクリプトに、この形式で既定値もまとめると、
プリンタ追加と既定値設定が1コマンドで完了する。

---

## テスト印刷

設定完了後、必ずテスト印刷を行う:

```bash
echo "テストページ - $(date) - $(hostname)" | lp -d "Yamagata_Office_MFP"
```

または、システム設定 > プリンタとスキャナ > 該当プリンタ > 「テストページをプリント」。

確認項目:
- [ ] 両面で出力されているか
- [ ] モノクロで出力されているか
- [ ] 部門コード入力が必要な場合、正常に通っているか
- [ ] 印刷キューにエラーが残っていないか（`lpstat -W not-completed`）
