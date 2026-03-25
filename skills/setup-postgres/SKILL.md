---
description: Install PostgreSQL and create a secured database and role
---

## Steps

### 1. Install
```bash
sudo apt-get update && sudo apt-get install -y postgresql
sudo systemctl enable --now postgresql
```

### 2. Create database and role
```bash
DB_NAME="myapp"
DB_USER="myapp"
DB_PASS="$(openssl rand -base64 24)"

sudo -u postgres psql << SQL
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL

echo "DB_URL=postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}"
```

Write the connection string to `~/.env` or the app's config file.

### 3. Restrict to localhost

Edit `/etc/postgresql/<version>/main/pg_hba.conf`:
```bash
PG_VERSION=$(ls /etc/postgresql/)
sudo sed -i 's/^host\s\+all\s\+all\s\+0\.0\.0\.0\/0/# &/' /etc/postgresql/$PG_VERSION/main/pg_hba.conf
```

Edit `/etc/postgresql/<version>/main/postgresql.conf`:
```bash
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '127.0.0.1'/" /etc/postgresql/$PG_VERSION/main/postgresql.conf
```

```bash
sudo systemctl restart postgresql
```

### 4. Verify
```bash
psql "postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}" -c "SELECT 1"
```

## Security notes
- `listen_addresses = '127.0.0.1'` — postgres is not reachable from the network
- If an app on another VM needs access, use SSH tunnel: `ssh -L 5432:127.0.0.1:5432 claude@<db-vm-ip>`
- Never store the DB password in the git repo; use environment variables or a secrets manager
