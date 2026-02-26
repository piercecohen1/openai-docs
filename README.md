# OpenAI API Docs Mirror

Local mirror of the OpenAI API reference documentation from [developers.openai.com](https://developers.openai.com/api/reference), downloaded as raw markdown via the `llms.txt` index.

## Scrape Info

| | |
|---|---|
| **Last scraped** | February 26, 2026 |
| **Pages downloaded** | 225 |
| **Source** | [developers.openai.com/api/reference/llms.txt](https://developers.openai.com/api/reference/llms.txt) |

## Sections

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 1 |
| `resources/` | 220 |
| `responses/` | 1 |
| `realtime-beta/` | 1 |
| `chat-completions/` | 1 |
| `administration/` | 1 |

## Directory Structure

```
docs
├── administration
├── chat-completions
├── realtime-beta
├── resources
│   ├── audio
│   ├── batches
│   ├── beta
│   ├── chat
│   ├── completions
│   ├── containers
│   ├── conversations
│   ├── embeddings
│   ├── evals
│   ├── files
│   ├── fine_tuning
│   ├── images
│   ├── models
│   ├── moderations
│   ├── organization
│   ├── projects
│   ├── realtime
│   ├── responses
│   ├── uploads
│   ├── vector_stores
│   ├── videos
│   └── webhooks
└── responses
```

## Usage

Search with ripgrep:

```bash
rg "chat completions" docs/
rg "embeddings" docs/resources/
rg "fine-tuning" docs/resources/
```

Full-text search across the entire API reference:

```bash
rg "function calling" docs/llms-full.txt
```

## Updating

```bash
cd /Users/piercecohen/claude-code/openai-docs
bash download.sh --force   # Re-fetch URL list from llms.txt
```

## How It Works

The OpenAI API reference site publishes an index at `llms.txt` with direct `.md` URLs for every page. The download script fetches this index, extracts all URLs, and downloads them with 10 parallel connections. Directory structure is preserved (files nested up to 7 levels deep under `resources/`). Additionally, `llms-full.txt` (a single-file concatenation of all docs) is downloaded for full-text search.
