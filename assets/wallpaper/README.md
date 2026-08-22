# デスクトップ画像（壁紙）

`lib/85-wallpaper.sh` がキッティング時に適用するデスクトップ画像を置く場所。

## 使い方

1. 使いたい画像を **`wallpaper.jpg`**（または `wallpaper.png`）という名前でこのディレクトリに置いて main にマージする
   - 推奨: 横長 16:10 または 16:9、5120×3200 程度まで（MacBook の Retina 解像度に合わせる）
   - 1 ファイル 100MB 未満（GitHub の制限）
2. 以降のキッティングで自動的に全ディスプレイ・全スペースの壁紙に設定される
3. 画像が未格納のときは「壁紙画像が未格納のためスキップ」と表示されるだけで、キッティングは止まらない

## 既存端末に単体で適用する

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/lib/85-wallpaper.sh)
```

## 別の画像 URL を使いたい場合

```bash
WALLPAPER_URL="https://example.com/xxx.jpg" bash <(curl -fsSL https://raw.githubusercontent.com/koseki-code/mac-kitting/main/lib/85-wallpaper.sh)
```
