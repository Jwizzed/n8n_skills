#!/bin/bash
# Local n8n MCP server wrapper for OpenCode
# Runs the locally installed n8n-mcp with your n8n instance credentials

export N8N_API_URL="http://localhost:5678/api/v1"
export N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzYmVjYjVjYi1kYjBkLTRmMjgtODVjMy1lODQyMzQ1YzMxYzIiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNDk3MzI1YzUtYmFmOS00NzA2LWJiNGItOWE1MzI0ZmFlNDZlIiwiaWF0IjoxNzc3NzE2NzM3fQ.1XasMP_3nh7LCYrsbngb8NACZ8ahP3c9Udwsh-EL0Dc"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/node_modules/.bin/n8n-mcp"
