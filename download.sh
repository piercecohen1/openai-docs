#!/bin/bash
# Downloads all OpenAI API reference docs as markdown from llms.txt
# Uses llms.txt index at developers.openai.com for URL discovery
# Usage: ./download.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/docs"
URL_LIST="/tmp/openai-docs-urls.txt"
MAX_PARALLEL=10
FAILED_LOG="/tmp/openai-docs-failed.txt"
BASE_URL="https://developers.openai.com/api/reference"

# Handle --force flag
if [[ "${1:-}" == "--force" ]]; then
  echo "Force mode: clearing cached URL list..."
  rm -f "$URL_LIST"
fi

# Discover .md files via llms.txt
if [[ ! -f "$URL_LIST" ]]; then
  echo "Fetching llms.txt index..."
  curl -sL "$BASE_URL/llms.txt" \
    | rg -o 'https://developers\.openai\.com/api/reference/[^ )]*\.md' \
    | sort -u > "$URL_LIST"
  echo "Found $(wc -l < "$URL_LIST" | tr -d ' ') markdown files"
fi

TOTAL=$(wc -l < "$URL_LIST" | tr -d ' ')
echo "Downloading $TOTAL pages (max $MAX_PARALLEL parallel)..."

mkdir -p "$DOCS_DIR"
> "$FAILED_LOG"

download_page() {
  local md_url="$1"
  local rel_path="${md_url#https://developers.openai.com/api/reference/}"
  local out_file="$DOCS_DIR/$rel_path"

  mkdir -p "$(dirname "$out_file")"

  local http_code
  http_code=$(curl -sL -w '%{http_code}' -o "$out_file" "$md_url" 2>/dev/null)

  if [[ "$http_code" != "200" ]] || [[ ! -s "$out_file" ]]; then
    rm -f "$out_file"
    echo "$md_url" >> "$FAILED_LOG"
    echo "FAIL [$http_code] $rel_path"
  else
    echo "OK   $rel_path"
  fi
}

export -f download_page
export DOCS_DIR FAILED_LOG

cat "$URL_LIST" | xargs -P "$MAX_PARALLEL" -I {} bash -c 'download_page "$@"' _ {}

# Download llms-full.txt (single-file concatenation of all API reference docs)
echo ""
echo "Downloading llms-full.txt..."
if curl -sL -o "$DOCS_DIR/llms-full.txt" "$BASE_URL/llms-full.txt" && [[ -s "$DOCS_DIR/llms-full.txt" ]]; then
  FULL_LINES=$(wc -l < "$DOCS_DIR/llms-full.txt" | tr -d ' ')
  echo "OK   llms-full.txt ($FULL_LINES lines)"
else
  rm -f "$DOCS_DIR/llms-full.txt"
  echo "FAIL llms-full.txt"
fi

FAILED_COUNT=0
if [[ -f "$FAILED_LOG" ]]; then
  FAILED_COUNT=$(wc -l < "$FAILED_LOG" | tr -d ' ')
fi

DOWNLOADED=$((TOTAL - FAILED_COUNT))

echo ""
echo "Done. Downloaded $DOWNLOADED/$TOTAL pages to $DOCS_DIR/"
if [[ "$FAILED_COUNT" -gt 0 ]]; then
  echo "$FAILED_COUNT failures logged to $FAILED_LOG"
fi

# Generate README with scrape metadata
SCRAPE_DATE="$(date '+%B %-d, %Y')"
SCRAPE_SHORT="$(date '+%-m-%-d-%y')"

# Count pages per section
section_table() {
  # Top-level files (excluding llms-full.txt)
  local top_count
  top_count=$(find "$DOCS_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  if [[ "$top_count" -gt 0 ]]; then
    echo "| \`(top-level)\` | $top_count |"
  fi
  # Subdirectories
  for dir in "$DOCS_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name=$(basename "$dir")
    local count
    count=$(find "$dir" -name "*.md" | wc -l | tr -d ' ')
    echo "| \`$name/\` | $count |"
  done | sort -t'|' -k3 -rn
}

cat > "$SCRIPT_DIR/README.md" <<EOF
# OpenAI API Docs Mirror

Local mirror of the OpenAI API reference documentation from [developers.openai.com](https://developers.openai.com/api/reference), downloaded as raw markdown via the \`llms.txt\` index.

## Scrape Info

| | |
|---|---|
| **Last scraped** | $SCRAPE_DATE |
| **Pages downloaded** | $DOWNLOADED |
| **Source** | [developers.openai.com/api/reference/llms.txt](https://developers.openai.com/api/reference/llms.txt) |

## Sections

| Directory | Pages |
|-----------|-------|
$(section_table)

## Directory Structure

\`\`\`
$(tree "$DOCS_DIR" -d -L 2 --noreport 2>/dev/null | sed 's|'"$DOCS_DIR"'|docs|' || find "$DOCS_DIR" -type d -maxdepth 2 | sed "s|$DOCS_DIR|docs|" | sort)
\`\`\`

## Usage

Search with ripgrep:

\`\`\`bash
rg "chat completions" docs/
rg "embeddings" docs/resources/
rg "fine-tuning" docs/resources/
\`\`\`

Full-text search across the entire API reference:

\`\`\`bash
rg "function calling" docs/llms-full.txt
\`\`\`

## Updating

\`\`\`bash
cd /Users/piercecohen/claude-code/openai-docs
bash download.sh --force   # Re-fetch URL list from llms.txt
\`\`\`

## How It Works

The OpenAI API reference site publishes an index at \`llms.txt\` with direct \`.md\` URLs for every page. The download script fetches this index, extracts all URLs, and downloads them with $MAX_PARALLEL parallel connections. Directory structure is preserved (files nested up to 7 levels deep under \`resources/\`). Additionally, \`llms-full.txt\` (a single-file concatenation of all docs) is downloaded for full-text search.
EOF

echo "Generated README.md (scraped $SCRAPE_SHORT)"
