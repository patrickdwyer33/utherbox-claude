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

# Use a temp file as a flag so the URL is registered only once per run,
# even though the pipe body runs in a subshell.
REGISTERED_FILE=$(mktemp)
trap 'rm -f "$REGISTERED_FILE"' EXIT

# Run claude remote-control and watch stdout/stderr for the session URL.
# pipefail means a non-zero exit from claude propagates through the pipe,
# causing this script to exit non-zero and triggering a systemd restart.
/home/claude/.local/bin/claude remote-control --name "Utherbox $PROJECT_ID" 2>&1 | \
  while IFS= read -r line; do
    echo "$line"
    if [ ! -s "$REGISTERED_FILE" ] && [[ "$line" =~ https://claude\.ai/code/[^[:space:]]+ ]]; then
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
