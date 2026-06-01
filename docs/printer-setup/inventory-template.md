# 拠点別プリンタ一覧（マスタ）

**最終更新**: YYYY-MM-DD by 担当者名
**運用ルール**:
- 拠点でプリンタを追加・撤去・IP変更したら、必ずこのファイルを更新
- 更新は Pull Request 経由でレビュー後マージ
- 古い情報はバージョン履歴に残るので削除してOK

---

## 共通設定

| 項目 | 値 |
|---|---|
| 標準プロトコル | LPD (`lpd://`) |
| 標準ドライバ | FUJIFILM Print Driver for Mac vX.X.X |
| 既定の用紙サイズ | A4 |
| 既定のカラーモード | モノクロ (Gray) |
| 既定の両面 | 長辺綴じ両面 (DuplexNoTumble) |
| 認証方針 | （要決定: A=Login保存 / B=毎回入力 / C=なし） |

---

## 山形本社

### Yamagata_Office_1F_MFP

| 項目 | 値 |
|---|---|
| キュー名 | `Yamagata_Office_1F_MFP` |
| 表示名 | 山形本社1F複合機 |
| 設置場所 | 山形本社 1F 受付付近 |
| 機種 | （要調査）例: Apeos C5570 |
| IPアドレス | （要調査）例: 192.168.10.50 |
| プロトコル | LPD |
| PPDファイル | （要調査）例: FUJIFILM ApeosPro C650.ppd |
| 認証 | （要調査） |
| 既定値（両面） | DuplexNoTumble |
| 既定値（カラー） | Gray |
| デフォルトプリンタ | ✅ |
| 備考 | - |

### Yamagata_Office_2F_MFP

| 項目 | 値 |
|---|---|
| キュー名 | `Yamagata_Office_2F_MFP` |
| 表示名 | 山形本社2F複合機 |
| 設置場所 | 山形本社 2F |
| 機種 | （要調査） |
| IPアドレス | （要調査） |
| プロトコル | LPD |
| PPDファイル | （要調査） |
| 認証 | （要調査） |
| 既定値（両面） | DuplexNoTumble |
| 既定値（カラー） | Gray |
| デフォルトプリンタ | - |
| 備考 | - |

---

## 宮城拠点

### Sendai_Office_MFP

| 項目 | 値 |
|---|---|
| キュー名 | `Sendai_Office_MFP` |
| 表示名 | 仙台オフィス複合機 |
| 設置場所 | （要調査） |
| 機種 | （要調査） |
| IPアドレス | （要調査） |
| プロトコル | LPD |
| PPDファイル | （要調査） |
| 認証 | （要調査） |
| 既定値（両面） | DuplexNoTumble |
| 既定値（カラー） | Gray |
| デフォルトプリンタ | ✅ |
| 備考 | - |

---

## 福島拠点

### Fukushima_Koriyama_MFP

| 項目 | 値 |
|---|---|
| キュー名 | `Fukushima_Koriyama_MFP` |
| 表示名 | 郡山オフィス複合機 |
| 設置場所 | （要調査） |
| 機種 | （要調査） |
| IPアドレス | （要調査） |
| プロトコル | LPD |
| PPDファイル | （要調査） |
| 認証 | （要調査） |
| 既定値（両面） | DuplexNoTumble |
| 既定値（カラー） | Gray |
| デフォルトプリンタ | ✅ |
| 備考 | - |

---

## モデルハウス・営業所（必要に応じて追加）

（EXCEED 各ブランドのモデルハウス・営業所にもプリンタがある場合はここに追加）

---

## 拠点別 一括追加スクリプトの保管場所

各拠点の lpadmin 一括スクリプトは下記に格納:

```
docs/printer-setup/scripts/
├── add-printers-yamagata.sh
├── add-printers-miyagi.sh
└── add-printers-fukushima.sh
```

→ 03-printer-add.md の例を参考に、本ファイルの内容をもとに作成。

---

## 変更履歴

| 日付 | 変更内容 | 担当 |
|---|---|---|
| YYYY-MM-DD | 初版作成（要調査箇所多数） | - |
