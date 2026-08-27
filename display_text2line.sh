#!/bin/bash
set -euo pipefail

TEXT="${1:-READY}"
FG_COLOR="${2:-#000000}"
BG_COLOR="${3:-#ffffff}"

# \n という文字列も改行として扱う
TEXT="$(printf '%b' "$TEXT")"

validate_color()
{
    case "$1" in
        \#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])
            ;;
        *)
            echo "Invalid color: $1" >&2
            echo "Use #RRGGBB format" >&2
            exit 1
            ;;
    esac
}

validate_color "$FG_COLOR"
validate_color "$BG_COLOR"

if [ -n "${DEVICE:-}" ]; then
    DEV="$DEVICE"
else
    DEV="$(find /dev -maxdepth 1 -name 'cu.usbmodem*' -print 2>/dev/null | head -n 1)"
fi

if [ -z "$DEV" ]; then
    echo "Display device not found." >&2
    exit 1
fi

echo "Device:     $DEV"
echo "Foreground: $FG_COLOR"
echo "Background: $BG_COLOR"

TMPDIR_DISPLAY="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_DISPLAY"' EXIT

SVG="$TMPDIR_DISPLAY/text.svg"
PNG="$TMPDIR_DISPLAY/text.png"
BMP="$TMPDIR_DISPLAY/text.bmp"
RGB565="$TMPDIR_DISPLAY/text.rgb565"

xml_escape()
{
    printf '%s' "$1" |
    sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g'
}

LINE1="${TEXT%%$'\n'*}"
LINE2=""

if [[ "$TEXT" == *$'\n'* ]]; then
    LINE2="${TEXT#*$'\n'}"
fi

LINE1="$(xml_escape "$LINE1")"
LINE2="$(xml_escape "$LINE2")"

if [ -n "$LINE2" ]; then

    cat > "$SVG" <<EOF
<svg xmlns="http://www.w3.org/2000/svg"
     width="160" height="80"
     viewBox="0 0 160 80">

  <rect x="0" y="0"
        width="160" height="80"
        fill="$BG_COLOR"/>

  <text x="80" y="31"
        text-anchor="middle"
        font-family="Menlo"
        font-size="16"
        fill="$FG_COLOR">$LINE1</text>

  <text x="80" y="57"
        text-anchor="middle"
        font-family="Menlo"
        font-size="16"
        fill="$FG_COLOR">$LINE2</text>

</svg>
EOF

else

    cat > "$SVG" <<EOF
<svg xmlns="http://www.w3.org/2000/svg"
     width="160" height="80"
     viewBox="0 0 160 80">

  <rect x="0" y="0"
        width="160" height="80"
        fill="$BG_COLOR"/>

  <text x="80" y="46"
        text-anchor="middle"
        font-family="Menlo"
        font-size="18"
        fill="$FG_COLOR">$LINE1</text>

</svg>
EOF

fi

sips \
    -s format png \
    "$SVG" \
    --out "$PNG" \
    >/dev/null

sips \
    -s format bmp \
    "$PNG" \
    --out "$BMP" \
    >/dev/null

/usr/bin/perl - "$BMP" > "$RGB565" <<'PERL'
use strict;
use warnings;

my $file = shift or die "BMP file required\n";

open(my $fh, '<:raw', $file)
    or die "$file: $!\n";

local $/;
my $data = <$fh>;
close($fh);

die "not BMP\n"
    unless substr($data, 0, 2) eq 'BM';

my $offset      = unpack('V',  substr($data, 10, 4));
my $width       = unpack('l<', substr($data, 18, 4));
my $height      = unpack('l<', substr($data, 22, 4));
my $bpp         = unpack('v',  substr($data, 28, 2));
my $compression = unpack('V',  substr($data, 30, 4));

die "unexpected size: ${width}x${height}\n"
    unless $width == 160 && abs($height) == 80;

die "BMP compression $compression unsupported\n"
    unless $compression == 0 || $compression == 3;

die "only 24/32-bit BMP supported\n"
    unless $bpp == 24 || $bpp == 32;

my $bytes_per_pixel = $bpp / 8;
my $abs_height = abs($height);
my $stride = int(($width * $bpp + 31) / 32) * 4;

binmode(STDOUT);

for my $y (0 .. $abs_height - 1) {

    my $sy =
        ($height > 0)
        ? ($abs_height - 1 - $y)
        : $y;

    my $row = $offset + $sy * $stride;

    for my $x (0 .. $width - 1) {

        my $p = $row + $x * $bytes_per_pixel;

        my ($b, $g, $r) =
            unpack('CCC', substr($data, $p, 3));

        my $rgb565 =
              (($r >> 3) << 11)
            | (($g >> 2) << 5)
            |  ($b >> 3);

        print pack('v', $rgb565);
    }
}
PERL

SIZE="$(wc -c < "$RGB565" | tr -d ' ')"

if [ "$SIZE" -ne 25600 ]; then
    echo "Unexpected RGB565 size: $SIZE bytes" >&2
    exit 1
fi

echo "RGB565:     $SIZE bytes"

stty -f "$DEV" 115200 raw -echo
exec 3>"$DEV"

# LANDSCAPE = 2
/usr/bin/perl -e '
binmode STDOUT;
print pack("C*", 0x02, 0x02, 0x0a);
' >&3

sleep 0.05

# Bitmap 160 x 80
# x = 0..159, y = 0..79
/usr/bin/perl -e '
binmode STDOUT;
print pack(
    "C*",
    0x05,
    0,   0,
    0,   0,
    159, 0,
    79,  0,
    0x0a
);
' >&3

cat "$RGB565" >&3

sleep 0.2
exec 3>&-

echo "Done."
