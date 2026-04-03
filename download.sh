#!/bin/bash
# Downloads all OpenAI developer docs as markdown from llms.txt indexes
# Auto-discovers documentation sets from the root llms.txt at developers.openai.com
# New sections added upstream are picked up automatically on next run
# Usage: ./download.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_PARALLEL=10
ROOT_URL="https://developers.openai.com"
FAILED_LOG="/tmp/openai-docs-failed.txt"
SECTIONS_META="/tmp/openai-docs-sections.txt"

# Map URL paths to local directory names for backward compat.
# Unmapped paths use the URL path segment as the directory name.
dir_for_path() {
  case "$1" in
    api/reference) echo "reference" ;;
    api/docs)      echo "guides" ;;
    *)             echo "$1" ;;
  esac
}

# --force flag is accepted for backward compat but is now a no-op
# (URL lists are always re-fetched)

# --- Generic section downloader ---
# Args: $1=label $2=base_url $3=url_regex $4=strip_prefix $5=out_dir $6=cache_file $7=local_dir
download_section() {
  local label="$1"
  local base_url="$2"
  local url_regex="$3"
  local strip_prefix="$4"
  local out_dir="$5"
  local cache_file="$6"
  local local_dir="$7"

  echo ""
  echo "=== $label ==="

  # Always re-fetch to catch new/removed pages
  echo "Fetching llms.txt index..."
  curl -sL "$base_url/llms.txt" \
    | rg -o "$url_regex" \
    | sort -u > "$cache_file"
  echo "Found $(wc -l < "$cache_file" | tr -d ' ') markdown files"

  local total
  total=$(wc -l < "$cache_file" | tr -d ' ')
  echo "Downloading $total pages (max $MAX_PARALLEL parallel)..."

  mkdir -p "$out_dir"

  > "$FAILED_LOG"

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
  echo "Done. Downloaded $downloaded/$total pages to $out_dir/"
  if [[ "$failed_count" -gt 0 ]]; then
    echo "$failed_count failures logged to $FAILED_LOG"
  fi

  # Append section metadata (pipe-delimited) for README generation
  echo "${local_dir}|${label}|${total}|${downloaded}|${base_url#$ROOT_URL/}" >> "$SECTIONS_META"
}

# --- Discover sections from root llms.txt ---

echo "Discovering documentation sets..."
ROOT_INDEX=$(curl -sL "$ROOT_URL/llms.txt")

# Extract all llms.txt index URLs (exclude llms-full.txt)
ALL_URLS=$(echo "$ROOT_INDEX" \
  | rg -o 'https://developers\.openai\.com/[^ )]+/llms\.txt' \
  | grep -v 'llms-full' \
  | sort -u)

# Convert to URL paths
ALL_PATHS=""
for url in $ALL_URLS; do
  path=$(echo "$url" | sed "s|${ROOT_URL}/||; s|/llms\.txt||")
  ALL_PATHS="$ALL_PATHS $path"
done

# Filter out parent paths whose content is covered by child indexes
# e.g. skip "api" when "api/docs" and "api/reference" exist
LEAF_PATHS=""
for path in $ALL_PATHS; do
  is_parent=false
  for other in $ALL_PATHS; do
    if [[ "$other" != "$path" ]] && [[ "$other" == "$path/"* ]]; then
      is_parent=true
      break
    fi
  done
  if [[ "$is_parent" == true ]]; then
    echo "Skipping parent index: $path/ (covered by child indexes)"
  else
    LEAF_PATHS="$LEAF_PATHS $path"
  fi
done
LEAF_PATHS="${LEAF_PATHS# }"  # trim leading space

SECTION_COUNT=$(echo "$LEAF_PATHS" | wc -w | tr -d ' ')
echo "Found $SECTION_COUNT sections: $LEAF_PATHS"

# --- Download all sections ---

> "$SECTIONS_META"

for url_path in $LEAF_PATHS; do
  local_dir=$(dir_for_path "$url_path")
  base_url="$ROOT_URL/$url_path"

  # Extract label from section's llms.txt header (first "# Title" line)
  label=$(curl -sL "$base_url/llms.txt" | head -1 | sed 's/^# //')
  [[ -z "$label" ]] && label="$local_dir"

  # Build regex for .md URLs under this path
  escaped_path=$(echo "$url_path" | sed 's/\./\\./g')
  url_regex="https://developers\\.openai\\.com/${escaped_path}/[^ )]*\\.md"
  strip_prefix="https://developers.openai.com/${url_path}/"
  cache_file="/tmp/openai-docs-${local_dir}-urls.txt"

  download_section "$label" \
    "$base_url" \
    "$url_regex" \
    "$strip_prefix" \
    "$SCRIPT_DIR/$local_dir" \
    "$cache_file" \
    "$local_dir"
