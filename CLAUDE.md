# OpenAI Developer Docs Mirror

Local mirror of OpenAI developer documentation from developers.openai.com, stored as raw markdown. Sections are auto-discovered from the [root llms.txt](https://developers.openai.com/llms.txt).

- `reference/` — API reference (endpoint schemas, request/response formats, method signatures)
- `guides/` — Conceptual docs, tutorials, and how-to guides
- `codex/` — Codex CLI, IDE extension, cloud, SDK, and product documentation
- `apps-sdk/` — Apps SDK for building ChatGPT apps (MCP servers, UI components, deployment)
- `commerce/` — Agentic Commerce protocol (checkout, payment, product feeds)

## How It Works

- Root `llms.txt` at developers.openai.com lists per-section indexes
- `download.sh` auto-discovers all sections, filters out parent indexes, downloads leaf sections
- Each section gets individual `.md` files plus a `llms-full.txt` for full-text search
- New sections added upstream are picked up automatically on next `--force` run
- Directory mapping: `api/reference` → `reference/`, `api/docs` → `guides/`, others use URL path as-is

## Re-scraping

```bash
bash download.sh
git add -A && git commit -m "Update docs mirror $(date +%-m-%-d-%y)" && git push
```

## Searching

```bash
rg "query" .                           # Everything
rg "query" reference/                  # API reference
rg "query" guides/                     # Guides
rg "query" codex/                      # Codex
rg "query" apps-sdk/                   # Apps SDK
rg "query" commerce/                   # Commerce
rg "query" reference/llms-full.txt     # Full-text reference
rg "query" guides/llms-full.txt        # Full-text guides
rg "query" codex/llms-full.txt         # Full-text codex
rg "query" apps-sdk/llms-full.txt      # Full-text apps-sdk
rg "query" commerce/llms-full.txt      # Full-text commerce
```
