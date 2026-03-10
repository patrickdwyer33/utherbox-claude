#!/usr/bin/env bash
# utherbox-claude/setup.sh
# Runs as root via cloud-init on each new project VM, after utherbox-toolserver/setup.sh.
# Creates the claude user, installs Claude Code natively, and configures MCP servers + skills.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 1. Create claude system user
# ---------------------------------------------------------------------------
if ! id -u claude &>/dev/null; then
  useradd --system \
          --shell /bin/bash \
          --home-dir /home/claude \
          --create-home \
          claude
fi

# ---------------------------------------------------------------------------
# 2. Add toolserver to claude group so dns-mcp can chgrp TLS private keys
# ---------------------------------------------------------------------------
# dns-mcp runs as toolserver (setuid). For it to set key.pem group to claude
# (mode 0640), toolserver must be a member of the claude group.
if id -u toolserver &>/dev/null; then
  usermod -aG claude toolserver
fi

# ---------------------------------------------------------------------------
# 3. Install Claude Code natively as the claude user
# ---------------------------------------------------------------------------
# Installs standalone binary to ~claude/.local/bin/claude. Never run as root.
su -c "curl -fsSL https://claude.ai/install.sh | bash" claude

# ---------------------------------------------------------------------------
# 4. Create Claude config directory
# ---------------------------------------------------------------------------
mkdir -p /home/claude/.claude

# ---------------------------------------------------------------------------
# 5. Write MCP server configuration
# ---------------------------------------------------------------------------
cat > /home/claude/.claude/settings.json << 'EOF'
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
# 6. Install standalone skills
# ---------------------------------------------------------------------------
# Skills in ~/.claude/skills/<name>/SKILL.md are auto-loaded by Claude Code.
if [ -d "$SCRIPT_DIR/skills" ]; then
  mkdir -p /home/claude/.claude/skills
  cp -r "$SCRIPT_DIR/skills/." /home/claude/.claude/skills/
fi

# ---------------------------------------------------------------------------
# 7. Plugins — placeholder
# ---------------------------------------------------------------------------
# (reserved for future plugin installation)

# ---------------------------------------------------------------------------
# 8. Set ownership
# ---------------------------------------------------------------------------
chown -R claude:claude /home/claude

echo "utherbox-claude setup complete"
