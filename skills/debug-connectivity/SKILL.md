---
description: Systematically diagnose DNS, port reachability, and service issues
---

Work through each tier in order. Stop when you find the problem.

## Tier 1: DNS

```bash
# Does the domain resolve at all?
dig +short A <domain>

# Does it resolve from Google's resolver (catches local caching issues)?
dig @8.8.8.8 +short A <domain>

# Does it resolve to this VM's IP?
curl -sf https://api.ipify.org
```

If DNS is wrong: use `manage-dns` or `setup-subdomain` skill to fix it.

## Tier 2: Port reachability from inside the VM

```bash
# What is listening?
ss -tlnp

# Can we reach a specific port locally?
curl -sv http://127.0.0.1:<port>/
nc -zv 127.0.0.1 <port>
```

If nothing is listening on the expected port: the service is down (see Tier 4).

## Tier 3: Port reachability from outside

```bash
# From outside (run on your laptop or another VM):
curl -sv http://<domain>:<port>/
nc -zv <ip> <port>
```

Linode VMs have no default firewall. If ports are reachable locally but not externally, check:
1. If a Linode Cloud Firewall is attached to this instance (not set up by platform by default)
2. If iptables rules are blocking: `sudo iptables -L -n -v`

## Tier 4: Service status and logs

```bash
# systemd service:
sudo systemctl status <service>
journalctl -u <service> -n 100 --no-pager

# nginx specifically:
sudo nginx -t
tail -50 /var/log/nginx/error.log

# Caddy:
journalctl -u caddy -n 50 --no-pager

# App logs:
journalctl -u app -n 100 --no-pager   # or: pm2 logs app --lines 100
```

## Tier 5: TLS

```bash
# Check cert validity and expiry:
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -dates -subject

# Is the cert for the right domain?
curl -sv https://<domain> 2>&1 | grep -E 'SSL|certificate|subject'
```

If cert is expired: re-run `setup-tls` skill.
If cert is for wrong domain: check nginx `server_name` directive and acme.sh cert domain.
