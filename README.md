# n8n Workflow Automation Project

> **n8n version**: `1.90.x` (local instance at `http://localhost:5678`)  
> **MCP Bridge**: `n8n-mcp@2.47.14` via OpenCode agent  
> **Environment**: macOS, local n8n instance, OpenCode IDE with MCP tools

---

## What This Repo Is

This is an **AI-assisted n8n workflow engineering workspace**. It contains:

1. **Live workflow definitions** — JSON exports and markdown specs for n8n automations running on your local n8n instance
2. **Custom n8n skill files** — Enhanced documentation for the OpenCode agent to build, validate, and fix n8n workflows faster
3. **MCP configuration** — Connection bridge between OpenCode and your local n8n instance via the Model Context Protocol
4. **Agent instructions** — `AGENT.md` with hard-won configuration patterns specific to this n8n version

The core workflow built here is **"The Krit.Tech Content Factory"** — a deterministic pipeline that transforms a single topic seed into a complete TikTok script via Perplexity research, Gemini writing, and Google Drive asset management.

---

## Architecture Overview

```
OpenCode Agent
    |
    |--(MCP)--> n8n-mcp@2.47.14
                    |
                    |--(HTTP)--> n8n@1.90.x (localhost:5678)
```

### Key Workflows

| Workflow | ID | Description |
|----------|-----|-------------|
| **The Krit.Tech Content Factory** | `E3UyxNFMnTGwgZC5` | TikTok script generation pipeline |

### Pipeline Stages

```
Form Input (Pillar + Topic)
  → Deduplication Check (Google Sheets)
    → Mindset Injector (Code Node)
      → Perplexity API (Research)
        → Extract Media + Drive Upload (Assets)
          → Switch Routing (by Pillar)
            → Gemini Writer (3 isolated personas)
              → Production Queue (Google Sheets)
```

---

## Setup

### Prerequisites

- **n8n** running locally on `http://localhost:5678`
- **OpenCode** IDE with MCP support
- **Node.js** for the MCP bridge

### Installation

```bash
# 1. Install MCP bridge
npm install

# 2. Configure your n8n API key in mcp.json (or n8n-mcp-local.sh)
# The API key is already set in the shell script

# 3. Make the launcher executable
chmod +x n8n-mcp-local.sh
```

### Connecting OpenCode

The `mcp.json` file configures OpenCode to use the local MCP bridge:

```json
{
  "mcpServers": {
    "n8n": {
      "command": "/Users/krittinsetdhavanich/Documents/n8n/n8n-mcp-local.sh",
      "args": [],
      "env": {
        "N8N_API_URL": "http://localhost:5678/api/v1",
        "N8N_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

**To regenerate the API key**:
1. Open n8n UI → Settings → n8n API
2. Create a new API key
3. Update `n8n-mcp-local.sh` and `mcp.json`

---

## Project Structure

```
.
├── AGENT.md                              # OpenCode agent instructions (updated)
├── README.md                             # This file
├── TikTok Growth Strategy 2026.md        # System architecture specification
├── TikTok Growth Strategy 2026.json      # Reference workflow export (may be outdated)
├── format.md                             # Generic n8n JSON schema template
├── mcp.json                              # OpenCode MCP server configuration
├── n8n-mcp-local.sh                      # MCP bridge launcher script
├── package.json                          # n8n-mcp dependency
└── skills/                               # Enhanced n8n skill documentation
    ├── n8n-code-javascript/
    ├── n8n-code-python/
    ├── n8n-expression-syntax/
    ├── n8n-mcp-tools-expert/
    ├── n8n-node-configuration/           # UPDATED with Google Sheets/Drive/API patterns
    ├── n8n-validation-expert/            # UPDATED with 5 new real-world errors
    └── n8n-workflow-patterns/            # UPDATED + new Content Factory pattern
