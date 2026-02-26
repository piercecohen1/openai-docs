#!/bin/bash
# Downloads all OpenAI API docs as markdown from llms.txt indexes
# Fetches both API reference (/api/reference/) and guides (/api/docs/)
# Usage: ./download.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_PARALLEL=10
FAILED_LOG="/tmp/openai-docs-failed.txt"

# Handle --force flag
FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
  echo "Force mode: clearing cached URL lists..."
fi

# Generic download function for a section
# Args: $1=section_name $2=base_url $3=url_regex $4=strip_prefix $5=out_dir $6=cache_file
download_section() {
  local section_name="$1"
  local base_url="$2"
  local url_regex="$3"
  local strip_prefix="$4"
  local out_dir="$5"
  local cache_file="$6"

  echo ""
  echo "=== $section_name ==="

  if [[ "$FORCE" == true ]]; then
    rm -f "$cache_file"
  fi

  # Discover .md files via llms.txt
  if [[ ! -f "$cache_file" ]]; then
    echo "Fetching llms.txt index..."
    curl -sL "$base_url/llms.txt" \
      | rg -o "$url_regex" \
      | sort -u > "$cache_file"
    echo "Found $(wc -l < "$cache_file" | tr -d ' ') markdown files"
  fi

  local total
  total=$(wc -l < "$cache_file" | tr -d ' ')
  echo "Downloading $total pages (max $MAX_PARALLEL parallel)..."

  mkdir -p "$out_dir"

  download_page() {
    local md_url="$1"
    local rel_path="${md_url#$strip_prefix}"
    local out_file="$out_dir/$rel_path"

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
  export out_dir strip_prefix FAILED_LOG

  cat "$cache_file" | xargs -P "$MAX_PARALLEL" -I {} bash -c 'download_page "$@"' _ {}

  # Download llms-full.txt
  echo ""
  echo "Downloading llms-full.txt..."
  if curl -sL -o "$out_dir/llms-full.txt" "$base_url/llms-full.txt" && [[ -s "$out_dir/llms-full.txt" ]]; then
    local full_lines
    full_lines=$(wc -l < "$out_dir/llms-full.txt" | tr -d ' ')
    echo "OK   llms-full.txt ($full_lines lines)"
  else
    rm -f "$out_dir/llms-full.txt"
    echo "FAIL llms-full.txt"
  fi

  local failed_count=0
  if [[ -f "$FAILED_LOG" ]]; then
    failed_count=$(wc -l < "$FAILED_LOG" | tr -d ' ')
  fi

  local downloaded=$((total - failed_count))
  echo ""
  echo "Done. Downloaded $downloaded/$total $section_name pages to $out_dir/"
  if [[ "$failed_count" -gt 0 ]]; then
    echo "$failed_count failures logged to $FAILED_LOG"
  fi

  # Return counts via globals
  eval "${section_name//[ -]/_}_TOTAL=$total"
  eval "${section_name//[ -]/_}_DOWNLOADED=$downloaded"
}

> "$FAILED_LOG"

# Download API reference (225 pages)
download_section "reference" \
  "https://developers.openai.com/api/reference" \
  'https://developers\.openai\.com/api/reference/[^ )]*\.md' \
  "https://developers.openai.com/api/reference/" \
  "$SCRIPT_DIR/reference" \
  "/tmp/openai-docs-reference-urls.txt"

> "$FAILED_LOG"

# Download guides/docs (122 pages)
download_section "guides" \
  "https://developers.openai.com/api/docs" \
  'https://developers\.openai\.com/api/docs/[^ )]*\.md' \
  "https://developers.openai.com/api/docs/" \
  "$SCRIPT_DIR/guides" \
  "/tmp/openai-docs-guides-urls.txt"

# Generate README with scrape metadata
SCRAPE_DATE="$(date '+%B %-d, %Y')"
SCRAPE_SHORT="$(date '+%-m-%-d-%y')"
TOTAL_PAGES=$((reference_TOTAL + guides_TOTAL))
TOTAL_DOWNLOADED=$((reference_DOWNLOADED + guides_DOWNLOADED))

# Count pages per section for a given directory
section_table() {
  local dir="$1"
  # Top-level files
  local top_count
  top_count=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  if [[ "$top_count" -gt 0 ]]; then
    echo "| \`(top-level)\` | $top_count |"
  fi
  # Subdirectories
  for subdir in "$dir"/*/; do
    [[ -d "$subdir" ]] || continue
    local name
    name=$(basename "$subdir")
    local count
    count=$(find "$subdir" -name "*.md" | wc -l | tr -d ' ')
    echo "| \`$name/\` | $count |"
  done | sort -t'|' -k3 -rn
}

cat > "$SCRIPT_DIR/README.md" <<EOF
# OpenAI API Docs Mirror

Local mirror of the OpenAI API documentation from [developers.openai.com](https://developers.openai.com), downloaded as raw markdown via \`llms.txt\` indexes.

## Scrape Info

| | |
|---|---|
| **Last scraped** | $SCRAPE_DATE |
| **Total pages** | $TOTAL_DOWNLOADED |
| **API reference** | $reference_DOWNLOADED pages ([llms.txt](https://developers.openai.com/api/reference/llms.txt)) |
| **Guides** | $guides_DOWNLOADED pages ([llms.txt](https://developers.openai.com/api/docs/llms.txt)) |

## API Reference (\`reference/\`)

Endpoint schemas, request/response formats, and method signatures.

| Directory | Pages |
|-----------|-------|
$(section_table "$SCRIPT_DIR/reference")

## Guides (\`guides/\`)

Conceptual docs, tutorials, and how-to guides.

| Directory | Pages |
|-----------|-------|
$(section_table "$SCRIPT_DIR/guides")

## Directory Structure

\`\`\`
$(tree "$SCRIPT_DIR/reference" -d -L 2 --noreport 2>/dev/null | sed 's|'"$SCRIPT_DIR/reference"'|reference|' || find "$SCRIPT_DIR/reference" -type d -maxdepth 2 | sed "s|$SCRIPT_DIR/reference|reference|" | sort)
$(tree "$SCRIPT_DIR/guides" -d -L 2 --noreport 2>/dev/null | sed 's|'"$SCRIPT_DIR/guides"'|guides|' || find "$SCRIPT_DIR/guides" -type d -maxdepth 2 | sed "s|$SCRIPT_DIR/guides|guides|" | sort)
\`\`\`

## Usage

Search with ripgrep:

\`\`\`bash
# Search API reference
rg "chat completions" reference/
rg "embeddings" reference/resources/

# Search guides
rg "function calling" guides/
rg "structured outputs" guides/guides/
\`\`\`

Full-text search across all docs:

\`\`\`bash
rg "tool_choice" reference/llms-full.txt
rg "streaming" guides/llms-full.txt
\`\`\`

## Updating

\`\`\`bash
bash download.sh --force   # Re-fetch URL lists from llms.txt
\`\`\`

## How It Works

The OpenAI developer site publishes \`llms.txt\` indexes with direct \`.md\` URLs for every page. The download script fetches both indexes (API reference + guides), extracts all URLs, and downloads them with $MAX_PARALLEL parallel connections. Directory structure is preserved. Each section also gets a \`llms-full.txt\` (single-file concatenation) for full-text search.
EOF

echo ""
echo "=== Summary ==="
echo "Total: $TOTAL_DOWNLOADED/$TOTAL_PAGES pages"
echo "Generated README.md (scraped $SCRAPE_SHORT)"
