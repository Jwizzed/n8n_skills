# Content Factory Pipeline Pattern

**Use Case**: Deterministic, high-fidelity content production pipeline that transforms a single input keyword/topic into a complete, researched, and structured piece of content while managing all supporting assets.

**Real-world example**: The Krit.Tech Content Factory — generates TikTok scripts via Perplexity research + Gemini writing + Google Drive asset management.

---

## Pattern Structure

```
Input (Form Trigger)
  → Deduplication Gate (Sheet Lookup + IF)
    → Research Core (Code Persona + Perplexity API)
      → Asset Manager (Extract Media + Drive Folder + Batch Download/Upload)
        → Intelligence Switch (Switch Node)
          → Specialized Writers (Isolated LLM Nodes per Pillar)
            → Output Ledger (Sheet Append)
```

**Key Characteristics**:
- **Deterministic**: Same input always follows the same path
- **Pillar-based routing**: Content switches to different writing personalities
- **Asset-aware**: Downloads reference media and stores in dated Drive folders
- **Deduplication**: Prevents redundant content generation

---

## Core Components

### 1. Input & Logic Gate (Validation)

**Trigger**: n8n Form Trigger with dropdown + optional string

```javascript
{
  "type": "n8n-nodes-base.formTrigger",
  "typeVersion": 2.1,
  "parameters": {
    "formTitle": "Content Input",
    "formFields": {
      "values": [
        {
          "fieldLabel": "Pillar",
          "fieldType": "dropdown",
          "requiredField": true,
          "fieldOptions": {
            "values": [
              { "option": "Curiosity Detour" },
              { "option": "Low-Level Insight" },
              { "option": "Brutalist Review" }
            ]
          }
        },
        {
          "fieldLabel": "Topic_Seed",
          "fieldType": "string",
          "requiredField": false
        }
      ]
    }
  }
}
```

**Deduplication Engine**: Google Sheets read with filter

```javascript
{
  "type": "n8n-nodes-base.googleSheets",
  "parameters": {
    "resource": "sheet",
    "operation": "read",
    "range": "A:Z",                                    // REQUIRED
    "filtersUI": {
      "values": [
        { "lookupColumn": "Topic", "lookupValue": "={{ $json.Topic_Seed }}" }
      ]
    },
    "combineFilters": "AND",
    "returnFirstMatch": true
  }
}
```

**IF Duplicate Check**: Routes to termination (true branch) or continues (false branch)

```javascript
{
  "type": "n8n-nodes-base.if",
  "parameters": {
    "conditions": {
      "conditions": [
        {
          "leftValue": "={{ $json.Topic }}",
          "rightValue": "",
          "operator": { "type": "string", "operation": "notEquals" }
        }
      ],
      "combinator": "and"
    }
  }
}
```

- **Branch 0 (true)**: Topic exists → `noOp` Terminate Duplicate
- **Branch 1 (false)**: Topic not found → Continue to Mindset Injector

---

### 2. Dynamic Research Core (Arbitrage)

**Mindset Injector** (Code Node): Converts dropdown choice into a research persona

```javascript
const pillar = $input.first().json.Pillar;
const seed = $input.first().json.Topic_Seed || 'default topic';
let mindset = '';

if (pillar === 'Curiosity Detour') {
  mindset = `Analyze: "${seed}". Search for debates, hidden inefficiencies, and 'Manual Debt'.`;
} else if (pillar === 'Low-Level Insight') {
  mindset = `Analyze: "${seed}". Search for deep technical documentation and architectural mechanics.`;
} else if (pillar === 'Brutalist Review') {
  mindset = `Analyze: "${seed}". Search for technical limitations, self-hosting requirements, Docker setups.`;
}

return [{
  json: { topic: seed, pillar: pillar, perplexity_prompt: mindset }
}];
```

**Perplexity API** (HTTP Request): Executes research with citations

```javascript
{
  "method": "POST",
  "url": "https://api.perplexity.ai/chat/completions",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "sendBody": true,
  "contentType": "json",
  "body": {
    "model": "sonar-reasoning",
    "messages": [
      { "role": "system", "content": "You are a technical research assistant. Provide cited facts and include reference URLs for images, diagrams, and media." },
      { "role": "user", "content": "={{ $('Mindset Injector').item.json.perplexity_prompt }}" }
    ],
    "max_tokens": 2000,
    "temperature": 0.2
  }
}
```

---

### 3. Automated Asset Manager

**Extract Media** (Code Node): Parses citations and content for media URLs

