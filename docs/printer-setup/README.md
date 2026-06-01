# Mac プリンタ設定手順書

EXCEED GROUP の Mac に Fujifilm Apeos 系プリンタをセットアップするための手順書。

## 前提

- 対象: macOS 13 (Ventura) 以降
- 対象プリンタ: Fujifilm Apeos 系 複合機
- 実施者: 情シス担当者
- 実施タイミング: `setup.sh` によるキッティング完了後

## 全体フロー

```
[1] 既存環境の調査（初回のみ・拠点ごと）
       ↓
[2] 拠点プリンタ一覧の作成（inventory-template.md を埋める）
       ↓
[3] ドライバのダウンロード
       ↓
[4] プリンタキュー追加
       ↓
[5] 既定値（両面・モノクロ等）の設定
       ↓
[6] テスト印刷
```

## ドキュメント一覧

| # | ファイル | 目的 | 頻度 |
|---|---|---|---|
| 01 | [investigation.md](./01-investigation.md) | 既存Macからプリンタ情報を吸い出す | 拠点ごと初回 |
| 02 | [driver-download.md](./02-driver-download.md) | Fujifilm純正ドライバの入手方法 | ドライバ更新時のみ |
| 03 | [printer-add.md](./03-printer-add.md) | プリンタキュー追加（GUI/CLI） | 毎キッティング |
| 04 | [default-settings.md](./04-default-settings.md) | 既定値（両面・モノクロ等）の設定 | 毎キッティング |
| 05 | [troubleshooting.md](./05-troubleshooting.md) | よくあるトラブル対処 | 必要時 |
| -- | [inventory-template.md](./inventory-template.md) | 拠点別プリンタ一覧（埋めて運用） | マスタとして保守 |

## 自動化との関係

本手順書はプリンタセットアップを **手動キッティング** として整備するもの。
完全自動化していない理由:

- 拠点（山形/宮城/福島）ごとにプリンタ構成が異なる
- 月のキッティング台数が少なく、自動化の費用対効果が低い
- ICカード認証・部門コード等の個別設定が絡む
- Fujifilm ドライバの配布URLが安定せず、自動DLが組みにくい

将来、拠点間で構成が揃った場合や、キッティング頻度が上がった場合に
[Phase A: 調査スクリプト化] → [Phase B: マスタYAML化] → [Phase C: 自動化]
の順で段階的に自動化していく。
