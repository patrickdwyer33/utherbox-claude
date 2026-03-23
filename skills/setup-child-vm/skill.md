---
description: Provision a child VM and register it in ~/utherbox-vms/
---

## Prerequisites

Ask the user for anything missing:

| # | What | Notes |
|---|------|-------|
| 1 | **VM name** | used as the registry directory name |
| 2 | **Instance type** | default `g6-nanode-1` unless user specifies |
| 3 | **Region** | default to same region as this project VM |

## Steps

**1. Create the VM**
```
create_vm(label: "{name}", type: "{instance_type}", region: "{region}")
```
Note the returned IP address.

**2. Create registry entry**
```bash
mkdir -p ~/utherbox-vms/{name}
```

Write `~/utherbox-vms/{name}/state.md`:
```markdown
# {name}

ip: {ip}
created: {YYYY-MM-DD}
region: {region}
instance_type: {instance_type}

## History
- {YYYY-MM-DD}: provisioned
```

**3. Verify SSH access**
```bash
ssh root@{ip} "echo ok"
```
If this fails, wait 30s and retry — VM may still be booting.

**4. Confirm to user**

> Child VM `{name}` is ready.
> - IP: `{ip}`
> - SSH: `ssh root@{ip}`
>
> What would you like to set up on it?

## Updating state.md

After any significant action on this VM, append a line to the `## History` section and update any relevant fields. Keep it brief.