```javascript
const response = $input.first().json;
const citations = response.citations || [];
const content = response.choices?.[0]?.message?.content || '';

// Extract image URLs from content
const urlRegex = /https?:\/\/[^\s\"<>]+\.(?:png|jpg|jpeg|gif|webp|svg)/gi;
const contentUrls = content.match(urlRegex) || [];

// Deduplicate and filter valid URLs
const allUrls = [...new Set([...citations, ...contentUrls])]
  .filter(url => url && (url.startsWith('http://') || url.startsWith('https://')));

// Prepare downstream prompt
const topic = $('Mindset Injector').item.json.topic;
const geminiPrompt = `Research: ${content}\n\nTopic: ${topic}`;

return [{
  json: {
    research_content: content,
    media_urls: allUrls,
    gemini_prompt: geminiPrompt
  }
}];
```

**Drive Create Folder** (Google Drive): Creates dated folder

```javascript
{
  "resource": "folder",
  "operation": "create",
  "name": "={{ $now.format('yyyy-MM-dd') }} - {{ $('Mindset Injector').item.json.topic }}"
}
```

**SplitInBatches + Download + Upload Loop**:

```javascript
// SplitInBatches v3
{ "batchSize": 1, "options": {} }

// Download Media (HTTP Request)
{
  "url": "={{ $json }}",
  "options": { "response": { "response": { "neverError": true } } }
}

// Drive Upload File (Google Drive)
{
  "operation": "upload",
  "folderId": {
    "__rl": true,
    "mode": "id",
    "value": "={{ $('Drive Create Folder').first().json.id }}"
  },
  "binaryData": true,
  "binaryPropertyName": "data",
  "name": "={{ $now.format('yyyy-MM-dd') }}_{{ $binary.data.fileName || 'media' }}"
}
```

**Wiring**: Extract Media connects to BOTH Drive Create Folder AND SplitInBatches. The folder creation runs once; the download/upload loop runs per URL.

---

### 4. Specialized Intelligence Layer (The Switch)

**Switch Routing** routes by pillar:

```javascript
{
  "rules": {
    "rules": [
      { "value": "Curiosity Detour", "output": 0 },
      { "value": "Low-Level Insight", "output": 1 },
      { "value": "Brutalist Review", "output": 2 }
    ]
  },
  "dataType": "string",
  "value1": "={{ $('Mindset Injector').item.json.pillar }}"
}
```

**Three Isolated Gemini Nodes** (one per pillar):

Each Gemini node is an HTTP Request to Google Generative Language API with a **hardcoded system prompt** specific to its pillar:

```javascript
// Gemini Curiosity (output 0)
{
  "method": "POST",
  "url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent",
  "authentication": "genericCredentialType",
  "genericAuthType": "googleApi",
  "sendQuery": true,
  "queryParameters": { "parameters": [{ "name": "key", "value": "" }] },
  "sendBody": true,
  "contentType": "json",
  "body": {
    "system_instruction": {
      "parts": [{
        "text": "You are a TikTok scriptwriter for the 'Curiosity Detour' pillar. Focus on trend-debunking, polarizing hooks, and contrarian takes. Output a JSON object with: script (Thai/English mix, ~240 words), overlays (array of monospace text overlays), and hook."
      }]
    },
    "contents": [{
      "role": "user",
      "parts": [{ "text": "={{ $('Extract Media').item.json.gemini_prompt }}" }]
    }],
    "generationConfig": {
      "temperature": 0.9,
      "maxOutputTokens": 1500,
      "responseMimeType": "application/json"
    }
  }
}
```

**All three Gemini nodes converge** to the same Production Queue node.

---

### 5. Output Ledger

**Production Queue** (Google Sheets append):

```javascript
{
  "resource": "sheet",
  "operation": "append",
  "documentId": { "__rl": true, "mode": "list", "value": "" },
  "sheetName": { "__rl": true, "mode": "list", "value": "" },
  "columns": {
    "mappingMode": "defineBelow",
    "value": null
    // Map in UI: Date, Pillar, Topic, Script, Overlays, Posting_Time, Drive_Link, Status
  }
}
```

---

## Connections Map

