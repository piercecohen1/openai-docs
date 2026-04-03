# OpenAI API Docs Mirror

Local mirror of the OpenAI API documentation from [developers.openai.com](https://developers.openai.com), downloaded as raw markdown via `llms.txt` indexes.

## Scrape Info

| | |
|---|---|
| **Last scraped** | April 3, 2026 |
| **Total pages** | 422 |
| **API reference** | 225 pages ([llms.txt](https://developers.openai.com/api/reference/llms.txt)) |
| **Guides** | 126 pages ([llms.txt](https://developers.openai.com/api/docs/llms.txt)) |
| **Codex** | 71 pages ([llms.txt](https://developers.openai.com/codex/llms.txt)) |

## API Reference (`reference/`)

Endpoint schemas, request/response formats, and method signatures.

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 1 |
| `resources/` | 220 |
| `responses/` | 1 |
| `realtime-beta/` | 1 |
| `chat-completions/` | 1 |
| `administration/` | 1 |

## Guides (`guides/`)

Conceptual docs, tutorials, and how-to guides.

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 9 |
| `guides/` | 101 |
| `actions/` | 7 |
| `assistants/` | 6 |
| `tutorials/` | 2 |
| `gpts/` | 1 |

## Codex (`codex/`)

Codex CLI, IDE extension, cloud, SDK, and product documentation.

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 34 |
| `app/` | 9 |
| `ide/` | 4 |
| `concepts/` | 4 |
| `security/` | 3 |
| `integrations/` | 3 |
| `guides/` | 3 |
| `enterprise/` | 3 |
| `cli/` | 3 |
| `cloud/` | 2 |
| `plugins/` | 1 |
| `learn/` | 1 |
| `community/` | 1 |

## Directory Structure

```
reference
|-- administration
|-- chat-completions
|-- realtime-beta
|-- resources
|   |-- audio
|   |-- batches
|   |-- beta
|   |-- chat
|   |-- completions
|   |-- containers
|   |-- conversations
|   |-- embeddings
|   |-- evals
|   |-- files
|   |-- fine_tuning
|   |-- images
|   |-- models
|   |-- moderations
|   |-- organization
|   |-- projects
|   |-- realtime
|   |-- responses
|   |-- uploads
|   |-- vector_stores
|   |-- videos
|   `-- webhooks
`-- responses
guides
|-- actions
|-- assistants
|   `-- tools
|-- gpts
|-- guides
|   `-- safety-checks
`-- tutorials
codex
|-- app
|-- cli
|-- cloud
|-- community
|-- concepts
|-- enterprise
|-- guides
|-- ide
|-- integrations
|-- learn
|-- plugins
`-- security
```

## Usage

Search with ripgrep:

```bash
# Search API reference
rg "chat completions" reference/
rg "embeddings" reference/resources/

# Search guides
rg "function calling" guides/
rg "structured outputs" guides/guides/
```

Full-text search across all docs:

```bash
rg "tool_choice" reference/llms-full.txt
rg "streaming" guides/llms-full.txt
```

## Updating

```bash
bash download.sh --force   # Re-fetch URL lists from llms.txt
```

## How It Works

The OpenAI developer site publishes `llms.txt` indexes with direct `.md` URLs for every page. The download script fetches all three indexes (API reference, guides, and Codex), extracts all URLs, and downloads them with 10 parallel connections. Directory structure is preserved. Each section also gets a `llms-full.txt` (single-file concatenation) for full-text search.
