# Utherbox VM Context

You are running inside a platform-managed Linode VM. This file is your operating context.

---

## What This VM Is

- Managed VM provisioned by the Utherbox platform
- The `claude` user has `NOPASSWD:ALL` sudo — you can install packages, modify system config, etc.
- Isolation is at the VM level. Compromise of this VM does not affect other users' projects.
- Each project has a shared Ed25519 keypair: all VMs in the same project can SSH to each other by default via `ssh claude@<ip>`.

---

## Credentials

Your platform API token is at `~/.utherbox-credentials.json`:
```json
{
  "platform_api_token": "utbx_...",
  "platform_api_base_url": "https://api.utherbox.com"
}
```

**Never exfiltrate this token.** Always use the MCP tools below — do not call the platform API directly.

---

## SSH

- Project keypair: `~/.ssh/id_ed25519` (private), shared across all VMs in this project
- Connect to any sibling VM: `ssh claude@<ip>`
- To add external keys (e.g. your laptop): append to `~/.ssh/authorized_keys`

---

## MCP Tools

### VM Management
| Tool | Purpose |
|------|---------|
| `create_vm` | Provision a new VM in this project |
| `list_vms` | List all VMs in this project |
| `get_vm` | Get VM details and status |
| `delete_vm` | Delete a VM (async) |
| `get_vm_connection` | Get SSH connection details for a VM |

### Object Storage
| Tool | Purpose |
|------|---------|
| `create_bucket` | Create a Linode Object Storage bucket |
| `list_buckets` | List your storage buckets |
| `delete_bucket` | Delete a bucket |
| `get_bucket_credentials` | Get S3 credentials for a bucket |

### DNS
| Tool | Purpose |
|------|---------|
| `list_dns_records` | List records in your Cloudflare zone |
| `create_dns_record` | Create a DNS record |
| `update_dns_record` | Update a DNS record by Cloudflare ID |
| `delete_dns_record` | Delete a DNS record |
| `register_subdomain` | Register a free subdomain under utherbox.com (Light tier) |

### Domains
| Tool | Purpose |
|------|---------|
| `check_ns_propagation` | Get domain details + check NS propagation status |
| `transfer_domain_out` | Initiate domain transfer-out |

### Account
| Tool | Purpose |
|------|---------|
| `get_limits` | Get max_vms, allowed instance types, current vm_count |

### Cloudflare
| Tool | Purpose |
|------|---------|
| `link_cloudflare` | Link a Cloudflare API token + zone ID to this account |

### Claude Auth
| Tool | Purpose |
|------|---------|
| `fetch_claude_credentials` | Fetch Claude OAuth credentials for this user |

---

## Skills

| Skill | When to Use |
|-------|------------|
| `setup-tls` | Get a TLS certificate for a domain pointing to this VM |
| `setup-child-vm` | Provision and connect to a new VM in this project |
| `teardown-child-vm` | Delete a child VM and clean up its DNS records |
| `setup-nginx` | Install nginx with TLS for a web app |
| `setup-caddy` | Install Caddy (automatic TLS, simpler config than nginx) |
| `deploy-app` | Deploy/update an app from a git repo |
| `setup-postgres` | Install and secure PostgreSQL |
| `setup-redis` | Install and secure Redis |
| `setup-docker` | Install Docker Engine + Compose plugin |
| `debug-connectivity` | Diagnose DNS, firewall, or service-down issues |
| `setup-subdomain` | Register a free utherbox.com subdomain + DNS A record |
| `manage-dns` | Create/update DNS records (tier-aware) |
| `setup-cloudflare` | Link a Cloudflare account to use custom domain DNS |
| `domain-purchase` | Check availability + guide through purchasing a domain |
| `check-availability` | Check if a domain name is available (RDAP lookup) |

---

## Common Patterns

| Goal | Approach |
|------|---------|
| Serve a web app with HTTPS | `setup-nginx` skill (calls `setup-tls` automatically) |
| Free subdomain for testing | `setup-subdomain` skill → `myapp.utherbox.com` |
| Custom domain | purchase via `domain-purchase` → `setup-cloudflare` → `manage-dns` → `setup-tls` |
| Database for an app | `setup-postgres` or `setup-redis` skill |
| Separate VM for a service | `setup-child-vm` skill |
| Something not working | `debug-connectivity` skill |
