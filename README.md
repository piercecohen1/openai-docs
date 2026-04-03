# OpenAI Developer Docs Mirror

Local mirror of OpenAI developer documentation from [developers.openai.com](https://developers.openai.com), downloaded as raw markdown via `llms.txt` indexes. Sections are auto-discovered from the [root llms.txt](https://developers.openai.com/llms.txt) — new sections added upstream are picked up automatically.

## Scrape Info

| | |
|---|---|
| **Last scraped** | April 3, 2026 |
| **Total pages** | 461 |
| **OpenAI API docs** | 126 pages ([llms.txt](https://developers.openai.com/api/docs/llms.txt)) |
| **OpenAI API reference** | 225 pages ([llms.txt](https://developers.openai.com/api/reference/llms.txt)) |
| **Apps SDK** | 24 pages ([llms.txt](https://developers.openai.com/apps-sdk/llms.txt)) |
| **Codex** | 71 pages ([llms.txt](https://developers.openai.com/codex/llms.txt)) |
| **Agentic Commerce** | 15 pages ([llms.txt](https://developers.openai.com/commerce/llms.txt)) |

## OpenAI API docs (`guides/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 9 |
| `guides/` | 101 |
| `actions/` | 7 |
| `assistants/` | 6 |
| `tutorials/` | 2 |
| `gpts/` | 1 |

## OpenAI API reference (`reference/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 1 |
| `resources/` | 220 |
| `responses/` | 1 |
| `realtime-beta/` | 1 |
| `chat-completions/` | 1 |
| `administration/` | 1 |

## Apps SDK (`apps-sdk/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 5 |
| `build/` | 6 |
| `deploy/` | 4 |
| `concepts/` | 4 |
| `plan/` | 3 |
| `guides/` | 2 |

## Codex (`codex/`)

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

## Agentic Commerce (`commerce/`)

| Directory | Pages |
|-----------|-------|
| `specs/` | 11 |
| `guides/` | 4 |

## Directory Structure

```
guides
|-- actions
|-- assistants
|   `-- tools
|-- gpts
|-- guides
|   `-- safety-checks
`-- tutorials
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
apps-sdk
|-- build
|-- concepts
|-- deploy
|-- guides
`-- plan
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
commerce
|-- guides
`-- specs
    |-- api
    `-- file-upload
```

## Usage

Search with ripgrep:

```bash
# Search everything
rg "query" .

# Search a specific section
rg "query" guides/
rg "query" reference/
rg "query" apps-sdk/
rg "query" codex/
rg "query" commerce/
```

Full-text search (single file per section):

```bash
rg "query" guides/llms-full.txt
rg "query" reference/llms-full.txt
rg "query" apps-sdk/llms-full.txt
rg "query" codex/llms-full.txt
rg "query" commerce/llms-full.txt
```

## Updating

```bash
bash download.sh --force   # Re-discover and re-fetch all sections
```

## How It Works

The OpenAI developer site publishes a root [`llms.txt`](https://developers.openai.com/llms.txt) that links to per-section indexes. This script fetches the root index, discovers all documentation sets, filters out parent indexes (whose content is covered by child indexes), and downloads each leaf section with 10 parallel connections. Directory structure is preserved. Each section also gets a `llms-full.txt` for full-text search.

New sections added to the root `llms.txt` are picked up automatically on the next `--force` run.
