---
description: Install Redis with authentication and localhost binding
---

## Steps

### 1. Install
```bash
sudo apt-get update && sudo apt-get install -y redis-server
```

### 2. Configure
```bash
REDIS_PASS="$(openssl rand -base64 32)"

sudo tee -a /etc/redis/redis.conf > /dev/null << EOF

# Utherbox hardening
bind 127.0.0.1
requirepass ${REDIS_PASS}
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command DEBUG ""
rename-command CONFIG ""
EOF
```

Write the password: `echo "REDIS_URL=redis://:${REDIS_PASS}@127.0.0.1:6379"`

### 3. Enable and restart
```bash
sudo systemctl enable --now redis-server
sudo systemctl restart redis-server
```

### 4. Verify
```bash
redis-cli -a "${REDIS_PASS}" PING
```
Expected: `PONG`

## Security notes
- `bind 127.0.0.1` — Redis not reachable from network
- Dangerous commands (`FLUSHALL`, `DEBUG`, `CONFIG`) disabled
- `requirepass` enforces authentication for local connections too
