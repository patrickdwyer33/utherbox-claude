#!/usr/bin/env bash
# Starts claude remote-control and registers the session URL with the platform API.
# Runs as the claude user via utherbox-remote-session.service.
set -euo pipefail

# Skip if no Claude OAuth credentials (no crash-restart loop).
if [ ! -f /home/claude/.claude/.credentials.json ]; then
  echo "No Claude credentials found — remote session not started"
  exit 0
fi

# Load VM_NAME from .utherbox-config (written by cloud-init).
if [ ! -f /home/claude/.utherbox-config ]; then
  echo "Missing /home/claude/.utherbox-config — cannot determine VM_NAME"
  exit 1
fi
# shellcheck source=/dev/null
source /home/claude/.utherbox-config

if [ -z "${VM_NAME:-}" ]; then
  echo "VM_NAME not set in /home/claude/.utherbox-config"
  exit 1
fi

# Load platform API credentials.
PLATFORM_API_TOKEN=$(jq -r '.platform_api_token' /home/claude/.utherbox-credentials.json)
PLATFORM_API_BASE_URL=$(jq -r '.platform_api_base_url' /home/claude/.utherbox-credentials.json)

if [ -z "$PLATFORM_API_TOKEN" ] || [ "$PLATFORM_API_TOKEN" = "null" ]; then
  echo "platform_api_token missing from ~/.utherbox-credentials.json"
  exit 1
fi

echo "Starting claude remote-control for VM: $VM_NAME"

# Re-apply trust flags before each invocation (Claude Code may reset them on start).
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

# Temp files for session tracking, login error detection, and credential refresh.
REGISTERED_FILE=$(mktemp)
LOGIN_ERROR_FILE=$(mktemp)
CREDS_TMPFILE=$(mktemp)
trap 'rm -f "$REGISTERED_FILE" "$LOGIN_ERROR_FILE" "$CREDS_TMPFILE"' EXIT

# Pipe "y" to auto-confirm the "Enable Remote Control? (y/n)" prompt.
# pipefail: non-zero exit from claude propagates, triggering systemd restart.
echo "y" | /home/claude/.local/bin/claude remote-control --name "$VM_NAME" 2>&1 | \
  while IFS= read -r line; do
    echo "$line"
    # Strip ANSI escape sequences and OSC8 hyperlinks to get a clean URL.
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
      if curl -sf -X POST "$PLATFORM_API_BASE_URL/vms/me/remote-session" \
           -H "Authorization: Bearer $PLATFORM_API_TOKEN" \
           -H "Content-Type: application/json" \
           -d "{\"url\": \"$URL\"}"; then
        echo "$URL" > "$REGISTERED_FILE"
        echo "Session URL registered successfully"
      else
        echo "Registration failed — will retry on next restart"
        exit 1
      fi
    fi
    if [[ "${clean_line,,}" == *"you must be logged in"* ]]; then
      echo "Login error detected — will refresh credentials"
      echo "1" > "$LOGIN_ERROR_FILE"
    fi
  done || PIPE_EXIT=$?
PIPE_EXIT=${PIPE_EXIT:-0}

if [ -s "$LOGIN_ERROR_FILE" ]; then
  echo "Fetching fresh Claude credentials from platform API"
  HTTP_CODE=$(curl -s -o "$CREDS_TMPFILE" -w "%{http_code}" \
    "$PLATFORM_API_BASE_URL/vms/me/claude-credentials" \
    -H "Authorization: Bearer $PLATFORM_API_TOKEN")
  if [ "$HTTP_CODE" = "200" ]; then
    install -m 600 "$CREDS_TMPFILE" /home/claude/.claude/.credentials.json
    echo "Credentials refreshed — restarting"
    exit 1
  elif [ "$HTTP_CODE" = "404" ]; then
    echo "No Claude credentials on file — removing stale credentials and stopping"
    rm -f /home/claude/.claude/.credentials.json
    exit 0
  else
    echo "Failed to fetch credentials from platform API (HTTP ${HTTP_CODE:-curl_error})"
    exit 1
  fi
fi

exit $PIPE_EXIT
