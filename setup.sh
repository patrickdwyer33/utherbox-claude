#!/usr/bin/env bash
# utherbox-claude/setup.sh
# Runs as the claude user via cloud-init (runuser -l claude -c "bash .../setup.sh").
# Prerequisites (handled by cloud-init's setup-privileged.sh before this runs):
#   - claude user + home directory created
#   - ~/.utherbox-credentials.json written (platform_api_token + platform_api_base_url)
#   - ~/.ssh/id_ed25519 written (project private key, mode 600)
#   - ~/.ssh/authorized_keys written
#   - ~/.claude/.credentials.json written if Claude OAuth credentials were provided
#   - /home/claude/.utherbox-config written (VM_NAME=<hostname>)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 1. Install Claude Code
# ---------------------------------------------------------------------------
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.profile 2>/dev/null \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
curl -fsSL https://claude.ai/install.sh | bash

# ---------------------------------------------------------------------------
# 2. Pre-accept workspace trust for /home/claude
# ---------------------------------------------------------------------------
# Run claude once to initialize ~/.claude.json, then patch trust flag.
# Note: trust is scoped per directory; /home/claude covers the default working
# directory. --dangerously-skip-permissions is not needed for MCP startup.
claude --dangerously-skip-permissions --print "ok" 2>/dev/null || true
if [ -f ~/.claude.json ]; then
  jq '.projects //= {} | .projects["/home/claude"] //= {} | .projects["/home/claude"].hasTrustDialogAccepted = true' \
    ~/.claude.json > /tmp/claude-trust.json && mv /tmp/claude-trust.json ~/.claude.json
fi

# ---------------------------------------------------------------------------
# 3. Install Node 20+ via NodeSource (distro nodejs is typically v12)
# ---------------------------------------------------------------------------
if ! node --version 2>/dev/null | grep -qE '^v(2[0-9]|[3-9][0-9])'; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# ---------------------------------------------------------------------------
# 4. Build the Node MCP
# ---------------------------------------------------------------------------
cd "$SCRIPT_DIR/mcp"
npm ci
npm run build
cd "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# 5. Configure MCP server in ~/.claude.json (merge, do not clobber)
# ---------------------------------------------------------------------------
# Uses /usr/bin/node (absolute path) — avoids PATH resolution issues when
# Claude Code spawns the MCP as a subprocess.
node - << JSEOF
const fs = require('fs');
const path = process.env.HOME + '/.claude.json';
const settings = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, 'utf8')) : {};
settings.mcpServers = settings.mcpServers || {};
settings.mcpServers.utherbox = {
  command: '/usr/bin/node',
  args: ['$SCRIPT_DIR/mcp/dist/index.js']
};
fs.writeFileSync(path, JSON.stringify(settings, null, 2));
JSEOF

# ---------------------------------------------------------------------------
# 6. Install ~/CLAUDE.md
# ---------------------------------------------------------------------------
ln -sfn "$SCRIPT_DIR/UTHERBOX-CLAUDE.md" ~/CLAUDE.md

# ---------------------------------------------------------------------------
# 7. Install skills (symlink each skill dir — preserves user-created skills)
# ---------------------------------------------------------------------------
mkdir -p ~/.claude/skills
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  ln -sfn "$skill_dir" ~/.claude/skills/"$(basename "$skill_dir")"
done

# ---------------------------------------------------------------------------
# 8. Install plugins
# ---------------------------------------------------------------------------
claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
claude plugin install superpowers 2>/dev/null || true

# ---------------------------------------------------------------------------
# 9. Install hooks
# ---------------------------------------------------------------------------
if [ -d "$SCRIPT_DIR/hooks" ]; then
  mkdir -p ~/.claude/hooks
  cp "$SCRIPT_DIR/hooks/"* ~/.claude/hooks/
  chmod +x ~/.claude/hooks/*.sh
fi

# Wire UserPromptSubmit hook into ~/.claude/settings.json
node - << 'JSEOF'
const fs = require('fs');
const settingsPath = process.env.HOME + '/.claude/settings.json';
const settings = fs.existsSync(settingsPath) ? JSON.parse(fs.readFileSync(settingsPath, 'utf8')) : {};
settings.hooks = settings.hooks || {};
settings.hooks.UserPromptSubmit = settings.hooks.UserPromptSubmit || [];
const cmd = process.env.HOME + '/.claude/hooks/list-vms.sh';
const already = settings.hooks.UserPromptSubmit.some(
  e => e.hooks && e.hooks.some(h => h.command === cmd)
);
if (!already) {
  settings.hooks.UserPromptSubmit.push({ matcher: '', hooks: [{ type: 'command', command: cmd }] });
}
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
JSEOF

# ---------------------------------------------------------------------------
# 10. Install and start systemd service
# ---------------------------------------------------------------------------
sudo cp "$SCRIPT_DIR/utherbox-remote-session.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now utherbox-remote-session

echo "utherbox-claude setup complete"
