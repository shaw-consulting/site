#!/bin/sh
# Compose Shaw Consulting's SVG wordmark and icon using only POSIX sh + awk.
# Works with Git Bash on Windows and with the system shell on macOS/Linux.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ICON="$ROOT/site/assets/icon.svg"
TEXT="$ROOT/site/assets/text.svg"
OUTPUT=${1:-"$ROOT/site/assets/logo.svg"}

if [ "$#" -gt 1 ]; then
  echo 'Usage: sh scripts/build-logo.sh [output.svg]' >&2
  exit 2
fi

for file in "$ICON" "$TEXT"; do
  if [ ! -f "$file" ]; then
    echo "Missing source SVG: $file" >&2
    exit 1
  fi
done

mkdir -p "$(dirname -- "$OUTPUT")"
TEMP="${OUTPUT}.tmp.$$"
trap 'rm -f "$TEMP"' 0
trap 'exit 1' 1 2 3 15

# Strip the XML declaration, verify each component viewBox, and place the
# self-contained SVG into the combined SVG as a nested SVG viewport.
# This deliberately preserves paths, embedded CSS (including dark mode),
# and transparency instead of generating <image href=...> external refs.
embed_svg() {
  awk -v file="$1" -v expected="$2" -v pos_x="$3" -v pos_y="$4" \
      -v pos_width="$5" -v pos_height="$6" '
    BEGIN { found = 0 }
    /^<\?xml[[:space:]]/ { next }
    !found {
      if ($0 !~ /^<svg[[:space:]>]/) {
        print file ": expected an <svg> root element" > "/dev/stderr"
        exit 2
      }
      if (!match($0, /<svg[^>]*>/)) {
        print file ": incomplete <svg> start tag" > "/dev/stderr"
        exit 2
      }
      tag = substr($0, RSTART, RLENGTH)
      if (index(tag, "viewBox=\"" expected "\"") == 0) {
        print file ": unexpected viewBox (update placements deliberately)" > "/dev/stderr"
        exit 2
      }
      rest = substr($0, RSTART + RLENGTH)
      # The original width/height are intrinsic dimensions, not placement.
      # Remove them from the nested root and replace with layout dimensions.
      gsub(/[[:space:]]+(x|y|width|height)="[^"]*"/, "", tag)
      sub(/^<svg/, "<svg x=\"" pos_x "\" y=\"" pos_y "\" width=\"" pos_width "\" height=\"" pos_height "\"", tag)
      $0 = tag rest
      found = 1
    }
    { print }
    END { if (!found) exit 2 }
  ' "$1"
}

{
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
  printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 470" width="1000" height="470" role="img" aria-labelledby="shaw-logo-title shaw-logo-desc">'
  printf '%s\n' '  <title id="shaw-logo-title">Shaw Consulting</title>'
  printf '%s\n' '  <desc id="shaw-logo-desc">Networked head icon above Shaw Consulting wordmark</desc>'
  embed_svg "$ICON" '0 0 400 400' 310 -12 380 380
  embed_svg "$TEXT" '0 352 1000 116' 0 352 1000 116
  printf '%s\n' '</svg>'
} > "$TEMP"

# Avoid rewriting the logo on unrelated commits/checkouts.
if [ -f "$OUTPUT" ] && command -v cmp >/dev/null 2>&1 && cmp -s "$TEMP" "$OUTPUT"; then
  printf 'Logo unchanged: %s\n' "$OUTPUT"
else
  mv -f "$TEMP" "$OUTPUT"
  printf 'Generated: %s\n' "$OUTPUT"
fi
