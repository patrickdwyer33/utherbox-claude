#!/usr/bin/env bash
# Starts claude remote-control and registers the session URL with the platform API.
# Runs as the claude user via utherbox-remote-session.service.
set -euo pipefail

# Belt-and-suspenders: ConditionPathExists in the service file guards this too,
# but exit cleanly here so a missing credentials file never causes a crash loop.
if [ ! -f /home/claude/.claude/.credentials.json ]; then
  echo "No Claude credentials found — remote session not started"
  exit 0
fi

if [ ! -f /home/claude/.utherbox-config ]; then
  echo "Missing /home/claude/.utherbox-config — cannot determine PROJECT_ID"
  exit 1
fi

# shellcheck source=/dev/null
source /home/claude/.utherbox-config

if [ -z "${PROJECT_ID:-}" ]; then
  echo "PROJECT_ID not set in /home/claude/.utherbox-config"
  exit 1
fi

echo "Starting claude remote-control for project $PROJECT_ID"

# Claude Code writes hasTrustDialogAccepted=false when it starts non-interactively.
# Also resets cachedGrowthBookFeatures (including tengu_ccr_bridge) on every startup
# by re-fetching from GrowthBook with TTL=0. Force the flag and set a long TTL before
# each invocation so it survives at least one session.
if [ -f ~/.claude.json ]; then
  jq '
    .projects //= {}
    | .projects["/home/claude"] //= {}
    | .projects["/home/claude"].hasTrustDialogAccepted = true
    | .cachedGrowthBookFeatures //= {}
    | .cachedGrowthBookFeatures.tengu_ccr_bridge = true
    | .cachedGrowthBookFeatures.tengu_willow_refresh_ttl_hours = 168
    | .cachedGrowthBookFeatures.tengu_willow_sentinel_ttl_hours = 168
    | .cachedGrowthBookFeatures.tengu_willow_census_ttl_hours = 168
  ' ~/.claude.json > /tmp/claude-fix.json && mv /tmp/claude-fix.json ~/.claude.json
fi

# Use a temp file as a flag so the URL is registered only once per run,
# even though the pipe body runs in a subshell.
REGISTERED_FILE=$(mktemp)
trap 'rm -f "$REGISTERED_FILE"' EXIT

# Run claude remote-control and watch stdout/stderr for the session URL.
# Pipe "y\n" to stdin to auto-confirm the "Enable Remote Control? (y/n)" prompt.
# Strip ANSI escape sequences before matching the URL.
# pipefail means a non-zero exit from claude propagates through the pipe,
# causing this script to exit non-zero and triggering a systemd restart.
echo "y" | /home/claude/.local/bin/claude remote-control --name "${PROJECT_NAME:-$PROJECT_ID}" 2>&1 | \
  while IFS= read -r line; do
    echo "$line"
    # Strip ANSI escape sequences and OSC8 hyperlinks to get a clean line for URL matching.
    # OSC8 format: ESC]8;;URL BEL link-text ESC]8;; BEL — replace with just the URL.
    clean_line=$(printf '%s' "$line" | python3 -c "
import sys, re
line = sys.stdin.read()
line = re.sub(r'\x1b\]8;;([^\x07]*)\x07[^\x1b]*\x1b\]8;;\x07', r'\1', line)
line = re.sub(r'\x1b\[[0-9;]*[A-Za-z]', '', line)
sys.stdout.write(line)
")
    if [ ! -s "$REGISTERED_FILE" ] && [[ "$clean_line" =~ https://claude\.ai/code/[^[:space:]]+ ]]; then
      URL="${BASH_REMATCH[0]}"
      echo "Registering session URL: $URL"
      if /usr/local/bin/vm-mcp register-remote-session --url "$URL"; then
        echo "$URL" > "$REGISTERED_FILE"
        echo "Session URL registered successfully"
      else
        echo "Registration failed — will retry on next restart"
      fi
    fi
  done
