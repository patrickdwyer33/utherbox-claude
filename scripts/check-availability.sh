#!/usr/bin/env bash
# Usage: check-availability.sh <domain>
# Queries ICANN RDAP to check domain registration status.
# Exit codes: 0 = available, 1 = taken, 2 = lookup error
set -euo pipefail

DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then
  echo "Usage: check-availability.sh <domain>" >&2
  exit 2
fi

# Basic domain format validation
if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$'; then
  echo "Invalid domain name: $DOMAIN" >&2
  exit 2
fi

HTTP_CODE=$(curl -sL -o /tmp/rdap-response.json -w "%{http_code}" \
  --max-time 15 \
  "https://rdap.org/domain/$DOMAIN" 2>/dev/null) || {
  echo "ERROR: RDAP lookup failed (network error)" >&2
  exit 2
}

case "$HTTP_CODE" in
  404)
    echo "AVAILABLE: $DOMAIN is not registered"
    exit 0
    ;;
  200)
    REGISTRAR=$(python3 -c "
import json, sys
try:
  data = json.load(open('/tmp/rdap-response.json'))
  entities = data.get('entities', [])
  for e in entities:
    for role in e.get('roles', []):
      if role == 'registrar':
        vcard = e.get('vcardArray', [None, []])[1]
        for field in vcard:
          if field[0] == 'fn':
            print(field[3])
            sys.exit(0)
  print('unknown registrar')
except Exception:
  print('unknown registrar')
" 2>/dev/null || echo "unknown registrar")
    EXPIRY=$(python3 -c "
import json, sys
try:
  data = json.load(open('/tmp/rdap-response.json'))
  for event in data.get('events', []):
    if event.get('eventAction') == 'expiration':
      print(event.get('eventDate', ''))
      sys.exit(0)
  print('')
except Exception:
  print('')
" 2>/dev/null || echo "")
    echo "TAKEN: $DOMAIN is registered"
    echo "  Registrar: $REGISTRAR"
    [ -n "$EXPIRY" ] && echo "  Expires: $EXPIRY"
    exit 1
    ;;
  *)
    echo "ERROR: RDAP returned unexpected status $HTTP_CODE" >&2
    exit 2
    ;;
esac
