# n8n Workflow Format Template (JSON Schema)

Use this document as a format template. Replace values with concrete workflow data while preserving the schema.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "n8n Workflow Format Template",
  "type": "object",
  "required": ["name", "nodes", "connections"],
  "properties": {
    "name": { "type": "string", "description": "Workflow display name" },
    "nodes": {
      "type": "array",
      "description": "Array of node objects",
      "items": {
        "type": "object",
        "required": ["id", "name", "type", "typeVersion", "parameters", "position"],
        "properties": {
          "id": { "type": "string" },
          "name": { "type": "string" },
          "type": { "type": "string", "description": "n8n node type identifier" },
          "typeVersion": { "type": "integer" },
          "parameters": { "type": "object", "description": "Node-specific configuration" },
          "position": { "type": "array", "items": { "type": "number" }, "minItems": 2, "maxItems": 2 }
        },
        "additionalProperties": true
      }
    },
    "connections": {
      "type": "object",
      "description": "Mapping of node names to connection objects",
      "additionalProperties": {
        "type": "object"
      }
    }
  },
  "additionalProperties": false
}
```

Notes:
- Keep `nodes` as an array of node objects following the required properties.
- `connections` should map node names (as keys) to their `main` arrays describing target nodes.
- Add custom node `parameters` as needed but preserve the top-level keys.

Saved as a reusable template for new workflows.
