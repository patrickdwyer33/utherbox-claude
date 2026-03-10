#!/usr/bin/env bash
# utherbox-claude/setup.sh
# Runs as the claude user via cloud-init (su - claude -c "bash .../setup.sh").
# Prerequisites (handled by cloud-init's setup-privileged.sh, which runs first):
#   - claude user and home directory created
#   - toolserver added to claude group (for dns-mcp chgrp of TLS keys)
#   - MCP binaries installed at /usr/local/bin/vm-mcp and /usr/local/bin/dns-mcp
set -euo pipefail

# su - sets working directory to $HOME (/home/claude), not the repo root.
# Use SCRIPT_DIR for all repo-relative paths.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 1. Install Claude Code natively
# ---------------------------------------------------------------------------
# Installs standalone binary to ~/.local/bin/claude. Never run as root.
curl -fsSL https://claude.ai/install.sh | bash

# ---------------------------------------------------------------------------
# 2. Create Claude config directory and write MCP server configuration
# ---------------------------------------------------------------------------
mkdir -p ~/.claude

cat > ~/.claude/settings.json << 'EOF'
{
  "mcpServers": {
    "vm-networking": {
      "command": "/usr/local/bin/vm-mcp",
      "args": []
    },
    "dns-acmecert": {
      "command": "/usr/local/bin/dns-mcp",
      "args": []
    }
  }
}
EOF

# ---------------------------------------------------------------------------
# 3. Install standalone skills
# ---------------------------------------------------------------------------
# Skills in ~/.claude/skills/<name>/SKILL.md are auto-loaded by Claude Code.
# Use SCRIPT_DIR (not a relative path) — working dir is $HOME, not the repo root.
if [ -d "$SCRIPT_DIR/skills" ]; then
  mkdir -p ~/.claude/skills
  cp -r "$SCRIPT_DIR/skills/." ~/.claude/skills/
fi

# ---------------------------------------------------------------------------
# 4. Plugins — placeholder
# ---------------------------------------------------------------------------
# (reserved for future plugin installation)

echo "utherbox-claude setup complete"
