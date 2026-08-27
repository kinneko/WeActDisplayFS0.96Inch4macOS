# WeActDisplayFS0.96Inch4macOS

WeAct Display FS 0.96 Inch で、指定した文字を表示するためのシェルスクリプトです。

macOS の標準シェル環境で動作するように、以下のコマンドだけを使用しています。

| コマンド | 用途 |
|---|---|
| `sed` | XML 用の文字エスケープ |
| `ls` | `/dev/cu.usbmodem*` の検出 |
| `head` | 最初に見つかったデバイスを選択 |
| `mktemp` | 一時ディレクトリ作成 |
| `sips` | SVG → PNG → BMP 変換 |
| `/usr/bin/perl` | BMP 解析、RGB565 変換、送信用バイナリヘッダ生成 |
| `wc` | RGB565 ファイルサイズ確認 |
| `tr` | `wc` 出力の空白除去 |
| `stty` | USB CDC シリアルポート設定 |
| `cat` | RGB565 データをシリアルへ送信 |
| `sleep` | コマンド送信間のウェイト |

## Linux で使用する場合

`sips` は macOS 固有のコマンドです。

Linux 環境で使用する場合は、SVG / PNG / BMP 変換部分を ImageMagick などを使用するように書き換えてください。

