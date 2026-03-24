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
# Ensure ~/.local/bin is on PATH for this session and future logins.
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Installs standalone binary to ~/.local/bin/claude. Never run as root.
curl -fsSL https://claude.ai/install.sh | bash

# Pre-accept workspace trust so remote-control can start non-interactively.
# Runs once here; subsequent invocations (including remote-control) skip the prompt.
claude --dangerously-skip-permissions --print "ok" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 2. Write MCP server configuration
# ---------------------------------------------------------------------------
# Claude Code reads global MCP servers from ~/.claude.json, not ~/.claude/settings.json.
mkdir -p ~/.claude

cat > ~/.claude.json << 'EOF'
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
# 4. Install hooks
# ---------------------------------------------------------------------------
if [ -d "$SCRIPT_DIR/hooks" ]; then
  mkdir -p ~/.claude/hooks
  cp "$SCRIPT_DIR/hooks/"* ~/.claude/hooks/
  chmod +x ~/.claude/hooks/*.sh
fi

# Wire UserPromptSubmit hook into Claude Code settings
node - << 'JSEOF'
const fs = require('fs');
const settingsPath = process.env.HOME + '/.claude/settings.json';
const settings = fs.existsSync(settingsPath) ? JSON.parse(fs.readFileSync(settingsPath, 'utf8')) : {};
settings.hooks = settings.hooks || {};
settings.hooks.UserPromptSubmit = settings.hooks.UserPromptSubmit || [];
const cmd = process.env.HOME + '/.claude/hooks/list-vms.sh';
// New format: each entry is { matcher: string, hooks: [{type, command}] }
const already = settings.hooks.UserPromptSubmit.some(e => e.hooks && e.hooks.some(h => h.command === cmd));
if (!already) settings.hooks.UserPromptSubmit.push({ matcher: '', hooks: [{ type: 'command', command: cmd }] });
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
JSEOF

echo "utherbox-claude setup complete"