```javascript
{
  "n8n Form Trigger": { "main": [[{ "node": "Deduplication Check", "type": "main", "index": 0 }]] },
  "Deduplication Check": { "main": [[{ "node": "If Duplicate", "type": "main", "index": 0 }]] },
  "If Duplicate": {
    "main": [
      [{ "node": "Terminate Duplicate", "type": "main", "index": 0 }],
      [{ "node": "Mindset Injector", "type": "main", "index": 0 }]
    ]
  },
  "Mindset Injector": { "main": [[{ "node": "Perplexity API", "type": "main", "index": 0 }]] },
  "Perplexity API": {
    "main": [[
      { "node": "Extract Media", "type": "main", "index": 0 },
      { "node": "Switch Routing", "type": "main", "index": 0 }
    ]]
  },
  "Extract Media": {
    "main": [[
      { "node": "Drive Create Folder", "type": "main", "index": 0 },
      { "node": "Split Media URLs", "type": "main", "index": 0 }
    ]]
  },
  "Split Media URLs": { "main": [[{ "node": "Download Media", "type": "main", "index": 0 }]] },
  "Download Media": { "main": [[{ "node": "Drive Upload File", "type": "main", "index": 0 }]] },
  "Switch Routing": {
    "main": [
      [{ "node": "Gemini Curiosity", "type": "main", "index": 0 }],
      [{ "node": "Gemini LowLevel", "type": "main", "index": 0 }],
      [{ "node": "Gemini Brutalist", "type": "main", "index": 0 }]
    ]
  },
  "Gemini Curiosity": { "main": [[{ "node": "Production Queue", "type": "main", "index": 0 }]] },
  "Gemini LowLevel": { "main": [[{ "node": "Production Queue", "type": "main", "index": 0 }]] },
  "Gemini Brutalist": { "main": [[{ "node": "Production Queue", "type": "main", "index": 0 }]] }
}
```

---

## Variations

### Variation A: Research-Only Pipeline
Skip the writer nodes. Output research content directly to Sheets/Notion for human writers.

### Variation B: Multi-Platform Output
After the Switch, add parallel branches for each platform (TikTok, LinkedIn, Blog) with different LLM nodes per platform.

### Variation C: Approval Gate
Insert a Wait node before Production Queue that sends the draft for human approval via Slack/Email. Only append to queue after approval.

### Variation D: Scheduled Generation
Replace Form Trigger with Schedule Trigger. Pre-seed topics from a Sheet and run unattended.

---

## Common Pitfalls

### 1. ❌ Google Sheets missing `range`
```javascript
// WRONG — filtersUI alone isn't enough
{ "operation": "read", "filtersUI": { ... } }

// CORRECT
{ "operation": "read", "range": "A:Z", "filtersUI": { ... } }
```

### 2. ❌ Google Drive `folderCreate`
```javascript
// WRONG
{ "operation": "folderCreate" }

// CORRECT
{ "resource": "folder", "operation": "create" }
```

### 3. ❌ Expressions without `=` prefix in mixed strings
```javascript
// WRONG
"text": "Research: {{ $json.content }}"

// CORRECT
"text": "=Research: {{ $json.content }}"
```

### 4. ❌ Switch outputs not matching connections
If you have 3 rules, you MUST have 3 `main` arrays in connections (even if some go to the same target node).

### 5. ❌ Perplexity API body format
Use `contentType: "json"` and pass the JSON object directly in `body`. Do NOT stringify or wrap in `={...}`.

---

## Validation Checklist

Before activating this workflow:
- [ ] Form Trigger has all dropdown options populated
- [ ] Google Sheets credentials configured (Deduplication + Production Queue)
- [ ] Google Drive credentials configured (Create Folder + Upload)
- [ ] Perplexity API key configured (HTTP Header Auth)
- [ ] Gemini API key configured (Google API auth or query param)
- [ ] Deduplication Sheet has a "Topic" column
- [ ] Production Queue Sheet has columns: Date, Pillar, Topic, Script, Overlays, Posting_Time, Drive_Link, Status
- [ ] All expressions validated (`n8n_validate_workflow`)
- [ ] Media download loop tested with a sample URL

---

## Related Patterns

- **[ai_agent_workflow.md](ai_agent_workflow.md)** — For non-deterministic AI agent workflows (conversational, tool-calling)
- **[webhook_processing.md](webhook_processing.md)** — If replacing Form Trigger with a custom webhook
- **[database_operations.md](database_operations.md)** — If replacing Google Sheets with Postgres/MySQL for the ledger
- **[http_api_integration.md](http_api_integration.md)** — For integrating additional research APIs

---

## Summary

**The Content Factory Pattern** is ideal when you need:
1. **Deterministic routing** based on content category/pillar
2. **Research + synthesis** in a single pipeline
3. **Asset management** (images, documents) alongside content
4. **Deduplication** to prevent redundant work
5. **Multi-persona output** from the same research input

**Key insight**: The Switch node is the architectural heart. It lets you maintain isolated, optimized prompts for each content type while sharing the same research and asset infrastructure upstream.