done

# --- Generate README ---

SCRAPE_DATE="$(date '+%B %-d, %Y')"
GRAND_TOTAL=0
GRAND_DOWNLOADED=0
while IFS='|' read -r _d _l total downloaded _u; do
  GRAND_TOTAL=$((GRAND_TOTAL + total))
  GRAND_DOWNLOADED=$((GRAND_DOWNLOADED + downloaded))
done < "$SECTIONS_META"

section_table() {
  local dir="$1"
  local top_count
  top_count=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  if [[ "$top_count" -gt 0 ]]; then
    echo "| \`(top-level)\` | $top_count |"
  fi
  for subdir in "$dir"/*/; do
    [[ -d "$subdir" ]] || continue
    local name
    name=$(basename "$subdir")
    local count
    count=$(find "$subdir" -name "*.md" | wc -l | tr -d ' ')
    echo "| \`$name/\` | $count |"
  done | sort -t'|' -k3 -rn
}

{
  cat <<'HEADER'
# OpenAI Developer Docs Mirror

Local mirror of OpenAI developer documentation from [developers.openai.com](https://developers.openai.com), downloaded as raw markdown via `llms.txt` indexes. Sections are auto-discovered from the [root llms.txt](https://developers.openai.com/llms.txt) — new sections added upstream are picked up automatically.

## Scrape Info

| | |
|---|---|
HEADER

  echo "| **Last scraped** | $SCRAPE_DATE |"
  echo "| **Total pages** | $GRAND_DOWNLOADED |"
  while IFS='|' read -r dir label total downloaded url_path; do
    echo "| **$label** | $downloaded pages ([llms.txt]($ROOT_URL/$url_path/llms.txt)) |"
  done < "$SECTIONS_META"

  while IFS='|' read -r dir label total downloaded url_path; do
    echo ""
    echo "## $label (\`$dir/\`)"
    echo ""
    echo "| Directory | Pages |"
    echo "|-----------|-------|"
    section_table "$SCRIPT_DIR/$dir"
  done < "$SECTIONS_META"

  echo ""
  echo "## Directory Structure"
  echo ""
  echo '```'
  while IFS='|' read -r dir label total downloaded url_path; do
    tree "$SCRIPT_DIR/$dir" -d -L 2 --noreport 2>/dev/null \
      | sed "s|$SCRIPT_DIR/$dir|$dir|" \
      || find "$SCRIPT_DIR/$dir" -type d -maxdepth 2 | sed "s|$SCRIPT_DIR/$dir|$dir|" | sort
  done < "$SECTIONS_META"
  echo '```'

  echo ""
  echo "## Usage"
  echo ""
  echo "Search with ripgrep:"
  echo ""
  echo '```bash'
  echo '# Search everything'
  echo 'rg "query" .'
  echo ""
  echo "# Search a specific section"
  while IFS='|' read -r dir label total downloaded url_path; do
    printf 'rg "query" %s/\n' "$dir"
  done < "$SECTIONS_META"
  echo '```'
  echo ""
  echo "Full-text search (single file per section):"
  echo ""
  echo '```bash'
  while IFS='|' read -r dir label total downloaded url_path; do
    printf 'rg "query" %s/llms-full.txt\n' "$dir"
  done < "$SECTIONS_META"
  echo '```'

  cat <<FOOTER

## Updating

\`\`\`bash
bash download.sh --force   # Re-discover and re-fetch all sections
\`\`\`

## How It Works

The OpenAI developer site publishes a root [\`llms.txt\`]($ROOT_URL/llms.txt) that links to per-section indexes. This script fetches the root index, discovers all documentation sets, filters out parent indexes (whose content is covered by child indexes), and downloads each leaf section with $MAX_PARALLEL parallel connections. Directory structure is preserved. Each section also gets a \`llms-full.txt\` for full-text search.

New sections added to the root \`llms.txt\` are picked up automatically on the next \`--force\` run.
FOOTER
} > "$SCRIPT_DIR/README.md"

echo ""
echo "=== Summary ==="
echo "Total: $GRAND_DOWNLOADED/$GRAND_TOTAL pages across $SECTION_COUNT sections"
echo "Generated README.md (scraped $(date '+%-m-%-d-%y'))"

# Write machine-readable timestamp for freshness checks
date +%Y-%m-%d > "$SCRIPT_DIR/.last-updated"
