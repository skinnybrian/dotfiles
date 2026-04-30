#!/bin/bash
# Markdown to PDF converter
# Uses marked (npm) for MD→HTML and Google Chrome --headless for HTML→PDF.
# Avoid `md-to-pdf` (puppeteer) — its Chromium download is excruciatingly slow.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
CACHE_DIR="$HOME/.cache/md-to-pdf"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

usage() {
  cat <<EOF
Usage: $(basename "$0") <input.md> [--out <output.pdf>] [--title <text>]

Options:
  --out <path>    Output PDF path (default: ~/Downloads/<basename>.pdf)
  --title <text>  PDF metadata title (default: filename without extension)
  -h, --help      Show this help
EOF
  exit 1
}

INPUT=""
OUTPUT=""
TITLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUTPUT="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    -h|--help) usage ;;
    --*) echo "Unknown option: $1" >&2; usage ;;
    *)
      if [[ -z "$INPUT" ]]; then
        INPUT="$1"
      else
        echo "Multiple input files specified — only one is supported" >&2
        usage
      fi
      shift
      ;;
  esac
done

[[ -z "$INPUT" ]] && usage
[[ ! -f "$INPUT" ]] && { echo "Error: file not found: $INPUT" >&2; exit 1; }

# Resolve to absolute path
INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd -P)/$(basename "$INPUT")"

BASENAME="$(basename "$INPUT_ABS")"
BASENAME="${BASENAME%.md}"
BASENAME="${BASENAME%.markdown}"

[[ -z "$OUTPUT" ]] && OUTPUT="$HOME/Downloads/${BASENAME}.pdf"
[[ -z "$TITLE" ]] && TITLE="$BASENAME"

# Ensure output directory exists
OUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUT_DIR"

# Verify Chrome
if [[ ! -x "$CHROME" ]]; then
  echo "Error: Google Chrome not found at $CHROME" >&2
  exit 1
fi

# Verify node
if ! command -v node >/dev/null 2>&1; then
  echo "Error: node not found in PATH" >&2
  exit 1
fi

# Install marked to cache (one-time)
if [[ ! -d "$CACHE_DIR/node_modules/marked" ]]; then
  echo "Installing marked to $CACHE_DIR (first run only)..." >&2
  mkdir -p "$CACHE_DIR"
  (cd "$CACHE_DIR" && npm init -y >/dev/null 2>&1 && npm install --silent marked) || {
    echo "Error: failed to install marked" >&2
    exit 1
  }
fi

# Convert MD → HTML
TMP_HTML="$(mktemp -t md-to-pdf-XXXXXX).html"
trap 'rm -f "$TMP_HTML"' EXIT

NODE_PATH="$CACHE_DIR/node_modules" node "$SCRIPT_DIR/md2html.js" \
  "$INPUT_ABS" "$TMP_HTML" "$SCRIPT_DIR/style.css" "$TITLE" >&2

# Convert HTML → PDF
"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-pdf-header-footer \
  --virtual-time-budget=10000 \
  --print-to-pdf="$OUTPUT" \
  "file://$TMP_HTML" >&2

if [[ -f "$OUTPUT" ]]; then
  SIZE="$(du -h "$OUTPUT" | cut -f1)"
  echo "✅ PDF generated: $OUTPUT ($SIZE)"
else
  echo "❌ PDF generation failed" >&2
  exit 1
fi
