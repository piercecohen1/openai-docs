# OpenAI Developer Docs Mirror

Local mirror of OpenAI developer documentation from [developers.openai.com](https://developers.openai.com), downloaded as raw markdown via `llms.txt` indexes. Sections are auto-discovered from the [root llms.txt](https://developers.openai.com/llms.txt) — new sections added upstream are picked up automatically.

## Scrape Info

| | |
|---|---|
| **Last scraped** | July 6, 2026 |
| **Total pages** | 533 |
| **Ads** | 15 pages ([llms.txt](https://developers.openai.com/ads/llms.txt)) |
| **OpenAI API docs** | 154 pages ([llms.txt](https://developers.openai.com/api/docs/llms.txt)) |
| **OpenAI API reference** | 226 pages ([llms.txt](https://developers.openai.com/api/reference/llms.txt)) |
| **Apps SDK** | 26 pages ([llms.txt](https://developers.openai.com/apps-sdk/llms.txt)) |
| **Codex** | 95 pages ([llms.txt](https://developers.openai.com/codex/llms.txt)) |
| **Agentic Commerce** | 15 pages ([llms.txt](https://developers.openai.com/commerce/llms.txt)) |
| **Workspace Agents** | 2 pages ([llms.txt](https://developers.openai.com/workspace-agents/llms.txt)) |

## Ads (`ads/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 8 |
| `api-reference/` | 7 |

## OpenAI API docs (`guides/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 9 |
| `guides/` | 129 |
| `actions/` | 7 |
| `assistants/` | 6 |
| `tutorials/` | 2 |
| `libraries/` | 1 |
| `gpts/` | 1 |

## OpenAI API reference (`reference/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 2 |
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
| `guides/` | 4 |
| `deploy/` | 4 |
| `concepts/` | 4 |
| `plan/` | 3 |

## Codex (`codex/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 46 |
| `app/` | 12 |
| `security/` | 11 |
| `concepts/` | 5 |
| `ide/` | 4 |
| `enterprise/` | 4 |
| `integrations/` | 3 |
| `guides/` | 3 |
| `cli/` | 3 |
| `cloud/` | 2 |
| `plugins/` | 1 |
| `memories/` | 1 |
| `learn/` | 1 |
| `community/` | 1 |

## Agentic Commerce (`commerce/`)

| Directory | Pages |
|-----------|-------|
| `specs/` | 11 |
| `guides/` | 4 |

## Workspace Agents (`workspace-agents/`)

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 2 |

## Directory Structure

```
ads
└── api-reference
guides
├── actions
├── assistants
│   └── tools
├── gpts
├── guides
│   ├── agent-builder
│   ├── agents
│   ├── prompting
│   ├── safety-checks
│   └── workload-identity-federation
├── libraries
└── tutorials
reference
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
apps-sdk
├── build
├── concepts
├── deploy
├── guides
└── plan
codex
├── app
├── cli
├── cloud
├── community
├── concepts
│   └── sandboxing
├── enterprise
├── guides
├── ide
├── integrations
├── learn
├── memories
├── plugins
└── security
    └── plugin
commerce
├── guides
└── specs
    ├── api
    └── file-upload
workspace-agents
```

## Usage

Search with ripgrep:

```bash
# Search everything
rg "query" .

# Search a specific section
rg "query" ads/
rg "query" guides/
rg "query" reference/
rg "query" apps-sdk/
rg "query" codex/
rg "query" commerce/
rg "query" workspace-agents/
```

Full-text search (single file per section):

```bash
rg "query" ads/llms-full.txt
rg "query" guides/llms-full.txt
rg "query" reference/llms-full.txt
rg "query" apps-sdk/llms-full.txt
rg "query" codex/llms-full.txt
rg "query" commerce/llms-full.txt
rg "query" workspace-agents/llms-full.txt
```

## Updating

```bash
bash download.sh --force   # Re-discover and re-fetch all sections
```

## How It Works

The OpenAI developer site publishes a root [`llms.txt`](https://developers.openai.com/llms.txt) that links to per-section indexes. This script fetches the root index, discovers all documentation sets, filters out parent indexes (whose content is covered by child indexes), and downloads each leaf section with 10 parallel connections. Directory structure is preserved. Each section also gets a `llms-full.txt` for full-text search.

New sections added to the root `llms.txt` are picked up automatically on the next `--force` run.
