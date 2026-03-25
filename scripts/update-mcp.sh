#!/usr/bin/env bash
# Hot-reload the Node MCP after code changes.
# Run from anywhere — resolves script dir automatically.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR/mcp"
npm run build
# Claude Code restarts MCP subprocesses on-demand when a tool call finds the process gone.
# Rebuilding dist/index.js does NOT terminate the running process automatically.
# Kill the running MCP process so the new binary is picked up on the next tool call:
pkill -f 'node.*mcp/dist/index.js' || true
echo "MCP rebuilt and old process terminated. Changes take effect on next tool call."