```

---

## What We Modified (vs. Stock n8n Skills)

The `skills/` directory started as standard n8n skill files. We enhanced them with **real-world error patterns and configuration recipes** discovered while building the Content Factory workflow:

### 1. `skills/n8n-validation-expert/ERROR_CATALOG.md`

**Added 5 new error entries** not covered in the stock catalog:

| # | Error | Root Cause | Fix |
|---|-------|------------|-----|
| 10 | `"Range is required for read operation"` | Google Sheets `read` + `filtersUI` still needs top-level `range` field | Add `"range": "A:Z"` at parameters top level |
| 11 | `"Invalid operation 'folderCreate'"` | Google Drive has no `folderCreate` operation | Use `"resource": "folder"` + `"operation": "create"` |
| 12 | `"Mixed literal text and expression requires = prefix"` | String fields with both text + `{{}}` must start with `=` | Prefix with `=` e.g., `"=Research: {{...}}"` |
| 13 | `"Invalid type 'exists'"` (IF node) | `operator.type` must be a data type, not operation name | Use `"type": "string"`, `"operation": "notEquals"` |
| 14 | `"Unary operator requires singleValue: true"` | IF v2 unary ops need explicit `singleValue` | Let auto-sanitization handle it on save |

### 2. `skills/n8n-node-configuration/SKILL.md`

**Added 4 new configuration pattern sections**:

- **Google Sheets — Read with Filters**: Exact JSON for deduplication/lookup pattern with `range` + `filtersUI`
- **Google Drive — Create Folder + Upload**: Resource/operation pattern for folder creation and binary uploads
- **HTTP Request — POST JSON to API**: Body format for Perplexity/Gemini/OpenAI with `contentType: "json"`
- **Switch Node v2 — Multi-Route Routing**: Rules wiring and connections map explanation

### 3. `skills/n8n-workflow-patterns/` (NEW + UPDATED)

**New file**: `content_factory_pipeline.md`
- Complete architectural pattern for research-to-content pipelines
- All 16 nodes documented with exact parameters
- Connections map, 4 variations, 5 common pitfalls

**Updated**: `SKILL.md`
- Added Content Factory Pipeline as the **7th core pattern**
- Linked to new pattern file

### 4. `AGENT.md` (MAJOR UPDATE)

Rewrote with:
- **"Building from Specification Documents"** section — how to read `.md` specs + `.json` references together
- **"Critical Configuration Patterns"** — 5 hard-won lessons with exact JSON
- Known reference files in this project
- Expectation of 2-5 validation iterations

---

## n8n Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| **n8n Instance** | `1.90.x` | Local docker/desktop install |
| **n8n-mcp** | `2.47.14` | MCP bridge package |
| **Node Type Versions Used** | | |
| `formTrigger` | `2.1` | Form input with dropdown |
| `googleSheets` | `4.5` | Read with filters, append rows |
| `googleDrive` | `3` | Folder create, file upload |
| `if` | `2` | Conditions v2 structure |
| `switch` | `2` | Multi-route routing |
| `httpRequest` | `4.2` | POST JSON, binary download |
| `code` | `2` | JS for persona injection, media extraction |
| `splitInBatches` | `3` | Batch processing |

**Warning**: Older `.json` exports (like `TikTok Growth Strategy 2026.json`) may contain **outdated node configurations**. Always validate against the live workflow or the updated skill files before reuse.

---

## Usage

### Working with OpenCode

1. **Start n8n**: Ensure `http://localhost:5678` is running
2. **Open OpenCode**: The MCP tools should auto-connect via `mcp.json`
3. **Give OpenCode a workflow URL**: 
   - Example: `http://localhost:5678/workflow/E3UyxNFMnTGwgZC5`
   - OpenCode will extract the ID (`E3UyxNFMnTGwgZC5`) and fetch the live workflow
4. **Reference specs**: Point OpenCode to `.md` files for architecture requirements

### Common Commands

```bash
# Test MCP connection
./n8n-mcp-local.sh

# Check n8n health (via OpenCode)
n8n_n8n_health_check

# List workflows (via OpenCode)
n8n_n8n_list_workflows
```

---

## Credentials Required

The Content Factory workflow needs these credentials configured in n8n UI:

| Service | Credential Type | Used In |
|---------|----------------|---------|
| **Google Sheets** | OAuth2 or Service Account | Deduplication Check, Production Queue |
| **Google Drive** | OAuth2 or Service Account | Drive Create Folder, Drive Upload File |
| **Perplexity API** | HTTP Header Auth (`Authorization: Bearer <key>`) | Perplexity API node |
| **Gemini API** | Google API or Query Param Key | Gemini Curiosity, LowLevel, Brutalist |

---

## Troubleshooting

### MCP Connection Fails

```bash
# Check if n8n is running
curl http://localhost:5678/api/v1/workflows \
  -H "X-N8N-API-KEY: your-key-here"

# Restart MCP in OpenCode
# Cmd+Shift+P -> "MCP: Restart Server"
```

### Validation Errors

1. Run `n8n_validate_workflow` on your workflow JSON
2. Check `skills/n8n-validation-expert/ERROR_CATALOG.md` for the exact error
3. Fix iteratively — expect 2-5 cycles for complex workflows

### Outdated Node Configurations

If importing from `TikTok Growth Strategy 2026.json`:
1. Compare with live workflow via `n8n_get_workflow`
2. Check `skills/n8n-node-configuration/SKILL.md` for current patterns
3. Run `n8n_autofix_workflow` for auto-migration

---

## License

ISC (per `package.json`)

---

## Changelog

### 2026-05-05
- **Built** The Krit.Tech Content Factory workflow (16 nodes)
- **Updated** AGENT.md with configuration patterns and spec-file handling
- **Updated** n8n-validation-expert/ERROR_CATALOG.md with 5 real-world errors
- **Updated** n8n-node-configuration/SKILL.md with Google Sheets/Drive/API patterns
- **Created** n8n-workflow-patterns/content_factory_pipeline.md (new pattern)
- **Updated** n8n-workflow-patterns/SKILL.md with 7th core pattern

---

**Maintained by**: OpenCode agent + human-in-the-loop  
**Last updated**: 2026-05-05
