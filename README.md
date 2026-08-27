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

## 使い方

スクリプトに実行権限を付与します。

```sh
chmod +x display_text.sh
```

基本的な実行方法は以下です。

```sh
./display_text.sh "表示する文字" "文字色" "背景色"
```

引数は以下の順番です。

| 引数 | 内容 | デフォルト |
|---|---|---|
| 第1引数 | 表示する文字列 | `READY` |
| 第2引数 | 文字色（`#RRGGBB`） | `#000000` |
| 第3引数 | 背景色（`#RRGGBB`） | `#ffffff` |

### 1行表示

```sh
./display_text.sh "READY"
```

文字色と背景色を指定する場合：

```sh
./display_text.sh "READY" "#ffffff" "#000000"
```

上記の場合は、黒背景に白文字で `READY` を表示します。

### 2行表示

文字列中に `\n` を指定すると2行で表示できます。

```sh
./display_text.sh "READY\n192.168.1.100"
```

### デバイスを指定する

通常は `/dev/cu.usbmodem*` の最初のデバイスを自動的に使用します。

複数のUSBシリアルデバイスが接続されている場合などは、`DEVICE` 環境変数で明示的に指定できます。

接続されているデバイスを確認します。

```sh
ls /dev/cu.usbmodem*
```

例えば `/dev/cu.usbmodem1101` を使用する場合：

```sh
DEVICE=/dev/cu.usbmodem1101 ./display_text.sh "READY"
```

文字色、背景色も同時に指定できます。

```sh
DEVICE=/dev/cu.usbmodem1101 ./display_text.sh \
    "READY\n192.168.1.100" \
    "#ffffff" \
    "#000000"
```

### 色の指定

文字色と背景色はHTML/CSSと同じ `#RRGGBB` 形式で指定します。

例：

```text
#000000  black
#ffffff  white
#ff0000  red
#00ff00  green
#0000ff  blue
#ffff00  yellow
```

例えば黄色文字を青背景で表示する場合：

```sh
./display_text.sh "HELLO" "#ffff00" "#0000ff"
```

## Linux で使用する場合

`sips` は macOS 固有のコマンドです。

Linux 環境で使用する場合は、SVG / PNG / BMP 変換部分を ImageMagick などを使用するように書き換えてください。

